import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/purchase.dart';
import '../services/purchase_service.dart';
import '../services/export_service.dart';
import '../services/file_upload_service.dart';
import '../widgets/dropdown_selector.dart';
import '../services/data_service.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  String itemName = '';
  double? price;
  String invoiceIssuer = '';
  String? selectedEmployee;
  String? selectedCostCenter;
  String? selectedProject;
  String? selectedCard;
  String? receiptFileName;
  String? selectedVAT;
  DateTime? selectedPurchaseDate;
  File? receiptFile;

  List<Map<String, String>> employees = [];
  List<Map<String, String>> costCenters = [];
  List<Map<String, String>> projects = [];
  List<String> paymentCards = [];
  List<String> vatOptions = [];

  List<Purchase> _purchases = [];
  final PurchaseService _purchaseService = PurchaseService();
  final FileUploadService _fileUploadService = FileUploadService();
  final ExportService _exportService = ExportService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _loadPurchases();
  }

  Future<void> _loadDropdownData() async {
    try {
      print('Lade Dropdown-Daten...');
      final emp = await DataService().getEmployees();
      final cc = await DataService().getCostCenters();
      final proj = await DataService().getProjects();
      final cards = await DataService().getPaymentCards();
      final vatRates = await DataService().getVatRates();

      setState(() {
        employees = emp;
        costCenters = cc;
        projects = proj;
        paymentCards = cards;
        vatOptions = vatRates;

        if (employees.isNotEmpty) selectedEmployee = employees[0]['name'];
        if (costCenters.isNotEmpty)
          selectedCostCenter =
              "${costCenters[0]['id']} - ${costCenters[0]['description']}";
        if (projects.isNotEmpty)
          selectedProject =
              "${projects[0]['id']} - ${projects[0]['description']}";
        if (paymentCards.isNotEmpty) selectedCard = paymentCards[0];
        if (vatOptions.isNotEmpty) selectedVAT = vatOptions[0];
      });
      print('Dropdown-Daten geladen: $employees, $costCenters, $projects');
    } catch (e) {
      print("❌ Fehler beim Laden der Dropdown-Daten: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Daten: $e')),
        );
      }
    }
  }

  Future<void> _loadPurchases() async {
    try {
      print('Lade Käufe...');
      final purchases = await _purchaseService.getPurchases();
      if (mounted) {
        setState(() {
          _purchases = purchases;
        });
      }
      print('Käufe geladen: $_purchases');
    } catch (e) {
      print("❌ Fehler beim Laden der Käufe: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Käufe: $e')),
        );
      }
    }
  }

  String _cleanFileName(String fileName) {
    return fileName
        .replaceAll(' ', '_')
        .replaceAll('–', '-')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Erklärung anzeigen, bevor die Berechtigung angefragt wird
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Berechtigungen erforderlich'),
            content: const Text(
                'Diese App benötigt Zugriff auf Kamera und Fotobibliothek, um Fotos für Belege aufzunehmen oder auszuwählen. Bitte erlauben Sie den Zugriff.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      // Berechtigungen anfragen
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        if (Platform.isAndroid) ...[
          // Für Android 13+ die neuen Berechtigungen verwenden
          if (int.parse(Platform.version.split('.')[0]) >= 33)
            Permission.photos
          else
            Permission.storage,
        ],
        if (Platform.isIOS) Permission.photos,
      ].request();

      bool cameraGranted = statuses[Permission.camera]!.isGranted;
      bool photosGranted = (Platform.isIOS
          ? statuses[Permission.photos]!.isGranted
          : (int.parse(Platform.version.split('.')[0]) >= 33
              ? statuses[Permission.photos]!.isGranted
              : statuses[Permission.storage]!.isGranted));

      if (!cameraGranted || !photosGranted) {
        // Prüfen, ob die Berechtigung dauerhaft verweigert wurde
        bool cameraPermanentlyDenied =
            await Permission.camera.isPermanentlyDenied;
        bool photosPermanentlyDenied = await (Platform.isIOS
                ? Permission.photos
                : (int.parse(Platform.version.split('.')[0]) >= 33
                    ? Permission.photos
                    : Permission.storage))
            .isPermanentlyDenied;

        if (cameraPermanentlyDenied || photosPermanentlyDenied) {
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Berechtigung verweigert'),
                content: const Text(
                    'Sie haben den Zugriff auf Kamera oder Fotobibliothek dauerhaft verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      openAppSettings(); // Nutzer zu den Einstellungen weiterleiten
                    },
                    child: const Text('Einstellungen öffnen'),
                  ),
                ],
              ),
            );
          }
        }
        return false;
      }
      return true;
    }
    return true; // Für Desktop-Plattformen (keine Berechtigungen nötig)
  }

  Future<void> _pickReceiptFile() async {
    if (Platform.isMacOS || Platform.isWindows) {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'files',
        extensions: ['pdf', 'jpg', 'png'],
        uniformTypeIdentifiers: ['public.pdf', 'public.jpeg', 'public.png'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        try {
          print('Datei ausgewählt: ${file.name}');
          final cleanFileName = _cleanFileName(file.name);
          print('Bereinigter Dateiname: $cleanFileName');

          setState(() {
            receiptFile = File(file.path);
            receiptFileName = cleanFileName;
          });
        } catch (e) {
          print('❌ Fehler beim Auswählen der Datei: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fehler beim Auswählen der Datei: $e')),
            );
          }
        }
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      if (await _requestPermissions()) {
        final XFile? file =
            await _picker.pickImage(source: ImageSource.gallery);
        if (file != null) {
          await _convertImageToPdf(file);
        }
      }
    }
  }

  Future<void> _takePhoto() async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (await _requestPermissions()) {
        final XFile? photo =
            await _picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          await _convertImageToPdf(photo);
        }
      }
    }
  }

  Future<void> _convertImageToPdf(XFile file) async {
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

      final cleanFileName = _cleanFileName(file.name);
      setState(() {
        receiptFile = pdfFile;
        receiptFileName = cleanFileName;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Konvertieren: $e')),
        );
      }
    }
  }

  Future<void> _pickPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedPurchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        selectedPurchaseDate = picked;
      });
    }
  }

  Future<void> _saveAndExportPurchase() async {
    if (_formKey.currentState!.validate() &&
        selectedEmployee != null &&
        selectedCostCenter != null &&
        selectedProject != null &&
        selectedCard != null &&
        selectedVAT != null &&
        price != null &&
        selectedPurchaseDate != null) {
      try {
        print('Starte Speichern des Einkaufs...');
        final costCenterId = selectedCostCenter!.split(' - ')[0];
        final projectId = selectedProject!.split(' - ')[0];

        String? receiptPath;
        if (receiptFile != null && receiptFileName != null) {
          print('Beleg-Datei vorhanden: ${receiptFile!.path}');
          print(
              'Versuche, Datei in Bucket purchase-receipts hochzuladen: $receiptFileName');
          final savedPath = await _fileUploadService.uploadFile(
            XFile(receiptFile!.path),
            selectedPurchaseDate!,
            'purchase-receipts',
            cleanFileName: receiptFileName!,
          );
          receiptPath = savedPath;
          print('Beleg hochgeladen, Pfad: $receiptPath');
        } else {
          print('Keine Beleg-Datei ausgewählt.');
        }

        final newPurchase = Purchase(
          id: 0,
          itemName: itemName,
          price: price!,
          costCenter: costCenterId,
          projectNumber: projectId,
          invoiceIssuer: invoiceIssuer,
          employee: selectedEmployee!,
          cardUsed: selectedCard!,
          receiptPath: receiptPath ?? '',
          vatRate: selectedVAT!,
          date: selectedPurchaseDate!,
        );

        print('Speichere Einkauf in purchases-Tabelle...');
        await _purchaseService.addPurchase(newPurchase);
        print('✅ Einkauf gespeichert: ${newPurchase.itemName}');

        await _loadPurchases();

        if (_purchases.isNotEmpty) {
          print('Exportiere Käufe...');
          await _exportService.exportPurchasesFancy(purchases: _purchases);
          print('Käufe exportiert.');
        } else {
          print('⚠️ Keine Käufe zum Exportieren gefunden.');
        }

        _formKey.currentState!.reset();
        if (mounted) {
          setState(() {
            selectedEmployee =
                employees.isNotEmpty ? employees[0]['name'] : null;
            selectedCostCenter = costCenters.isNotEmpty
                ? "${costCenters[0]['id']} - ${costCenters[0]['description']}"
                : null;
            selectedProject = projects.isNotEmpty
                ? "${projects[0]['id']} - ${projects[0]['description']}"
                : null;
            selectedCard = paymentCards.isNotEmpty ? paymentCards[0] : null;
            receiptFileName = null;
            receiptFile = null;
            price = null;
            itemName = '';
            invoiceIssuer = '';
            selectedVAT = vatOptions.isNotEmpty ? vatOptions[0] : null;
            selectedPurchaseDate = null;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Vielen Dank, Ihr Einkauf wurde erfolgreich erfasst und exportiert!'),
            ),
          );
        }
      } catch (e) {
        print('❌ Fehler beim Speichern oder Exportieren: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Fehler beim Speichern oder Exportieren: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Bitte alle Felder, einschließlich Kaufdatum, ausfüllen.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Einkauf erfassen",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Artikelname'),
                onChanged: (val) => itemName = val,
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Bitte Artikelname eingeben'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Preis (CHF)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => price = double.tryParse(val),
                validator: (val) =>
                    (val == null || double.tryParse(val) == null)
                        ? 'Bitte gültigen Preis eingeben'
                        : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Rechnungssteller'),
                onChanged: (val) => invoiceIssuer = val,
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Bitte Rechnungssteller angeben'
                    : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedPurchaseDate != null
                          ? 'Kaufdatum: ${DateFormat('dd.MM.yyyy').format(selectedPurchaseDate!)}'
                          : 'Kaufdatum wählen',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickPurchaseDate,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownSelector<String>(
                items: employees.map((e) => e['name']!).toList(),
                value: selectedEmployee,
                hint: 'Mitarbeiter wählen',
                onChanged: (val) => setState(() => selectedEmployee = val),
              ),
              const SizedBox(height: 10),
              DropdownSelector<String>(
                items: costCenters
                    .map((c) => "${c['id']} - ${c['description']}")
                    .toList(),
                value: selectedCostCenter,
                hint: 'Kostenstelle wählen',
                onChanged: (val) => setState(() => selectedCostCenter = val),
              ),
              const SizedBox(height: 10),
              DropdownSelector<String>(
                items: projects
                    .map((p) => "${p['id']} - ${p['description']}")
                    .toList(),
                value: selectedProject,
                hint: 'Projekt wählen',
                onChanged: (val) => setState(() => selectedProject = val),
              ),
              const SizedBox(height: 10),
              DropdownSelector<String>(
                items: paymentCards,
                value: selectedCard,
                hint: 'Zahlungskarte wählen',
                onChanged: (val) => setState(() => selectedCard = val),
              ),
              const SizedBox(height: 10),
              DropdownSelector<String>(
                items: vatOptions,
                value: selectedVAT,
                hint: 'Mehrwertsteuer wählen',
                onChanged: (val) => setState(() => selectedVAT = val),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(receiptFileName ?? 'Rechnung auswählen'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: _pickReceiptFile,
                        ),
                      ],
                    ),
                  ),
                  if (Platform.isAndroid || Platform.isIOS)
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: Text('Foto machen')),
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _takePhoto,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _saveAndExportPurchase,
                  child: const Text('Einkauf erfassen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
