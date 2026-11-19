// Régressions du 19/11/2026 (extraction depuis taxiboat, deux portages
// manuels ratés avant celui-ci) : la pastille active doit avoir une largeur
// intrinsèque (pas toute la zone tactile) et des marges extérieures
// symétriques quel que soit l'onglet actif — premier, milieu ou dernier.
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

void main() {
  testWidgets('la pastille est plus étroite que toute la zone active', (tester) async {
    await _pump(tester, 0, (_) {});

    final zoneActive = tester.getSize(find.byType(FloatingNavTab).first).width;
    final pastille = tester.getSize(find.byKey(const ValueKey('floating-nav-bar-pastille')));

    expect(pastille.width, lessThan(zoneActive));
  });

  testWidgets('marges extérieures symétriques : premier onglet actif', (tester) async {
    await _pump(tester, 0, (_) {});

    final bar = tester.getRect(
      find.descendant(of: find.byType(FloatingNavBar), matching: find.byType(Container)).first,
    );
    final pastille = tester.getRect(find.byKey(const ValueKey('floating-nav-bar-pastille')));
    // L'ICÔNE du dernier onglet, pas sa zone tactile (toujours flush avec
    // le bord intérieur du conteneur, peu importe l'inset visuel de l'icône).
    final derniereIcone = tester.getRect(find.byIcon(Icons.chat_bubble_outline));

    final margeGauche = pastille.left - bar.left;
    final margeDroite = bar.right - derniereIcone.right;

    expect(margeGauche, closeTo(margeDroite, 1));
  });

  testWidgets('marges extérieures symétriques : dernier onglet actif', (tester) async {
    await _pump(tester, 4, (_) {});

    final bar = tester.getRect(
      find.descendant(of: find.byType(FloatingNavBar), matching: find.byType(Container)).first,
    );
    final premiereIcone = tester.getRect(find.byIcon(Icons.home_outlined));
    final pastille = tester.getRect(find.byKey(const ValueKey('floating-nav-bar-pastille')));

    final margeGauche = premiereIcone.left - bar.left;
    final margeDroite = bar.right - pastille.right;

    expect(margeGauche, closeTo(margeDroite, 1));
  });

  testWidgets('taper un onglet notifie son index', (tester) async {
    int? tapped;
    await _pump(tester, 0, (i) => tapped = i);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(tapped, 2);
  });
}
