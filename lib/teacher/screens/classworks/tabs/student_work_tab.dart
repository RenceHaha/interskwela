import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:interskwela/models/classwork.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/dropdowns/dropdown_single_select.dart';

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
  
  // Selection & Viewing State
  final Set<int> _selectedUserIds = {};
  bool _allSelected = false;
  int? _viewingUserId; // The student currently being viewed on the right side

  // Max Points State
  late TextEditingController _maxPointsController;

  // Sorting State
  int? _sortOrderId = 1;
  final List<DropdownOption> _sortOptions = const [
    DropdownOption(id: 1, label: "Sort by status"),
    DropdownOption(id: 2, label: "Sort by last name"),
  ];

  @override
  void initState() {
    super.initState();
    _maxPointsController = TextEditingController(text: _formatPoints(widget.classwork.points));
    _fetchStudentWork();
  }

  @override
  void dispose() {
    _maxPointsController.dispose();
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

  /// Saves changes for selected students (Submits grades & marks as returned)
  Future<void> _returnSelectedSubmissions() async {
    if (_selectedUserIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Create a list of futures to return all selected submissions
      // (In a production app, a single bulk-update API endpoint is preferred)
      final futures = _selectedUserIds.map((userId) {
        // Find the student object to get the latest 'score' from local state
        final student = _students.firstWhere((s) => s['user_id'] == userId);
        final grade = student['score']; 

        return http.post(
          Uri.parse('http://localhost:3000/api/classworks'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'action': 'return-grade',
            'class_work_id': widget.classwork.id,
            'user_id': userId,
            'grade': grade, 
          }),
        );
      }).toList();

      // Wait for all requests to complete
      await Future.wait(futures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Returned ${_selectedUserIds.length} submission(s)")),
        );
        
        // Clear selection and refresh data to show updated statuses
        setState(() {
          _selectedUserIds.clear();
          _allSelected = false;
        });
        _fetchStudentWork();
      }
    } catch (e) {
      print("Error returning submissions: $e");
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
      _students.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
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

  Future<void> _updateGrade(int userId, String val) async {
    // Updates the local state immediately so it's ready for 'Return'
    final index = _students.indexWhere((s) => s['user_id'] == userId);
    if (index != -1) {
      setState(() {
        _students[index]['score'] = double.tryParse(val);
      });
    }
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
            // --- TOP ACTION BAR ---
            _buildTopActionBar(),

            // --- MAIN CONTENT ---
            Expanded(
              child: isDesktop 
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Side: Student List
                        Container(
                          width: 350, 
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: _buildStudentList(),
                        ),
                        // Right Side: Work Area (Summary or Individual)
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
                           SizedBox(
                             height: 500,
                             child: _buildStudentList(),
                           ),
                           const Divider(thickness: 8),
                           if (_viewingUserId != null)
                              SizedBox(
                                height: 500, 
                                child: _buildIndividualStudentView()
                              )
                           else 
                              SizedBox(
                                height: 500,
                                child: _buildSummaryView()
                              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Return Button with Split Dropdown
          Container(
            decoration: BoxDecoration(
              color: _selectedUserIds.isEmpty ? Colors.grey.shade300 : AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // Calls _returnSelectedSubmissions when clicked
                    onTap: _selectedUserIds.isEmpty ? null : _returnSelectedSubmissions,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        "Return",
                        style: TextStyle(
                          color: _selectedUserIds.isEmpty ? Colors.grey.shade600 : Colors.white,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.white24),
                PopupMenuButton<String>(
                  icon: Icon(Icons.arrow_drop_down, color: _selectedUserIds.isEmpty ? Colors.grey.shade600 : Colors.white),
                  enabled: _selectedUserIds.isNotEmpty,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'return', child: Text("Return this submission")),
                    const PopupMenuItem(value: 'return_multiple', child: Text("Return multiple submissions")),
                  ],
                  onSelected: (val) {
                     // Can add logic here if specific dropdown action differs from main click
                     if(val == 'return' || val == 'return_multiple') {
                        _returnSelectedSubmissions();
                     }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.email_outlined),
            onPressed: () {},
            tooltip: "Email students",
          ),
          
          const Spacer(),
          
          // Editable Max Points
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maxPointsController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    onSubmitted: (val) {
                      // TODO: Add API call to update max points
                      print("Updated max points to $val");
                    },
                  ),
                ),
                const SizedBox(width: 4),
                const Text("points", style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LEFT PANE: STUDENT LIST ---
  Widget _buildStudentList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _allSelected, 
                    onChanged: _toggleSelectAll,
                  ),
                  const Icon(Icons.group_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Text("All students", style: TextStyle(fontWeight: FontWeight.w500)),
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
        const Divider(height: 1),
        
        Expanded(
          child: ListView.separated(
            itemCount: _students.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = _students[index];
              final int userId = student['user_id'];
              final bool isSelected = _selectedUserIds.contains(userId);
              final bool isViewing = _viewingUserId == userId;

              return Material(
                color: isViewing ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                child: InkWell(
                  onTap: () => _selectStudentForView(userId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected, 
                          onChanged: (_) => _toggleStudentSelection(userId),
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          backgroundImage: student['avatar'] != null 
                              ? NetworkImage("http://localhost:3000${student['avatar']}") 
                              : null,
                          child: student['avatar'] == null 
                              ? Text(student['name'][0], style: const TextStyle(color: Colors.white, fontSize: 12)) 
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        // Editable Grade Input
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            key: ValueKey(userId), // Helps maintain state when scrolling
                            initialValue: student['score']?.toString() ?? "",
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: "__",
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              border: UnderlineInputBorder(),
                            ),
                            style: TextStyle(
                              color: student['status'] == 'missing' ? Colors.red : Colors.black87,
                              fontWeight: FontWeight.bold
                            ),
                            onChanged: (val) => _updateGrade(userId, val),
                          ),
                        ),
                        const Text("/100", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 8),
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

  // --- RIGHT PANE: INDIVIDUAL STUDENT VIEW ---
  Widget _buildIndividualStudentView() {
    final student = _students.firstWhere((s) => s['user_id'] == _viewingUserId, orElse: () => null);
    if (student == null) return const SizedBox.shrink();

    String statusText = "Assigned";
    if (student['status'] == 'handed-in') statusText = "Handed in";
    if (student['status'] == 'missing') statusText = "Missing";
    if (student['status'] == 'returned') statusText = "Marked";

    // Attachments
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'],
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(statusText, style: TextStyle(
                              color: statusText == "Missing" ? Colors.red : Colors.black54,
                              fontSize: 13
                            )),
                            if (student['status'] == 'handed-in')
                               const Padding(
                                 padding: EdgeInsets.only(left: 4.0),
                                 child: Text("(See history)", style: TextStyle(decoration: TextDecoration.underline, fontSize: 13)),
                               )
                          ],
                        ),
                      ],
                    ),
                    if (student['score'] == null)
                       const Text("No mark", style: TextStyle(color: Colors.grey, fontSize: 16))
                  ],
                ),
                const SizedBox(height: 24),

                // Files / Work Area
                if (attachments.isEmpty)
                  Container(
                    width: double.infinity,
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: const Text("No attachments submitted", style: TextStyle(color: Colors.grey)),
                  )
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: attachments.map<Widget>((att) {
                      return Container(
                        width: 200,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                color: Colors.grey.shade100,
                                child: const Center(child: Icon(Icons.insert_drive_file, size: 40, color: Colors.red)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                att['file_name'] ?? 'File',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        
        // Private Comments Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Add private comment...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, size: 18, color: Colors.grey),
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

  // --- RIGHT PANE: SUMMARY VIEW (Grid) ---
  Widget _buildSummaryView() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.classwork.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 24),
          
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
          Text("Student Attachments", style: TextStyle(color: Colors.grey.shade800)),
          const SizedBox(height: 16),
          
          Expanded(child: _buildAttachmentsGrid()),
        ],
      ),
    );
  }

  Widget _buildAttachmentsGrid() {
    // Collect all attachments for summary
    List<Map<String, dynamic>> allAttachments = [];
    for (var s in _students) {
      if (s['attachments'] != null) {
        for (var att in s['attachments']) {
          allAttachments.add({
            'student_name': s['name'],
            'student_avatar': s['avatar'],
            'file_name': att['file_name'],
            'status': s['status']
          });
        }
      }
    }

    if (allAttachments.isEmpty) {
      return Center(child: Text("No work submitted yet", style: TextStyle(color: Colors.grey.shade400)));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: allAttachments.length,
      itemBuilder: (context, index) {
        final item = allAttachments[index];
        return _buildSubmissionCard(item);
      },
    );
  }

  Widget _buildBigStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
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
                   backgroundColor: Colors.blueGrey,
                   backgroundImage: item['student_avatar'] != null 
                      ? NetworkImage("http://localhost:3000${item['student_avatar']}")
                      : null,
                   child: item['student_avatar'] == null 
                      ? Text(item['student_name'][0], style: const TextStyle(fontSize: 10, color: Colors.white)) 
                      : null,
                 ),
                 const SizedBox(width: 8),
                 Expanded(child: Text(item['student_name'], style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              width: double.infinity,
              alignment: Alignment.center,
              child: const Icon(Icons.insert_drive_file, size: 40, color: Colors.redAccent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['file_name'], style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(item['status'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPoints(double? points) {
    if (points == null) return "Ungraded";
    return points.truncateToDouble() == points ? points.truncate().toString() : points.toString();
  }
}