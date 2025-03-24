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

  Future<String?> uploadFile(
    XFile file,
    DateTime timestamp,
    String bucketName, {
    String?
        cleanFileName, // Optionaler Parameter für den bereinigten Dateinamen
  }) async {
    try {
      print('Starte Datei-Upload in Bucket $bucketName...');

      // Lese die Bytes der Datei
      final fileBytes = await File(file.path).readAsBytes();
      print('Datei-Bytes gelesen: ${fileBytes.length} Bytes');

      // Erstelle einen eindeutigen Dateinamen
      final originalFileName = cleanFileName ?? file.name;
      print('Originaler Dateiname: $originalFileName');

      // Bereinige den Dateinamen
      final sanitizedFileName = _cleanFileName(originalFileName);
      print('Bereinigter Dateiname: $sanitizedFileName');

      // Kombiniere den Zeitstempel mit dem bereinigten Dateinamen
      final fileName = '${timestamp.toIso8601String()}_$sanitizedFileName';
      print('Endgültiger Dateiname für Upload: $fileName');

      // Lade die Datei in den angegebenen Bucket hoch
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
