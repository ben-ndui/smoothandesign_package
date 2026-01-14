import 'package:equatable/equatable.dart';
import 'base_model.dart';
import 'base_user_role.dart';

/// Modèle utilisateur de base.
///
/// Étendre cette classe pour ajouter des champs spécifiques au projet.
/// ```dart
/// class AppUser extends BaseUser {
///   final String? companyName;
///   final String? siret;
///
///   AppUser({
///     required super.uid,
///     required super.email,
///     // ...autres champs
///     this.companyName,
///     this.siret,
///   });
/// }
/// ```
class BaseUser extends Equatable implements BaseModel {
  @override
  String get id => uid;

  /// Identifiant unique Firebase Auth.
  final String uid;

  /// Adresse email.
  final String email;

  /// Nom complet.
  final String? name;

  /// Nom d'affichage.
  final String? displayName;

  /// URL de la photo de profil.
  final String? photoURL;

  /// Numéro de téléphone.
  final String? phoneNumber;

  /// Rôle de l'utilisateur.
  final BaseUserRole role;

  /// Token FCM pour les notifications push.
  final String? fcmToken;

  /// Indique si c'est la première connexion.
  final bool isFirstTime;

  /// Indique si l'utilisateur est en ligne.
  final bool isOnline;

  /// Indique si le compte est bloqué.
  final bool isBlocked;

  /// Date de création.
  final DateTime? createdAt;

  /// Dernière mise à jour.
  final DateTime? updatedAt;

  const BaseUser({
    required this.uid,
    required this.email,
    this.name,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.role = BaseUserRole.user,
    this.fcmToken,
    this.isFirstTime = true,
    this.isOnline = false,
    this.isBlocked = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Crée un BaseUser depuis une Map Firestore.
  factory BaseUser.fromMap(Map<String, dynamic> map, [String? id]) {
    return BaseUser(
      uid: id ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      displayName: map['displayName'],
      photoURL: map['photoUrl'] ?? map['photo_Url'],
      phoneNumber: map['phoneNumber'],
      role: BaseUserRoleExtension.fromString(map['role']),
      fcmToken: map['fcmToken'] ?? map['token'],
      isFirstTime: map['isFirstTime'] ?? true,
      isOnline: map['isOnline'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      createdAt: FirestoreModel.dateTimeFromFirestore(map['createdAt']),
      updatedAt: FirestoreModel.dateTimeFromFirestore(map['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'displayName': displayName,
      'photoUrl': photoURL,
      'photo_Url': photoURL,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'fcmToken': fcmToken,
      'isFirstTime': isFirstTime,
      'isOnline': isOnline,
      'isBlocked': isBlocked,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  BaseUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    BaseUserRole? role,
    String? fcmToken,
    bool? isFirstTime,
    bool? isOnline,
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BaseUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      isOnline: isOnline ?? this.isOnline,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Nom complet formaté.
  String get fullName => name ?? displayName ?? email.split('@').first;

  /// Initiales pour avatar.
  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
  }

  // Helpers de rôle
  bool get isUser => role == BaseUserRole.user;
  bool get isAdmin => role == BaseUserRole.admin;
  bool get isWorker => role == BaseUserRole.worker;
  bool get isClient => role == BaseUserRole.client;
  bool get isSuperAdmin => role == BaseUserRole.superAdmin;
  bool get hasAdminRights => isAdmin || isSuperAdmin;

  @override
  List<Object?> get props => [uid, email, role, isBlocked];
}
