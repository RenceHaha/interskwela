class Topic {
  final int topicId;
  final int classId;
  final String topicName;

  Topic({
    required this.topicId,
    required this.classId,
    required this.topicName,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      topicId: json['topic_id'],
      classId: json['class_id'],
      topicName: json['topic_name'],
    );
  }
}
