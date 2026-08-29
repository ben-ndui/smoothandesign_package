import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smoothandesign_package/smoothandesign.dart';

/// Un bundle de banc : il rend les octets qu'on lui a confiés, et refuse le
/// reste — comme le vrai, qui lève sur un chemin inconnu.
class _BundleDeBanc extends CachingAssetBundle {
  _BundleDeBanc(this._fichiers);

  final Map<String, ByteData> _fichiers;

  @override
  Future<ByteData> load(String key) async {
    final octets = _fichiers[key];
    if (octets == null) {
      throw FlutterError('Asset introuvable : $key');
    }
    return octets;
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '';
}

class _ServiceDeBanc extends BasePdfService {
  @override
  Future<pw.Document> generateDocument() async => pw.Document();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ByteData jost;

  setUpAll(() async {
    // Une vraie police, pas des octets au hasard : `pw.Font.ttf` la parse.
    // Lue depuis le disque — le bundle d'un test ne sert pas les fixtures.
    final octets = File('test/fixtures/Jost-Regular.ttf').readAsBytesSync();
    jost = ByteData.sublistView(octets);
  });

  test('sans chargement, aucune police n\'est posée', () {
    expect(_ServiceDeBanc().policesChargees, isFalse);
  });

  test('chargerLesPolices pose bien les deux', () async {
    final svc = _ServiceDeBanc();
    await svc.chargerLesPolices(
      regular: 'a.ttf',
      bold: 'b.ttf',
      bundle: _BundleDeBanc({'a.ttf': jost, 'b.ttf': jost}),
    );
    expect(svc.policesChargees, isTrue);
  });

  test('⚠️ un chemin faux LÈVE au lieu de se taire', () async {
    // C'est tout l'objet du correctif : l'ancien `loadFonts` avalait l'échec,
    // et les documents sortaient sans le symbole € pendant des mois.
    final svc = _ServiceDeBanc();
    await expectLater(
      svc.chargerLesPolices(
        regular: 'introuvable.ttf',
        bold: 'b.ttf',
        bundle: _BundleDeBanc({'b.ttf': jost}),
      ),
      throwsA(isA<FlutterError>()),
    );
    expect(svc.policesChargees, isFalse);
  });
}
