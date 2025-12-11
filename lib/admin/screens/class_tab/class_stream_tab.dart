import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:interskwela/models/announcement.dart';
import 'package:interskwela/models/classes.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/announcement/announce_card.dart';
import 'package:interskwela/widgets/announcement/announcement_post_card.dart';
import 'package:interskwela/widgets/announcement/create_announcement_modal.dart';
import 'package:interskwela/widgets/class/class_banner.dart';
import 'package:interskwela/widgets/class/meeting_card.dart';
import 'package:interskwela/widgets/class/upcoming_card.dart';

class ClassStreamTab extends StatefulWidget {
  final Classes specificClass;
  final int userId;
  final String username;

  const ClassStreamTab({
    required this.specificClass,
    required this.userId,
    required this.username,
    super.key,
  });

  @override
  State<ClassStreamTab> createState() => _ClassStreamTabState();
}

class _ClassStreamTabState extends State<ClassStreamTab> {
  late Future<List<Announcement>> _announcements;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _announcements = _fetchAnnouncements();
  }

  Future<List<Announcement>> _fetchAnnouncements() async {
    const String url = 'http://localhost:3000/api/announcement';
    var payload = {
      'class_id': widget.specificClass.classId,
      'user_id': widget.userId,
      'action': 'get-announcements',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        List<dynamic> data;
        if (jsonResponse is List) {
          data = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          data = jsonResponse['data'] ?? [];
        } else {
          data = [];
        }
        return data.map((json) => Announcement.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> postAnnouncement(
    String content,
    List<int>? classIds,
    List<int>? studentIds, {
    String category = 'general',
    List<PlatformFile> files = const [],
  }) async {
    if ((classIds?.length ?? 0) == 0 && (studentIds?.length ?? 0) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one class or student."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse("http://localhost:3000/api/announcement");

    String finalCategory = category;
    var classID = widget.specificClass.classId;

    if ((studentIds?.length ?? 0) > 0) {
      finalCategory = 'specific-students';
      classID = widget.specificClass.classId;
    } else if ((classIds?.length ?? 0) > 0) {
      finalCategory = 'specific-classes';
    }

    try {
      List<Map<String, String>> attachments = [];
      final safeFiles = List<PlatformFile>.from(files);

      for (var file in safeFiles) {
        if (file.path != null) {
          final fileBytes = await File(file.path!).readAsBytes();
          attachments.add({
            'file_name': file.name,
            'file_data': base64Encode(fileBytes),
          });
        }
      }

      final Map<String, dynamic> payload = {
        'user_id': widget.userId,
        'content': content,
        'classes': classIds ?? [],
        'student_ids': studentIds ?? [],
        'category': finalCategory,
        'action': 'create-announcement',
        'attachments': attachments,
      };

      if ((studentIds?.length ?? 0) > 0) {
        payload['classID'] = classID;
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Announcement posted successfully!")),
        );
        setState(() {
          _announcements = _fetchAnnouncements();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAnnouncementModal(
    String initialText,
    List<PlatformFile> initialFiles,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return CreateAnnouncementModal(
          initialContent: initialText,
          initialFiles: initialFiles,
          currentClass: widget.specificClass,
          userId: widget.userId,
          onPost: (content, classIds, studentIds, files) {
            postAnnouncement(content, classIds, studentIds, files: files);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Banner
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ClassHeaderBanner(classInfo: widget.specificClass),
              ),
            ),
            const SizedBox(height: 24),

            // Two Column Layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Sidebar
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      MeetingCard(
                        code: widget.specificClass.classCode,
                        username: widget.username,
                        selectedClass: widget.specificClass,
                        role: 'admin',
                      ),
                      const SizedBox(height: 16),
                      UpcomingCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      AnnounceCard(
                        onPost: (text, files) {
                          postAnnouncement(
                            text,
                            [widget.specificClass.classId],
                            [],
                            files: files,
                          );
                        },
                        onSettingsPress: (text, files) {
                          _openAnnouncementModal(text, files);
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildAnnouncementsList(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return FutureBuilder<List<Announcement>>(
      future: _announcements,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            Icons.error_outline,
            'Error loading announcements',
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            Icons.campaign_outlined,
            'No announcements yet',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return AnnouncementPostCard(announcement: snapshot.data![index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
