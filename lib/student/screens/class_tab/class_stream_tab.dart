import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:interskwela/models/announcement.dart';
import 'package:interskwela/models/classes.dart';
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
      'action': 'get-student-announcements',
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
      print('Error fetching announcements: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ClassHeaderBanner(classInfo: widget.specificClass),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    MeetingCard(
                      code: widget.specificClass.classCode,
                      username: widget.username,
                      role: 'student',
                      selectedClass: widget.specificClass,
                    ),
                    const SizedBox(height: 24),
                    UpcomingCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    FutureBuilder<List<Announcement>>(
                      future: _announcements,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('No announcements yet'),
                          );
                        } else {
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return AnnouncementPostCard(
                                announcement: snapshot.data![index],
                              );
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
