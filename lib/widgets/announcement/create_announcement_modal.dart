import 'package:flutter/material.dart';
import 'package:interskwela/models/classes.dart';
import 'package:interskwela/models/user.dart'; // Required for DropdownStudents
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

import 'package:interskwela/widgets/dropdowns/dropdown_classes.dart'; // Reusable Widget
import 'package:interskwela/widgets/dropdowns/dropdown_students.dart'; // Reusable Widget

class CreateAnnouncementModal extends StatefulWidget {
  final String initialContent;
  final List<PlatformFile> initialFiles;
  final Classes currentClass;
  final int userId;

  final Function(
    String content,
    List<int> classIds,
    List<int> studentIds,
    List<PlatformFile> files,
  )
  onPost;

  const CreateAnnouncementModal({
    required this.initialContent,
    this.initialFiles = const [],
    required this.currentClass,
    required this.userId,
    required this.onPost,
    super.key,
  });

  @override
  State<CreateAnnouncementModal> createState() =>
      _CreateAnnouncementModalState();
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
      await Future.wait([_fetchClasses(), _fetchStudents()]);
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
          'action': 'get-teacher-classes',
        }),
      );

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        List<dynamic> data = jsonResponse is List
            ? jsonResponse
            : (jsonResponse['data'] ?? []);

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
          'action': 'get-students',
        }),
      );

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        List<dynamic> data = jsonResponse is List
            ? jsonResponse
            : (jsonResponse['data'] ?? []);
        print('students: ${data}');
        if (mounted) {
          setState(() {
            // Map to User objects for DropdownStudents
            _availableStudents = data
                .map((json) => User.fromJson(json))
                .toList();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C3353).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.campaign_outlined, // Changed to campaign icon
                      color: Color(0xFF1C3353),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "New Announcement",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C3353),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.grey[500],
                      splashRadius: 20,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),

            // --- SCROLLABLE CONTENT ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- CONTENT INPUT ---
                    const Text(
                      "What do you want to announce?",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1C3353),
                            width: 1.5,
                          ),
                        ),
                        hintText: "Type your announcement here...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- ATTACHMENTS SECTION ---
                    Row(
                      children: [
                        const Text(
                          "Attachments",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _pickFiles,
                          icon: const Icon(Icons.attach_file_rounded, size: 18),
                          label: const Text("Add File"),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1C3353),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_selectedFiles.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            style: BorderStyle.values[1],
                          ), // Dashed border simulated
                        ),
                        child: Center(
                          child: Text(
                            "No files attached",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedFiles.map((file) {
                          return Container(
                            constraints: const BoxConstraints(maxWidth: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  splashRadius: 16,
                                  color: Colors.grey[400],
                                  onPressed: () => _removeFile(file),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 24),

                    // --- AUDIENCE SELECTION ---
                    const Text(
                      "Post to",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownClasses(
                              classes: _availableClasses,
                              selectedClassIds: _selectedClassIds,
                              initialSelectedClassIds: [
                                widget.currentClass.classId,
                              ],
                              onChanged: (newSelectedIds) {
                                setState(() {
                                  _selectedClassIds = newSelectedIds;
                                  if (_selectedClassIds.length > 1) {
                                    _selectedStudentIds.clear();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Opacity(
                              opacity: isMultiClass ? 0.5 : 1.0,
                              child: IgnorePointer(
                                ignoring: isMultiClass,
                                child: DropdownStudents(
                                  key: ValueKey(
                                    "students_${isMultiClass ? 'disabled' : 'enabled'}",
                                  ),
                                  students: _availableStudents,
                                  selectedStudentIds: isMultiClass
                                      ? []
                                      : _selectedStudentIds,
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
                  ],
                ),
              ),
            ),

            // --- FOOTER ACTIONS ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C3353),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () {
                      widget.onPost(
                        _contentController.text,
                        _selectedClassIds,
                        isMultiClass ? [] : _selectedStudentIds,
                        _selectedFiles,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Post Announcement"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
