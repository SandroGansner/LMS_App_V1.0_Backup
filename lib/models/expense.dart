class Expense {
  final int id;
  final String employeeName;
  final String costCenter;
  final String projectNumber;
  final double amount;
  final DateTime date;
  final String description;
  final String receiptPath;
  final String vatRate;
  final String cardUsed;
  final String iban; // Neu
  final String bankName; // Neu

  Expense({
    required this.id,
    required this.employeeName,
    required this.costCenter,
    required this.projectNumber,
    required this.amount,
    required this.date,
    required this.description,
    required this.receiptPath,
    required this.vatRate,
    required this.cardUsed,
    required this.iban, // Neu
    required this.bankName, // Neu
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      employeeName: json['employeeName'],
      costCenter: json['costCenter'],
      projectNumber: json['projectNumber'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
      receiptPath: json['receiptPath'],
      vatRate: json['vatRate'],
      cardUsed: json['cardUsed'],
      iban: json['iban'] ?? '', // Falls in der DB NULL vorkommt
      bankName: json['bankName'] ?? '', // Falls in der DB NULL vorkommt
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeName': employeeName,
        'costCenter': costCenter,
        'projectNumber': projectNumber,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
        'receiptPath': receiptPath,
        'vatRate': vatRate,
        'cardUsed': cardUsed,
        'iban': iban,
        'bankName': bankName,
      };
}
