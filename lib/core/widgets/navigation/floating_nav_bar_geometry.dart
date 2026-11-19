// Où se pose chaque onglet de [FloatingNavBar], et donc où glisse la
// pastille active. Un calcul explicite plutôt que `Expanded` : la pastille
// vit dans un `Stack` derrière la rangée, elle doit donc connaître la
// position et la largeur exactes de l'onglet visé. Avec `Expanded`, la
// pastille devrait deviner ce que la mise en page a décidé — et dès que le
// contenu d'un onglet dépasse sa part égale, le recadrage devient
// asymétrique (l'icône paraît décentrée).
import 'dart:math' as math;

class FloatingNavBarGeometry {
  FloatingNavBarGeometry({
    required this.largeurTotale,
    required this.nombre,
    required this.indexActif,
    required this.compact,
    required this.ecart,
    required this.largeurMin,
  }) : assert(nombre > 0);

  final double largeurTotale;
  final int nombre;
  final int indexActif;

  /// En compact, seul l'onglet actif s'étire ; les autres tiennent leur
  /// plancher tactile. Hors compact, tous les onglets sont égaux.
  final bool compact;

  final double ecart;

  /// Plancher tactile d'un onglet inactif en mode compact (seuil Apple HIG).
  final double largeurMin;

  double get _ecarts => (nombre - 1) * ecart;

  /// La ZONE TACTILE de l'onglet [index] — pas forcément la largeur visible
  /// de son contenu : en compact, l'onglet actif reçoit tout l'espace
  /// restant comme cible tactile généreuse, mais sa pastille visible (cf.
  /// [FloatingNavBar]) se dimensionne ensuite sur son propre contenu et se
  /// centre dedans.
  double largeur(int index) {
    if (!compact) {
      return math.max(0, (largeurTotale - _ecarts) / nombre);
    }
    if (index != indexActif) return largeurMin;
    final restant = largeurTotale - _ecarts - (nombre - 1) * largeurMin;
    return math.max(largeurMin, restant);
  }

  /// Le bord gauche de l'onglet [index].
  double gauche(int index) {
    var x = 0.0;
    for (var i = 0; i < index; i++) {
      x += largeur(i) + ecart;
    }
    return x;
  }

  /// Vrai si l'onglet actif a la place d'écrire son libellé ; en dessous il
  /// serait réduit à une ellipse, autant garder la cible tactile seule.
  bool libelleTient(double placeMinimale) =>
      !compact || largeur(indexActif) >= placeMinimale;
}
