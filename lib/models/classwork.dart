class Classwork {
  final int id;
  final String title;
  final String? instruction;
  final double? points;
  final DateTime? dueDate;
  final String type; // assignment, quiz, question
  final String category;
  final DateTime dateUpdated;
  final String? topicName;
  final int? topicId;
  final int userId;
  final String author_firstname;
  final String author_lastname;
  final int? rubric_id;
  final String? rubric_name;

  Classwork({
    required this.id,
    required this.title,
    this.instruction,
    this.points,
    this.dueDate,
    required this.type,
    required this.category,
    required this.dateUpdated,
    this.topicName,
    this.topicId,
    required this.userId,
    required this.author_firstname,
    required this.author_lastname,
    this.rubric_id,
    this.rubric_name,
  });

  factory Classwork.fromJson(Map<String, dynamic> json) {
    return Classwork(
      id: json['class_work_id'],
      title: json['title'],
      instruction: json['instruction'],
      points: json['points'] != null
          ? double.tryParse(json['points'].toString())
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      type: json['class_work_type'],
      category: json['category'],
      dateUpdated: DateTime.parse(json['date_updated']),
      topicName: json['topic_name'],
      topicId: json['topic_id'],
      userId: json['user_id'],
      author_firstname: json['author_firstname'],
      author_lastname: json['author_lastname'],
      rubric_id: json['rubric_id'],
      rubric_name: json['rubric_name'],
    );
  }
}
