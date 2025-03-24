class CostCenter {
  final String id;
  final String description;

  CostCenter({
    required this.id,
    required this.description,
  });

  factory CostCenter.fromJson(Map<String, dynamic> json) {
    return CostCenter(
      id: json['id'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
      };
}
