class User {
  final int userId;
  final String email;
  final String firstname;
  final String? middlename;
  final String lastname;
  final String? suffix;
  final String dob;
  final String address;
  final String? contact;
  final String role;

  User({
    required this.userId,
    required this.email,
    required this.firstname,
    required this.lastname,
    this.middlename,
    this.suffix,
    required this.dob,
    required this.address,
    this.contact,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      firstname: json['firstname'],
      middlename: json['middlename'],
      lastname: json['lastname'],
      suffix: json['suffix'],
      dob: json['dob'],
      address: json['address'],
      contact: json['contact'] ?? '',
      email: json['email'],
      role: json['role'],
    );
  }
}
