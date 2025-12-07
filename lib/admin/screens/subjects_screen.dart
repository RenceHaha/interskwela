import 'package:flutter/material.dart';
import 'package:interskwela/admin/screens/subjects_form_screen.dart';
import 'package:interskwela/models/subject.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:interskwela/themes/app_theme.dart';

// Assuming the Subject model and SubjectFormScreen are available

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _searchController = TextEditingController();
  // State variable to hold the current search query
  String _searchQuery = ''; 
  // Future to hold the result of fetching all subjects
  late Future<List<Subject>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the Future to fetch data when the widget is created
    _subjectsFuture = _fetchSubjects();
    
    // 1. Listen to search bar changes and update state
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  // Method to update the search query state
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  // --- BUILD METHOD: Now includes the search bar and FutureBuilder ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        color: AppColors.surfaceDim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subject Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold
                  ),
                ),
                _buildSearchBar(),
              ]
            ),
            const SizedBox(height: 16),
            // Use FutureBuilder to display the data
            Expanded(
              child: FutureBuilder<List<Subject>>(
                future: _subjectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) { 
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No subjects found.'));
                  }

                  // 3. Filter the subjects based on the search query
                  final filteredSubjects = _getFilteredSubjects(snapshot.data!);

                  if (filteredSubjects.isEmpty) {
                    return const Center(child: Text('No results for your search.'));
                  }

                  // Display the filtered list
                  return ListView.separated(
                    itemCount: filteredSubjects.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final subject = filteredSubjects[index];
                      return Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.surface,
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subject.subjectName),
                                Text(subject.subjectCode),
                                Text(subject.description, overflow: TextOverflow.ellipsis, maxLines: 1)
                              ],
                            )
                          ],
                        ),
                      );
                        // Add more details or an action button here
                      
                    },
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
            MaterialPageRoute(
              builder: (context) => const SubjectFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      )
    );
  }

  // --- SEARCH BAR: Already correct, but now connected to the state ---
  Widget _buildSearchBar() {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _onSearchChanged(), // This is redundant with listener, but harmless
        decoration: InputDecoration(
          hintText: 'Search subjects...', // Changed hint text
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 12), child: Icon(Icons.search, color: Colors.grey[600], size: 20,)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        ),
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
    );
  }
  
  // --- FETCH SUBJECTS: No changes needed here ---
  Future<List<Subject>> _fetchSubjects() async {
    const String url = 'http://localhost:3000/api/subjects';
    try {
      final response = await http
          .get(Uri.parse(url), headers: <String, String>{
        'Content-Type': 'application/json'
      });
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Subject.fromJson(json)).toList();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception('Failed to load Subjects: ${responseData['error']}');
      }
    } catch (e) {
      print('Error during api call $e');
      throw Exception('An error occurred: Could not connect to the server.');
    }
  }

  // --- FILTER LOGIC: Fixed to use Subject model fields ---
  List<Subject> _getFilteredSubjects(List<Subject> allSubjects) {
    if (_searchQuery.isEmpty) {
      // If the query is empty, return the entire list of subjects
      return allSubjects;
    }

    final query = _searchQuery.toLowerCase();
    
    // 2. Corrected filtering logic using Subject properties
    return allSubjects.where((subject) {
      // Check subjectName, subjectCode, or description for a match
      final nameMatch = subject.subjectName.toLowerCase().contains(query);
      final codeMatch = subject.subjectCode.toLowerCase().contains(query);
      final descriptionMatch = subject.description.toLowerCase().contains(query);

      return nameMatch || codeMatch || descriptionMatch;
    }).toList();
  }
}