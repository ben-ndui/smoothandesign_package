import 'package:intl/intl.dart';

/// Utilitaires pour le formatage français (devise, TVA, dates).
class FrenchUtils {
  FrenchUtils._();

  // ===== Formatage monétaire =====

  /// Formate un montant en euros.
  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(amount);
  }

  /// Formate un montant en euros sans décimales si entier.
  static String formatCurrencyCompact(double amount) {
    if (amount == amount.roundToDouble()) {
      return NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 0).format(amount);
    }
    return formatCurrency(amount);
  }

  /// Parse un montant depuis une chaîne française.
  static double? parseCurrency(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleaned = value.replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  // ===== TVA =====

  /// Taux de TVA français.
  static const double tvaNormale = 20.0;
  static const double tvaIntermediaire = 10.0;
  static const double tvaReduite = 5.5;
  static const double tvaSuperReduite = 2.1;
  static const double tvaExoneree = 0.0;

  /// Calcule le montant TTC à partir du HT.
  static double calculateTTC(double amountHT, double tvaRate) {
    return amountHT * (1 + tvaRate / 100);
  }

  /// Calcule le montant HT à partir du TTC.
  static double calculateHT(double amountTTC, double tvaRate) {
    return amountTTC / (1 + tvaRate / 100);
  }

  /// Calcule le montant de TVA.
  static double calculateTVA(double amountHT, double tvaRate) {
    return amountHT * tvaRate / 100;
  }

  /// Formate un taux de TVA.
  static String formatTVARate(double rate) {
    if (rate == 0) return 'Exonéré';
    if (rate == rate.roundToDouble()) {
      return '${rate.toInt()}%';
    }
    return '${rate.toStringAsFixed(1)}%';
  }

  // ===== Dates =====

  /// Formate une date en français (ex: 15 janvier 2025).
  static String formatDateFull(DateTime date) {
    return DateFormat.yMMMMd('fr_FR').format(date);
  }

  /// Formate une date courte (ex: 15/01/2025).
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formate une date avec heure (ex: 15/01/2025 14:30).
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Formate une heure (ex: 14:30).
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Formate une durée en texte.
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) return '${minutes}min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  // ===== Numéros =====

  /// Formate un numéro de téléphone français.
  static String formatPhoneNumber(String? phone) {
    if (phone == null) return '';
    final cleaned = phone.replaceAll(RegExp(r'[\s\.\-]'), '');

    if (cleaned.length == 10) {
      return cleaned.replaceAllMapped(
        RegExp(r'(\d{2})'),
        (m) => '${m.group(0)} ',
      ).trim();
    }
    return phone;
  }

  /// Formate un SIRET avec espaces.
  static String formatSiret(String? siret) {
    if (siret == null) return '';
    final cleaned = siret.replaceAll(' ', '');
    if (cleaned.length != 14) return siret;

    return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
  }

  /// Formate un IBAN avec espaces.
  static String formatIban(String? iban) {
    if (iban == null) return '';
    final cleaned = iban.replaceAll(' ', '').toUpperCase();

    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  // ===== Texte =====

  /// Pluralise un mot français simple.
  static String pluralize(int count, String singular, [String? plural]) {
    if (count <= 1) return '$count $singular';
    return '$count ${plural ?? '${singular}s'}';
  }
}
