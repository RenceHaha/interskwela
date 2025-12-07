import 'package:flutter/material.dart';
import 'package:interskwela/models/classes.dart';
import 'package:interskwela/models/user.dart'; // Required for DropdownStudents
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:interskwela/widgets/announcement/attachment_file.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_classes.dart'; // Reusable Widget
import 'package:interskwela/widgets/dropdowns/dropdown_students.dart'; // Reusable Widget

class CreateAnnouncementModal extends StatefulWidget {
  final String initialContent;
  final List<PlatformFile> initialFiles; 
  final Classes currentClass;
  final int userId;
  
  final Function(String content, List<int> classIds, List<int> studentIds, List<PlatformFile> files) onPost;

  const CreateAnnouncementModal({
    required this.initialContent,
    this.initialFiles = const [], 
    required this.currentClass,
    required this.userId,
    required this.onPost,
    super.key,
  });

  @override
  State<CreateAnnouncementModal> createState() => _CreateAnnouncementModalState();
}

class _CreateAnnouncementModalState extends State<CreateAnnouncementModal> {
  late TextEditingController _contentController;
  
  // Selection State
  List<int> _selectedClassIds = [];
  List<int> _selectedStudentIds = [];
  bool _isLoading = true;

  // File State
  late List<PlatformFile> _selectedFiles;

  // Data Source
  List<Classes> _availableClasses = [];
  List<User> _availableStudents = []; // Changed to List<User>

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    _selectedFiles = List.from(widget.initialFiles);
    
    // Default to current class
    _selectedClassIds.add(widget.currentClass.classId);
    _availableClasses = [widget.currentClass];
    
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchClasses(),
        _fetchStudents(),
      ]);
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchClasses() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/classes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'action': 'get-teacher-classes'
        }),
      );

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        List<dynamic> data = jsonResponse is List ? jsonResponse : (jsonResponse['data'] ?? []);

        if (mounted) {
          setState(() {
            final otherClasses = data
                .map((json) => Classes.fromJson(json))
                .where((c) => c.classId != widget.currentClass.classId)
                .toList();
            _availableClasses = [widget.currentClass, ...otherClasses];
          });
        }
      }
    } catch (e) {
      print("Error fetching classes: $e");
    }
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/classes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'class_id': widget.currentClass.classId,
          'action': 'get-students'
        }),
      );

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        List<dynamic> data = jsonResponse is List ? jsonResponse : (jsonResponse['data'] ?? []);
        print('students: ${data}');
        if (mounted) {
          setState(() {
            // Map to User objects for DropdownStudents
            _availableStudents = data.map((json) => User.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching students: $e");
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Disable student selection if more than 1 class is selected
    final bool isMultiClass = _selectedClassIds.length > 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TITLE ---
            Row(
              children: [
                const Icon(Icons.display_settings, color: Color(0xFF1C3353)),
                const SizedBox(width: 8),
                const Text(
                  "Announcement Settings",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C3353)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            // --- CONTENT ---
            const Text("Content", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: "Announce something to your class...",
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // --- ATTACHMENTS ---
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text("Attach File"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                if (_selectedFiles.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _selectedFiles.map((file) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: AttachmentFile(fileName: file.name, onDelete: () => _removeFile(file))
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),

            // --- SELECTION AREA (USING REUSABLE DROPDOWNS) ---
            if (_isLoading) 
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ))
            else
              Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. SELECT CLASSES
                    Expanded(
                      child: DropdownClasses(
                        classes: _availableClasses,
                        selectedClassIds: _selectedClassIds,
                        initialSelectedClassIds: [widget.currentClass.classId],
                        onChanged: (newSelectedIds) {
                          setState(() {
                            _selectedClassIds = newSelectedIds;
                            
                            // Auto-disable students logic
                            if (_selectedClassIds.length > 1) {
                              _selectedStudentIds.clear();
                            }
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    // 2. SELECT STUDENTS
                    Expanded(
                      child: Opacity(
                        opacity: isMultiClass ? 0.5 : 1.0,
                        child: IgnorePointer(
                          ignoring: isMultiClass, // Disable interaction
                          child: DropdownStudents(
                            // Use a key to force rebuild/reset when disabled state changes
                            key: ValueKey("students_${isMultiClass ? 'disabled' : 'enabled'}"),
                            students: _availableStudents,
                            selectedStudentIds: isMultiClass ? [] : _selectedStudentIds,
                            onChanged: (newSelectedIds) {
                              setState(() {
                                _selectedStudentIds = newSelectedIds;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // --- ACTIONS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C3353),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    widget.onPost(
                      _contentController.text,
                      _selectedClassIds,
                      // If list is empty, it implies "All Students" in your logic
                      isMultiClass ? [] : _selectedStudentIds, 
                      _selectedFiles,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Post"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}