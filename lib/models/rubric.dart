import 'package:interskwela/models/criteria.dart';

class Rubric {
  final int id;
  final String name;
  final List<Criteria> criteria;
  final double _apiTotalPoints; 
  final int userId;

  Rubric({
    required this.id,
    required this.name,
    required this.criteria,
    double apiTotalPoints = 0.0,
    required this.userId
  }) : _apiTotalPoints = apiTotalPoints;

  factory Rubric.fromJson(Map<String, dynamic> json) {
    var criteriaList = <Criteria>[];
    if (json['criteria'] != null) {
      criteriaList = (json['criteria'] as List)
          .map((i) => Criteria.fromJson(i))
          .toList();
    }

    return Rubric(
      id: json['rubric_id'] ?? 0,
      name: json['rubric_name'] ?? '',
      criteria: criteriaList,
      userId: json['creator_id'],
      
      // == FIX: Safe Parsing for Total Points ==
      // Handles if API sends 20 (int), 20.5 (double), or "20" (string)
      apiTotalPoints: double.tryParse(json['total_points']?.toString() ?? '0') ?? 0.0,
    );
  }

  double get totalPoints {
    // If we have criteria details (e.g. after editing), calculate sum from them.
    if (criteria.isNotEmpty) {
      return criteria.fold(0.0, (sum, item) => sum + item.points);
    }
    // Otherwise, use the summary provided by the API list
    return _apiTotalPoints;
  }
}