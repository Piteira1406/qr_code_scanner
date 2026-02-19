/// Model representing a student user in the ISTEC campus system.
class User {
  final String id;
  final String email;
  final String name;
  final String studentNumber;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.studentNumber,
  });

  /// Creates a User from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      studentNumber: json['studentNumber'] as String,
    );
  }

  /// Converts the User to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'studentNumber': studentNumber,
    };
  }

  @override
  String toString() => 'User(id: $id, email: $email, name: $name)';
}
