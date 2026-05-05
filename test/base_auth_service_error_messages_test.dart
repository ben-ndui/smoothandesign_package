import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_package/core/services/base_auth_service.dart';

FirebaseAuthException _exc(String code, {String? message}) =>
    FirebaseAuthException(code: code, message: message);

void main() {
  group('BaseAuthService.authErrorMessageFor', () {
    test('maps wrong-password / user-not-found / invalid-credential to a single user-friendly line', () {
      // The 3 codes share the same surface message because Firebase's
      // emailPrivacyConfig collapses them when enabled. Locking the same
      // message for all 3 prevents a regression where one of them slips
      // back to the raw "INVALID_LOGIN_CREDENTIALS" string.
      const expected = 'Email ou mot de passe incorrect';
      expect(BaseAuthService.authErrorMessageFor(_exc('user-not-found')),
          expected);
      expect(BaseAuthService.authErrorMessageFor(_exc('wrong-password')),
          expected);
      expect(BaseAuthService.authErrorMessageFor(_exc('invalid-credential')),
          expected);
      expect(
          BaseAuthService.authErrorMessageFor(_exc('INVALID_LOGIN_CREDENTIALS')),
          expected);
    });

    test('common Firebase Auth codes have human messages', () {
      expect(BaseAuthService.authErrorMessageFor(_exc('email-already-in-use')),
          'Cet email est déjà utilisé');
      expect(BaseAuthService.authErrorMessageFor(_exc('invalid-email')),
          'Email invalide');
      expect(BaseAuthService.authErrorMessageFor(_exc('weak-password')),
          contains('faible'));
      expect(BaseAuthService.authErrorMessageFor(_exc('user-disabled')),
          contains('désactivé'));
      expect(BaseAuthService.authErrorMessageFor(_exc('too-many-requests')),
          contains('Trop de tentatives'));
      expect(
          BaseAuthService.authErrorMessageFor(_exc('network-request-failed')),
          contains('internet'));
      expect(BaseAuthService.authErrorMessageFor(_exc('operation-not-allowed')),
          contains('désactivée'));
    });

    test('unknown code falls back to the exception message', () {
      final msg = BaseAuthService.authErrorMessageFor(
          _exc('something-completely-new', message: 'Server explosion'));
      expect(msg, 'Server explosion');
    });

    test('unknown code with null message falls back to a generic line', () {
      final msg =
          BaseAuthService.authErrorMessageFor(_exc('something-completely-new'));
      expect(msg, 'Une erreur est survenue');
    });
  });
}
