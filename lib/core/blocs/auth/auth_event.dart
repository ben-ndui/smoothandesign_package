import 'package:equatable/equatable.dart';
import '../../models/base_user_role.dart';

/// Events pour AuthBloc.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Vérifie l'état d'authentification actuel.
class CheckAuthEvent extends AuthEvent {
  const CheckAuthEvent();
}

/// Connexion avec email et mot de passe.
class SignInWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Inscription avec email et mot de passe.
class SignUpWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  final String? name;
  final BaseUserRole role;
  final Map<String, dynamic>? extraData;

  const SignUpWithEmailEvent({
    required this.email,
    required this.password,
    this.name,
    this.role = BaseUserRole.user,
    this.extraData,
  });

  @override
  List<Object?> get props => [email, password, name, role];
}

/// Connexion avec Google.
class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

/// Connexion avec Apple.
class SignInWithAppleEvent extends AuthEvent {
  const SignInWithAppleEvent();
}

/// Complète l'inscription sociale avec sélection de rôle.
class CompleteSocialSignUpEvent extends AuthEvent {
  final String? name;
  final BaseUserRole role;
  final Map<String, dynamic>? extraData;

  const CompleteSocialSignUpEvent({
    this.name,
    this.role = BaseUserRole.user,
    this.extraData,
  });

  @override
  List<Object?> get props => [name, role];
}

/// Déconnexion.
class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

/// Réinitialisation du mot de passe.
class ResetPasswordEvent extends AuthEvent {
  final String email;

  const ResetPasswordEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Suppression du compte.
class DeleteAccountEvent extends AuthEvent {
  const DeleteAccountEvent();
}

/// Recharge les données utilisateur.
class ReloadUserEvent extends AuthEvent {
  const ReloadUserEvent();
}

/// Mise à jour interne quand le document utilisateur change.
class UserDocumentChangedEvent extends AuthEvent {
  const UserDocumentChangedEvent();
}

/// Démarre l'impersonation d'un utilisateur (MasterDev only).
class ImpersonateUserEvent extends AuthEvent {
  final String targetUserId;

  const ImpersonateUserEvent(this.targetUserId);

  @override
  List<Object?> get props => [targetUserId];
}

/// Arrête l'impersonation et revient à l'utilisateur original.
class StopImpersonationEvent extends AuthEvent {
  const StopImpersonationEvent();
}
