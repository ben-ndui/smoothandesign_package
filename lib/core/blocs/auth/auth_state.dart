import 'package:equatable/equatable.dart';
import '../../models/base_user.dart';

/// États pour AuthBloc.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// État initial.
class AuthInitialState extends AuthState {
  const AuthInitialState();
}

/// Chargement en cours.
class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

/// Chargement Google en cours.
class AuthGoogleLoadingState extends AuthState {
  const AuthGoogleLoadingState();
}

/// Chargement Apple en cours.
class AuthAppleLoadingState extends AuthState {
  const AuthAppleLoadingState();
}

/// Utilisateur authentifié.
class AuthAuthenticatedState extends AuthState {
  final BaseUser user;

  const AuthAuthenticatedState({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Utilisateur non authentifié.
class AuthUnauthenticatedState extends AuthState {
  const AuthUnauthenticatedState();
}

/// Nouvel utilisateur social - nécessite sélection de rôle.
class AuthNeedsRoleSelectionState extends AuthState {
  const AuthNeedsRoleSelectionState();
}

/// Email de réinitialisation envoyé.
class AuthPasswordResetSentState extends AuthState {
  final String email;

  const AuthPasswordResetSentState({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Compte supprimé.
class AuthAccountDeletedState extends AuthState {
  const AuthAccountDeletedState();
}

/// Erreur d'authentification.
class AuthErrorState extends AuthState {
  final String message;
  final int? code;

  const AuthErrorState({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Utilisateur impersoné (MasterDev only).
class AuthImpersonatingState extends AuthState {
  final BaseUser originalUser;
  final BaseUser impersonatedUser;

  const AuthImpersonatingState({
    required this.originalUser,
    required this.impersonatedUser,
  });

  /// Retourne l'utilisateur impersoné comme utilisateur actif.
  BaseUser get user => impersonatedUser;

  @override
  List<Object?> get props => [originalUser, impersonatedUser];
}

/// App verrouillée — token Firebase toujours en cache, mais l'UI doit
/// demander une vérification biométrique avant de remettre l'utilisateur
/// au dashboard. Le user est embarqué pour pouvoir afficher l'avatar/nom
/// sur l'écran de verrouillage sans avoir à le re-fetch.
class AuthLockedState extends AuthState {
  final BaseUser user;
  final DateTime lockedAt;

  const AuthLockedState({
    required this.user,
    required this.lockedAt,
  });

  @override
  List<Object?> get props => [user, lockedAt];
}
