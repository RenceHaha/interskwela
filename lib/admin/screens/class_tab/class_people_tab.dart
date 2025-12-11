import 'package:flutter/material.dart';
import 'package:interskwela/models/user.dart';
import 'package:interskwela/models/classes.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PeopleTab extends StatefulWidget {
  final Classes specificClass;

  const PeopleTab({required this.specificClass, super.key});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  late Future<List<User>> _students;
  late Future<User?> _teacher;

  final Set<int> _selectedUserIds = {};
  bool _isAllStudentsSelected = false;
  String _actionsValue = 'Actions';

  @override
  void initState() {
    super.initState();
    _students = _getStudents();
    _teacher = _getTeacher();
  }

  Future<User?> _getTeacher() async {
    const String url = 'http://localhost:3000/api/classes';
    var payload = {
      'class_id': widget.specificClass.classId,
      'action': 'get-teacher',
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

        List<User> teachers = data.map((json) => User.fromJson(json)).toList();
        if (teachers.isNotEmpty) return teachers.first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<User>> _getStudents() async {
    const String url = 'http://localhost:3000/api/classes';
    var payload = {
      'class_id': widget.specificClass.classId,
      'action': 'get-students',
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
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

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
      _isAllStudentsSelected = _selectedUserIds.length == totalStudentCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teachers Section
              _buildSectionHeader(
                icon: Icons.person_outline,
                title: 'Teacher',
                onAdd: () {},
              ),
              const SizedBox(height: 12),
              _buildTeacherCard(),

              const SizedBox(height: 32),

              // Students Section
              _buildStudentsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required VoidCallback onAdd,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.primary, width: 2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          if (trailing != null) ...[trailing, const SizedBox(width: 12)],
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.person_add_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard() {
    return FutureBuilder<User?>(
      future: _teacher,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const LinearProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  'No teacher assigned to this class',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        return _buildUserCard(user: snapshot.data!, showCheckbox: false);
      },
    );
  }

  Widget _buildStudentsSection() {
    return FutureBuilder<List<User>>(
      future: _students,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icon: Icons.groups_outlined,
                title: 'Students',
                trailing: Text(
                  '0 students',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                onAdd: () {},
              ),
              const SizedBox(height: 24),
              _buildEmptyStudentsState(),
            ],
          );
        }

        final students = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.groups_outlined,
              title: 'Students',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${students.length} student${students.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              onAdd: () {},
            ),
            const SizedBox(height: 16),

            // Controls
            _buildStudentControls(students),
            const SizedBox(height: 12),

            // Student List
            ...students.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildUserCard(
                  user: student,
                  showCheckbox: true,
                  isSelected: _selectedUserIds.contains(student.userId),
                  onSelected: (selected) => _onSelectStudent(
                    student.userId,
                    selected,
                    students.length,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentControls(List<User> allStudents) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _isAllStudentsSelected,
            onChanged: (val) => _onSelectAllStudents(val, allStudents),
            activeColor: AppColors.primary,
          ),
          Text(
            'Select all',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _actionsValue,
                items: ['Actions', 'Email', 'Remove']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null && value != 'Actions') {
                    setState(() => _actionsValue = 'Actions');
                  } else {
                    setState(() => _actionsValue = value ?? 'Actions');
                  }
                },
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.sort_by_alpha,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard({
    required User user,
    required bool showCheckbox,
    bool isSelected = false,
    ValueChanged<bool?>? onSelected,
  }) {
    String initial = user.firstname.isNotEmpty
        ? user.firstname[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          if (showCheckbox) ...[
            Checkbox(
              value: isSelected,
              onChanged: onSelected,
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 8),
          ],

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name
          Expanded(
            child: Text(
              "${user.firstname} ${user.lastname}",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Actions
          if (showCheckbox)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (value) {},
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'email', child: Text('Email')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyStudentsState() {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No students in this class',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
