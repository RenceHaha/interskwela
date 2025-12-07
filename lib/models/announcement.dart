class Announcement {
  final int announcementID;
  final String authorFirstName;
  final String authorLastName;
  final String? profilePath; 
  final String content;
  final DateTime dateUpdated;
  final String? attachmentPath; // Legacy single path
  final List<String> attachments; // New list of paths
  final String category;
  final int? classID;

  Announcement({
    required this.announcementID,
    required this.authorFirstName,
    required this.authorLastName,
    this.profilePath,
    required this.content,
    required this.dateUpdated,
    this.attachmentPath,
    this.attachments = const [], // Default to empty list
    required this.category,
    this.classID,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    
    // Parse the 'attachments' list safely
    List<String> parsedAttachments = [];
    if (json['attachments'] != null) {
      if (json['attachments'] is List) {
        // If it's already a list (standard JSON response)
        parsedAttachments = List<String>.from(json['attachments']);
      } else if (json['attachments'] is String) {
        // Fallback: sometimes SQL/JSON interactions return a string representation
        // This depends on your specific DB driver configuration, but List is expected from your backend code.
      }
    }

    return Announcement(
      announcementID: json['announcement_id'],
      authorFirstName: json['firstname'] ?? 'Unknown', 
      authorLastName: json['lastname'] ?? 'Teacher',
      profilePath: json['profile_path'], 
      content: json['content'] ?? '',
      dateUpdated: DateTime.tryParse(json['date_updated']?.toString() ?? '') ?? DateTime.now(),
      
      attachmentPath: json['attachment_path'],
      attachments: parsedAttachments, // Assign the parsed list
      
      category: json['category'] ?? 'general',
      classID: json['class_id'],
    );
  }
}