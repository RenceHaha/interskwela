import 'package:flutter/material.dart';
import 'package:interskwela/admin/screens/subjects_form_screen.dart';
import 'package:interskwela/models/subject.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<Subject>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _fetchSubjects();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<List<Subject>> _fetchSubjects() async {
    const String url = 'http://localhost:3000/api/subjects';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Subject.fromJson(json)).toList();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception('Failed to load Subjects: ${responseData['error']}');
      }
    } catch (e) {
      throw Exception('An error occurred: Could not connect to the server.');
    }
  }

  List<Subject> _getFilteredSubjects(List<Subject> allSubjects) {
    if (_searchQuery.isEmpty) return allSubjects;

    final query = _searchQuery.toLowerCase();
    return allSubjects.where((subject) {
      final nameMatch = subject.subjectName.toLowerCase().contains(query);
      final codeMatch = subject.subjectCode.toLowerCase().contains(query);
      final descriptionMatch = subject.description.toLowerCase().contains(
        query,
      );
      return nameMatch || codeMatch || descriptionMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
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
                    const Text(
                      'Subject Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage all subjects in the system',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Search and Refresh
            Row(
              children: [
                Expanded(child: _buildSearchBar()),
                const SizedBox(width: 16),
                _buildRefreshButton(),
              ],
            ),

            const SizedBox(height: 20),

            // Subject List
            Expanded(
              child: FutureBuilder<List<Subject>>(
                future: _subjectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState('${snapshot.error}');
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filteredSubjects = _getFilteredSubjects(snapshot.data!);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${filteredSubjects.length} subjects',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: filteredSubjects.isEmpty
                            ? _buildNoResultsState()
                            : ListView.separated(
                                itemCount: filteredSubjects.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (ctx, index) {
                                  return SubjectListItem(
                                    subject: filteredSubjects[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SubjectFormScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, code, or description...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          setState(() {
            _subjectsFuture = _fetchSubjects();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(
            Icons.refresh_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No subjects found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add subjects by clicking the + button',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No matching subjects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------
// SUBJECT LIST ITEM
// ---------------------------------------------------
class SubjectListItem extends StatefulWidget {
  final Subject subject;

  const SubjectListItem({super.key, required this.subject});

  @override
  State<SubjectListItem> createState() => _SubjectListItemState();
}

class _SubjectListItemState extends State<SubjectListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovering
                ? AppColors.primary.withOpacity(0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            subject.subjectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDim,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            subject.subjectCode,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject.description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Actions Menu
              _buildActionsMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: const Offset(0, 40),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SubjectFormScreen(subject: widget.subject),
              ),
            );
            if (result == true && context.mounted) {
              // Trigger refresh in parent
            }
            break;
          case 'delete':
            _showDeleteConfirmation();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to delete "${widget.subject.subjectName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete API call
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
