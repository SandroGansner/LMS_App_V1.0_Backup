import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/export_service.dart';
import '../services/file_upload_service.dart';
import '../widgets/dropdown_selector.dart';
import '../services/data_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedEmployee;
  String? selectedCostCenter;
  String? selectedProject;
  String description = '';
  double? amount;
  DateTime? expenseDate;
  String? receiptFileName;
  String? selectedVatRate;
  String? selectedCard;
  String iban = '';
  String bankName = '';
  File? receiptFile;

  List<Map<String, String>> employees = [];
  List<Map<String, String>> costCenters = [];
  List<Map<String, String>> projects = [];
  List<String> paymentCards = [];
  List<String> vatOptions = [];

  List<Expense> _expenses = [];
  final ExpenseService _expenseService = ExpenseService();
  final ExportService _exportService = ExportService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _loadExpenses();
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
        if (costCenters.isNotEmpty) {
          selectedCostCenter =
              "${costCenters[0]['id']} - ${costCenters[0]['description']}";
        }
        if (projects.isNotEmpty) {
          selectedProject =
              "${projects[0]['id']} - ${projects[0]['description']}";
        }
        if (paymentCards.isNotEmpty) selectedCard = paymentCards[0];
        if (vatOptions.isNotEmpty) selectedVatRate = vatOptions[0];
      });
      print(
          'Dropdown-Daten geladen: $employees, $costCenters, $projects, $paymentCards');
    } catch (e) {
      print("❌ Fehler beim Laden der Dropdown-Daten: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Daten: $e')),
        );
      }
    }
  }

  Future<void> _loadExpenses() async {
    try {
      print('Lade Spesen...');
      final expenses = await _expenseService.getExpenses();
      if (mounted) {
        setState(() {
          _expenses = expenses;
        });
      }
      print('Spesen geladen: $_expenses');
    } catch (e) {
      print("❌ Fehler beim Laden der Spesen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Spesen: $e')),
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
                'Diese App benötigt Zugriff auf Kamera und Fotobibliothek, um Fotos für Spesen aufzunehmen oder auszuwählen. Bitte erlauben Sie den Zugriff.'),
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

  Future<void> _saveAndExportExpense() async {
    if (_formKey.currentState!.validate() &&
        selectedEmployee != null &&
        selectedCostCenter != null &&
        selectedProject != null &&
        expenseDate != null &&
        amount != null &&
        selectedVatRate != null &&
        selectedCard != null &&
        iban.isNotEmpty &&
        bankName.isNotEmpty) {
      try {
        print('Starte Speichern der Spese...');
        final costCenterId = selectedCostCenter!.split(' - ')[0];
        final projectId = selectedProject!.split(' - ')[0];

        String? receiptPath;
        if (receiptFile != null && receiptFileName != null) {
          print('Beleg-Datei vorhanden: ${receiptFile!.path}');
          print(
              'Versuche, Datei in Bucket expense-receipts hochzuladen: $receiptFileName');
          final savedPath = await FileUploadService().uploadFile(
            XFile(receiptFile!.path),
            expenseDate!,
            'expense-receipts',
            cleanFileName: receiptFileName!,
          );
          receiptPath = savedPath;
          print('Beleg hochgeladen, Pfad: $receiptPath');
        } else {
          print('Keine Beleg-Datei ausgewählt.');
        }

        final newExpense = Expense(
          id: 0,
          employeeName: selectedEmployee!,
          costCenter: costCenterId,
          projectNumber: projectId,
          amount: amount!,
          date: expenseDate!,
          description: description,
          receiptPath: receiptPath ?? '',
          vatRate: selectedVatRate!,
          cardUsed: selectedCard!,
          iban: iban,
          bankName: bankName,
        );

        print('Speichere Spese in expenses-Tabelle...');
        await _expenseService.addExpense(newExpense);
        print('✅ Spese gespeichert: ${newExpense.description}');

        await _loadExpenses();

        if (_expenses.isNotEmpty) {
          print('Exportiere Spesen...');
          await _exportService.exportExpensesFancy(_expenses);
          print('Spesen exportiert.');
        } else {
          print('⚠️ Keine Spesen zum Exportieren gefunden.');
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
            expenseDate = null;
            amount = null;
            receiptFileName = null;
            receiptFile = null;
            description = '';
            selectedVatRate = vatOptions.isNotEmpty ? vatOptions[0] : null;
            selectedCard = paymentCards.isNotEmpty ? paymentCards[0] : null;
            iban = '';
            bankName = '';
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Vielen Dank, Ihre Spesen wurden erfolgreich erfasst und exportiert!'),
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
          const SnackBar(content: Text('Bitte alle Felder ausfüllen.')),
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
              Text("Spesen erfassen",
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
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
              TextFormField(
                decoration: const InputDecoration(labelText: 'Betrag (CHF)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => amount = double.tryParse(val),
                validator: (val) =>
                    (val == null || double.tryParse(val) == null)
                        ? 'Bitte gültigen Betrag eingeben'
                        : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Beschreibung'),
                onChanged: (val) => description = val,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'IBAN'),
                onChanged: (val) => iban = val,
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Bitte IBAN eingeben' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Bankname'),
                onChanged: (val) => bankName = val,
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Bitte Bankname eingeben'
                    : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expenseDate == null
                          ? 'Datum wählen'
                          : 'Datum: ${DateFormat('dd.MM.yyyy').format(expenseDate!)}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() => expenseDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(receiptFileName ?? 'Beleg auswählen'),
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
              const SizedBox(height: 10),
              DropdownSelector<String>(
                items: vatOptions,
                value: selectedVatRate,
                hint: 'Mehrwertsteuer wählen',
                onChanged: (val) => setState(() => selectedVatRate = val),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _saveAndExportExpense,
                  child: const Text('Spesen erfassen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
