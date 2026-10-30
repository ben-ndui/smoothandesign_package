import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_package/core/widgets/messaging/message_input.dart';

/// Régression (Ben, 30/10/2026) : la barre de saisie restait collée au bord
/// bas de l'écran quand tout le reste de l'app (nav, bottom sheets) flotte.
/// `floating: false` (défaut) doit garder EXACTEMENT le comportement
/// historique easybiz/amobiz — ce test verrouille ça autant que le nouveau
/// mode.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('floating par défaut (false) : pas de marge, bordure au lieu d\'ombre', (tester) async {
    await tester.pumpWidget(wrap(MessageInput(onSendText: (_) {})));
    await tester.pumpAndSettle();

    // Aucune marge de type "flottant" ajoutée autour du widget.
    expect(
      find.ancestor(of: find.byType(MessageInput), matching: find.byType(Padding)),
      findsNothing,
    );

    final container = tester.widget<Container>(find.descendant(
      of: find.byType(MessageInput),
      matching: find.byType(Container),
    ).first);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('floating: true : coins arrondis + ombre, pas de bordure', (tester) async {
    await tester.pumpWidget(wrap(MessageInput(onSendText: (_) {}, floating: true)));
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(find.descendant(
      of: find.byType(MessageInput),
      matching: find.byType(Container),
    ).first);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isNotNull);
    expect(decoration.borderRadius, BorderRadius.circular(28));
  });

  testWidgets('floating: true : le champ reste utilisable (saisie + envoi)', (tester) async {
    String? sent;
    await tester.pumpWidget(wrap(MessageInput(
      onSendText: (text) => sent = text,
      floating: true,
    )));

    await tester.enterText(find.byType(TextField), 'salut');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(sent, 'salut');
  });
}
