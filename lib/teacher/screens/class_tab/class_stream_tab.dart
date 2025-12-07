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
import 'package:interskwela/widgets/class/class_code.dart';
import 'package:interskwela/widgets/class/upcoming_card.dart';

class ClassStreamTab extends StatefulWidget {
  final Classes specificClass;
  final int userId;

  const ClassStreamTab({
    required this.specificClass, 
    required this.userId, 
    super.key
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
      'class_id' : widget.specificClass.classId,
      'user_id' : widget.userId,
      'action' : 'get-announcements'
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload)
      );

      if(response.statusCode == 200) {
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

  Future<void> postAnnouncement(
    String content, 
    List<int>? classIds, 
    List<int>? studentIds, 
    {
      String category = 'general', 
      List<PlatformFile> files = const []
    }
  ) async {
    
    // Validation: Ensure at least one class is selected if not student specific
    if ((classIds?.length ?? 0) == 0 && (studentIds?.length ?? 0) == 0) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one class or student.")),
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
      
      // == FIX: Create a copy of the list using List.from() ==
      // This prevents "Concurrent modification" error if the UI clears the original list
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

      if((studentIds?.length ?? 0) > 0){
        payload['classID'] = classID;
      }

      print('payload: $payload');

      final response = await http.post(
        url,
        headers: {'Content-Type' : 'application/json'},
        body: jsonEncode(payload),
      );
      
      if(!mounted) return;

      if(response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Announcement posted successfully!")),
        );
        setState(() {
           _announcements = _fetchAnnouncements();
        });
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
        print("Error Response: ${data['error']}");
      }
    } catch (e) {
      print("Error details: $e"); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network Error: ${e.toString()}")), // Show actual error
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAnnouncementModal(String initialText, List<PlatformFile> initialFiles) {
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
      }
    );
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
                    ClassCodeCard(code: widget.specificClass.classCode),
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
                    AnnounceCard(
                      onPost: (text, files) {
                        postAnnouncement(text, [widget.specificClass.classId], [], files: files);
                      },
                      onSettingsPress: (text, files) {
                        _openAnnouncementModal(text, files);
                      },
                    ),
                    const SizedBox(height: 24),
                    FutureBuilder<List<Announcement>>(
                      future: _announcements,
                      builder: (context, snapshot) {
                        if(snapshot.connectionState == ConnectionState.waiting){
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                           return Center(child: Text('Error: ${snapshot.error}'));
                        } else if(!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No announcements yet'));
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
                    )
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}