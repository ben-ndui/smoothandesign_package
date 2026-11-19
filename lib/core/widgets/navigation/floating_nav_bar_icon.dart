// Icône d'un onglet de [FloatingNavBar] : rebond à l'activation + pastille
// de compteur. Sorti de `floating_nav_bar_tab.dart` pour tenir la charte
// des 250 lignes ; interne à ce dossier.
import 'package:flutter/material.dart';

import 'floating_nav_bar.dart';

/// L'icône active grossit d'un cran avec un léger dépassement — un cran, pas
/// un zoom : sur une barre touchée vingt fois par session, un vrai zoom
/// fatiguerait l'œil.
class IconeQuiRebondit extends StatelessWidget {
  const IconeQuiRebondit({
    super.key,
    required this.actif,
    required this.sansAnimation,
    required this.enfant,
  });

  final bool actif;
  final bool sansAnimation;
  final Widget enfant;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: actif ? 1 : 0),
        duration:
            sansAnimation ? Duration.zero : const Duration(milliseconds: 320),
        // `easeOutBack` dépasse la valeur cible puis revient : c'est ce
        // dépassement qui donne le rebond, pas une seconde animation.
        curve: Curves.easeOutBack,
        builder: (_, avancee, enfantConstant) => Transform.scale(
          scale: 1 + 0.09 * avancee,
          child: enfantConstant,
        ),
        child: enfant,
      );
}

/// L'icône, surmontée de sa pastille de compteur s'il y a lieu.
class IconeEtBadge extends StatelessWidget {
  const IconeEtBadge({
    super.key,
    required this.item,
    required this.encre,
    required this.taille,
    required this.badge,
    required this.onBadge,
  });

  final FloatingNavItem item;
  final Color encre;
  final double taille;
  final Color badge;
  final Color onBadge;

  @override
  Widget build(BuildContext context) {
    final compteur = item.badgeCount;
    final icone = Icon(item.icon, size: taille, color: encre);
    if (compteur == null || compteur <= 0) return icone;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icone,
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: badge, borderRadius: BorderRadius.circular(9)),
            child: Text(
              // Au-delà de 99 la pastille s'élargirait au point de manger
              // l'onglet voisin ; le nombre exact n'y ajoute rien.
              compteur > 99 ? '99+' : '$compteur',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: onBadge),
            ),
          ),
        ),
      ],
    );
  }
}
