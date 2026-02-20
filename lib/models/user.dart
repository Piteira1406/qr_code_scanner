/// User roles in the ISTEC campus system.
enum UserRole {
  aluno, // Student - can scan QR codes for check-in
  professor, // Professor - can generate QR codes for classes
}

/// Model representing a user in the ISTEC campus system.
class User {
  final String id;
  final String email;
  final String name;
  final String studentNumber;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.studentNumber,
    required this.role,
  });

  /// Creates a User from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      studentNumber: json['studentNumber'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.aluno,
      ),
    );
  }

  /// Converts the User to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'studentNumber': studentNumber,
      'role': role.name,
    };
  }

  /// Returns true if user is a professor.
  bool get isProfessor => role == UserRole.professor;

  /// Returns true if user is a student.
  bool get isAluno => role == UserRole.aluno;

  /// Returns readable role name in Portuguese.
  String get roleDisplayName => switch (role) {
    UserRole.professor => 'Professor',
    UserRole.aluno => 'Aluno',
  };

  @override
  String toString() =>
      'User(id: $id, email: $email, name: $name, role: ${role.name})';
}
