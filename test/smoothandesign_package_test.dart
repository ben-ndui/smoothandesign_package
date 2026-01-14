import 'package:flutter_test/flutter_test.dart';

import 'package:smoothandesign_package/smoothandesign.dart';

void main() {
  group('FrenchUtils', () {
    test('formatCurrency formats euros correctly', () {
      expect(FrenchUtils.formatCurrency(1234.56), contains('1'));
      expect(FrenchUtils.formatCurrency(1234.56), contains('€'));
    });

    test('formatTVARate formats rates correctly', () {
      expect(FrenchUtils.formatTVARate(20.0), '20%');
      expect(FrenchUtils.formatTVARate(5.5), '5.5%');
      expect(FrenchUtils.formatTVARate(0), 'Exonéré');
    });

    test('calculateTTC computes correctly', () {
      expect(FrenchUtils.calculateTTC(100, 20), closeTo(120, 0.01));
      expect(FrenchUtils.calculateTTC(100, 10), closeTo(110, 0.01));
    });
  });

  group('Validators', () {
    test('isValidEmail validates correctly', () {
      expect(Validators.isValidEmail('test@example.com'), true);
      expect(Validators.isValidEmail('invalid'), false);
      expect(Validators.isValidEmail(null), false);
    });

    test('isValidFrenchPhone validates correctly', () {
      expect(Validators.isValidFrenchPhone('0612345678'), true);
      expect(Validators.isValidFrenchPhone('+33612345678'), true);
      expect(Validators.isValidFrenchPhone('123'), false);
    });

    test('isValidFrenchPostalCode validates correctly', () {
      expect(Validators.isValidFrenchPostalCode('75001'), true);
      expect(Validators.isValidFrenchPostalCode('7500'), false);
    });
  });

  group('ColorUtils', () {
    test('isValidHex validates hex colors', () {
      expect(ColorUtils.isValidHex('FF5733'), true);
      expect(ColorUtils.isValidHex('#FF5733'), true);
      expect(ColorUtils.isValidHex('GGGGGG'), false);
    });

    test('getContrastTextColor returns correct color', () {
      expect(ColorUtils.getContrastTextColor('FFFFFF'), '000000'); // White bg -> black text
      expect(ColorUtils.getContrastTextColor('000000'), 'FFFFFF'); // Black bg -> white text
    });
  });

  group('SmoothResponse', () {
    test('success creates successful response', () {
      final response = SmoothResponse.success(data: 'data');
      expect(response.isSuccess, true);
      expect(response.data, 'data');
    });

    test('error creates error response', () {
      final response = SmoothResponse<String>.error(message: 'Error message');
      expect(response.isSuccess, false);
      expect(response.message, 'Error message');
    });
  });
}
