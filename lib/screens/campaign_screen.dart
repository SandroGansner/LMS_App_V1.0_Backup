import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import '../services/export_service.dart';
import '../services/file_upload_service.dart';
import '../widgets/dropdown_selector.dart';
import '../services/data_service.dart';

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  final _formKey = GlobalKey<FormState>();

  String campaignName = '';
  DateTime? startDate;
  DateTime? endDate;
  double? adBudget;
  String? selectedCostCenter;
  String? selectedEmployee;
  String? selectedProject;
  String? selectedMetaAccount;
  String targetUrl = '';
  String? assetFileName;
  File? assetFile; // Temporäre Datei für den Upload

  List<Map<String, String>> costCenters = [];
  List<Map<String, String>> employees = [];
  List<Map<String, String>> projects = [];
  List<Map<String, String>> metaAccounts = [];

  List<Campaign> _campaigns = [];
  final CampaignService _campaignService = CampaignService();
  final ExportService _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _loadCampaigns();
  }

  Future<void> _loadAllData() async {
    try {
      print('Lade Dropdown-Daten...');
      final cc = await DataService().getCostCenters();
      final emp = await DataService().getEmployees();
      final proj = await DataService().getProjects();
      final meta = await DataService().getMetaAccounts();

      setState(() {
        costCenters = cc;
        employees = emp;
        projects = proj;
        metaAccounts = meta;

        // Standardwerte setzen
        if (employees.isNotEmpty) selectedEmployee = employees[0]['name'];
        if (costCenters.isNotEmpty)
          selectedCostCenter =
              "${costCenters[0]['id']} - ${costCenters[0]['description']}";
        if (projects.isNotEmpty)
          selectedProject =
              "${projects[0]['id']} - ${projects[0]['description']}";
        if (metaAccounts.isNotEmpty)
          selectedMetaAccount =
              "${metaAccounts[0]['id']} - ${metaAccounts[0]['description']}";
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

  Future<void> _loadCampaigns() async {
    try {
      print('Lade Kampagnen...');
      final campaigns = await _campaignService.getCampaigns();
      if (mounted) {
        setState(() {
          _campaigns = campaigns;
        });
      }
      print('Kampagnen geladen: $_campaigns');
    } catch (e) {
      print("❌ Fehler beim Laden der Kampagnen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Kampagnen: $e')),
        );
      }
    }
  }

  String _cleanFileName(String fileName) {
    // Dateinamen bereinigen: Leerzeichen und Sonderzeichen ersetzen
    return fileName
        .replaceAll(' ', '_')
        .replaceAll('–', '-')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
  }

  Future<void> _pickAssetFile() async {
    const typeGroup =
        XTypeGroup(label: 'files', extensions: ['jpg', 'png', 'pdf']);
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      try {
        print('Datei ausgewählt: ${file.name}');
        final cleanFileName = _cleanFileName(file.name);
        print('Bereinigter Dateiname: $cleanFileName');

        // Temporäre Datei speichern
        setState(() {
          assetFile = File(file.path);
          assetFileName = cleanFileName;
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

  Future<void> _saveAndExportCampaign() async {
    if (_formKey.currentState!.validate() &&
        startDate != null &&
        endDate != null &&
        selectedCostCenter != null &&
        adBudget != null &&
        selectedEmployee != null &&
        selectedProject != null &&
        selectedMetaAccount != null) {
      try {
        print('Starte Speichern der Kampagne...');
        final costCenterId = selectedCostCenter!.split(' - ')[0];
        final projectId = selectedProject!.split(' - ')[0];
        final metaAccountId = selectedMetaAccount!.split(' - ')[0];

        // Asset hochladen, falls vorhanden
        String? assetPath;
        if (assetFile != null && assetFileName != null) {
          print('Asset-Datei vorhanden: ${assetFile!.path}');
          print(
              'Versuche, Datei in Bucket campaign-assets hochzuladen: $assetFileName');
          final savedPath = await FileUploadService().uploadFile(
            XFile(assetFile!.path),
            startDate!,
            'campaign-assets',
            cleanFileName: assetFileName!,
          );
          assetPath = savedPath;
          print('Asset hochgeladen, Pfad: $assetPath');
        } else {
          print('Keine Asset-Datei ausgewählt.');
        }

        // Erstelle die neue Kampagne mit assetPath direkt im Konstruktor
        final newCampaign = Campaign(
          id: 0, // Dummy-Wert, wird von der DB überschrieben
          name: campaignName, // Ändere von campaignName zu name
          employee: selectedEmployee!,
          startDate: startDate!,
          endDate: endDate!,
          adBudget: adBudget!,
          costCenter: costCenterId,
          project: projectId,
          metaAccount: metaAccountId,
          targetUrl: targetUrl,
          assetPath: assetPath ?? '', // Direkt im Konstruktor setzen
        );

        // Kampagne speichern
        print('Speichere Kampagne in campaigns-Tabelle...');
        await _campaignService.addCampaign(newCampaign);
        print('✅ Kampagne gespeichert: ${newCampaign.name}');

        // Kampagnen neu laden
        await _loadCampaigns();

        // Exportieren, wenn Kampagnen vorhanden sind
        if (_campaigns.isNotEmpty) {
          print('Exportiere Kampagnen...');
          await _exportService.exportCampaignsFancy(_campaigns);
          print('Kampagnen exportiert.');
        } else {
          print('⚠️ Keine Kampagnen zum Exportieren gefunden.');
        }

        // Formular zurücksetzen
        _formKey.currentState!.reset();
        if (mounted) {
          setState(() {
            campaignName = '';
            startDate = null;
            endDate = null;
            adBudget = null;
            selectedCostCenter = costCenters.isNotEmpty
                ? "${costCenters[0]['id']} - ${costCenters[0]['description']}"
                : null;
            selectedEmployee =
                employees.isNotEmpty ? employees[0]['name'] : null;
            selectedProject = projects.isNotEmpty
                ? "${projects[0]['id']} - ${projects[0]['description']}"
                : null;
            selectedMetaAccount = metaAccounts.isNotEmpty
                ? "${metaAccounts[0]['id']} - ${metaAccounts[0]['description']}"
                : null;
            targetUrl = '';
            assetFileName = null;
            assetFile = null;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Vielen Dank, Ihre Kampagne wurde erfolgreich erfasst und exportiert!'),
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
              Text(
                "Kampagne erfassen",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Kampagnenname'),
                onChanged: (val) => campaignName = val,
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Bitte Kampagnenname eingeben'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownSelector<String>(
                items: employees.map((e) => e['name']!).toList(),
                value: selectedEmployee,
                hint: 'Mitarbeiter wählen',
                onChanged: (val) => setState(() => selectedEmployee = val),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      startDate == null
                          ? 'Startdatum wählen'
                          : 'Start: ${DateFormat('dd.MM.yyyy').format(startDate!)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() => startDate = picked);
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      endDate == null
                          ? 'Enddatum wählen'
                          : 'Ende: ${DateFormat('dd.MM.yyyy').format(endDate!)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() => endDate = picked);
                      }
                    },
                  ),
                ],
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Werbebudget (CHF)'),
                keyboardType: TextInputType.number,
                onChanged: (val) => adBudget = double.tryParse(val),
                validator: (val) =>
                    (val == null || double.tryParse(val) == null)
                        ? 'Bitte gültigen Betrag eingeben'
                        : null,
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
                items: metaAccounts
                    .map((m) => "${m['id']} - ${m['description']}")
                    .toList(),
                value: selectedMetaAccount,
                hint: 'Meta-Konto wählen',
                onChanged: (val) => setState(() => selectedMetaAccount = val),
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Ziel-URL'),
                onChanged: (val) => targetUrl = val,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assetFileName ?? 'Asset-Datei auswählen',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.white),
                    onPressed: _pickAssetFile,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _saveAndExportCampaign,
                  child: const Text('Kampagne erfassen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
