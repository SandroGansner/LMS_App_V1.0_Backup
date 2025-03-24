import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/campaign.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';

class CampaignService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> addCampaign(Campaign campaign) async {
    try {
      await supabase
          .from(AppConstants.campaignsTable)
          .insert(campaign.toJson());
      print("✅ Kampagne gespeichert: ${campaign.name}");
    } catch (e) {
      print("❌ Fehler beim Speichern der Kampagne: $e");
      rethrow;
    }
  }

  Future<List<Campaign>> getCampaigns() async {
    try {
      final response =
          await supabase.from(AppConstants.campaignsTable).select();
      return (response as List).map((json) => Campaign.fromJson(json)).toList();
    } catch (e) {
      print("❌ Fehler beim Laden der Kampagnen: $e");
      return [];
    }
  }

  Future<String> exportCampaignsToExcel() async {
    try {
      List<Campaign> campaigns = await getCampaigns();

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
      }

      // Datei speichern
      final directory = await getApplicationDocumentsDirectory();
      String filePath = p.join(directory.path, "campaigns_export.xlsx");
      final file = File(filePath);
      final bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes);
      workbook.dispose();

      print("✅ Kampagnen-Excel gespeichert: $filePath");
      return filePath;
    } catch (e) {
      print("❌ Fehler beim Exportieren der Kampagnen: $e");
      return "";
    }
  }
}
