
class User {
  final int userId;
  final String email;
  final String firstname;
  final String? middlename;
  final String lastname;
  final String? suffix;
  final String role;

  User({
    required this.userId,
    required this.email,
    required this.firstname,
    required this.lastname,
    this.middlename,
    this.suffix,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      firstname: json['firstname'],
      middlename: json['middlename'],
      lastname: json['lastname'],
      suffix: json['suffix'],
      email: json['email'],
      role: json['role'],
    );
  }
}