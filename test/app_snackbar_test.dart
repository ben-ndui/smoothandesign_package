import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_package/core/widgets/feedback/app_snackbar.dart';

/// Régression : le fond du snackbar était codé en dur (#1E293B, gris
/// ardoise) au lieu de suivre la charte de l'app appelante. Relevé sur
/// UZME le 29/10/2026 : « ca suit pas du tout la DA de l'app... ni les
/// couleurs du theme ». success/error/warning gardent leur sémantique
/// universelle ; info reprend desormais la couleur primaire de CHAQUE app.
void main() {
  final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF5B7FE8),
      surfaceContainerHigh: Color(0xFF1E47B5),
      onSurface: Color(0xFFE8E8EC),
    ),
  );

  group('AppSnackBar.getTypeConfig', () {
    test('success/error/warning gardent leurs couleurs semantiques universelles', () {
      final success = AppSnackBar.getTypeConfig(SnackBarType.success, darkTheme);
      final error = AppSnackBar.getTypeConfig(SnackBarType.error, darkTheme);
      final warning = AppSnackBar.getTypeConfig(SnackBarType.warning, darkTheme);

      expect(success.iconColor, const Color(0xFF22C55E));
      expect(error.iconColor, const Color(0xFFEF4444));
      expect(warning.iconColor, const Color(0xFFF59E0B));
    });

    test('info reprend la couleur primaire du theme appelant, pas une couleur fixe', () {
      final info = AppSnackBar.getTypeConfig(SnackBarType.info, darkTheme);
      expect(info.iconColor, darkTheme.colorScheme.primary);
      expect(info.iconColor, isNot(const Color(0xFF3B82F6)));
    });
  });

  group('AppSnackBar.show', () {
    testWidgets('le fond et le texte suivent le theme, plus de gris fixe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppSnackBar.success(context, 'Fait'),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      final container = tester.widget<Container>(
        find
            .descendant(of: find.byType(SnackBar), matching: find.byType(Container))
            .first,
      );
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, darkTheme.colorScheme.surfaceContainerHigh);
      expect(decoration.color, isNot(const Color(0xFF1E293B)));
    });
  });
}
