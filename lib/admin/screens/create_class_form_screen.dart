import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

// Assuming you have these models from previous files
import '../../models/user.dart'; // Using User for Teacher
import '../../models/subject.dart';
import '../../models/section.dart';

class CreateClassFormScreen extends StatefulWidget {
  const CreateClassFormScreen({super.key});

  @override
  State<CreateClassFormScreen> createState() => _CreateClassFormScreenState();
}

class _CreateClassFormScreenState extends State<CreateClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- Controllers ---
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _classCodeController = TextEditingController();

  // --- Dropdown State ---
  User? _selectedTeacher;
  Subject? _selectedSubject;
  Section? _selectedSection;

  // --- NEW: Store the Futures ---
  late Future<List<User>> _teachersFuture;
  late Future<List<Subject>> _subjectsFuture;
  late Future<List<Section>> _sectionsFuture;

  // --- Schedule State ---
  final Map<String, Map<String, String?>> _schedule = {
    'monday': {'start_time': null, 'end_time': null},
    'tuesday': {'start_time': null, 'end_time': null},
    'wednesday': {'start_time': null, 'end_time': null},
    'thursday': {'start_time': null, 'end_time': null},
    'friday': {'start_time': null, 'end_time': null},
    'saturday': {'start_time': null, 'end_time': null},
  };

  @override
  void initState() {
    super.initState();
    // --- ASSIGN THE FUTURES HERE ---
    _teachersFuture = _fetchTeachers();
    _subjectsFuture = _fetchSubjects();
    _sectionsFuture = _fetchSections();
  }

  // --- API Fetching Functions ---

  Future<List<User>> _fetchTeachers() async {
    const String url = 'http://localhost:3000/api/accounts';
    try {
      final response = await http.post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(<String, String>{'action': 'get-teachers'}));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // Don't set state here, just return the data
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load teachers');
      }
    } catch (e) {
      log('Error during API call: $e');
      throw Exception('Error fetching teachers: $e');
    }
  }

  Future<List<Subject>> _fetchSubjects() async {
    const String url = 'http://localhost:3000/api/subjects';
    try {
      final response = await http.get(Uri.parse(url),
          headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Subject.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      log('Error during API call: $e');
      throw Exception('Error fetching subjects: $e');
    }
  }

  Future<List<Section>> _fetchSections() async {
    const String url = 'http://localhost:3000/api/sections';
    try {
      final response = await http.get(Uri.parse(url),
          headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Section.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sections');
      }
    } catch (e) {
      log('Error during API call: $e');
      throw Exception('Error fetching sections: $e');
    }
  }

  // --- Create Class Function ---
  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> finalSchedule = {};
    _schedule.forEach((day, times) {
      if (times['start_time'] != null && times['end_time'] != null) {
        finalSchedule[day] = times;
      }
    });

    const String url = 'http://localhost:3000/api/classes';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'action': 'create-class',
          'subject_id': _selectedSubject!.subjectId,
          'teacher_id': _selectedTeacher!.userId,
          'section_id': _selectedSection!.sectionId,
          'description': _descriptionController.text,
          'class_code': _classCodeController.text,
          'schedule': finalSchedule,
        }),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(responseData['message'] ?? 'Class created successfully!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['error'] ?? 'Failed to create class')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      log('Error during API call: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _classCodeController.dispose();
    super.dispose();
  }

  // --- Main Build Method (Re-styled) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Create New Class'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('CLASS DETAILS'),
                SizedBox(height: 16),
                // --- Subject Dropdown ---
                _buildDropdown<Subject>(
                  hintText: 'Select Subject',
                  future: _subjectsFuture, // <-- Pass the Future
                  itemBuilder: (Subject subject) => DropdownMenuItem(
                    value: subject,
                    child: Text('${subject.subjectCode} | ${subject.subjectName}'),
                  ),
                  onChanged: (Subject? value) {
                    setState(() {
                      _selectedSubject = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                // --- Teacher Dropdown ---
                _buildDropdown<User>(
                  hintText: 'Select Teacher',
                  future: _teachersFuture, // <-- Pass the Future
                  itemBuilder: (User teacher) => DropdownMenuItem(
                    value: teacher,
                    child: Text('${teacher.firstname} ${teacher.lastname}'),
                  ),
                  onChanged: (User? value) {
                    setState(() {
                      _selectedTeacher = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                // --- Section Dropdown ---
                _buildDropdown<Section>(
                  hintText: 'Select Section',
                  future: _sectionsFuture, // <-- Pass the Future
                  itemBuilder: (Section section) => DropdownMenuItem(
                    value: section,
                    child: Text(section.sectionName),
                  ),
                  onChanged: (Section? value) {
                    setState(() {
                      _selectedSection = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                _buildTextFormField(
                  controller: _classCodeController,
                  hintText: 'Class Code (e.g., SBIT-4K)',
                ),
                SizedBox(height: 16),
                _buildTextFormField(
                  controller: _descriptionController,
                  hintText: 'Description (Optional)',
                  isOptional: true,
                  maxLines: 3,
                ),

                // --- Schedule Section ---
                SizedBox(height: 24),
                _buildSectionHeader('CLASS SCHEDULE'),
                SizedBox(height: 16),
                _buildScheduleInput('monday', 'Monday'),
                _buildScheduleInput('tuesday', 'Tuesday'),
                _buildScheduleInput('wednesday', 'Wednesday'),
                _buildScheduleInput('thursday', 'Thursday'),
                _buildScheduleInput('friday', 'Friday'),
                _buildScheduleInput('saturday', 'Saturday'),

                // --- Submit Button ---
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1C3353),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          'Create Class',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for the Form ---

  // REPLACED _buildDropdown helper
  Widget _buildDropdown<T>({
    required String hintText,
    required Future<List<T>> future,
    required DropdownMenuItem<T> Function(T) itemBuilder,
    required void Function(T?) onChanged,
  }) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return DropdownButtonFormField<T>(
            decoration: _buildInputDecoration(hintText),
            hint: Text('Loading...'),
            items: [],
            onChanged: null,
          );
        }
        if (snapshot.hasError) {
          return DropdownButtonFormField<T>(
            decoration: _buildInputDecoration(hintText),
            hint: Text('Error loading data'),
            items: [],
            onChanged: null,
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return DropdownButtonFormField<T>(
            decoration: _buildInputDecoration(hintText),
            hint: Text('No data found'),
            items: [],
            onChanged: null,
          );
        }
        return DropdownButtonFormField<T>(
          decoration: _buildInputDecoration(hintText),
          items: snapshot.data!.map(itemBuilder).toList(), // Use snapshot.data
          onChanged: onChanged,
          validator: (value) {
            if (value == null) {
              return 'Please make a selection';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildScheduleInput(String dayKey, String dayLabel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              dayLabel,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _TimePickerField(
              hintText: 'Start Time',
              onTimeSelected: (time) {
                setState(() {
                  _schedule[dayKey]!['start_time'] = time;
                });
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _TimePickerField(
              hintText: 'End Time',
              onTimeSelected: (time) {
                setState(() {
                  _schedule[dayKey]!['end_time'] = time;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _buildInputDecoration(hintText),
      validator: (value) {
        if (isOptional) return null;
        if (value == null || value.isEmpty) {
          return '$hintText is required';
        }
        return null;
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hintText, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }
}

// --- Time Picker Field Widget ---
class _TimePickerField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onTimeSelected;

  const _TimePickerField({
    required this.hintText,
    required this.onTimeSelected,
  });

  @override
  State<_TimePickerField> createState() => _TimePickerFieldState();
}

class _TimePickerFieldState extends State<_TimePickerField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Icon(Icons.access_time),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
      ),
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (pickedTime != null) {
          final hour = pickedTime.hour.toString().padLeft(2, '0');
          final minute = pickedTime.minute.toString().padLeft(2, '0');
          final formattedTime = '$hour:$minute';

          setState(() {
            _controller.text = pickedTime.format(context);
          });
          widget.onTimeSelected(formattedTime);
        }
      },
    );
  }
}