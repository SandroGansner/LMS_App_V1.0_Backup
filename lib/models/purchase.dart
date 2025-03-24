class Purchase {
  final int id; // Ändere von String zu int
  final String itemName;
  final double price;
  final String costCenter;
  final String projectNumber;
  final String invoiceIssuer;
  final String employee;
  final String cardUsed;
  final String receiptPath;
  final String vatRate;
  final DateTime date;

  Purchase({
    required this.id,
    required this.itemName,
    required this.price,
    required this.costCenter,
    required this.projectNumber,
    required this.invoiceIssuer,
    required this.employee,
    required this.cardUsed,
    required this.receiptPath,
    required this.vatRate,
    required this.date,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as int, // Konvertiere von int (von Supabase)
      itemName: json['itemName'] as String,
      price: (json['price'] as num).toDouble(),
      costCenter: json['costCenter'] as String,
      projectNumber: json['projectNumber'] as String,
      invoiceIssuer: json['invoiceIssuer'] as String,
      employee: json['employee'] as String,
      cardUsed: json['cardUsed'] as String,
      receiptPath: json['receiptPath'] as String? ?? '',
      vatRate: json['vatRate'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Entferne 'id' aus toJson, da es von der Datenbank generiert wird
      'itemName': itemName,
      'price': price,
      'costCenter': costCenter,
      'projectNumber': projectNumber,
      'invoiceIssuer': invoiceIssuer,
      'employee': employee,
      'cardUsed': cardUsed,
      'receiptPath': receiptPath,
      'vatRate': vatRate,
      'date': date.toIso8601String(),
    };
  }
}
