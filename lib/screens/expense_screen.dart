import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';
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
  String iban = ''; // Neu: IBAN
  String bankName = ''; // Neu: Bankname
  File? receiptFile;

  List<Map<String, String>> employees = [];
  List<Map<String, String>> costCenters = [];
  List<Map<String, String>> projects = [];
  List<String> paymentCards = [];
  List<String> vatOptions = [];

  List<Expense> _expenses = [];
  final ExpenseService _expenseService = ExpenseService();
  final ExportService _exportService = ExportService();

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

  Future<void> _pickReceiptFile() async {
    const typeGroup =
        XTypeGroup(label: 'files', extensions: ['pdf', 'jpg', 'png']);
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
    } else {
      print('Keine Datei ausgewählt.');
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
        iban.isNotEmpty && // Neu: IBAN muss angegeben sein
        bankName.isNotEmpty) {
      // Neu: Bankname muss angegeben sein
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
          id: 0, // Dummy-Wert, wird von der DB überschrieben
          employeeName: selectedEmployee!,
          costCenter: costCenterId,
          projectNumber: projectId,
          amount: amount!,
          date: expenseDate!,
          description: description,
          receiptPath: receiptPath ?? '',
          vatRate: selectedVatRate!,
          cardUsed: selectedCard!,
          iban: iban, // Neu
          bankName: bankName, // Neu
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
            iban = ''; // Neu
            bankName = ''; // Neu
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
                keyboardType: TextInputType.number,
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
                children: [
                  Expanded(child: Text(receiptFileName ?? 'Beleg auswählen')),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickReceiptFile,
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
