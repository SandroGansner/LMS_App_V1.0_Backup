import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
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
  File? receiptFile; // Temporäre Datei für den Upload

  List<Map<String, String>> employees = [];
  List<Map<String, String>> costCenters = [];
  List<Map<String, String>> projects = [];
  List<String> paymentCards = [];
  List<String> vatOptions = [];

  List<Purchase> _purchases = [];
  final PurchaseService _purchaseService = PurchaseService();
  final FileUploadService _fileUploadService = FileUploadService();
  final ExportService _exportService = ExportService();

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

        // Standardwerte setzen
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
    // Dateinamen bereinigen: Leerzeichen und Sonderzeichen ersetzen
    return fileName
        .replaceAll(' ', '_') // Leerzeichen durch Unterstriche ersetzen
        .replaceAll('–', '-') // Langer Bindestrich durch normalen Bindestrich
        .replaceAll(
            RegExp(r'[^a-zA-Z0-9_.-]'), ''); // Ungültige Zeichen entfernen
  }

  Future<void> _pickReceiptFile() async {
    if (selectedPurchaseDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bitte zuerst ein Kaufdatum auswählen.')),
        );
      }
      return;
    }

    const typeGroup =
        XTypeGroup(label: 'files', extensions: ['pdf', 'jpg', 'png']);
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      try {
        print('Datei ausgewählt: ${file.name}');
        final cleanFileName = _cleanFileName(file.name);
        print('Bereinigter Dateiname: $cleanFileName');

        // Temporäre Datei speichern
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
    } else {
      print('Keine Datei ausgewählt.');
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

        // Beleg hochladen, falls vorhanden
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

        // Erstelle den neuen Einkauf mit receiptPath direkt im Konstruktor
        final newPurchase = Purchase(
          id: 0, // Dummy-Wert, wird von der DB überschrieben
          itemName: itemName,
          price: price!,
          costCenter: costCenterId,
          projectNumber: projectId,
          invoiceIssuer: invoiceIssuer,
          employee: selectedEmployee!,
          cardUsed: selectedCard!,
          receiptPath: receiptPath ?? '', // Direkt im Konstruktor setzen
          vatRate: selectedVAT!,
          date: selectedPurchaseDate!,
        );

        // Einkauf speichern
        print('Speichere Einkauf in purchases-Tabelle...');
        await _purchaseService.addPurchase(newPurchase);
        print('✅ Einkauf gespeichert: ${newPurchase.itemName}');

        // Käufe neu laden
        await _loadPurchases();

        // Exportieren, wenn Käufe vorhanden sind
        if (_purchases.isNotEmpty) {
          print('Exportiere Käufe...');
          await _exportService.exportPurchasesFancy(purchases: _purchases);
          print('Käufe exportiert.');
        } else {
          print('⚠️ Keine Käufe zum Exportieren gefunden.');
        }

        // Formular zurücksetzen
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
                keyboardType: TextInputType.number,
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
