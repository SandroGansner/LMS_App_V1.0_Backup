import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/purchase.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';

class PurchaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> addPurchase(Purchase purchase) async {
    try {
      await supabase
          .from(AppConstants.purchasesTable)
          .insert(purchase.toJson());
      print("✅ Kauf gespeichert: ${purchase.itemName}");
    } catch (e) {
      print("❌ Fehler beim Speichern des Kaufs: $e");
      rethrow;
    }
  }

  Future<List<Purchase>> getPurchases() async {
    try {
      final response =
          await supabase.from(AppConstants.purchasesTable).select();
      return (response as List).map((json) => Purchase.fromJson(json)).toList();
    } catch (e) {
      print("❌ Fehler beim Laden der Käufe: $e");
      return [];
    }
  }

  Future<String> exportPurchasesToExcel() async {
    try {
      List<Purchase> purchases = await getPurchases();

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
      sheet.getRangeByName('E1').setText('Projekt');
      sheet.getRangeByName('F1').setText('Rechnungssteller');
      sheet.getRangeByName('G1').setText('Mitarbeiter');
      sheet.getRangeByName('H1').setText('Karte verwendet');
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
      String filePath = p.join(directory.path, "purchases_export.xlsx");
      final file = File(filePath);
      final bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes);
      workbook.dispose();

      print("✅ Käufe-Excel gespeichert: $filePath");
      return filePath;
    } catch (e) {
      print("❌ Fehler beim Exportieren der Käufe: $e");
      return "";
    }
  }
}
