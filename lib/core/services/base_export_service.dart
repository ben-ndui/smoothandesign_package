import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Configuration d'une colonne Excel.
class ExcelColumn {
  final String header;
  final double width;
  final CellStyle? headerStyle;
  final CellStyle? cellStyle;

  const ExcelColumn({
    required this.header,
    this.width = 20.0,
    this.headerStyle,
    this.cellStyle,
  });
}

/// Service d'export de données (Excel, CSV).
class BaseExportService {
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  /// Style par défaut pour les headers.
  CellStyle get defaultHeaderStyle => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4F46E5'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Style par défaut pour les cellules.
  CellStyle get defaultCellStyle => CellStyle(
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

  /// Style pour les montants.
  CellStyle get amountStyle => CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

  /// Formate un montant.
  String formatCurrency(double amount) => _currencyFormat.format(amount);

  /// Formate une date.
  String formatDate(DateTime date) => _dateFormat.format(date);

  /// Crée un fichier Excel avec plusieurs feuilles.
  ///
  /// [sheets] : Map de nomFeuille vers données.
  /// Chaque donnée est une liste de lignes (liste de cellules).
  Future<File> createExcelFile({
    required String fileName,
    required Map<String, ExcelSheetData> sheets,
  }) async {
    final excel = Excel.createExcel();

    // Supprimer la feuille par défaut
    excel.delete('Sheet1');

    for (final entry in sheets.entries) {
      final sheetName = entry.key;
      final sheetData = entry.value;

      final sheet = excel[sheetName];

      // Headers
      for (int col = 0; col < sheetData.columns.length; col++) {
        final column = sheetData.columns[col];
        final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: col,
          rowIndex: 0,
        ));
        cell.value = TextCellValue(column.header);
        cell.cellStyle = column.headerStyle ?? defaultHeaderStyle;

        // Largeur de colonne
        sheet.setColumnWidth(col, column.width);
      }

      // Données
      for (int row = 0; row < sheetData.rows.length; row++) {
        final rowData = sheetData.rows[row];
        for (int col = 0; col < rowData.length && col < sheetData.columns.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: row + 1,
          ));

          final value = rowData[col];
          if (value is double) {
            cell.value = DoubleCellValue(value);
          } else if (value is int) {
            cell.value = IntCellValue(value);
          } else if (value is DateTime) {
            cell.value = TextCellValue(formatDate(value));
          } else {
            cell.value = TextCellValue(value?.toString() ?? '');
          }

          cell.cellStyle = sheetData.columns[col].cellStyle ?? defaultCellStyle;
        }
      }
    }

    // Sauvegarder
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/${fileName}_$timestamp.xlsx';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Erreur encodage Excel');

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Crée un fichier CSV simple.
  Future<File> createCsvFile({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String separator = ';',
  }) async {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln(headers.join(separator));

    // Rows
    for (final row in rows) {
      final formattedRow = row.map((cell) {
        if (cell == null) return '';
        if (cell is DateTime) return formatDate(cell);
        if (cell is double) return cell.toStringAsFixed(2).replaceAll('.', ',');
        final str = cell.toString();
        // Échapper les guillemets et entourer si contient séparateur
        if (str.contains(separator) || str.contains('"') || str.contains('\n')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).toList();
      buffer.writeln(formattedRow.join(separator));
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/${fileName}_$timestamp.csv';

    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    return file;
  }

  /// Partage un fichier via le système natif.
  Future<void> shareFile(File file, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: subject,
      ),
    );
  }

  /// Exporte et partage directement un Excel.
  Future<void> exportAndShareExcel({
    required String fileName,
    required Map<String, ExcelSheetData> sheets,
    String? subject,
  }) async {
    final file = await createExcelFile(fileName: fileName, sheets: sheets);
    await shareFile(file, subject: subject);
  }

  /// Exporte et partage directement un CSV.
  Future<void> exportAndShareCsv({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String? subject,
  }) async {
    final file = await createCsvFile(
      fileName: fileName,
      headers: headers,
      rows: rows,
    );
    await shareFile(file, subject: subject);
  }

  // ===== HELPERS POUR EXPORTS COMMUNS =====

  /// Crée une feuille de données de base.
  ExcelSheetData createSimpleSheet({
    required List<String> headers,
    required List<List<dynamic>> rows,
    List<double>? columnWidths,
  }) {
    final columns = <ExcelColumn>[];
    for (int i = 0; i < headers.length; i++) {
      columns.add(ExcelColumn(
        header: headers[i],
        width: columnWidths != null && i < columnWidths.length
            ? columnWidths[i]
            : 15.0,
      ));
    }
    return ExcelSheetData(columns: columns, rows: rows);
  }

  /// Crée une ligne de totaux.
  List<dynamic> createTotalRow({
    required int columnCount,
    required String label,
    required int labelColumn,
    required Map<int, double> totals,
  }) {
    final row = List<dynamic>.filled(columnCount, '');
    row[labelColumn] = label;
    for (final entry in totals.entries) {
      row[entry.key] = entry.value;
    }
    return row;
  }
}

/// Données d'une feuille Excel.
class ExcelSheetData {
  final List<ExcelColumn> columns;
  final List<List<dynamic>> rows;

  const ExcelSheetData({
    required this.columns,
    required this.rows,
  });
}
