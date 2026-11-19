// Régressions du 19/11/2026 (extraction depuis taxiboat) : la pastille
// active doit avoir une largeur intrinsèque (pas toute la zone tactile) et
// ne jamais déborder de la barre, quel que soit l'onglet actif. Le fond de
// la pastille est le MÊME widget que son contenu (pas une couche séparée
// à synchroniser) — deux correctifs successifs avaient échoué avant cette
// simplification.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_package/core/widgets/navigation/navigation_exports.dart';
import 'package:smoothandesign_package/core/widgets/navigation/floating_nav_bar_tab.dart';

const _style = FloatingNavBarStyle(
  background: Colors.black,
  border: Colors.white24,
  shadow: [],
  inactiveContent: Colors.white60,
  activePill: Colors.green,
  activeContent: Colors.black,
);

const _items = [
  FloatingNavItem(icon: Icons.home_outlined, label: 'Accueil'),
  FloatingNavItem(icon: Icons.grid_view_rounded, label: 'Modules'),
  FloatingNavItem(icon: Icons.flag_outlined, label: 'Défis'),
  FloatingNavItem(icon: Icons.person_outline, label: 'Profil'),
  FloatingNavItem(icon: Icons.chat_bubble_outline, label: 'Messages'),
];

Future<void> _pump(WidgetTester tester, int indexActif, ValueChanged<int> onChanged) async {
  // Largeur réaliste (téléphone) : sans ça, la surface de test par défaut
  // (bien plus large) donne un mou énorme à l'onglet actif et fausse les
  // bornes vérifiées ici.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            FloatingNavBar.compact(
              items: _items,
              indexActif: indexActif,
              onChanged: onChanged,
              style: _style,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// La pastille de l'onglet actif : le Container le plus proche qui porte
/// directement l'icône (fond + padding), pas un calque séparé.
Rect _pastilleDe(WidgetTester tester, IconData icone) {
  final container = find.ancestor(of: find.byIcon(icone), matching: find.byType(Container));
  return tester.getRect(container.first);
}

void main() {
  testWidgets('la pastille est plus étroite que toute la zone active', (tester) async {
    await _pump(tester, 0, (_) {});

    final zoneActive = tester.getSize(find.byType(FloatingNavTab).first).width;
    final pastille = _pastilleDe(tester, Icons.home_outlined);

    expect(pastille.width, lessThan(zoneActive));
  });

  testWidgets('le libellé reste DANS la pastille', (tester) async {
    await _pump(tester, 0, (_) {});

    final pastille = _pastilleDe(tester, Icons.home_outlined);
    final texte = tester.getRect(find.text('Accueil'));

    expect(texte.left, greaterThanOrEqualTo(pastille.left));
    expect(texte.right, lessThanOrEqualTo(pastille.right));
  });

  testWidgets('la pastille ne déborde jamais de la barre : premier onglet actif', (tester) async {
    await _pump(tester, 0, (_) {});

    final bar = tester.getRect(find.byType(FloatingNavBar));
    final pastille = _pastilleDe(tester, Icons.home_outlined);

    expect(pastille.left, greaterThan(bar.left));
    expect(pastille.left - bar.left, lessThan(60));
  });

  testWidgets('la pastille ne déborde jamais de la barre : dernier onglet actif', (tester) async {
    await _pump(tester, 4, (_) {});

    final bar = tester.getRect(find.byType(FloatingNavBar));
    final pastille = _pastilleDe(tester, Icons.chat_bubble_outline);

    expect(pastille.right, lessThan(bar.right));
    expect(bar.right - pastille.right, lessThan(60));
  });

  testWidgets('taper un onglet notifie son index', (tester) async {
    int? tapped;
    await _pump(tester, 0, (i) => tapped = i);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(tapped, 2);
  });
}
