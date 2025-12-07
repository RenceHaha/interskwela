import 'package:flutter/material.dart';
import 'package:interskwela/models/user.dart';
import 'package:interskwela/models/classes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PeopleTab extends StatefulWidget {
  final Classes specificClass;

  const PeopleTab({
    required this.specificClass,
    super.key
  });

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  late Future<List<User>> _students;
  late Future<User?> _teacher;

  @override
  void initState() {
    super.initState();
    _students = _getStudents();
    _teacher = _getTeacher();
  }
  

  Future<User?> _getTeacher() async {
    const String url = 'http://localhost:3000/api/classes';

    var payload = {
      'class_id' : widget.specificClass.classId,
      'action' : 'get-teacher'
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

        List<User> teachers = data.map((json) => User.fromJson(json)).toList();
        if(teachers.isNotEmpty){
          return teachers.first;
        }
      } 
      return null;
    } catch (e) {
      print('Error fetching students: $e');
      return null;
    }
  }

  Future<List<User>> _getStudents() async {
    const String url = 'http://localhost:3000/api/classes';

    var payload = {
      'class_id' : widget.specificClass.classId,
      'action' : 'get-students'
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
        return data.map((json) => User.fromJson(json)).toList();
      } 
      return [];
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  // --- SELECTION STATE ---
  String _actionsValue = 'Actions';
  
  // CHANGED: Storing UserIDs is safer than List Indices
  final Set<int> _selectedUserIds = {}; 
  bool _isAllStudentsSelected = false;

  void _onSelectAllStudents(bool? selected, List<User> allStudents) {
    setState(() {
      _isAllStudentsSelected = selected ?? false;
      if (_isAllStudentsSelected) {
        _selectedUserIds.addAll(allStudents.map((u) => u.userId));
      } else {
        _selectedUserIds.clear();
      }
    });
  }

  void _onSelectStudent(int userId, bool? selected, int totalStudentCount) {
    setState(() {
      if (selected ?? false) {
        _selectedUserIds.add(userId);
      } else {
        _selectedUserIds.remove(userId);
      }
      // Check if all are selected
      _isAllStudentsSelected = _selectedUserIds.length == totalStudentCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Teachers Section ---
          _buildSectionHeader(
            title: 'Teachers',
            onAdd: () {
              print('Invite teacher');
            },
          ),
          const Divider(height: 24),
          
          // Display Teacher (Using the User model)
          // _buildUserTile(
          //   user: _teacher,
          //   showCheckbox: false,
          // ),
          FutureBuilder<User?>(
            future: _teacher,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(), // Loading line for teacher
                );
              } else if (snapshot.hasError) {
                return Text("Error loading teacher");
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("No teacher assigned to this class.", 
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)
                  ),
                );
              }

              final User teacherData = snapshot.data!;

              return _buildUserTile(
                user: teacherData, // Now passing a real User object
                showCheckbox: false,
              );
            }
          ),

          const SizedBox(height: 40),

          // --- Students Section ---
          FutureBuilder<List<User>>(
            future: _students,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildSectionHeader(title: 'Students (0)', onAdd: (){});
              }

              final students = snapshot.data!;

              return Column(
                children: [
                  _buildSectionHeader(
                    title: 'Students',
                    trailing: Text(
                      '${students.length} Student${students.length == 1 ? '' : 's'}',
                    ),
                    onAdd: () {
                      print('Invite student');
                    },
                  ),
                  const Divider(height: 24),

                  // --- Student Controls ---
                  _buildStudentControls(students),

                  // --- Student List ---
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _buildUserTile(
                        user: student,
                        showCheckbox: true,
                        // Check if this specific UserID is in our set
                        isSelected: _selectedUserIds.contains(student.userId), 
                        onSelected: (selected) => _onSelectStudent(student.userId, selected, students.length),
                      );
                    },
                  ),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onAdd,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 16),
            ],
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              tooltip: 'Invite ${title.toLowerCase()}',
              onPressed: onAdd,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudentControls(List<User> allStudents) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: _isAllStudentsSelected,
            onChanged: (val) => _onSelectAllStudents(val, allStudents),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _actionsValue,
                items: ['Actions', 'Email', 'Remove']
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null && value != 'Actions') {
                    print('Action: $value on ${_selectedUserIds.length} students');
                    setState(() => _actionsValue = 'Actions');
                  } else {
                    setState(() => _actionsValue = value ?? 'Actions');
                  }
                },
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            tooltip: 'Sort by name',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // RENAMED: _buildPersonTile -> _buildUserTile
  // UPDATED: To use User model
  Widget _buildUserTile({
    required User user,
    required bool showCheckbox,
    bool isSelected = false,
    ValueChanged<bool?>? onSelected,
  }) {
    // Helper to get initials (e.g., Mark Marfil -> M)
    String initial = user.firstname.isNotEmpty ? user.firstname[0].toUpperCase() : '?';

    return ListTile(
      leading: showCheckbox
          ? Checkbox(
              value: isSelected,
              onChanged: onSelected,
            )
          : null,
      title: Row(
        children: [
          // Since User model has no image, we use CircleAvatar with Initials
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            radius: 20,
            child: Text(
              initial, 
              style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "${user.firstname} ${user.lastname}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      trailing: showCheckbox
          ? PopupMenuButton<String>(
              onSelected: (value) {
                print('Action: $value on ${user.firstname}');
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'email', child: Text('Email')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            )
          : null,
    );
  }
}