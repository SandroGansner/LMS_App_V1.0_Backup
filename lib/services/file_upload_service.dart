import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';

class FileUploadService {
  final supabase = Supabase.instance.client;

  // Hilfsfunktion zum Bereinigen des Dateinamens
  String _cleanFileName(String fileName) {
    return fileName
        .replaceAll(' ', '_') // Leerzeichen durch Unterstriche ersetzen
        .replaceAll('–', '-') // Langer Bindestrich durch normalen Bindestrich
        .replaceAll(
            RegExp(r'[^a-zA-Z0-9_.-]'), ''); // Ungültige Zeichen entfernen
  }

  // Upload für XFile (Desktop)
  Future<String?> uploadFile(
    XFile file,
    DateTime timestamp,
    String bucketName, {
    String? cleanFileName,
  }) async {
    try {
      print('Starte Datei-Upload in Bucket $bucketName...');

      final fileBytes = await File(file.path).readAsBytes();
      print('Datei-Bytes gelesen: ${fileBytes.length} Bytes');

      final originalFileName = cleanFileName ?? file.name;
      print('Originaler Dateiname: $originalFileName');

      final sanitizedFileName = _cleanFileName(originalFileName);
      print('Bereinigter Dateiname: $sanitizedFileName');

      final fileName = '${timestamp.toIso8601String()}_$sanitizedFileName';
      print('Endgültiger Dateiname für Upload: $fileName');

      final uploadedPath = await supabase.storage
          .from(bucketName)
          .uploadBinary(fileName, fileBytes);

      print("✅ Datei erfolgreich hochgeladen in $bucketName: $uploadedPath");
      return uploadedPath;
    } catch (e) {
      print("❌ Fehler beim Hochladen der Datei in $bucketName: $e");
      return null;
    }
  }

  // Überladung für File (Mobil nach PDF-Umwandlung)
  Future<String?> uploadFileFromFile(
    File file,
    DateTime timestamp,
    String bucketName, {
    String? cleanFileName,
  }) async {
    try {
      print('Starte Datei-Upload in Bucket $bucketName...');

      final fileBytes = await file.readAsBytes();
      print('Datei-Bytes gelesen: ${fileBytes.length} Bytes');

      final originalFileName = cleanFileName ?? file.path.split('/').last;
      print('Originaler Dateiname: $originalFileName');

      final sanitizedFileName = _cleanFileName(originalFileName);
      print('Bereinigter Dateiname: $sanitizedFileName');

      final fileName = '${timestamp.toIso8601String()}_$sanitizedFileName';
      print('Endgültiger Dateiname für Upload: $fileName');

      final uploadedPath = await supabase.storage
          .from(bucketName)
          .uploadBinary(fileName, fileBytes);

      print("✅ Datei erfolgreich hochgeladen in $bucketName: $uploadedPath");
      return uploadedPath;
    } catch (e) {
      print("❌ Fehler beim Hochladen der Datei in $bucketName: $e");
      return null;
    }
  }
}
