import 'package:equatable/equatable.dart';
import '../../models/base_notification.dart';

/// États pour NotificationBloc.
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// État initial.
class NotificationInitialState extends NotificationState {
  const NotificationInitialState();
}

/// Chargement en cours.
class NotificationLoadingState extends NotificationState {
  const NotificationLoadingState();
}

/// Notifications chargées.
class NotificationLoadedState extends NotificationState {
  final List<BaseNotification> notifications;

  const NotificationLoadedState({required this.notifications});

  /// Nombre de notifications non lues.
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Indique s'il y a des notifications non lues.
  bool get hasUnread => unreadCount > 0;

  /// Notifications non lues.
  List<BaseNotification> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  @override
  List<Object?> get props => [notifications];
}

/// Erreur.
class NotificationErrorState extends NotificationState {
  final String message;

  const NotificationErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
