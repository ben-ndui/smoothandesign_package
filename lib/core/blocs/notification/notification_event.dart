import 'package:equatable/equatable.dart';
import '../../models/base_notification.dart';

/// Events pour NotificationBloc.
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Charge les notifications pour un utilisateur.
class LoadNotificationsEvent extends NotificationEvent {
  final String userId;

  const LoadNotificationsEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Marque une notification comme lue.
class MarkNotificationAsReadEvent extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsReadEvent({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Marque toutes les notifications comme lues.
class MarkAllNotificationsAsReadEvent extends NotificationEvent {
  const MarkAllNotificationsAsReadEvent();
}

/// Supprime une notification.
class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;

  const DeleteNotificationEvent({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Supprime toutes les notifications.
class DeleteAllNotificationsEvent extends NotificationEvent {
  const DeleteAllNotificationsEvent();
}

/// Mise à jour interne des notifications (depuis stream).
class NotificationsUpdatedEvent extends NotificationEvent {
  final List<BaseNotification> notifications;

  const NotificationsUpdatedEvent({required this.notifications});

  @override
  List<Object?> get props => [notifications];
}
