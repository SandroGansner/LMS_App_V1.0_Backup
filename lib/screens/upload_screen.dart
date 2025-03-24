import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../services/file_upload_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? fileName;
  final FileUploadService _fileUploadService = FileUploadService();

  Future<void> _pickFile() async {
    const typeGroup =
        XTypeGroup(label: 'files', extensions: ['pdf', 'jpg', 'png']);
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      try {
        // Datei in den 'receipts'-Bucket hochladen
        String? savedPath = await _fileUploadService.uploadFile(
          file,
          DateTime.now(),
          'receipts', // Bucket-Name explizit angeben
        );
        if (mounted) {
          setState(() {
            fileName = savedPath ?? file.name;
          });
          // Erfolgsmeldung anzeigen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datei erfolgreich hochgeladen!'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          // Fehlermeldung anzeigen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Hochladen der Datei: $e'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Datei hochladen", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(fileName ?? 'Datei auswählen')),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
