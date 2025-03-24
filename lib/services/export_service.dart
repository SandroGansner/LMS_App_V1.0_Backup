import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/campaign.dart';
import '../models/expense.dart';
import '../models/purchase.dart';

class ExportService {
  Future<String> exportCampaignsFancy(List<Campaign> campaigns) async {
    try {
      if (campaigns.isEmpty) {
        print("⚠️ Keine Kampagnen zum Exportieren gefunden.");
        return "";
      }

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      // Spaltenüberschriften
      sheet.getRangeByName('A1').setText('ID');
      sheet.getRangeByName('B1').setText('Name');
      sheet.getRangeByName('C1').setText('Startdatum');
      sheet.getRangeByName('D1').setText('Enddatum');
      sheet.getRangeByName('E1').setText('Budget (CHF)');
      sheet.getRangeByName('F1').setText('Kostenstelle');
      sheet.getRangeByName('G1').setText('Meta-Konto');
      sheet.getRangeByName('H1').setText('Ziel-URL');
      sheet.getRangeByName('I1').setText('Asset-Pfad');

      // Zeilen füllen
      for (int i = 0; i < campaigns.length; i++) {
        final c = campaigns[i];
        sheet
            .getRangeByIndex(i + 2, 1)
            .setText(c.id.toString()); // int zu String
        sheet.getRangeByIndex(i + 2, 2).setText(c.name);
        sheet.getRangeByIndex(i + 2, 3).setText(c.startDate.toIso8601String());
        sheet.getRangeByIndex(i + 2, 4).setText(c.endDate.toIso8601String());
        sheet.getRangeByIndex(i + 2, 5).setNumber(c.adBudget);
        sheet.getRangeByIndex(i + 2, 6).setText(c.costCenter);
        sheet.getRangeByIndex(i + 2, 7).setText(c.metaAccount);
        sheet.getRangeByIndex(i + 2, 8).setText(c.targetUrl);
        sheet.getRangeByIndex(i + 2, 9).setText(c.assetPath);
      }

      // Datei speichern
      final directory = await getApplicationDocumentsDirectory();
      String filePath = p.join(directory.path, "campaigns_fancy_export.xlsx");
      final file = File(filePath);
      final bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes);
      workbook.dispose();

      print("✅ Kampagnen-Fancy-Excel gespeichert: $filePath");
      return filePath;
    } catch (e) {
      print("❌ Fehler beim Exportieren der Kampagnen: $e");
      return "";
    }
  }

  Future<String> exportExpensesFancy(List<Expense> expenses) async {
    try {
      if (expenses.isEmpty) {
        print("⚠️ Keine Spesen zum Exportieren gefunden.");
        return "";
      }

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      // Spaltenüberschriften
      sheet.getRangeByName('A1').setText('ID');
      sheet.getRangeByName('B1').setText('Mitarbeiter');
      sheet.getRangeByName('C1').setText('Kostenstelle');
      sheet.getRangeByName('D1').setText('Projektnummer');
      sheet.getRangeByName('E1').setText('Betrag (CHF)');
      sheet.getRangeByName('F1').setText('Datum');
      sheet.getRangeByName('G1').setText('Beschreibung');
      sheet.getRangeByName('H1').setText('Belegpfad');
      sheet.getRangeByName('I1').setText('MwSt.-Satz');
      sheet.getRangeByName('J1').setText('Zahlungskarte');

      // Zeilen füllen
      for (int i = 0; i < expenses.length; i++) {
        final e = expenses[i];
        sheet
            .getRangeByIndex(i + 2, 1)
            .setText(e.id.toString()); // int zu String
        sheet.getRangeByIndex(i + 2, 2).setText(e.employeeName);
        sheet.getRangeByIndex(i + 2, 3).setText(e.costCenter);
        sheet.getRangeByIndex(i + 2, 4).setText(e.projectNumber);
        sheet.getRangeByIndex(i + 2, 5).setNumber(e.amount);
        sheet.getRangeByIndex(i + 2, 6).setText(e.date.toIso8601String());
        sheet.getRangeByIndex(i + 2, 7).setText(e.description);
        sheet.getRangeByIndex(i + 2, 8).setText(e.receiptPath);
        sheet.getRangeByIndex(i + 2, 9).setText(e.vatRate);
        sheet.getRangeByIndex(i + 2, 10).setText(e.cardUsed ?? 'N/A');
      }

      // Datei speichern
      final directory = await getApplicationDocumentsDirectory();
      String filePath = p.join(directory.path, "expenses_fancy_export.xlsx");
      final file = File(filePath);
      final bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes);
      workbook.dispose();

      print("✅ Spesen-Fancy-Excel gespeichert: $filePath");
      return filePath;
    } catch (e) {
      print("❌ Fehler beim Exportieren der Spesen: $e");
      return "";
    }
  }

  Future<String> exportPurchasesFancy(
      {required List<Purchase> purchases}) async {
    try {
      if (purchases.isEmpty) {
        print("⚠️ Keine Käufe zum Exportieren gefunden.");
        return "";
      }

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      // Spaltenüberschriften
      sheet.getRangeByName('A1').setText('ID');
      sheet.getRangeByName('B1').setText('Artikelname');
      sheet.getRangeByName('C1').setText('Preis (CHF)');
      sheet.getRangeByName('D1').setText('Kostenstelle');
      sheet.getRangeByName('E1').setText('Projektnummer');
      sheet.getRangeByName('F1').setText('Rechnungssteller');
      sheet.getRangeByName('G1').setText('Mitarbeiter');
      sheet.getRangeByName('H1').setText('Zahlungskarte');
      sheet.getRangeByName('I1').setText('Belegpfad');
      sheet.getRangeByName('J1').setText('MwSt.-Satz');
      sheet.getRangeByName('K1').setText('Datum');

      // Zeilen füllen
      for (int i = 0; i < purchases.length; i++) {
        final p = purchases[i];
        sheet
            .getRangeByIndex(i + 2, 1)
            .setText(p.id.toString()); // int zu String
        sheet.getRangeByIndex(i + 2, 2).setText(p.itemName);
        sheet.getRangeByIndex(i + 2, 3).setNumber(p.price);
        sheet.getRangeByIndex(i + 2, 4).setText(p.costCenter);
        sheet.getRangeByIndex(i + 2, 5).setText(p.projectNumber);
        sheet.getRangeByIndex(i + 2, 6).setText(p.invoiceIssuer);
        sheet.getRangeByIndex(i + 2, 7).setText(p.employee);
        sheet.getRangeByIndex(i + 2, 8).setText(p.cardUsed);
        sheet.getRangeByIndex(i + 2, 9).setText(p.receiptPath);
        sheet.getRangeByIndex(i + 2, 10).setText(p.vatRate);
        sheet.getRangeByIndex(i + 2, 11).setText(p.date.toIso8601String());
      }

      // Datei speichern
      final directory = await getApplicationDocumentsDirectory();
      String filePath = p.join(directory.path, "purchases_fancy_export.xlsx");
      final file = File(filePath);
      final bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes);
      workbook.dispose();

      print("✅ Käufe-Fancy-Excel gespeichert: $filePath");
      return filePath;
    } catch (e) {
      print("❌ Fehler beim Exportieren der Käufe: $e");
      return "";
    }
  }
}
