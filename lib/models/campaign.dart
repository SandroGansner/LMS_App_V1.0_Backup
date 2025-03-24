class Campaign {
  final int id;
  final String name; // Verwende 'name' statt 'campaignName'
  final String employee;
  final DateTime startDate;
  final DateTime endDate;
  final double adBudget;
  final String costCenter;
  final String project;
  final String metaAccount;
  final String targetUrl;
  final String assetPath;

  Campaign({
    required this.id,
    required this.name,
    required this.employee,
    required this.startDate,
    required this.endDate,
    required this.adBudget,
    required this.costCenter,
    required this.project,
    required this.metaAccount,
    required this.targetUrl,
    required this.assetPath,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as int,
      name: json['name'] as String,
      employee: json['employee'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      adBudget: (json['adBudget'] as num).toDouble(),
      costCenter: json['costCenter'] as String,
      project: json['project'] as String,
      metaAccount: json['metaAccount'] as String,
      targetUrl: json['targetUrl'] as String? ?? '',
      assetPath: json['assetPath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'employee': employee,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'adBudget': adBudget,
      'costCenter': costCenter,
      'project': project,
      'metaAccount': metaAccount,
      'targetUrl': targetUrl,
      'assetPath': assetPath,
    };
  }
}
