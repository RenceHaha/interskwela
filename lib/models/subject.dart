class Subject{
  final int subjectId;
  final String subjectName;
  final String subjectCode;
  final String description;

  Subject({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.description,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
      subjectCode: json['subject_code'],
      description: json['description'],
    );
  }
}
