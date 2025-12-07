class Teacher {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;

  Teacher({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      userId: json['user_id'],
      firstName: json['firstname'],
      lastName: json['lastname'],
      email: json['email'],
    );
  }
}
