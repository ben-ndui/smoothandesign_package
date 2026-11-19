// Un onglet de [FloatingNavBar] — icône, libellé éventuel, badge, encre qui
// se fond, icône qui rebondit à l'activation, léger enfoncement au toucher.
// Portage FIDÈLE de taxiboat/lib/widgets/vagua/vagua_nav_bar_parts.dart —
// interne au dossier `navigation/`, pas d'usage hors de ce composant.
import 'package:flutter/material.dart';

import 'floating_nav_bar.dart';
import 'floating_nav_bar_icon.dart';
import 'floating_nav_bar_style.dart';

class FloatingNavTab extends StatefulWidget {
  const FloatingNavTab({
    super.key,
    required this.item,
    required this.actif,
    required this.compact,
    required this.avecLibelle,
    required this.sansAnimation,
    required this.style,
    required this.onTap,
  });

  final FloatingNavItem item;
  final bool actif;
  final bool compact;

  /// L'onglet écrit-il son libellé ? La barre en décide selon la place.
  final bool avecLibelle;

  /// Le système demande de réduire les animations : tout devient instantané.
  final bool sansAnimation;

  final FloatingNavBarStyle style;
  final VoidCallback onTap;

  @override
  State<FloatingNavTab> createState() => _FloatingNavTabState();
}

class _FloatingNavTabState extends State<FloatingNavTab> {
  bool _enfonce = false;

  /// Le doigt est posé : l'onglet s'enfonce légèrement — sans ça, rien ne
  /// répond au toucher avant que la navigation elle-même n'ait eu lieu.
  void _presser(bool oui) {
    if (_enfonce != oui) setState(() => _enfonce = oui);
  }

  @override
  Widget build(BuildContext context) {
    final duree = widget.sansAnimation
        ? Duration.zero
        : const Duration(milliseconds: 170);

    return Semantics(
      // Annoncé seulement si le libellé n'est PAS écrit : sinon l'annotation
      // et le texte fusionnent, et le lecteur d'écran dit « Carte Carte ».
      label: widget.avecLibelle ? null : widget.item.label,
      button: true,
      selected: widget.actif,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _presser(true),
        onTapUp: (_) => _presser(false),
        onTapCancel: () => _presser(false),
        child: AnimatedScale(
          scale: _enfonce ? 0.94 : 1,
          duration: widget.sansAnimation
              ? Duration.zero
              : const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: SizedBox(
            height: FloatingNavBar.hauteurOnglet,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: widget.actif ? 1 : 0),
              duration: duree,
              curve: Curves.easeOut,
              builder: (_, avancee, _) => _Contenu(
                item: widget.item,
                compact: widget.compact,
                avecLibelle: widget.avecLibelle,
                encre: Color.lerp(
                  widget.style.inactiveContent,
                  widget.style.activeContent,
                  avancee,
                )!,
                sansAnimation: widget.sansAnimation,
                rebond: widget.actif ? 1 : 0,
                badge: widget.style.badge,
                onBadge: widget.style.onBadge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({
    required this.item,
    required this.compact,
    required this.avecLibelle,
    required this.encre,
    required this.sansAnimation,
    required this.rebond,
    required this.badge,
    required this.onBadge,
  });

  final FloatingNavItem item;
  final bool compact;
  final bool avecLibelle;
  final Color encre;
  final bool sansAnimation;
  final double rebond;
  final Color badge;
  final Color onBadge;

  @override
  Widget build(BuildContext context) {
    final icone = IconeQuiRebondit(
      actif: rebond == 1,
      sansAnimation: sansAnimation,
      enfant: IconeEtBadge(
        item: item,
        encre: encre,
        taille: compact && !avecLibelle ? 24 : 22,
        badge: badge,
        onBadge: onBadge,
      ),
    );

    if (!avecLibelle) return Center(child: icone);

    final libelle = Text(
      item.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 14 : 11,
        fontWeight: FontWeight.w600,
        color: encre,
      ),
    );

    // En compact, l'actif se lit en ligne (icône puis libellé) ; en complet,
    // chaque onglet empile son icône au-dessus de son libellé. Padding fixe,
    // pas de centrage : la pastille (couche séparée) occupe toute la zone.
    return compact
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [icone, const SizedBox(width: 8), Flexible(child: libelle)],
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [icone, const SizedBox(height: 2), Flexible(child: libelle)],
          );
  }
}
