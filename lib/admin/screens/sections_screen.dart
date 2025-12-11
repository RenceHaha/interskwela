import 'package:flutter/material.dart';
import 'package:interskwela/admin/screens/section_form_screen.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SectionsScreen extends StatefulWidget {
  const SectionsScreen({super.key});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<dynamic>> _sectionsFuture;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _fetchSections();
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

  Future<List<dynamic>> _fetchSections() async {
    const String url = 'http://localhost:3000/api/sections';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load sections');
      }
    } catch (e) {
      throw Exception('Could not connect to the server.');
    }
  }

  List<dynamic> _getFilteredSections(List<dynamic> allSections) {
    if (_searchQuery.isEmpty) return allSections;

    final query = _searchQuery.toLowerCase();
    return allSections.where((section) {
      final name = (section['section_name'] ?? '').toString().toLowerCase();
      return name.contains(query);
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
                      'Section Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage all sections in the system',
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

            // Section List
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _sectionsFuture,
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

                  final filteredSections = _getFilteredSections(snapshot.data!);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${filteredSections.length} sections',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: filteredSections.isEmpty
                            ? _buildNoResultsState()
                            : ListView.separated(
                                itemCount: filteredSections.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (ctx, index) {
                                  return SectionListItem(
                                    section: filteredSections[index],
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
            MaterialPageRoute(builder: (context) => const SectionsFormScreen()),
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
          hintText: 'Search sections...',
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
            _sectionsFuture = _fetchSections();
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
            Icons.grid_view_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No sections found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add sections by clicking the + button',
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
            'No matching sections',
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
// SECTION LIST ITEM
// ---------------------------------------------------
class SectionListItem extends StatefulWidget {
  final dynamic section;

  const SectionListItem({super.key, required this.section});

  @override
  State<SectionListItem> createState() => _SectionListItemState();
}

class _SectionListItemState extends State<SectionListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final String name = section['section_name'] ?? 'Unnamed Section';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

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
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Section',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
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
                    SectionsFormScreen(section: widget.section),
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
    final name = widget.section['section_name'] ?? 'this section';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text('Are you sure you want to delete "$name"?'),
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
