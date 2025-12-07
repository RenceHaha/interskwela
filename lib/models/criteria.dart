class Criteria {
  final int criteriaId;
  final String criteriaTitle;
  final String? criteriaDescription;
  final double points;
  final int creatorId;

  Criteria({
    this.criteriaId = 0, // Default 0 for new items
    required this.criteriaTitle,
    required this.points,
    this.criteriaDescription,
    required this.creatorId,
  });

  factory Criteria.fromJson(Map<String, dynamic> json) {
    return Criteria(
      criteriaId: json['criteria_id'] ?? 0,
      criteriaTitle: json['criteria_title'] ?? '',
      criteriaDescription: json['criteria_description'],
      // Safely parse double (handles int or double from API)
      points: (json['points'] ?? 0).toDouble(),
      creatorId: json['creator_id'] ?? 0,
    );
  }

  // Helper for editing state
  Criteria copyWith({
    int? criteriaId,
    String? criteriaTitle,
    String? criteriaDescription,
    double? points,
    int? creatorId,
  }) {
    return Criteria(
      criteriaId: criteriaId ?? this.criteriaId,
      criteriaTitle: criteriaTitle ?? this.criteriaTitle,
      criteriaDescription: criteriaDescription ?? this.criteriaDescription,
      points: points ?? this.points,
      creatorId: creatorId ?? this.creatorId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'criteria_id': criteriaId,
      'criteria_title': criteriaTitle,
      'criteria_description': criteriaDescription,
      'criteria_points': points, // Matching your fromJson key
      'creator_id': creatorId,
    };
  }
}