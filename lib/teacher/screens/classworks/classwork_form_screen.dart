import 'package:flutter/material.dart';
import 'package:interskwela/models/criteria.dart';
import 'package:interskwela/models/topic.dart';
import 'package:interskwela/models/rubric.dart';
import 'package:interskwela/teacher/screens/class_tab/class_stream_tab.dart';
import 'package:interskwela/teacher/screens/classworks/chat_bot_screen.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/announcement/attachment_file.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_classes.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_students.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_topic.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_rubric.dart';
import 'package:interskwela/widgets/forms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:interskwela/models/classes.dart';
import 'package:interskwela/models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ClassworkFormScreen extends StatefulWidget {
  final Classes currentClass;
  final int userId;
  final String creationMode;

  const ClassworkFormScreen({
    required this.currentClass,
    required this.userId,
    required this.creationMode,
    super.key,
  });

  @override
  State<ClassworkFormScreen> createState() => _ClassworkFormScreenState();
}

class _ClassworkFormScreenState extends State<ClassworkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionController = TextEditingController();
  final _pointsController = TextEditingController();
  final _dueDateController = TextEditingController();

  bool _isLoading = true;

  List<int> _selectedClassIds = [];
  List<int> _selectedStudentIds = [];
  List<Classes> _availableClasses = [];
  List<User> _availableStudents = [];
  List<Topic> _topicList = [];

  Topic? _selectedTopic;
  List<PlatformFile> _selectedFiles = [];

  List<Rubric> _availableRubrics = [];
  Rubric? _selectedRubric;

  List<ChatMessage> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _selectedClassIds = [widget.currentClass.classId];
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchClasses(),
        _fetchStudents(),
        _fetchTopics(),
        _fetchRubrics(),
      ]);
    } catch (e) {
      print('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchRubrics() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/rubrics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'get-rubrics', 'user_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _availableRubrics = data
                .map((json) => Rubric.fromJson(json))
                .toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching rubrics: $e");
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
        if (mounted) {
          setState(() {
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

  Future<void> _fetchTopics() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/topics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'class_id': widget.currentClass.classId,
          'action': 'get-topics',
        }),
      );

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        List<dynamic> data = jsonResponse is List
            ? jsonResponse
            : (jsonResponse['data'] ?? []);

        if (mounted) {
          setState(() {
            _topicList = data.map((json) => Topic.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching topics: $e");
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

  Future<void> _handleCreateTopic(String newTopicName) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/topics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'class_id': widget.currentClass.classId,
          'topic_name': newTopicName,
          'action': 'create-topic',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newTopic = Topic(
          topicId: int.parse(data['topic_id'].toString()),
          classId: widget.currentClass.classId,
          topicName: newTopicName,
        );

        setState(() {
          _topicList.add(newTopic);
          _selectedTopic = newTopic;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Topic created and selected")),
          );
        }
      }
    } catch (e) {
      print("Error creating topic: $e");
    }
  }

  Future<void> _handleCreateAssignment(
    String title,
    String instructions,
    DateTime? duedate,
    List<int>? classIds,
    List<int>? studentIds,
    String? pointsStr,
    Rubric? rubric,
    String classWorkType, {
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

    String finalCategory;
    double? points = double.tryParse(pointsStr ?? '0');
    var classID = widget.currentClass.classId;

    bool isSingleClass = _selectedClassIds.length == 1;
    bool hasStudentsSelected = _selectedStudentIds.isNotEmpty;
    bool isAllStudentsSelected =
        _selectedStudentIds.length == _availableStudents.length;

    if (isSingleClass) {
      if (hasStudentsSelected && !isAllStudentsSelected) {
        finalCategory = 'specific-students';
      } else {
        finalCategory = 'specific-classes';
      }
    } else {
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
        'action': 'create-classwork',
        'user_id': widget.userId,
        'title': title,
        'instruction': instructions,
        'points': points,
        'due_date': duedate?.toIso8601String(),
        'category': finalCategory,
        'class_work_type': classWorkType,
        'class_ids': classIds ?? [],
        'student_ids': finalCategory == 'specific-students'
            ? (studentIds ?? [])
            : [],
        'attachments': attachments,
        'rubric_id': rubric?.id,
        'topic_id': _selectedTopic?.topicId,
      };

      if (finalCategory == 'specific-students') {
        payload['classID'] = classID;
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/classworks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Class work added successfully!")),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      print("Error creating assignment: $e");
    }
  }

  String _formatNumber(double n) {
    return n.truncateToDouble() == n ? n.truncate().toString() : n.toString();
  }

  Future<void> _selectRubric(Rubric? rubric) async {
    if (rubric == null) {
      setState(() {
        _selectedRubric = null;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/rubrics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'get-rubric', 'rubric_id': rubric.id}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fullRubric = Rubric.fromJson(data);

        setState(() {
          _selectedRubric = fullRubric;
          _pointsController.text = _formatNumber(fullRubric.totalPoints);
        });
      }
    } catch (e) {
      print("Error fetching rubric details: $e");
    }
  }

  IconData _getTypeIcon() {
    switch (widget.creationMode.toLowerCase()) {
      case 'quiz':
        return Icons.quiz_outlined;
      case 'question':
        return Icons.help_outline_rounded;
      case 'material':
        return Icons.menu_book_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getTypeIcon(), color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Create ${widget.creationMode[0].toUpperCase()}${widget.creationMode.substring(1)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () => _handleCreateAssignment(
                _titleController.text,
                _instructionController.text,
                _dueDateController.text.isNotEmpty
                    ? DateTime.parse(_dueDateController.text)
                    : null,
                _selectedClassIds,
                _selectedStudentIds,
                _pointsController.text,
                _selectedRubric,
                widget.creationMode,
                files: _selectedFiles,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Assign',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAssignmentForm()),
                      const SizedBox(width: 24),
                      SizedBox(width: 320, child: _buildSidePanel()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAssignmentForm(),
                      const SizedBox(height: 24),
                      _buildSidePanel(),
                    ],
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatBotScreen(
                  creationMode: widget.creationMode,
                  messages: _chatMessages,
                  onMessagesChanged: (messages) {
                    _chatMessages = messages;
                  },
                  onAssignmentGenerated: (assignment) {
                    setState(() {
                      _titleController.text = assignment.title;
                      _instructionController.text = assignment.instruction;
                    });
                  },
                ),
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        tooltip: 'AI Assistant',
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  Widget _buildAssignmentForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Assignment Details', Icons.edit_note_outlined),
            const SizedBox(height: 20),

            // Title Field
            _buildInputLabel('Title'),
            const SizedBox(height: 8),
            _buildModernTextField(
              controller: _titleController,
              hintText: 'Enter assignment title',
            ),
            const SizedBox(height: 20),

            // Instructions Field
            _buildInputLabel('Instructions'),
            const SizedBox(height: 8),
            _buildModernTextField(
              controller: _instructionController,
              hintText: 'Enter instructions (Press Enter for new lines)',
              minLines: 6,
              maxLines: null,
            ),
            const SizedBox(height: 24),

            // Attachments Section
            _buildAttachmentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    int minLines = 1,
    int? maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
    );
  }

  Widget _buildAttachmentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Attachments',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildSmallButton(
                    icon: Icons.upload_file,
                    tooltip: 'Upload Files',
                    onPressed: _pickFiles,
                  ),
                  const SizedBox(width: 8),
                  _buildSmallButton(
                    icon: Icons.link,
                    tooltip: 'Add Link',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedFiles
                  .map(
                    (file) => AttachmentFile(
                      fileName: file.name,
                      onDelete: () => _removeFile(file),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Assignment Settings', Icons.settings_outlined),
          const SizedBox(height: 20),

          DropdownClasses(
            classes: _availableClasses,
            selectedClassIds: _selectedClassIds,
            initialSelectedClassIds: [widget.currentClass.classId],
            onChanged: (newSelectedIds) {
              setState(() {
                _selectedClassIds = newSelectedIds;
              });
            },
          ),
          const SizedBox(height: 20),

          DropdownStudents(
            students: _availableStudents,
            selectedStudentIds: _selectedStudentIds,
            onChanged: (newSelectedIds) {
              setState(() {
                _selectedStudentIds = newSelectedIds;
              });
            },
          ),
          const SizedBox(height: 20),

          _buildInputLabel('POINTS'),
          const SizedBox(height: 8),
          _buildModernTextField(
            controller: _pointsController,
            hintText: '0',
            readOnly: _selectedRubric != null,
          ),
          const SizedBox(height: 20),

          _buildInputLabel('DUE DATE'),
          const SizedBox(height: 8),
          CustomDatePickerFormField(
            controller: _dueDateController,
            hintText: 'No due date',
          ),
          const SizedBox(height: 20),

          DropdownTopic(
            topics: _topicList,
            selectedTopic: _selectedTopic,
            onChanged: (newTopicSelected) {
              setState(() {
                _selectedTopic = newTopicSelected;
              });
            },
            onAddTopic: _handleCreateTopic,
          ),
          const SizedBox(height: 20),

          DropdownRubric(
            rubrics: _availableRubrics,
            selectedRubric: _selectedRubric,
            userId: widget.userId,
            onChanged: _selectRubric,
            onRefreshRequired: _fetchRubrics,
          ),
        ],
      ),
    );
  }
}
