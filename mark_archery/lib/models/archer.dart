class Archer {
  final String id;
  final String name;
  final String email;

  const Archer({
    required this.id,
    required this.name,
    required this.email,
  });

  factory Archer.fromJson(Map<String, dynamic> json) {
    return Archer(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}