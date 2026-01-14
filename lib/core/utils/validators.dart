/// Utilitaires de validation.
class Validators {
  Validators._();

  /// Valide un email.
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Valide un numéro de téléphone français.
  static bool isValidFrenchPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final cleaned = phone.replaceAll(RegExp(r'[\s\.\-]'), '');
    return RegExp(r'^(?:(?:\+|00)33|0)[1-9](?:[0-9]{8})$').hasMatch(cleaned);
  }

  /// Valide un SIRET (14 chiffres).
  static bool isValidSiret(String? siret) {
    if (siret == null) return false;
    final cleaned = siret.replaceAll(' ', '');
    if (cleaned.length != 14) return false;
    if (!RegExp(r'^\d{14}$').hasMatch(cleaned)) return false;

    // Algorithme de Luhn
    int sum = 0;
    for (int i = 0; i < 14; i++) {
      int digit = int.parse(cleaned[i]);
      if (i % 2 == 0) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }
    return sum % 10 == 0;
  }

  /// Valide un SIREN (9 premiers chiffres du SIRET).
  static bool isValidSiren(String? siren) {
    if (siren == null) return false;
    final cleaned = siren.replaceAll(' ', '');
    if (cleaned.length != 9) return false;
    return RegExp(r'^\d{9}$').hasMatch(cleaned);
  }

  /// Valide un numéro de TVA intracommunautaire français.
  static bool isValidFrenchVat(String? vat) {
    if (vat == null) return false;
    final cleaned = vat.replaceAll(' ', '').toUpperCase();
    return RegExp(r'^FR[0-9A-Z]{2}[0-9]{9}$').hasMatch(cleaned);
  }

  /// Valide un IBAN.
  static bool isValidIban(String? iban) {
    if (iban == null || iban.isEmpty) return false;
    final cleaned = iban.replaceAll(' ', '').toUpperCase();
    if (cleaned.length < 15 || cleaned.length > 34) return false;
    return RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+$').hasMatch(cleaned);
  }

  /// Valide un code postal français.
  static bool isValidFrenchPostalCode(String? code) {
    if (code == null) return false;
    return RegExp(r'^[0-9]{5}$').hasMatch(code);
  }

  /// Valide un mot de passe (min 6 caractères).
  static bool isValidPassword(String? password, {int minLength = 6}) {
    if (password == null) return false;
    return password.length >= minLength;
  }

  /// Valide un mot de passe fort.
  static bool isStrongPassword(String? password) {
    if (password == null || password.length < 8) return false;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    return hasUppercase && hasLowercase && hasDigit;
  }

  /// Valide une URL.
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }

  /// Vérifie si une chaîne n'est pas vide.
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Retourne un message d'erreur ou null si valide.
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email requis';
    if (!isValidEmail(email)) return 'Email invalide';
    return null;
  }

  /// Retourne un message d'erreur ou null si valide.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Mot de passe requis';
    if (password.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  /// Retourne un message d'erreur ou null si valide.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName requis';
    return null;
  }
}
