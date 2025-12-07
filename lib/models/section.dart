import 'user.dart';

class Section {
  final int sectionId;
  final String sectionName;
  final List<User>? students;

  Section({
    required this.sectionId,
    required this.sectionName,
    this.students
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      sectionId: json['section_id'],
      sectionName: json['section_name'],
      students: json['students'],
    );
  }
}