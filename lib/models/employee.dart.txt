class Employee {
  final String name;
  final String role;

  Employee({
    required this.name,
    required this.role,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      name: json['name'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
      };
}
