import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../firebase/smooth_firebase.dart';
import '../../services/base_auth_service.dart';
import '../../models/base_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC d'authentification générique.
///
/// Gère l'état d'authentification avec support Email, Google et Apple.
/// Peut être étendu pour une logique métier spécifique.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final BaseAuthService _authService;
  StreamSubscription? _userDocSubscription;
  BaseUser? _originalUser; // Stocke l'utilisateur original lors de l'impersonation

  AuthBloc({required BaseAuthService authService})
      : _authService = authService,
        super(const AuthInitialState()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<SignInWithEmailEvent>(_onSignInWithEmail);
    on<SignUpWithEmailEvent>(_onSignUpWithEmail);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignInWithAppleEvent>(_onSignInWithApple);
    on<CompleteSocialSignUpEvent>(_onCompleteSocialSignUp);
    on<SignOutEvent>(_onSignOut);
    on<ResetPasswordEvent>(_onResetPassword);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<ReloadUserEvent>(_onReloadUser);
    on<UserDocumentChangedEvent>(_onUserDocumentChanged);
    on<ImpersonateUserEvent>(_onImpersonateUser);
    on<StopImpersonationEvent>(_onStopImpersonation);
    on<LockAppEvent>(_onLockApp);
    on<UnlockAppEvent>(_onUnlockApp);
  }

  /// Utilisateur actuellement connecté.
  BaseUser? get currentUser => _authService.currentUser;

  /// Vérifie si un utilisateur est authentifié.
  bool get isAuthenticated =>
      state is AuthAuthenticatedState || state is AuthImpersonatingState;

  /// Vérifie si en mode impersonation.
  bool get isImpersonating => state is AuthImpersonatingState;

  /// Utilisateur original (avant impersonation).
  BaseUser? get originalUser => _originalUser;

  /// Utilisateur actif (impersoné ou réel).
  BaseUser? get activeUser {
    if (state is AuthImpersonatingState) {
      return (state as AuthImpersonatingState).impersonatedUser;
    }
    if (state is AuthAuthenticatedState) {
      return (state as AuthAuthenticatedState).user;
    }
    return null;
  }

  Future<void> _onCheckAuth(
    CheckAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    if (SmoothFirebase.currentUser != null) {
      try {
        await _authService.reloadUser();
      } catch (_) {
        // reloadUser() can throw on cold start when the network stack isn't
        // ready yet (notably on iOS TestFlight release builds). Swallow and
        // fall back to the cached user — leaving the BLoC stuck on
        // AuthLoadingState would freeze the splash screen indefinitely.
      }

      if (_authService.currentUser != null) {
        if (await _authService.isAppLocked) {
          emit(AuthLockedState(
            user: _authService.currentUser!,
            lockedAt: DateTime.now(),
          ));
        } else {
          _startUserDocListener();
          emit(AuthAuthenticatedState(user: _authService.currentUser!));
        }
      } else {
        emit(const AuthUnauthenticatedState());
      }
    } else {
      emit(const AuthUnauthenticatedState());
    }
  }

  Future<void> _onLockApp(
    LockAppEvent event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authService.currentUser;
    if (user == null) return;
    // Must stop the user-doc listener before emitting: side effects of the
    // app-level Auth listener (e.g. clearing FCM token writes back to the
    // user doc) would otherwise trigger UserDocumentChangedEvent, which
    // re-emits AuthAuthenticatedState and undoes the lock instantly.
    _stopUserDocListener();
    await _authService.lockApp();
    emit(AuthLockedState(user: user, lockedAt: DateTime.now()));
  }

  Future<void> _onUnlockApp(
    UnlockAppEvent event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authService.currentUser;
    if (user == null) {
      // Edge case: token expired while locked — drop to unauthenticated.
      await _authService.unlockApp();
      emit(const AuthUnauthenticatedState());
      return;
    }
    await _authService.unlockApp();
    _startUserDocListener();
    emit(AuthAuthenticatedState(user: user));
  }

  Future<void> _onSignInWithEmail(
    SignInWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    final response = await _authService.signInWithEmail(
      event.email,
      event.password,
    );

    if (response.isSuccess) {
      _startUserDocListener();
      emit(AuthAuthenticatedState(user: _authService.currentUser!));
    } else {
      emit(AuthErrorState(message: response.message, code: response.code));
    }
  }

  Future<void> _onSignUpWithEmail(
    SignUpWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    final response = await _authService.signUpWithEmail(
      email: event.email,
      password: event.password,
      name: event.name,
      role: event.role,
      extraData: event.extraData,
    );

    if (response.isSuccess) {
      _startUserDocListener();
      emit(AuthAuthenticatedState(user: response.data!));
    } else {
      emit(AuthErrorState(message: response.message, code: response.code));
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthGoogleLoadingState());

    final response = await _authService.signInWithGoogle();

    if (response.code == 201) {
      // Nouvel utilisateur - nécessite sélection de rôle
      emit(const AuthNeedsRoleSelectionState());
    } else if (response.isSuccess) {
      _startUserDocListener();
      emit(AuthAuthenticatedState(user: _authService.currentUser!));
    } else {
      emit(AuthErrorState(message: response.message, code: response.code));
    }
  }

  Future<void> _onSignInWithApple(
    SignInWithAppleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthAppleLoadingState());

    final response = await _authService.signInWithApple();

    if (response.code == 201) {
      emit(const AuthNeedsRoleSelectionState());
    } else if (response.isSuccess) {
      _startUserDocListener();
      emit(AuthAuthenticatedState(user: _authService.currentUser!));
    } else {
      emit(AuthErrorState(message: response.message, code: response.code));
    }
  }

  Future<void> _onCompleteSocialSignUp(
    CompleteSocialSignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    final response = await _authService.completeSocialSignUp(
      name: event.name,
      role: event.role,
      extraData: event.extraData,
    );

    if (response.isSuccess) {
      _startUserDocListener();
      emit(AuthAuthenticatedState(user: response.data!));
    } else {
      emit(AuthErrorState(message: response.message, code: response.code));
    }
  }

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    _stopUserDocListener();
    await _authService.signOut();
    emit(const AuthUnauthenticatedState());
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Un reset lancé depuis le profil (utilisateur connecté) ne doit PAS
    // faire sortir le bloc de l'état authentifié : les listeners app-level
    // interpréteraient la transition comme une déconnexion (suppression du
    // token FCM, reset calendrier…). On saute le AuthLoadingState dans ce
    // cas et on restaure l'état authentifié après l'émission transitoire.
    final wasAuthenticated = state is AuthAuthenticatedState;
    final userBefore = _authService.currentUser;
    if (!wasAuthenticated) {
      emit(const AuthLoadingState());
    }

    final response = await _authService.resetPassword(event.email);

    if (response.isSuccess) {
      emit(AuthPasswordResetSentState(email: event.email));
    } else {
      emit(AuthErrorState(message: response.message, code: response.code));
    }

    if (wasAuthenticated && userBefore != null) {
      emit(AuthAuthenticatedState(user: userBefore));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    final response = await _authService.deleteAccount();

    if (response.isSuccess) {
      _stopUserDocListener();
      emit(const AuthAccountDeletedState());
    } else {
      emit(AuthErrorState(message: response.message, code: response.code));
    }
  }

  Future<void> _onReloadUser(
    ReloadUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.reloadUser();
    } catch (_) {
      // Timeout / blip réseau : on garde l'utilisateur en cache plutôt
      // que de laisser l'exception remonter en erreur de zone non gérée.
    }
    if (_authService.currentUser != null) {
      emit(AuthAuthenticatedState(user: _authService.currentUser!));
    }
  }

  Future<void> _onUserDocumentChanged(
    UserDocumentChangedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.reloadUser();
    } catch (_) {
      // Idem : ne pas transformer un échec de reload en crash fatal.
    }
    if (_authService.currentUser != null) {
      emit(AuthAuthenticatedState(user: _authService.currentUser!));
    }
  }

  void _startUserDocListener() {
    if (SmoothFirebase.currentUserId == null) return;

    _userDocSubscription?.cancel();
    _userDocSubscription = SmoothFirebase.collection('users')
        .doc(SmoothFirebase.currentUserId!)
        .snapshots()
        .listen((_) {
      add(const UserDocumentChangedEvent());
    }, onError: (_) {
      // permission-denied pendant la fenêtre de suppression de compte ou
      // sur token révoqué : sans onError, l'erreur remonte à
      // runZonedGuarded et est enregistrée comme crash fatal.
    });
  }

  void _stopUserDocListener() {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
  }

  Future<void> _onImpersonateUser(
    ImpersonateUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Stocker l'utilisateur original
    if (_originalUser == null) {
      _originalUser = _authService.currentUser;
    }

    if (_originalUser == null) {
      emit(const AuthErrorState(message: 'Pas d\'utilisateur connecté'));
      return;
    }

    emit(const AuthLoadingState());

    // Charger l'utilisateur cible depuis Firestore
    final targetDoc = await SmoothFirebase.collection('users')
        .doc(event.targetUserId)
        .get();

    if (!targetDoc.exists || targetDoc.data() == null) {
      emit(AuthAuthenticatedState(user: _originalUser!));
      return;
    }

    final impersonatedUser = BaseUser.fromMap(
      targetDoc.data()!,
      targetDoc.id,
    );

    emit(AuthImpersonatingState(
      originalUser: _originalUser!,
      impersonatedUser: impersonatedUser,
    ));
  }

  Future<void> _onStopImpersonation(
    StopImpersonationEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_originalUser == null) {
      emit(const AuthErrorState(message: 'Pas d\'utilisateur original'));
      return;
    }

    final original = _originalUser!;
    _originalUser = null;

    emit(AuthAuthenticatedState(user: original));
  }

  @override
  Future<void> close() {
    _stopUserDocListener();
    return super.close();
  }
}
