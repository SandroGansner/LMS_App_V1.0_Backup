import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/expense.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';

class ExpenseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> addExpense(Expense expense) async {
    try {
      await supabase.from(AppConstants.expensesTable).insert(expense.toJson());
      print("✅ Spese gespeichert: ${expense.description}");
    } catch (e) {
      print("❌ Fehler beim Speichern der Spese: $e");
      rethrow;
    }
  }

  Future<List<Expense>> getExpenses() async {
    try {
      final response = await supabase.from(AppConstants.expensesTable).select();
      return (response as List).map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      print("❌ Fehler beim Laden der Spesen: $e");
      return [];
    }
  }

  Future<String> exportExpensesToExcel() async {
    try {
      List<Expense> expenses = await getExpenses();

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
      sheet.getRangeByName('D1').setText('Projekt');
      sheet.getRangeByName('E1').setText('Betrag (CHF)');
      sheet.getRangeByName('F1').setText('Datum');
      sheet.getRangeByName('G1').setText('Beschreibung');

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
      }

      // Datei speichern
      final directory = await getApplicationDocumentsDirectory();
      String filePath = p.join(directory.path, "expenses_export.xlsx");
      final file = File(filePath);
      final bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes);
      workbook.dispose();

      print("✅ Spesen-Excel gespeichert: $filePath");
      return filePath;
    } catch (e) {
      print("❌ Fehler beim Exportieren der Spesen: $e");
      return "";
    }
  }
}
