import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/color_utils.dart';

/// Configuration pour la génération PDF.
class PdfConfig {
  final String? logoUrl;
  final String primaryColorHex;
  final String companyName;
  final String? companyAddress;
  final String? companyCity;
  final String? companyZipCode;
  final String? companyPhone;
  final String? companyEmail;
  final String? companySiret;
  final String? companyVatNumber;
  final String? bankName;
  final String? iban;
  final String? bic;

  const PdfConfig({
    this.logoUrl,
    this.primaryColorHex = '667EEA',
    required this.companyName,
    this.companyAddress,
    this.companyCity,
    this.companyZipCode,
    this.companyPhone,
    this.companyEmail,
    this.companySiret,
    this.companyVatNumber,
    this.bankName,
    this.iban,
    this.bic,
  });

  bool get hasBankInfo => iban != null && iban!.isNotEmpty;

  String get formattedAddress {
    final parts = <String>[];
    if (companyAddress != null) parts.add(companyAddress!);
    if (companyZipCode != null && companyCity != null) {
      parts.add('$companyZipCode $companyCity');
    }
    return parts.join(', ');
  }
}

/// Ligne d'un document (devis/facture).
class PdfLineItem {
  final String description;
  final double quantity;
  final double unitPriceHT;
  final double tvaRate;
  final String? unit;

  const PdfLineItem({
    required this.description,
    required this.quantity,
    required this.unitPriceHT,
    this.tvaRate = 20.0,
    this.unit,
  });

  double get totalHT => quantity * unitPriceHT;
  double get totalTVA => totalHT * tvaRate / 100;
  double get totalTTC => totalHT + totalTVA;
}

/// Données du destinataire.
class PdfRecipient {
  final String name;
  final String? company;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? zipCode;
  final String? siret;
  final String? vatNumber;

  const PdfRecipient({
    required this.name,
    this.company,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.zipCode,
    this.siret,
    this.vatNumber,
  });

  String get formattedAddress {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (zipCode != null && city != null) parts.add('$zipCode $city');
    return parts.join('\n');
  }
}

/// Service de base pour la génération PDF.
///
/// Fournit des utilitaires et une structure extensible pour créer des PDFs.
/// Chaque projet peut étendre cette classe pour personnaliser les templates.
abstract class BasePdfService {
  // Fonts
  pw.Font? _fontRegular;
  pw.Font? _fontBold;

  // Formatters
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  /// Formate un montant en euros.
  String formatCurrency(double amount) => _currencyFormat.format(amount);

  /// Formate une date.
  String formatDate(DateTime date) => _dateFormat.format(date);

  /// Une police a-t-elle réellement été chargée ?
  ///
  /// Faux = les documents partent en police par défaut, donc **sans le symbole
  /// €**. Voir [fontRegular].
  bool get policesChargees => _fontRegular != null;

  /// Charge les polices du document depuis le bundle de l'APPLICATION.
  ///
  /// ⚠️ Aucun `try/catch` ici, volontairement. Un chemin d'asset faux doit se
  /// voir au premier essai, pas se transformer en documents illisibles pendant
  /// des mois — c'est exactement ce qu'a fait [loadFonts].
  ///
  /// La police fournie doit porter le glyphe **€** : les polices par défaut du
  /// PDF ne l'ont pas (voir [fontRegular]).
  ///
  /// ```dart
  /// await chargerLesPolices(
  ///   regular: 'assets/fonts/Jost-Regular.ttf',
  ///   bold: 'assets/fonts/Jost-Bold.ttf',
  /// );
  /// ```
  Future<void> chargerLesPolices({
    required String regular,
    required String bold,
    AssetBundle? bundle,
  }) async {
    final source = bundle ?? rootBundle;
    _fontRegular = pw.Font.ttf(await source.load(regular));
    _fontBold = pw.Font.ttf(await source.load(bold));
  }

  /// ⚠️ NE CHARGE RIEN, et n'a jamais rien chargé.
  ///
  /// Cette méthode cherchait `Inter-Regular.ttf` dans les assets du paquet —
  /// une police qui n'y a **jamais existé**, ni comme fichier ni comme asset
  /// déclaré. Son `catch (_)` avalait l'échec et retombait sur Helvetica.
  ///
  /// Conséquence, mesurée sur les factures VAGUA le 29/08/2026 : le symbole €
  /// s'imprimait en caractère parasite sur TOUS les documents produits par le
  /// paquet, depuis toujours. Une erreur avalée qui s'imprimait sur des pièces
  /// comptables.
  ///
  /// Conservée pour ne casser aucune application à la compilation. Utiliser
  /// [chargerLesPolices] avec les polices de son propre bundle.
  @Deprecated(
    'Ne charge rien : les polices Inter n\'ont jamais existé dans le paquet, '
    'et le repli PDF par défaut ne sait pas écrire « € ». '
    'Utiliser chargerLesPolices(regular: ..., bold: ...).',
  )
  Future<void> loadFonts() async {
    assert(
      false,
      'BasePdfService.loadFonts() ne charge aucune police et vos montants '
      'sortiront sans le symbole €. Appelez chargerLesPolices() avec une '
      'police de votre application.',
    );
  }

  /// Police régulière.
  ///
  /// ⚠️ Le repli n'écrit pas les euros. `PdfType1Font.putText` encode en
  /// **latin-1** (`pdf/lib/src/pdf/obj/font.dart`), et latin-1 ne contient pas
  /// U+20AC. Toute police par défaut du PDF produit donc un caractère parasite
  /// à la place de « € ». Passer par [chargerLesPolices] n'est pas un confort
  /// de style : c'est ce qui rend les montants lisibles.
  pw.Font get fontRegular => _fontRegular ?? pw.Font.helvetica();

  /// Police grasse. Même réserve que [fontRegular].
  pw.Font get fontBold => _fontBold ?? pw.Font.helveticaBold();

  /// Convertit un hex en couleur PDF.
  PdfColor hexToPdfColor(String hex) {
    final color = ColorUtils.hexToColor(hex);
    return PdfColor.fromInt(color.toARGB32());
  }

  /// Calcule la couleur de texte contrastée.
  PdfColor getContrastTextColor(String backgroundHex) {
    final textHex = ColorUtils.getContrastTextColor(backgroundHex);
    return hexToPdfColor(textHex);
  }

  /// Crée une couleur de fond claire (10% de la couleur primaire).
  PdfColor getLightBackground(String primaryHex) {
    final color = ColorUtils.hexToColor(primaryHex);
    final light = ColorUtils.lighten(color, 0.35);
    return PdfColor.fromInt(light.toARGB32());
  }

  /// Calcule les totaux d'une liste de lignes.
  Map<String, double> calculateTotals(List<PdfLineItem> items) {
    double totalHT = 0;
    double totalTVA = 0;

    for (final item in items) {
      totalHT += item.totalHT;
      totalTVA += item.totalTVA;
    }

    return {
      'totalHT': totalHT,
      'totalTVA': totalTVA,
      'totalTTC': totalHT + totalTVA,
    };
  }

  /// Regroupe la TVA par taux.
  Map<double, double> getTvaBreakdown(List<PdfLineItem> items) {
    final breakdown = <double, double>{};
    for (final item in items) {
      final existing = breakdown[item.tvaRate] ?? 0;
      breakdown[item.tvaRate] = existing + item.totalTVA;
    }
    return breakdown;
  }

  // ===== WIDGETS RÉUTILISABLES =====

  /// Crée un header avec titre et logo.
  pw.Widget buildHeader({
    required String title,
    required PdfConfig config,
    Uint8List? logoBytes,
    PdfColor? primaryColor,
  }) {
    final color = primaryColor ?? hexToPdfColor(config.primaryColorHex);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 28,
            color: color,
          ),
        ),
        if (logoBytes != null)
          pw.Image(pw.MemoryImage(logoBytes), height: 60)
        else
          pw.Text(
            config.companyName,
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
      ],
    );
  }

  /// Crée une section émetteur/destinataire.
  pw.Widget buildParties({
    required PdfConfig config,
    required PdfRecipient recipient,
    String fromLabel = 'DE',
    String toLabel = 'POUR',
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(fromLabel,
                  style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(config.companyName,
                  style: pw.TextStyle(font: fontBold, fontSize: 12)),
              if (config.companyAddress != null)
                pw.Text(config.formattedAddress,
                    style: pw.TextStyle(font: fontRegular, fontSize: 10)),
              if (config.companyPhone != null)
                pw.Text(config.companyPhone!,
                    style: pw.TextStyle(font: fontRegular, fontSize: 10)),
              if (config.companyEmail != null)
                pw.Text(config.companyEmail!,
                    style: pw.TextStyle(font: fontRegular, fontSize: 10)),
              if (config.companySiret != null)
                pw.Text('SIRET: ${config.companySiret}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(toLabel,
                  style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.SizedBox(height: 4),
              if (recipient.company != null)
                pw.Text(recipient.company!,
                    style: pw.TextStyle(font: fontBold, fontSize: 12)),
              pw.Text(recipient.name,
                  style: pw.TextStyle(
                      font: recipient.company != null ? fontRegular : fontBold,
                      fontSize: recipient.company != null ? 10 : 12)),
              if (recipient.address != null)
                pw.Text(recipient.formattedAddress,
                    style: pw.TextStyle(font: fontRegular, fontSize: 10)),
              if (recipient.email != null)
                pw.Text(recipient.email!,
                    style: pw.TextStyle(font: fontRegular, fontSize: 10)),
              if (recipient.siret != null)
                pw.Text('SIRET: ${recipient.siret}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  /// Crée un tableau des lignes.
  pw.Widget buildItemsTable({
    required List<PdfLineItem> items,
    PdfColor? headerColor,
    PdfColor? headerTextColor,
    bool showUnitPrice = true,
  }) {
    final bgColor = headerColor ?? PdfColors.grey300;
    final textColor = headerTextColor ?? PdfColors.black;

    final headers = ['Description', 'Qté'];
    if (showUnitPrice) headers.add('Prix unit. HT');
    headers.addAll(['TVA', 'Total HT']);

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: textColor),
      headerDecoration: pw.BoxDecoration(color: bgColor),
      cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(6),
      headers: headers,
      data: items.map((item) {
        final row = [
          item.description,
          '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
        ];
        if (showUnitPrice) row.add(formatCurrency(item.unitPriceHT));
        row.addAll([
          '${item.tvaRate.toStringAsFixed(item.tvaRate == item.tvaRate.roundToDouble() ? 0 : 1)}%',
          formatCurrency(item.totalHT),
        ]);
        return row;
      }).toList(),
    );
  }

  /// Crée la section des totaux.
  pw.Widget buildTotals({
    required List<PdfLineItem> items,
    PdfColor? accentColor,
  }) {
    final totals = calculateTotals(items);
    final color = accentColor ?? PdfColors.indigo;

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 2),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            _buildTotalRow('Total HT', totals['totalHT']!),
            pw.SizedBox(height: 4),
            _buildTotalRow('TVA', totals['totalTVA']!),
            pw.Divider(color: color),
            _buildTotalRow('Total TTC', totals['totalTTC']!,
                isBold: true, color: color),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount,
      {bool isBold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: isBold ? fontBold : fontRegular, fontSize: 11)),
        pw.Text(
          formatCurrency(amount),
          style: pw.TextStyle(
            font: isBold ? fontBold : fontRegular,
            fontSize: isBold ? 14 : 11,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Crée une section informations bancaires.
  pw.Widget buildBankInfo({
    required PdfConfig config,
    String title = 'Coordonnées bancaires',
  }) {
    if (!config.hasBankInfo) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11)),
          pw.SizedBox(height: 6),
          if (config.bankName != null)
            pw.Text('Banque: ${config.bankName}',
                style: pw.TextStyle(font: fontRegular, fontSize: 10)),
          if (config.iban != null)
            pw.Text('IBAN: ${config.iban}',
                style: pw.TextStyle(font: fontRegular, fontSize: 10)),
          if (config.bic != null)
            pw.Text('BIC: ${config.bic}',
                style: pw.TextStyle(font: fontRegular, fontSize: 10)),
        ],
      ),
    );
  }

  /// Crée une section mentions légales.
  pw.Widget buildLegalMentions({
    String? customText,
    double latePenaltyRate = 12.0,
    double fixedRecoveryFee = 40.0,
  }) {
    final text = customText ??
        '''En cas de retard de paiement, une pénalité de ${latePenaltyRate.toStringAsFixed(1)}% sera appliquée, ainsi qu'une indemnité forfaitaire de ${formatCurrency(fixedRecoveryFee)} pour frais de recouvrement.''';

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: fontRegular, fontSize: 8),
      ),
    );
  }

  /// Crée un bloc de signature.
  pw.Widget buildSignatureBlock({
    String title = 'Signature',
    String mention = 'Lu et approuvé, bon pour accord',
  }) {
    return pw.Container(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(mention,
              style: pw.TextStyle(font: fontRegular, fontSize: 9)),
          pw.SizedBox(height: 40),
          pw.Container(
            height: 1,
            color: PdfColors.grey400,
          ),
        ],
      ),
    );
  }

  /// Crée un footer avec informations entreprise.
  pw.Widget buildFooter({required PdfConfig config}) {
    final parts = <String>[];
    parts.add(config.companyName);
    if (config.formattedAddress.isNotEmpty) parts.add(config.formattedAddress);
    if (config.companyPhone != null) parts.add(config.companyPhone!);
    if (config.companyEmail != null) parts.add(config.companyEmail!);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Text(
        parts.join(' • '),
        style: pw.TextStyle(font: fontRegular, fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Génère le document PDF final.
  /// À implémenter dans les sous-classes.
  Future<pw.Document> generateDocument();
}
