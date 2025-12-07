import 'package:flutter/material.dart';
import 'package:interskwela/models/criteria.dart'; 
import 'package:interskwela/models/topic.dart';
import 'package:interskwela/models/rubric.dart'; // New import
import 'package:interskwela/teacher/screens/class_tab/class_stream_tab.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/announcement/attachment_file.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_classes.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_students.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_topic.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_rubric.dart'; // New import
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

  const ClassworkFormScreen({required this.currentClass, required this.userId, required this.creationMode, super.key});

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
  
  // Rubric State
  List<Rubric> _availableRubrics = []; // List of rubrics from DB/Local
  Rubric? _selectedRubric;

  @override
  void initState(){
    super.initState();
    _selectedClassIds = [widget.currentClass.classId];
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try{
      await Future.wait([
        _fetchClasses(),
        _fetchStudents(),
        _fetchTopics(),
        _fetchRubrics(),
      ]);
    }catch(e){
      print('Error: $e');
    }finally{
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
        body: jsonEncode({
          'action': 'get-rubrics',
          'user_id': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Since get-rubrics returns shallow data, we might need to fetch details 
        // for the SELECTED one, but for the dropdown list, basic info is fine.
        // If your API returns criteria in the list, great. 
        // If not, we can fetch full rubric when selected.
        
        // For now assuming get-rubrics returns basic list. 
        // We will update this list dynamically.
        if (mounted) {
          setState(() {
            _availableRubrics = data.map((json) => Rubric.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching rubrics: $e");
    }
  }

  // ... [Keep existing _fetchStudents, _fetchTopics, _fetchClasses, _pickFiles, _removeFile, _handleCreateTopic] ...
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
        if (mounted) {
          setState(() {
            _availableStudents = data.map((json) => User.fromJson(json)).toList();
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
          'action': 'get-topics'
        }),
      );

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        List<dynamic> data = jsonResponse is List ? jsonResponse : (jsonResponse['data'] ?? []);
        
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
          'action': 'create-topic'
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newTopic = Topic(
          topicId: int.parse(data['topic_id'].toString()), 
          classId: widget.currentClass.classId, 
          topicName: newTopicName
        );

        setState(() {
          _topicList.add(newTopic);
          _selectedTopic = newTopic;
        });

        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Topic created and selected")),
          );
        }
      } else {
        print("Error creating topic: ${response.body}");
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
      String classWorkType,
      {
        List<PlatformFile> files = const []
      }
    ) async{

    if ((classIds?.length ?? 0) == 0 && (studentIds?.length ?? 0) == 0) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one class or student.")),
       );
       return;
    }

    String finalCategory;
    double? points = double.tryParse(pointsStr ?? '0');
    var classID = widget.currentClass.classId;

    bool isSingleClass = _selectedClassIds.length == 1;
    bool hasStudentsSelected = _selectedStudentIds.isNotEmpty;
    bool isAllStudentsSelected = _selectedStudentIds.length == _availableStudents.length;

    if(isSingleClass){
      if(hasStudentsSelected && !isAllStudentsSelected){
        finalCategory = 'specific-students';
      }else{
        finalCategory = 'specific-classes';
      }
    }else{
      finalCategory = 'specific-classes';
    }
    
    try{
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
        'student_ids': finalCategory == 'specific-students' ? (studentIds ?? []) : [], 
        'attachments': attachments,
        'rubric_id': rubric?.id,
        'topic_id': _selectedTopic?.topicId,
      };

      if(finalCategory == 'specific-students'){
        payload['classID'] = classID;
      }

      print("payload: $payload");
      print("category: ${payload['category']}");
      print("class_ids: ${payload['class_ids']}");
      print("student_ids: ${payload['stident_ids']}");
      
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/classworks'),
        headers: {'Content-Type' : 'application/json'},
        body: jsonEncode(payload)
      );

       if(response.statusCode == 200) {
          if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Class work added successfully!")),
            );

            Navigator.pop(context);
          }

        } else {
          final data = jsonDecode(response.body);
          if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Server error: ${response.statusCode}")),
            );
          }
          print("Error Response: ${data['error']}");
        }
    }catch(e){
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
        body: jsonEncode({
          'action': 'get-rubric',
          'rubric_id': rubric.id
        }),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.assignment),
            const SizedBox(width: 12),
            Text('Create ${widget.creationMode[0].toUpperCase()}${widget.creationMode.substring(1)}'),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _handleCreateAssignment(
                _titleController.text, 
                _instructionController.text, 
                _dueDateController.text.isNotEmpty ? DateTime.parse(_dueDateController.text) : null, 
                _selectedClassIds, 
                _selectedStudentIds, 
                _pointsController.text, 
                _selectedRubric,
                widget.creationMode,
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.primary),
                foregroundColor: WidgetStateProperty.all(AppColors.textOnPrimary)
              ),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (_isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAssignmentForm()),
                      const SizedBox(width: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: _buildSidePanel(),
                      ),
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
          print('Open chat bot');
        },
        child: const Icon(Icons.message_outlined),
      ),
    );
  }

  Widget _buildAssignmentForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionHeader('ASSIGNMENT DETAILS'),
          const SizedBox(height: 16),
          CustomTextFormField(controller: _titleController, hintText: 'Title'),
          const SizedBox(height: 16),
          CustomTextFormField(
              controller: _instructionController,
              maxLines: 4,
              hintText: 'Instructions'),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Attachments'),
                      Wrap(
                        spacing: 12,
                        children: [
                          IconButton.outlined(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.add),
                            iconSize: 16,
                            padding: const EdgeInsets.all(8),
                            tooltip: 'Upload Files',
                          ),
                          IconButton.outlined(
                            onPressed: () {},
                            icon: const Icon(Icons.link),
                            iconSize: 16,
                            padding: const EdgeInsets.all(8),
                            tooltip: 'Add Link',
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedFiles.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedFiles
                          .map(
                            (file) => AttachmentFile(
                                  fileName: file.name,
                                  onDelete: () => _removeFile(file)),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownClasses(
            classes: _availableClasses, 
            selectedClassIds: _selectedClassIds, 
            initialSelectedClassIds: [widget.currentClass.classId],
            onChanged: (newSelectedIds){
              setState(() {
                _selectedClassIds = newSelectedIds;
              });
            }
          ),
          const SizedBox(height: 24),
          DropdownStudents(
            students: _availableStudents, 
            selectedStudentIds: _selectedStudentIds, 
            onChanged: (newSelectedIds){
              setState(() {
                _selectedStudentIds = newSelectedIds;
              });
            }
          ),
          const SizedBox(height: 24),
          buildSectionHeader("POINTS"),
          const SizedBox(height: 8),
          CustomTextFormField(
            controller: _pointsController, 
            hintText: "0",
            readOnly: _selectedRubric != null,
          ),
          const SizedBox(height: 24),
          buildSectionHeader("DUE"),
          const SizedBox(height: 8),
          CustomDatePickerFormField(
            controller: _dueDateController, 
            hintText: "No due date"
          ),
          const SizedBox(height: 24),
          
          DropdownTopic(
            topics: _topicList, 
            selectedTopic: _selectedTopic, 
            onChanged: (newTopicSelected){
              setState(() {
                _selectedTopic = newTopicSelected;
              });
            },
            onAddTopic: _handleCreateTopic,
          ),
          const SizedBox(height: 24),

          // == NEW DROPDOWN RUBRIC ==
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