import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppConstants {
  // 🟢 Dynamischer Export-Pfad für alle Plattformen
  static Future<String> getExportPath() async {
    Directory baseDir;
    String exportSubDir = 'Export';

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      baseDir = await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      baseDir = await getApplicationDocumentsDirectory();
    } else if (Platform.isAndroid) {
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError("Plattform wird nicht unterstützt!");
    }

    final exportDir = Directory(p.join(baseDir.path, exportSubDir));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  // 🟢 Dynamischer Beleg-Pfad mit Erstellung
  static Future<String> getReceiptsPath() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(baseDir.path, 'Receipts'));

    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    return receiptsDir.path;
  }

  // 🟢 Supabase Tabellennamen
  static const String purchasesTable = "purchases";
  static const String expensesTable = "expenses";
  static const String campaignsTable = "campaigns";
  static const String employeesTable = "employees";
  static const String costCentersTable = "cost_centers";
  static const String projectsTable = "projects";
  static const String paymentCardsTable = "payment_cards";
  static const String metaAccountsTable = "meta_accounts";
  static const String vatRatesTable = "vat_rates"; // Neu
}
