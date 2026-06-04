class AppConstants {
  static const String appName = 'Delivery App';
}

enum UserRole {
  customer,
  technician,
  admin;

  String get value => name;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere((r) => r.name == value);
  }
}

enum OrderStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.inProgress:
        return 'in_progress';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'in_progress':
        return OrderStatus.inProgress;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

enum OrderType {
  maintenance,
  delivery;

  String get value => name;

  static OrderType fromString(String value) {
    return OrderType.values.firstWhere((r) => r.name == value);
  }
}
