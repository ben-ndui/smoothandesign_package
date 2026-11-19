import 'package:flutter/material.dart';

/// Couleurs de [FloatingNavBar] — PAS de `ThemeExtension` imposé : chaque
/// app passe les siennes (Nuit ouverte, BrandTheme VAGUA…), le composant ne
/// connaît qu'une palette abstraite.
@immutable
class FloatingNavBarStyle {
  const FloatingNavBarStyle({
    required this.background,
    required this.border,
    required this.shadow,
    required this.inactiveContent,
    required this.activePill,
    required this.activeContent,
    this.badge = const Color(0xFFEE4B4B),
    this.onBadge = Colors.white,
  });

  /// Fond de la barre — toujours PLEIN, jamais translucide : un fond
  /// translucide ferait varier le contraste des libellés selon ce qui
  /// flotte en dessous.
  final Color background;
  final Color border;
  final List<BoxShadow> shadow;

  /// Icône/libellé d'un onglet inactif.
  final Color inactiveContent;

  /// Fond de la pastille de l'onglet actif.
  final Color activePill;

  /// Icône/libellé de l'onglet actif, posés sur [activePill].
  final Color activeContent;

  final Color badge;
  final Color onBadge;
}
