// Contenu de [FloatingNavBar] : géométrie, pastille glissante à largeur
// intrinsèque, rangée d'onglets. Sorti du fichier principal pour tenir la
// charte des 250 lignes ; interne à ce dossier, pas d'usage hors de
// `floating_nav_bar.dart`.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'floating_nav_bar.dart';
import 'floating_nav_bar_geometry.dart';
import 'floating_nav_bar_style.dart';
import 'floating_nav_bar_tab.dart';

class FloatingNavBarContent extends StatelessWidget {
  const FloatingNavBarContent({
    super.key,
    required this.items,
    required this.indexActif,
    required this.onChanged,
    required this.compact,
    required this.style,
    required this.largeurTotale,
  });

  final List<FloatingNavItem> items;
  final int indexActif;
  final ValueChanged<int> onChanged;
  final bool compact;
  final FloatingNavBarStyle style;
  final double largeurTotale;

  double _largeurIntrinsequePilule(BuildContext context, String label) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      textDirection: Directionality.of(context),
    )..layout();
    return 15 * 2 + 22 + 8 + tp.width;
  }

  /// Position du bord gauche de la pastille.
  ///
  /// La centrer dans SA zone ne suffit pas en mode compact : la zone de
  /// l'onglet actif a plus de mou que celle d'un onglet icône seule, donc ce
  /// mou — s'il tombe au bord — fuit vers le coin de la barre. Premier/
  /// dernier onglet : la pastille reste flush avec le même retrait qu'une
  /// icône dans sa propre zone ; tout le mou va vers l'intérieur.
  double _gauchePastille({
    required FloatingNavBarGeometry geo,
    required double zoneActive,
    required double largeurPastille,
  }) {
    final surUnBord = compact && (indexActif == 0 || indexActif == items.length - 1);
    if (!surUnBord) {
      return geo.gauche(indexActif) + (zoneActive - largeurPastille) / 2;
    }
    final retraitIcone = (FloatingNavBar.largeurTactileMin - 22) / 2;
    return indexActif == 0
        ? geo.gauche(indexActif) + retraitIcone
        : geo.gauche(indexActif) + zoneActive - largeurPastille - retraitIcone;
  }

  @override
  Widget build(BuildContext context) {
    final sansAnimation = MediaQuery.disableAnimationsOf(context);
    final geo = FloatingNavBarGeometry(
      largeurTotale: largeurTotale,
      nombre: items.length,
      indexActif: indexActif,
      compact: compact,
      ecart: FloatingNavBar.ecartEntreOnglets,
      largeurMin: FloatingNavBar.largeurTactileMin,
    );
    final libelleTient = geo.libelleTient(FloatingNavBar.placeMinLibelle);
    final zoneActive = geo.largeur(indexActif);
    final largeurPastille = compact && libelleTient
        ? math.min(zoneActive, _largeurIntrinsequePilule(context, items[indexActif].label))
        : zoneActive;
    final gauchePastille = _gauchePastille(
      geo: geo,
      zoneActive: zoneActive,
      largeurPastille: largeurPastille,
    );

    return Stack(
      children: [
        // La pastille, DERRIÈRE les onglets : elle glisse et change de
        // largeur d'une position à l'autre. Clé stable pour les tests
        // (mesurer sa position/largeur sans ambiguïté avec le fond du
        // conteneur, qui est aussi un DecoratedBox).
        AnimatedPositioned(
          key: const ValueKey('floating-nav-bar-pastille'),
          left: gauchePastille,
          width: largeurPastille,
          top: 0,
          bottom: 0,
          duration: sansAnimation ? Duration.zero : FloatingNavBar.dureeGlissement,
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(color: style.activePill, borderRadius: BorderRadius.circular(24)),
          ),
        ),
        Row(
          children: [
            for (final (index, item) in items.indexed) ...[
              if (index > 0) const SizedBox(width: FloatingNavBar.ecartEntreOnglets),
              // Largeur EXPLICITE, lue sur la même géométrie que la
              // pastille : les deux ne peuvent plus diverger.
              SizedBox(
                width: geo.largeur(index),
                child: FloatingNavTab(
                  item: item,
                  actif: index == indexActif,
                  compact: compact,
                  avecLibelle: !compact || (index == indexActif && libelleTient),
                  sansAnimation: sansAnimation,
                  style: style,
                  onTap: () => onChanged(index),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
