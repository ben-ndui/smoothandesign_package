import 'package:equatable/equatable.dart';
import 'base_model.dart';

/// Types de notification de base.
enum BaseNotificationType {
  info,
  success,
  warning,
  error,
  message,
  documentCreated,
  documentUpdated,
  taskAssigned,
  taskCompleted,
  custom,
}

/// Extension pour BaseNotificationType.
extension BaseNotificationTypeExtension on BaseNotificationType {
  String get label {
    switch (this) {
      case BaseNotificationType.info:
        return 'Information';
      case BaseNotificationType.success:
        return 'Succès';
      case BaseNotificationType.warning:
        return 'Avertissement';
      case BaseNotificationType.error:
        return 'Erreur';
      case BaseNotificationType.message:
        return 'Message';
      case BaseNotificationType.documentCreated:
        return 'Document créé';
      case BaseNotificationType.documentUpdated:
        return 'Document mis à jour';
      case BaseNotificationType.taskAssigned:
        return 'Tâche assignée';
      case BaseNotificationType.taskCompleted:
        return 'Tâche terminée';
      case BaseNotificationType.custom:
        return 'Notification';
    }
  }

  static BaseNotificationType fromString(String? value) {
    if (value == null) return BaseNotificationType.info;
    return BaseNotificationType.values.firstWhere(
      (t) => t.name == value.toLowerCase(),
      orElse: () => BaseNotificationType.info,
    );
  }
}

/// Modèle notification de base.
///
/// Représente une notification utilisateur stockée en Firestore.
class BaseNotification extends Equatable implements BaseModel {
  @override
  final String id;

  /// ID de l'utilisateur destinataire.
  final String userId;

  /// Titre de la notification.
  final String title;

  /// Corps du message.
  final String body;

  /// Type de notification.
  final BaseNotificationType type;

  /// Données additionnelles (payload).
  final Map<String, dynamic>? data;

  /// Indique si la notification a été lue.
  final bool isRead;

  /// Date de création.
  final DateTime? createdAt;

  const BaseNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = BaseNotificationType.info,
    this.data,
    this.isRead = false,
    this.createdAt,
  });

  factory BaseNotification.fromMap(Map<String, dynamic> map, [String? docId]) {
    return BaseNotification(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? map['message'] ?? '',
      type: BaseNotificationTypeExtension.fromString(map['type']),
      data: map['data'] as Map<String, dynamic>?,
      isRead: map['isRead'] ?? false,
      createdAt: FirestoreModel.dateTimeFromFirestore(map['createdAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  @override
  BaseNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    BaseNotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return BaseNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Marque comme lue.
  BaseNotification markAsRead() => copyWith(isRead: true);

  /// Récupère une donnée du payload.
  T? getData<T>(String key) {
    if (data == null) return null;
    final value = data![key];
    if (value is T) return value;
    return null;
  }

  /// Temps écoulé depuis la création (format lisible).
  String get timeAgo {
    if (createdAt == null) return '';

    final diff = DateTime.now().difference(createdAt!);

    if (diff.inDays > 7) {
      return '${diff.inDays ~/ 7} sem';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min';
    } else {
      return 'À l\'instant';
    }
  }

  @override
  List<Object?> get props => [id, userId, isRead, createdAt];
}
