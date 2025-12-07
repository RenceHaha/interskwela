class Classes {
  final int classId;
  final int subjectId;
  final int sectionId;
  final int teacherId;
  final String classCode;
  final String description;
  final String subjectCode;
  final String subjectName;
  final String sectionName;
  final String teacherName;
  final String? bannerUrl;

  Classes({
    required this.classId,
    required this.subjectId,
    required this.sectionId,
    required this.teacherId,
    required this.classCode,
    required this.description,
    required this.subjectCode,
    required this.subjectName,
    required this.sectionName,
    required this.teacherName,
    this.bannerUrl
  });

  factory Classes.fromJson(Map<String, dynamic> json) {
    return Classes(
      classId: json['class_id'],
      sectionId: json['section_id'],
      subjectId: json['subject_id'],
      teacherId: json['teacher_id'],
      classCode: json['class_code'],
      description: json['description'],
      subjectCode: json['subject_code'],
      subjectName: json['subject_name'],
      sectionName: json['section_name'],
      teacherName: json['teacher'],
      bannerUrl: json['banner_url'],
    );
  }
}
