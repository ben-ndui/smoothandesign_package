// Contenu de [FloatingNavBar] : géométrie des onglets, rangée. Sorti du
// fichier principal pour tenir la charte des 250 lignes ; interne à ce
// dossier, pas d'usage hors de `floating_nav_bar.dart`.
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

    return Row(
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) const SizedBox(width: FloatingNavBar.ecartEntreOnglets),
          // Largeur EXPLICITE (pas Expanded) : un onglet plus large que sa
          // part égale décentrerait son icône.
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
    );
  }
}
