import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../constants/app_constants.dart';

class SyncService {
  final supabase = Supabase.instance.client;
  final String exportFolderPath;

  SyncService({required this.exportFolderPath});

  Future<void> start() async {
    print("✅ SyncService gestartet mit Exportpfad: $exportFolderPath");

    // Echtzeit-Listener für Expenses
    supabase
        .from(AppConstants.expensesTable)
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
      print("Echtzeit-Update für Expenses: $data");
      // Hier kannst du die Daten lokal speichern oder die UI aktualisieren
    });

    // Echtzeit-Listener für Purchases
    supabase
        .from(AppConstants.purchasesTable)
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
      print("Echtzeit-Update für Purchases: $data");
    });

    // Echtzeit-Listener für Campaigns
    supabase
        .from(AppConstants.campaignsTable)
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
      print("Echtzeit-Update für Campaigns: $data");
    });
  }
}
