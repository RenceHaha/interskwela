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
  Map<int, String> _topics = {}; // Map TopicID -> TopicName
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

        List<Classwork> parsedList = list.map((json) => Classwork.fromJson(json)).toList();
        
        // Extract unique topics for filter
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
      print("Error fetching classworks: $e");
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
    _fetchClassworks(); // Refresh after return
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Action Bar (Create + Filter) ---
          Row(
            children: [
              // Create Button
              PopupMenuButton<String>(
                offset: const Offset(0, 40),
                itemBuilder: (context) => [
                  _buildPopupItem('assignment', Icons.assignment, 'Assignment'),
                  _buildPopupItem('quiz', Icons.assignment_turned_in, 'Quiz'),
                  _buildPopupItem('question', Icons.help_outline, 'Question'),
                  const PopupMenuDivider(),
                  _buildPopupItem('material', Icons.book, 'Material'),
                  _buildPopupItem('topic', Icons.topic, 'Topic'),
                ],
                onSelected: (value) {
                   if(value == 'topic') {
                      // Handle create topic dialog
                   } else {
                      _navigateToCreate(value);
                   }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Topic Filter
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   border: Border.all(color: Colors.grey.shade300),
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: DropdownButtonHideUnderline(
                   child: DropdownButton<String>(
                     value: _filterOptions.contains(_filter) ? _filter : _filterOptions.first,
                     items: _filterOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                     onChanged: (val) => setState(() => _filter = val!),
                     style: const TextStyle(color: Colors.black87, fontSize: 14),
                   ),
                 ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // --- Content List ---
          if (_allClassworks.isEmpty)
             _buildEmptyState()
          else
             _buildGroupedList(),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    // 1. Filter items first
    List<Classwork> filtered = _allClassworks;
    if (_filter != 'All topics') {
      filtered = _allClassworks.where((cw) => cw.topicName == _filter).toList();
    }

    // 2. Group by Topic
    // Use a LinkedHashMap or specific logic to keep specific order if needed.
    // Here we sort by Topic Name (or ID) implicitly by iterating keys.
    Map<String, List<Classwork>> grouped = {};
    
    // Separate items with no topic
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
        // Items with NO Topic appear at the top
        if (noTopicItems.isNotEmpty) ...[
          ...noTopicItems.map((cw) => ClassworkCard(
            classwork: cw, 
            userRole: 'teacher',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassworkDetailScreen(
                    classwork: cw, 
                    userId: widget.userId
                  )
                )
              );
            }
          )),
          const SizedBox(height: 24),
        ],

        // Grouped Topics
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopicHeader(topicName: entry.key),
              ...entry.value.map((cw) => ClassworkCard(
                classwork: cw, 
                userRole: 'teacher',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassworkDetailScreen(
                        classwork: cw, 
                        userId: widget.userId)
                    )
                  );
                }
              )),
              const SizedBox(height: 32),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Icon(Icons.assignment_ind_outlined, size: 150, color: Colors.blue[100]),
          const SizedBox(height: 24),
          const Text(
            "This is where you'll assign work",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            "You can add assignments and other work for the class, then organise it into topics",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}