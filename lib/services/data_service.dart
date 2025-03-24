import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class DataService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, String>>> getEmployees() async {
    try {
      final response = await supabase
          .from(AppConstants.employeesTable)
          .select()
          .order('name', ascending: true);
      return List<Map<String, String>>.from(
        response.map((item) => {
              'id': item['id'].toString(),
              'name': item['name'].toString(),
            }),
      );
    } catch (e) {
      print('Fehler beim Abrufen der Mitarbeiter: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getCostCenters() async {
    try {
      final response = await supabase
          .from(AppConstants.costCentersTable)
          .select()
          .order('id', ascending: true);
      return List<Map<String, String>>.from(
        response.map((item) => {
              'id': item['id'].toString(),
              'description': item['description'].toString(),
            }),
      );
    } catch (e) {
      print('Fehler beim Abrufen der Kostenstellen: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getProjects() async {
    try {
      final response = await supabase
          .from(AppConstants.projectsTable)
          .select()
          .order('id', ascending: true);
      return List<Map<String, String>>.from(
        response.map((item) => {
              'id': item['id'].toString(),
              'description': item['description'].toString(),
            }),
      );
    } catch (e) {
      print('Fehler beim Abrufen der Projekte: $e');
      return [];
    }
  }

  Future<List<String>> getPaymentCards() async {
    try {
      final response = await supabase
          .from(AppConstants.paymentCardsTable)
          .select('name')
          .order('name', ascending: true);
      return List<String>.from(response.map((e) => e['name'].toString()));
    } catch (e) {
      print('Fehler beim Abrufen der Zahlungskarten: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getMetaAccounts() async {
    try {
      final response = await supabase
          .from(AppConstants.metaAccountsTable)
          .select()
          .order('id', ascending: true);
      return List<Map<String, String>>.from(
        response.map((item) => {
              'id': item['id'].toString(),
              'description': item['description'].toString(),
            }),
      );
    } catch (e) {
      print('Fehler beim Abrufen der Meta-Konten: $e');
      return [];
    }
  }

  Future<List<String>> getVatRates() async {
    try {
      final response = await supabase
          .from(AppConstants.vatRatesTable)
          .select('rate')
          .order('rate', ascending: true);
      return List<String>.from(response.map((e) => e['rate'].toString()));
    } catch (e) {
      print('Fehler beim Abrufen der Mehrwertsteuer-Sätze: $e');
      return [];
    }
  }
}
