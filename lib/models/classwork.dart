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
  });

  factory Classwork.fromJson(Map<String, dynamic> json) {
    return Classwork(
      id: json['class_work_id'],
      title: json['title'],
      instruction: json['instruction'],
      points: json['points'] != null ? double.tryParse(json['points'].toString()) : null,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      type: json['class_work_type'],
      category: json['category'],
      dateUpdated: DateTime.parse(json['date_updated']),
      topicName: json['topic_name'],
      topicId: json['topic_id'],
    );
  }
}