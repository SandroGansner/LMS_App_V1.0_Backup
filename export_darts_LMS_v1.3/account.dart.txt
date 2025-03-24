class Account {
  final String id;
  final String description;

  Account({
    required this.id,
    required this.description,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
      };
}
