import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/core/bloc/app_bloc_observer.dart';
import 'package:delivery_app/core/localization/app_localizations.dart';
import 'package:delivery_app/core/localization/locale_cubit.dart';
import 'package:delivery_app/core/router/app_router.dart';
import 'package:delivery_app/core/services/notification_service.dart';
import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/core/theme/theme_cubit.dart';
import 'package:delivery_app/data/datasources/firebase_auth_datasource.dart';
import 'package:delivery_app/data/datasources/firebase_firestore_datasource.dart';
import 'package:delivery_app/data/repositories/auth_repository.dart';
import 'package:delivery_app/data/repositories/chat_repository.dart';
import 'package:delivery_app/data/repositories/order_repository.dart';
import 'package:delivery_app/data/repositories/review_repository.dart';
import 'package:delivery_app/data/repositories/user_repository.dart';
import 'package:delivery_app/features/auth/bloc/auth_cubit.dart';
import 'package:delivery_app/features/auth/bloc/auth_state.dart';

final NotificationService notificationService = NotificationService(FirebaseFirestoreDataSource(FirebaseFirestore.instance));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  Bloc.observer = AppBlocObserver();

  try {
    await SharedPreferences.getInstance();
  } catch (_) {}

  runApp(const DeliveryApp());
}

class _NotifInit extends StatefulWidget {
  final Widget child;
  const _NotifInit({required this.child});

  @override
  State<_NotifInit> createState() => _NotifInitState();
}

class _NotifInitState extends State<_NotifInit> {
  @override
  void initState() {
    super.initState();
    final authCubit = context.read<AuthCubit>();
    final state = authCubit.state;
    if (state is Authenticated) {
      notificationService.initialize(userId: state.user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          notificationService.initialize(userId: state.user.uid);
        }
      },
      child: widget.child,
    );
  }
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = FirebaseAuth.instance;
    final firebaseFirestore = FirebaseFirestore.instance;

    final authDataSource = FirebaseAuthDataSource(firebaseAuth);
    final firestoreDataSource = FirebaseFirestoreDataSource(firebaseFirestore);

    final authRepository = AuthRepository(authDataSource);
    final orderRepository = OrderRepository(firestoreDataSource);
    final chatRepository = ChatRepository(firestoreDataSource);
    final reviewRepository = ReviewRepository(firestoreDataSource);
    final userRepository = UserRepository(firestoreDataSource);

    final authCubit = AuthCubit(
      authRepository: authRepository,
      userRepository: userRepository,
    )..checkAuth();

    final router = AppRouter(authCubit).router;
    NotificationService.initRouter(router);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: orderRepository),
        RepositoryProvider.value(value: chatRepository),
        RepositoryProvider.value(value: reviewRepository),
        RepositoryProvider.value(value: userRepository),
      ],
      child: BlocProvider.value(
        value: authCubit,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider(create: (_) => LocaleCubit()),
          ],
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return BlocBuilder<LocaleCubit, Locale>(
                builder: (context, locale) {
                  return _NotifInit(
                    child: MaterialApp.router(
                      title: 'Delivery App',
                      theme: AppTheme.lightTheme,
                      darkTheme: AppTheme.darkTheme,
                      themeMode: themeMode,
                      routerConfig: router,
                      debugShowCheckedModeBanner: false,
                      locale: locale,
                      supportedLocales: const [
                        Locale('en'),
                        Locale('ar'),
                      ],
                      localizationsDelegates: const [
                        AppLocalizationsDelegate(),
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      localeResolutionCallback: (locale, supportedLocales) {
                        if (locale != null && supportedLocales.contains(locale)) {
                          return locale;
                        }
                        return const Locale('en');
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
