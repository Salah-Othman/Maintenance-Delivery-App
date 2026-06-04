import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_app/features/auth/bloc/auth_cubit.dart';
import 'package:delivery_app/features/auth/bloc/auth_state.dart';
import 'package:delivery_app/features/auth/view/login_screen.dart';
import 'package:delivery_app/features/auth/view/register_screen.dart';
import 'package:delivery_app/features/navigation/splash_screen.dart';
import 'package:delivery_app/features/navigation/customer_shell.dart';
import 'package:delivery_app/features/navigation/technician_shell.dart';
import 'package:delivery_app/features/navigation/admin_shell.dart';
import 'package:delivery_app/features/customer/pages/home_page.dart';
import 'package:delivery_app/features/customer/pages/orders_page.dart';
import 'package:delivery_app/features/customer/pages/create_order_page.dart';
import 'package:delivery_app/features/customer/pages/order_detail_page.dart';
import 'package:delivery_app/features/customer/cubit/customer_orders_cubit.dart';
import 'package:delivery_app/features/customer/cubit/create_order_cubit.dart';
import 'package:delivery_app/features/technician/pages/tasks_page.dart';
import 'package:delivery_app/features/technician/pages/history_page.dart';
import 'package:delivery_app/features/technician/pages/task_detail_page.dart';
import 'package:delivery_app/features/technician/cubit/technician_tasks_cubit.dart';
import 'package:delivery_app/features/admin/pages/dashboard_page.dart';
import 'package:delivery_app/features/admin/pages/manage_orders_page.dart';
import 'package:delivery_app/features/admin/pages/manage_users_page.dart';
import 'package:delivery_app/features/admin/pages/order_detail_page.dart';
import 'package:delivery_app/features/admin/cubit/admin_orders_cubit.dart';
import 'package:delivery_app/features/admin/cubit/admin_users_cubit.dart';
import 'package:delivery_app/features/shared/pages/profile_page.dart';
import 'package:delivery_app/features/shared/pages/chat_detail_page.dart';
import 'package:delivery_app/features/shared/pages/chat_list_page.dart';
import 'package:delivery_app/features/shared/pages/rate_technician_page.dart';
import 'package:delivery_app/features/shared/pages/tracking_page.dart';
import 'package:delivery_app/features/shared/cubit/chat_cubit.dart';
import 'package:delivery_app/features/shared/cubit/review_cubit.dart';
import 'package:delivery_app/data/repositories/chat_repository.dart';
import 'package:delivery_app/data/repositories/order_repository.dart';
import 'package:delivery_app/data/repositories/review_repository.dart';
import 'package:delivery_app/data/repositories/user_repository.dart';

class AppRouter {
  final AuthCubit authCubit;

  AppRouter(this.authCubit);

  late final GoRouter router = GoRouter(
    refreshListenable: _AuthStateNotifier(authCubit),
    initialLocation: '/auth/login',
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => BlocProvider(
          create: (_) => ChatListCubit(context.read<ChatRepository>()),
          child: const ChatListPage(),
        ),
        routes: [
          GoRoute(
            path: ':chatId',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return BlocProvider(
                create: (_) => ChatCubit(context.read<ChatRepository>()),
                child: ChatDetailPage(
                  orderId: state.pathParameters['chatId']!,
                  participants: extra != null
                      ? List<String>.from(extra['participants'] as List)
                      : [],
                ),
              );
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final authState = context.watch<AuthCubit>().state;
          final userId = authState is Authenticated ? authState.user.uid : '';
          return BlocProvider(
            key: ValueKey('cust_$userId'),
            create: (_) => CustomerOrdersCubit(
              context.read<OrderRepository>(),
              userId,
            ),
            child: CustomerShell(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/home',
                builder: (context, state) => const CustomerHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/orders',
                builder: (context, state) => const CustomerOrdersPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => BlocProvider(
                      create: (_) => CreateOrderCubit(
                        context.read<OrderRepository>(),
                      ),
                      child: const CreateOrderPage(),
                    ),
                  ),
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => CustomerOrderDetailPage(
                      orderId: state.pathParameters['orderId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'chat',
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>?;
                          return BlocProvider(
                            create: (_) => ChatCubit(context.read<ChatRepository>()),
                            child: ChatDetailPage(
                              orderId: state.pathParameters['orderId']!,
                              participants: extra != null
                                  ? List<String>.from(extra['participants'] as List)
                                  : [],
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'track',
                        builder: (context, state) => TrackingPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'review',
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>?;
                          return BlocProvider(
                            create: (_) => ReviewCubit(context.read<ReviewRepository>()),
                            child: RateTechnicianPage(
                              orderId: state.pathParameters['orderId']!,
                              customerId: extra?['customerId'] as String? ?? '',
                              technicianId: extra?['technicianId'] as String? ?? '',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final authState = context.watch<AuthCubit>().state;
          final techId = authState is Authenticated ? authState.user.uid : '';
          return BlocProvider(
            key: ValueKey('tech_$techId'),
            create: (_) => TechnicianTasksCubit(
              context.read<OrderRepository>(),
              techId,
            ),
            child: TechnicianShell(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/technician/tasks',
                builder: (context, state) => const TechnicianTasksPage(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => TechnicianTaskDetailPage(
                      orderId: state.pathParameters['orderId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'chat',
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>?;
                          return BlocProvider(
                            create: (_) => ChatCubit(context.read<ChatRepository>()),
                            child: ChatDetailPage(
                              orderId: state.pathParameters['orderId']!,
                              participants: extra != null
                                  ? List<String>.from(extra['participants'] as List)
                                  : [],
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'track',
                        builder: (context, state) => TrackingPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/technician/history',
                builder: (context, state) => const TechnicianHistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/technician/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => AdminOrdersCubit(
                  context.read<OrderRepository>(),
                ),
              ),
              BlocProvider(
                create: (_) => AdminUsersCubit(
                  context.read<UserRepository>(),
                ),
              ),
            ],
            child: AdminShell(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                builder: (context, state) => const AdminDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/orders',
                builder: (context, state) => const AdminManageOrdersPage(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => AdminOrderDetailPage(
                      orderId: state.pathParameters['orderId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'chat',
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>?;
                          return BlocProvider(
                            create: (_) => ChatCubit(context.read<ChatRepository>()),
                            child: ChatDetailPage(
                              orderId: state.pathParameters['orderId']!,
                              participants: extra != null
                                  ? List<String>.from(extra['participants'] as List)
                                  : [],
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'track',
                        builder: (context, state) => TrackingPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                builder: (context, state) => const AdminManageUsersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  String? _guard(BuildContext context, GoRouterState state) {
    final authState = authCubit.state;
    final location = state.matchedLocation;

    final isAuthRoute = location.startsWith('/auth');
    final isSplash = location == '/splash';
    final isGlobal = location.startsWith('/chats');

    if (authState is AuthInitial || authState is AuthLoading) {
      if (!isSplash) return '/splash';
      return null;
    }

    if (authState is Unauthenticated) {
      if (!isAuthRoute) return '/auth/login';
      return null;
    }

    if (authState is Authenticated) {
      if (authState.user.role.isEmpty) return '/auth/login';
      if (isAuthRoute || isSplash) return _homeRouteForRole(authState.user.role);
      if (isGlobal) return null;
      final expectedPrefix = _pathPrefixForRole(authState.user.role);
      if (expectedPrefix.isEmpty || !location.startsWith(expectedPrefix)) {
        return _homeRouteForRole(authState.user.role);
      }
      return null;
    }

    return '/splash';
  }

  String _homeRouteForRole(String role) {
    switch (role) {
      case 'customer':
        return '/customer/home';
      case 'technician':
        return '/technician/tasks';
      case 'admin':
        return '/admin/dashboard';
      default:
        return '/auth/login';
    }
  }

  String _pathPrefixForRole(String role) {
    switch (role) {
      case 'customer':
        return '/customer';
      case 'technician':
        return '/technician';
      case 'admin':
        return '/admin';
      default:
        return '';
    }
  }
}

class _AuthStateNotifier extends ChangeNotifier {
  final AuthCubit _authCubit;

  _AuthStateNotifier(this._authCubit) {
    _authCubit.stream.listen((_) => notifyListeners());
  }
}
