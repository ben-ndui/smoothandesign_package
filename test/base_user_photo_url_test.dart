import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_package/core/models/base_user.dart';

void main() {
  group('BaseUser.fromMap photo', () {
    test('reads the photoURL written at sign-up', () {
      final user = BaseUser.fromMap({'photoURL': 'https://a/p.png'}, 'u1');
      expect(user.photoURL, 'https://a/p.png');
    });

    test('still reads the photoUrl and photo_Url written by toMap()', () {
      expect(BaseUser.fromMap({'photoUrl': 'https://a/1.png'}, 'u1').photoURL, 'https://a/1.png');
      expect(BaseUser.fromMap({'photo_Url': 'https://a/2.png'}, 'u1').photoURL, 'https://a/2.png');
    });

    test("the sign-up's empty photoURL never hides a real photoUrl", () {
      final user = BaseUser.fromMap({'photoURL': '', 'photoUrl': 'https://a/real.png'}, 'u1');
      expect(user.photoURL, 'https://a/real.png');
    });

    test('no photo anywhere is null, not an empty string', () {
      expect(BaseUser.fromMap({'photoURL': '  '}, 'u1').photoURL, isNull);
      expect(BaseUser.fromMap(const {}, 'u1').photoURL, isNull);
    });

    test('a non-string value is ignored', () {
      expect(
        BaseUser.fromMap({'photoURL': 42, 'photoUrl': 'https://a/ok.png'}, 'u1').photoURL,
        'https://a/ok.png',
      );
    });

    test('toMap() then fromMap() keeps the photo', () {
      final user = BaseUser.fromMap({'photoURL': 'https://a/p.png'}, 'u1');
      expect(BaseUser.fromMap(user.toMap(), 'u1').photoURL, 'https://a/p.png');
    });
  });
}
