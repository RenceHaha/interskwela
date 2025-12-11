import 'package:flutter/material.dart';
import 'package:interskwela/models/announcement.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementPostCard extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementPostCard({required this.announcement, super.key});

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

  Widget _buildFileCard(String path) {
    String fileName = path.split('/').last;
    if (fileName.contains('-')) {
      fileName = fileName.substring(fileName.indexOf('-') + 1);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchAttachment(path),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.insert_drive_file_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Tap to open",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> filesToDisplay = [];

    if (announcement.attachments.isNotEmpty) {
      filesToDisplay = announcement.attachments;
    } else if (announcement.attachmentPath != null &&
        announcement.attachmentPath!.isNotEmpty) {
      filesToDisplay = [announcement.attachmentPath!];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundImage: NetworkImage(
                    announcement.profilePath ??
                        'http://localhost:3000/profile_images/student.png',
                  ),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${announcement.authorFirstName} ${announcement.authorLastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(announcement.dateUpdated),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.more_horiz,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Content
            Text(
              announcement.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),

            // Attachments
            if (filesToDisplay.isNotEmpty)
              ...filesToDisplay.map((path) => _buildFileCard(path)),
          ],
        ),
      ),
    );
  }
}
