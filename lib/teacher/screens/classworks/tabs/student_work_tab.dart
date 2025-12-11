import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:interskwela/models/classwork.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_single_select.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentWorkTab extends StatefulWidget {
  final Classwork classwork;

  const StudentWorkTab({required this.classwork, super.key});

  @override
  State<StudentWorkTab> createState() => _StudentWorkTabState();
}

class _StudentWorkTabState extends State<StudentWorkTab> {
  bool _isLoading = true;
  List<dynamic> _students = [];
  Map<String, int> _stats = {'handed_in': 0, 'assigned': 0, 'marked': 0};

  final Set<int> _selectedUserIds = {};
  bool _allSelected = false;
  int? _viewingUserId;

  late TextEditingController _maxPointsController;

  // Grade controllers for each student
  final Map<int, TextEditingController> _gradeControllers = {};

  int? _sortOrderId = 1;
  final List<DropdownOption> _sortOptions = const [
    DropdownOption(id: 1, label: "Sort by status"),
    DropdownOption(id: 2, label: "Sort by last name"),
  ];

  @override
  void initState() {
    super.initState();
    _maxPointsController = TextEditingController(
      text: _formatPoints(widget.classwork.points),
    );
    _fetchStudentWork();
  }

  @override
  void dispose() {
    _maxPointsController.dispose();
    // Dispose all grade controllers
    for (var controller in _gradeControllers.values) {
      controller.dispose();
    }
    _gradeControllers.clear();
    super.dispose();
  }

  Future<void> _fetchStudentWork() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/classworks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'get-student-work',
          'class_work_id': widget.classwork.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _students = data['students'] ?? [];
            _stats = Map<String, int>.from(data['stats'] ?? {});

            // Initialize grade controllers for each student
            for (var student in _students) {
              final int userId = student['user_id'];
              if (!_gradeControllers.containsKey(userId)) {
                _gradeControllers[userId] = TextEditingController(
                  text: student['score']?.toString() ?? '',
                );
              }
            }

            _isLoading = false;
            _applySort();
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _returnSelectedSubmissions() async {
    if (_selectedUserIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final futures = _selectedUserIds.map((userId) {
        // Get grade from the controller, not from student['score']
        final controller = _gradeControllers[userId];
        final gradeText = controller?.text ?? '';
        final grade = double.tryParse(gradeText);

        print(
          'DEBUG: userId=$userId, controller exists=${controller != null}, text="$gradeText", grade=$grade',
        );
        print('DEBUG: All controllers: ${_gradeControllers.keys.toList()}');

        final payload = {
          'action': 'return-grade',
          'class_work_id': widget.classwork.id,
          'user_id': userId,
          'grade': grade,
        };

        print(payload);

        return http.post(
          Uri.parse('http://localhost:3000/api/classworks'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }).toList();

      await Future.wait(futures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Returned ${_selectedUserIds.length} submission(s)"),
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {
          _selectedUserIds.clear();
          _allSelected = false;
        });
        _fetchStudentWork();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error returning submissions")),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySort() {
    if (_sortOrderId == 1) {
      _students.sort((a, b) {
        int priority(String status) {
          if (status == 'handed-in') return 0;
          if (status == 'assigned') return 1;
          if (status == 'missing') return 2;
          return 3;
        }

        return priority(a['status']).compareTo(priority(b['status']));
      });
    } else if (_sortOrderId == 2) {
      _students.sort(
        (a, b) => a['name'].toString().compareTo(b['name'].toString()),
      );
    }
  }

  void _toggleSelectAll(bool? val) {
    setState(() {
      _allSelected = val ?? false;
      if (_allSelected) {
        _selectedUserIds.addAll(_students.map((s) => s['user_id'] as int));
      } else {
        _selectedUserIds.clear();
      }
    });
  }

  void _toggleStudentSelection(int userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
      _allSelected = _selectedUserIds.length == _students.length;
    });
  }

  void _selectStudentForView(int userId) {
    setState(() {
      _viewingUserId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return Column(
          children: [
            _buildTopActionBar(),
            Expanded(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 360,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: _buildStudentList(),
                        ),
                        Expanded(
                          child: _viewingUserId == null
                              ? _buildSummaryView()
                              : _buildIndividualStudentView(),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 500, child: _buildStudentList()),
                          Divider(thickness: 1, color: Colors.grey.shade200),
                          if (_viewingUserId != null)
                            SizedBox(
                              height: 500,
                              child: _buildIndividualStudentView(),
                            )
                          else
                            SizedBox(height: 500, child: _buildSummaryView()),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Return Button
          ElevatedButton.icon(
            onPressed: _selectedUserIds.isEmpty
                ? null
                : _returnSelectedSubmissions,
            icon: const Icon(Icons.reply_rounded, size: 18),
            label: const Text("Return"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade500,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
            onPressed: () {},
            tooltip: "Email students",
          ),
          const Spacer(),

          // Max Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _maxPointsController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "points",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _allSelected,
                    onChanged: _toggleSelectAll,
                    activeColor: AppColors.primary,
                  ),
                  Icon(
                    Icons.group_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "All students",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleSelectDropdown(
                label: "",
                options: _sortOptions,
                selectedValue: _sortOrderId,
                onChanged: (val) {
                  setState(() {
                    _sortOrderId = val;
                    _applySort();
                  });
                },
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        Expanded(
          child: ListView.separated(
            itemCount: _students.length,
            separatorBuilder: (ctx, i) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final student = _students[index];
              final int userId = student['user_id'];
              final bool isSelected = _selectedUserIds.contains(userId);
              final bool isViewing = _viewingUserId == userId;

              return Material(
                color: isViewing
                    ? AppColors.primary.withOpacity(0.05)
                    : AppColors.surface,
                child: InkWell(
                  onTap: () => _selectStudentForView(userId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleStudentSelection(userId),
                          activeColor: AppColors.primary,
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: student['avatar'] != null
                              ? NetworkImage(
                                  "http://localhost:3000${student['avatar']}",
                                )
                              : null,
                          child: student['avatar'] == null
                              ? Text(
                                  student['name'][0],
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            student['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: TextFormField(
                            key: ValueKey('grade_$userId'),
                            controller: _gradeControllers[userId],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: "—",
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: student['status'] == 'missing'
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "/100",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualStudentView() {
    final student = _students.firstWhere(
      (s) => s['user_id'] == _viewingUserId,
      orElse: () => null,
    );
    if (student == null) return const SizedBox.shrink();

    String statusText = "Assigned";
    Color statusColor = AppColors.textSecondary;
    if (student['status'] == 'handed-in') {
      statusText = "Handed in";
      statusColor = Colors.green;
    }
    if (student['status'] == 'missing') {
      statusText = "Missing";
      statusColor = AppColors.error;
    }
    if (student['status'] == 'returned') {
      statusText = "Marked";
      statusColor = AppColors.primary;
    }

    List<dynamic> attachments = [];
    if (student['attachments'] != null && student['attachments'] is List) {
      attachments = student['attachments'];
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _viewingUserId = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to Overview'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (student['score'] == null)
                      Text(
                        "No mark",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Files
                if (attachments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No attachments submitted",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: attachments.map<Widget>((att) {
                      final String? filePath = att['file_path'];
                      return InkWell(
                        onTap: () async {
                          if (filePath != null && filePath.isNotEmpty) {
                            // Build the full URL for the file
                            final String fileUrl =
                                'http://localhost:3000/$filePath';
                            final Uri uri = Uri.parse(fileUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open file'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 180,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDim,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(10),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 36,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  att['file_name'] ?? 'File',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),

        // Private Comments
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Add private comment...",
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.classwork.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _buildBigStat(_stats['handed_in'].toString(), "Handed in"),
              _buildDivider(),
              _buildBigStat(_stats['assigned'].toString(), "Assigned"),
              _buildDivider(),
              _buildBigStat(_stats['marked'].toString(), "Marked"),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            "Student Attachments",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildAttachmentsGrid(),
        ],
      ),
    );
  }

  Widget _buildAttachmentsGrid() {
    List<Map<String, dynamic>> allAttachments = [];
    for (var s in _students) {
      if (s['attachments'] != null) {
        for (var att in s['attachments']) {
          allAttachments.add({
            'student_name': s['name'],
            'student_avatar': s['avatar'],
            'file_name': att['file_name'],
            'file_path': att['file_path'],
            'status': s['status'],
          });
        }
      }
    }

    if (allAttachments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Text(
          "No work submitted yet",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: allAttachments
          .map((item) => _buildSubmissionCard(item))
          .toList(),
    );
  }

  Widget _buildBigStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> item) {
    final String? filePath = item['file_path'];
    return InkWell(
      onTap: () async {
        if (filePath != null && filePath.isNotEmpty) {
          final String fileUrl = 'http://localhost:3000/$filePath';
          final Uri uri = Uri.parse(fileUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open file')),
              );
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: item['student_avatar'] != null
                        ? NetworkImage(
                            "http://localhost:3000${item['student_avatar']}",
                          )
                        : null,
                    child: item['student_avatar'] == null
                        ? Text(
                            item['student_name'][0],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['student_name'],
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 80,
              width: double.infinity,
              color: AppColors.surfaceDim,
              child: const Center(
                child: Icon(
                  Icons.insert_drive_file_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['file_name'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['status']
                        .toString()
                        .replaceAll('-', ' ')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPoints(double? points) {
    if (points == null) return "Ungraded";
    return points.truncateToDouble() == points
        ? points.truncate().toString()
        : points.toString();
  }
}
