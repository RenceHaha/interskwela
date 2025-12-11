import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:interskwela/models/classes.dart';
import 'package:interskwela/models/classwork.dart';
import 'package:interskwela/teacher/screens/classworks/classwork_detail_screen.dart';
import 'package:interskwela/teacher/screens/classworks/classwork_form_screen.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/classwork/classwork_card.dart';
import 'package:interskwela/widgets/classwork/topic_header.dart';

class ClassworkTab extends StatefulWidget {
  final Classes currentClass;
  final int userId;

  const ClassworkTab({
    required this.currentClass,
    required this.userId,
    super.key,
  });

  @override
  State<ClassworkTab> createState() => _ClassworkTabState();
}

class _ClassworkTabState extends State<ClassworkTab> {
  bool _isLoading = true;
  List<Classwork> _allClassworks = [];
  Map<int, String> _topics = {};
  String _filter = 'All topics';
  List<String> _filterOptions = ['All topics'];

  @override
  void initState() {
    super.initState();
    _fetchClassworks();
  }

  Future<void> _fetchClassworks() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/classworks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'get-classwork',
          'class_id': widget.currentClass.classId,
          'user_id': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'];

        List<Classwork> parsedList = list
            .map((json) => Classwork.fromJson(json))
            .toList();

        Set<String> topicNames = {'All topics'};
        Map<int, String> topicMap = {};

        for (var cw in parsedList) {
          if (cw.topicId != null && cw.topicName != null) {
            topicNames.add(cw.topicName!);
            topicMap[cw.topicId!] = cw.topicName!;
          }
        }

        if (mounted) {
          setState(() {
            _allClassworks = parsedList;
            _filterOptions = topicNames.toList();
            _topics = topicMap;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToCreate(String type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassworkFormScreen(
          userId: widget.userId,
          currentClass: widget.currentClass,
          creationMode: type,
        ),
      ),
    );
    _fetchClassworks();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Bar
                  _buildActionBar(),
                  const SizedBox(height: 24),

                  // Content
                  if (_allClassworks.isEmpty)
                    _buildEmptyState()
                  else
                    _buildGroupedList(),
                ],
              ),
            ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Create Button
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              _buildPopupItem(
                'assignment',
                Icons.assignment_outlined,
                'Assignment',
              ),
              _buildPopupItem('quiz', Icons.quiz_outlined, 'Quiz'),
              _buildPopupItem(
                'question',
                Icons.help_outline_rounded,
                'Question',
              ),
              const PopupMenuDivider(),
              _buildPopupItem('material', Icons.menu_book_outlined, 'Material'),
              _buildPopupItem('topic', Icons.topic_outlined, 'Topic'),
            ],
            onSelected: (value) {
              if (value == 'topic') {
                // Handle create topic
              } else {
                _navigateToCreate(value);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Create",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterOptions.contains(_filter)
                    ? _filter
                    : _filterOptions.first,
                items: _filterOptions
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _filter = val!),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    List<Classwork> filtered = _allClassworks;
    if (_filter != 'All topics') {
      filtered = _allClassworks.where((cw) => cw.topicName == _filter).toList();
    }

    Map<String, List<Classwork>> grouped = {};
    List<Classwork> noTopicItems = [];

    for (var cw in filtered) {
      if (cw.topicName != null) {
        if (!grouped.containsKey(cw.topicName)) {
          grouped[cw.topicName!] = [];
        }
        grouped[cw.topicName!]!.add(cw);
      } else {
        noTopicItems.add(cw);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Items with NO Topic
        if (noTopicItems.isNotEmpty) ...[
          ...noTopicItems.map(
            (cw) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClassworkCard(
                classwork: cw,
                userRole: 'admin',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassworkDetailScreen(
                        classwork: cw,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Grouped Topics
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopicHeader(topicName: entry.key),
              const SizedBox(height: 8),
              ...entry.value.map(
                (cw) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClassworkCard(
                    classwork: cw,
                    userRole: 'admin',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassworkDetailScreen(
                            classwork: cw,
                            userId: widget.userId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "This is where you'll assign work",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add assignments and organise them into topics",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
