import 'package:flutter/material.dart';
import 'package:interskwela/models/announcement.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementPostCard extends StatelessWidget {
  final Announcement announcement;
  
  const AnnouncementPostCard({
    required this.announcement,
    super.key
  });

  Future<void> _launchAttachment(String path) async {
    final Uri url = Uri.parse("http://localhost:3000$path"); 
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      print("Error launching URL: $e");
    }
  }

  // Helper widget to build a single attachment card
  Widget _buildFileCard(String path) {
    // Extract filename
    String fileName = path.split('/').last;
    // Remove timestamp prefix if present (e.g. 1732983-name.png -> name.png)
    // This is optional, purely cosmetic
    if (fileName.contains('-')) {
      fileName = fileName.substring(fileName.indexOf('-') + 1);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: InkWell(
        onTap: () => _launchAttachment(path),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file, color: Color(0xFF1C3353)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C3353),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      "Click to open attachment",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prepare the list of attachments to display
    List<String> filesToDisplay = [];
    
    if (announcement.attachments.isNotEmpty) {
      filesToDisplay = announcement.attachments;
    } else if (announcement.attachmentPath != null && announcement.attachmentPath!.isNotEmpty) {
      // Fallback for old announcements with single path
      filesToDisplay = [announcement.attachmentPath!];
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1C3353),
                  foregroundImage: NetworkImage(announcement.profilePath ?? 'http://localhost:3000/profile_images/student.png'),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${announcement.authorFirstName} ${announcement.authorLastName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${announcement.dateUpdated.day}/${announcement.dateUpdated.month} ${announcement.dateUpdated.hour}:${announcement.dateUpdated.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Body
            Text(
              announcement.content,
              style: const TextStyle(fontSize: 14),
            ),

            // == ATTACHMENTS LIST ==
            if (filesToDisplay.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...filesToDisplay.map((path) => _buildFileCard(path)),
            ]
          ],
        ),
      ),
    );
  }
}