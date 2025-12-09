import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:interskwela/models/classes.dart';
import 'package:interskwela/models/classwork.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/classwork/classwork_card.dart';
import 'package:interskwela/widgets/classwork/topic_header.dart';
import 'package:interskwela/student/screens/classworks/classwork_detail_screen.dart'; // NEW Import

class StudentClassworkTab extends StatefulWidget {
  final Classes currentClass;
  final int userId;

  const StudentClassworkTab({
    required this.currentClass,
    required this.userId,
    super.key,
  });

  @override
  State<StudentClassworkTab> createState() => _StudentClassworkTabState();
}

class _StudentClassworkTabState extends State<StudentClassworkTab> {
  // ... (Keep existing State logic: _isLoading, _allClassworks, _fetchClassworks, initState) ...
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
      print("Error fetching classworks: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
          // Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.assignment_ind_outlined, size: 20),
                label: const Text("View your work"),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterOptions.contains(_filter)
                        ? _filter
                        : _filterOptions.first,
                    items: _filterOptions
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _filter = val!),
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          if (_allClassworks.isEmpty)
            _buildEmptyState()
          else
            _buildGroupedList(),
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
        if (noTopicItems.isNotEmpty) ...[
          ...noTopicItems.map(
            (cw) => ClassworkCard(
              classwork: cw,
              userRole: 'student',
              onTap: () => _navigateToDetail(cw),
            ),
          ),
          const SizedBox(height: 24),
        ],

        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopicHeader(topicName: entry.key),
              ...entry.value.map(
                (cw) => ClassworkCard(
                  classwork: cw,
                  userRole: 'student',
                  onTap: () => _navigateToDetail(cw),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        }),
      ],
    );
  }

  void _navigateToDetail(Classwork cw) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StudentClassworkDetailScreen(classwork: cw, userId: widget.userId),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 150,
            color: Colors.blue[100],
          ),
          const SizedBox(height: 24),
          const Text(
            "No classwork assigned yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Check back later for new assignments",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
