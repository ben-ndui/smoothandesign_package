// Vérifie que FloatingNavBar reste un portage FIDÈLE de VaguaNavBar
// (taxiboat/lib/widgets/vagua/vagua_nav_bar.dart) — décision de Ben
// (19/11/2026) après plusieurs tentatives d'amélioration ratées : en mode
// .compact, la pastille active occupe toute sa zone tactile, sans retouche
// de largeur ni de centrage. Ce test attrape un futur écart silencieux par
// rapport à ce choix, pas un défaut de layout.
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

void main() {
  testWidgets('la pastille couvre toute la zone tactile active (mécanique VAGUA)', (tester) async {
    await _pump(tester, 0, (_) {});

    final zoneActive = tester.getSize(find.byType(FloatingNavTab).first).width;
    final icone = tester.getRect(find.byIcon(Icons.home_outlined));
    final texte = tester.getRect(find.text('Accueil'));

    // Padding fixe de 16 de chaque côté du Row (icône+texte), comme
    // vagua_nav_bar_parts.dart — pas de centrage ni de largeur recalculée.
    final contenu = texte.right - icone.left + 2 * 16;
    expect(contenu, closeTo(zoneActive, 4));
  });

  testWidgets('le libellé reste lisible sur les 5 onglets', (tester) async {
    for (var i = 0; i < _items.length; i++) {
      await _pump(tester, i, (_) {});
      expect(find.text(_items[i].label), findsOneWidget);
    }
  });

  testWidgets('taper un onglet notifie son index', (tester) async {
    int? tapped;
    await _pump(tester, 0, (i) => tapped = i);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(tapped, 2);
  });
}
