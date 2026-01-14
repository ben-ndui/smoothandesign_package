import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utilitaires pour la gestion des couleurs et du contraste.
///
/// Conforme aux standards WCAG 2.1 pour l'accessibilité.
class ColorUtils {
  ColorUtils._();

  /// Vérifie si un hex est valide (avec ou sans #).
  static bool isValidHex(String hex) {
    final cleaned = hex.replaceAll('#', '').toUpperCase();
    if (cleaned.length != 6) return false;
    return RegExp(r'^[0-9A-F]{6}$').hasMatch(cleaned);
  }

  /// Normalise un hex (retourne sans #, en majuscules).
  static String normalizeHex(String hex) {
    return hex.replaceAll('#', '').toUpperCase();
  }

  /// Convertit un hex en Color Flutter.
  static Color hexToColor(String hex) {
    final cleaned = normalizeHex(hex);
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  /// Convertit un Color en hex (sans #).
  static String colorToHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '$r$g$b'.toUpperCase();
  }

  /// Calcule la luminosité relative selon WCAG 2.1.
  /// Retourne une valeur entre 0 (noir) et 1 (blanc).
  static double getRelativeLuminance(String hex) {
    final color = hexToColor(hex);

    double r = color.r;
    double g = color.g;
    double b = color.b;

    // Correction gamma sRGB
    r = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
    g = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
    b = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calcule la couleur de texte optimale pour un fond donné.
  /// Retourne 'FFFFFF' (blanc) ou '000000' (noir).
  static String getContrastTextColor(String backgroundHex) {
    final luminance = getRelativeLuminance(backgroundHex);
    return luminance > 0.179 ? '000000' : 'FFFFFF';
  }

  /// Vérifie si une couleur est considérée comme claire.
  static bool isLightColor(String hex) {
    return getRelativeLuminance(hex) > 0.179;
  }

  /// Calcule le ratio de contraste entre deux couleurs (WCAG).
  static double getContrastRatio(String hex1, String hex2) {
    final l1 = getRelativeLuminance(hex1);
    final l2 = getRelativeLuminance(hex2);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Retourne true si le contraste est suffisant (>= 4.5:1 pour AA).
  static bool hasGoodContrast(String textHex, String bgHex) {
    return getContrastRatio(textHex, bgHex) >= 4.5;
  }

  /// Éclaircit une couleur d'un certain pourcentage.
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Assombrit une couleur d'un certain pourcentage.
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
