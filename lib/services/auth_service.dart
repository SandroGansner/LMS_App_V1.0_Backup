import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Anmelden
  Future<void> signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        print('Erfolgreich angemeldet: ${response.user!.email}');
      }
    } catch (error) {
      print('Fehler beim Anmelden: $error');
      rethrow;
    }
  }

  // Registrieren
  Future<void> signUp(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        print('Erfolgreich registriert: ${response.user!.email}');
      }
    } catch (error) {
      print('Fehler bei der Registrierung: $error');
      rethrow;
    }
  }

  // Abmelden
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      print('Erfolgreich abgemeldet');
    } catch (error) {
      print('Fehler beim Abmelden: $error');
      rethrow;
    }
  }
}
