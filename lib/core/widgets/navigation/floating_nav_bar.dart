// Barre de navigation flottante — gabarit VaguaNavBar, décrété par Ben le
// 29/09/2026 pour tous les projets S&D mobiles : hauteur 68, rayon 32,
// marge basse 4 au-dessus de la safe area (24 la posait trop haut, 0 la
// fait intercepter par le geste d'accueil), onglets ≥56 de zone tactile
// (44 au plancher).
//
// Extrait ici le 19/11/2026 après un deuxième portage manuel raté (sur
// `performance_academy`) : chaque app réécrivait ce composant à la main
// depuis sa seule DESCRIPTION, jamais depuis le code, et reproduisait les
// mêmes bugs (icône décentrée par un `Expanded`, aucune animation, pastille
// qui occupe toute la zone tactile au lieu de sa largeur intrinsèque).
// Mécanique fidèle à `taxiboat/lib/widgets/vagua/vagua_nav_bar*.dart` — les
// couleurs sont un paramètre ([FloatingNavBarStyle]), pas un thème imposé :
// chaque app garde son identité (bleu maison VAGUA/PRC/Maki, accent propre
// d'un site vitrine ou d'une app avec sa propre charte).
import 'package:flutter/material.dart';

import 'floating_nav_bar_content.dart';
import 'floating_nav_bar_style.dart';

class FloatingNavItem {
  const FloatingNavItem({required this.icon, required this.label, this.badgeCount});

  final IconData icon;
  final String label;

  /// Nombre en attente (ex. demandes à traiter). `null` ou 0 n'affiche rien.
  final int? badgeCount;
}

/// Barre de navigation flottante du gabarit VaguaNavBar.
///
/// ## Fond PLEIN, jamais translucide
/// Elle flotte au-dessus d'un écran qui défile : un fond translucide ferait
/// varier le contraste des libellés selon ce qui passe en dessous.
///
/// ## La pastille GLISSE, à largeur INTRINSÈQUE
/// Elle vit derrière la rangée et se déplace plutôt que de basculer d'un
/// coup — l'œil suit un objet, il ne constate pas un changement d'état. Sa
/// largeur suit son propre contenu (icône + libellé), pas la zone tactile
/// de l'onglet actif, qui peut être bien plus large sur un petit nombre
/// d'onglets serrés (zone tactile généreuse, pastille visuelle centrée
/// dedans — sinon un grand aplat vide suit le libellé).
///
/// ⚠️ Tout est coupé quand le système demande de réduire les animations
/// (`MediaQuery.disableAnimationsOf`) : quelqu'un qui les a désactivées
/// dans iOS ne doit pas les récupérer parce qu'une app a réimplémenté les
/// siennes.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar._({
    super.key,
    required this.items,
    required this.indexActif,
    required this.onChanged,
    required this.compact,
    required this.style,
  });

  /// Chaque onglet porte son libellé sous l'icône. Tient jusqu'à 4 onglets.
  const FloatingNavBar.complet({
    Key? key,
    required List<FloatingNavItem> items,
    required int indexActif,
    required ValueChanged<int> onChanged,
    required FloatingNavBarStyle style,
  }) : this._(
          key: key,
          items: items,
          indexActif: indexActif,
          onChanged: onChanged,
          compact: false,
          style: style,
        );

  /// Seul l'onglet actif porte son libellé, dans une pastille à largeur
  /// intrinsèque ; les autres sont des icônes à zone tactile garantie.
  ///
  /// Pour les barres à plus de 4 onglets : afficher six libellés les
  /// tronquerait tous, alors qu'un seul — celui qu'on vient de choisir —
  /// peut se permettre de se tronquer en dernier recours.
  const FloatingNavBar.compact({
    Key? key,
    required List<FloatingNavItem> items,
    required int indexActif,
    required ValueChanged<int> onChanged,
    required FloatingNavBarStyle style,
  }) : this._(
          key: key,
          items: items,
          indexActif: indexActif,
          onChanged: onChanged,
          compact: true,
          style: style,
        );

  final List<FloatingNavItem> items;
  final int indexActif;
  final ValueChanged<int> onChanged;
  final bool compact;
  final FloatingNavBarStyle style;

  static const double hauteur = 68;
  static const double rayon = 32;
  static const double hauteurOnglet = 56;

  /// Plancher de la zone tactile d'un onglet (seuil Apple HIG).
  static const double largeurTactileMin = 44;

  /// En deçà, l'onglet actif n'a pas la place d'écrire son libellé
  /// lisiblement et repasse en icône seule.
  static const double placeMinLibelle = 90;
  static const double margeLaterale = 16;

  /// Au-dessus de la safe area, jamais dessous — sinon la barre d'accueil
  /// (iOS) intercepterait le geste sur le dernier onglet.
  static const double margeBasse = 4;
  static const double ecartEntreOnglets = 2;

  /// Le déplacement de la pastille — assez long pour qu'on le suive, assez
  /// court pour qu'une navigation rapide ne traîne pas derrière le doigt.
  static const Duration dureeGlissement = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: margeLaterale,
        right: margeLaterale,
        bottom: margeBasse + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        height: hauteur,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: style.background,
          border: Border.all(color: style.border),
          borderRadius: BorderRadius.circular(rayon),
          boxShadow: style.shadow,
        ),
        child: LayoutBuilder(
          builder: (context, contraintes) => FloatingNavBarContent(
            items: items,
            indexActif: indexActif,
            onChanged: onChanged,
            compact: compact,
            style: style,
            largeurTotale: contraintes.maxWidth,
          ),
        ),
      ),
    );
  }
}
