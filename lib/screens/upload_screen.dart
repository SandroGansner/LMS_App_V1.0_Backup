import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../services/file_upload_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? fileName;
  File? _selectedFile;
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _picker = ImagePicker();

  // Berechtigungen für Mobilgeräte anfragen
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.photos,
        Permission.storage,
      ].request();
      return statuses[Permission.camera]!.isGranted &&
          (statuses[Permission.photos]!.isGranted ||
              statuses[Permission.storage]!.isGranted);
    }
    return true;
  }

  // Datei für Desktop auswählen (nur macOS/Windows)
  Future<void> _pickFileDesktop() async {
    if (Platform.isMacOS || Platform.isWindows) {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'files',
        extensions: ['pdf', 'jpg', 'png'],
        uniformTypeIdentifiers: ['public.pdf', 'public.jpeg', 'public.png'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        try {
          String? savedPath = await _fileUploadService.uploadFile(
            file,
            DateTime.now(),
            'receipts',
          );
          if (mounted) {
            setState(() {
              fileName = savedPath ?? file.name;
              _selectedFile = File(file.path);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Datei erfolgreich hochgeladen!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fehler beim Hochladen: $e')),
            );
          }
        }
      }
    }
  }

  // Datei für Mobilgeräte aus Galerie auswählen (Android/iOS)
  Future<void> _pickFileMobile() async {
    if (await _requestPermissions()) {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        await _convertAndUpload(file);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berechtigungen fehlen!')),
        );
      }
    }
  }

  // Foto mit Kamera machen (Android/iOS)
  Future<void> _takePhoto() async {
    if (await _requestPermissions()) {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        await _convertAndUpload(photo);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera-Berechtigung fehlt!')),
        );
      }
    }
  }

  // Foto in PDF umwandeln und hochladen
  Future<void> _convertAndUpload(XFile file) async {
    try {
      final pdf = pw.Document();
      final image = pw.MemoryImage(await file.readAsBytes());
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(child: pw.Image(image)),
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final pdfPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      String? savedPath = await _fileUploadService.uploadFileFromFile(
        pdfFile,
        DateTime.now(),
        'receipts',
      );

      if (mounted) {
        setState(() {
          fileName = savedPath ?? pdfFile.path.split('/').last;
          _selectedFile = pdfFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datei erfolgreich hochgeladen!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hochladen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload'),
        backgroundColor: const Color(0xFFF2213B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Datei hochladen", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            if (_selectedFile != null && _selectedFile!.existsSync())
              Image.file(
                _selectedFile!,
                height: 200,
                errorBuilder: (context, error, stackTrace) =>
                    Text(fileName ?? 'Keine Vorschau verfügbar'),
              )
            else
              Text(fileName ?? 'Keine Datei ausgewählt'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Datei auswählen'),
                  onPressed: Platform.isAndroid || Platform.isIOS
                      ? _pickFileMobile
                      : _pickFileDesktop,
                ),
                if (Platform.isAndroid || Platform.isIOS)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Foto machen'),
                    onPressed: _takePhoto,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
