import 'package:flutter/material.dart';
import 'package:interskwela/student/screens/class_screen.dart';
import '../../models/classes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:interskwela/widgets/class/class_card.dart';
import 'package:shared_preferences/shared_preferences.dart';


class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  late Future<List<Classes>> _classes;
  String _message = '';
  int? userId;

  @override
  void initState() {
    super.initState();
    _classes = _fetchClasses();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
  }

  Future<List<Classes>> _fetchClasses() async {
    const String url = 'http://localhost:3000/api/classes';
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    setState(() {
      _message = 'Fetching classes...';
    });

    Map<String, dynamic> payload = {
      'action': 'get-student-classes',
      'user_id': userId
    };
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json'
        },
        body: jsonEncode(payload),
      );

      if(response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Classes.fromJson(json)).toList();
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _message = responseData['error'];
        });
        return []; // Return empty list on error
      }

    } catch (e) {
      setState(() {
        _message = 'An error occured: Could not connect to the server.';
      });
      log('Error during api call $e');
      return []; // Return empty list on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Classes>>(
        future: _classes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // This will now display the errors we are throwing
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No classes found.'));
          }

          final classesList = snapshot.data!;
          
          // --- 1. Use GridView.builder instead of ListView.builder ---
          // Replace GridView.builder with this:
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12, // Horizontal space between cards
              runSpacing: 12, // Vertical space between rows
              children: classesList.map((cl) {
                // We are just mapping your list to the ClassCard
                return GestureDetector(
                  onTap: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentClassScreen(specificCLass: cl, userId: userId!),
                      ),
                    ),
                  },
                  child: ClassCard(
                    teacherName: cl.teacherName,
                    subjectCode: cl.subjectCode,
                    subjectName: cl.subjectName,
                    sectionName: cl.sectionName,
                    description: cl.description,
                    classId: cl.classId,
                    classCode: cl.classCode,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}