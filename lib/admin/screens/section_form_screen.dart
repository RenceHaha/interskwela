import 'dart:convert';

import 'package:flutter/material.dart';
// We don't need 'intl' for this form anymore
// import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http;
import 'package:interskwela/models/user.dart';

class SectionsFormScreen extends StatefulWidget {
  const SectionsFormScreen({super.key});

  @override
  State<SectionsFormScreen> createState() => _SectionFormScreenState();
}

class _SectionFormScreenState extends State<SectionsFormScreen> {
  // A global key for the form to handle validation
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- 1. Simplified Controllers ---
  final _sectionNameController = TextEditingController();
  final _searchController = TextEditingController();

  // --- 2. State for Student List and Selection ---
  late Future<List<User>> _studentsFuture;
  final List<int> _selectedStudentIds = []; // Stores the IDs of selected students
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Fetch students when the screen loads
    _studentsFuture = _fetchStudents();

    // Listener for the search bar
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    // Clean up the controllers
    _sectionNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- 3. NEW: Function to Fetch Students ---
  Future<List<User>> _fetchStudents() async {
    // Assuming you have an endpoint to get all students
    // TODO: Update this URL to your actual student endpoint
    const String url = 'http://localhost:3000/api/accounts';

    try {
      final response = await http.post(
        Uri.parse(url), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'action': 'get-students'})
        );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // We parse the JSON data into a list of Student objects
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception('Failed to load students: ${responseData['error']}');
      }
    } catch (e) {
      print('Error during API call $e');
      throw Exception('An error occurred: Could not connect to the server.');
    }
  }

  // --- 4. Main Build Method (Updated) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA), // Light grey background
      appBar: AppBar(
        title: const Text('Create New Section'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0), // A bit more padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Section Details Section ---
                _buildSectionHeader('SECTION DETAILS'),
                SizedBox(height: 16),
                _buildTextFormField(
                  controller: _sectionNameController,
                  hintText: 'Section Name',
                ),

                // --- 5. NEW: Student Selector Section ---
                SizedBox(height: 24),
                _buildSectionHeader('STUDENTS'),
                SizedBox(height: 16),
                _buildSearchBar(), // The search bar
                SizedBox(height: 8),
                _buildStudentSelector(), // The list of students

                // --- Submit Button ---
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            createSection(); // Call the updated function
                            // print(_selectedStudentIds);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1C3353),
                    minimumSize: Size(double.infinity, 50), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          'Create Section',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(hintText),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$hintText is required';
        }
        return null;
      },
    );
  }

  // --- 6. NEW: Search Bar Widget ---
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: _buildInputDecoration(
        'Search students...',
        suffixIcon: Icon(Icons.search),
      ),
    );
  }

  // --- 7. NEW: Student Selector List Widget ---
  Widget _buildStudentSelector() {
    return Container(
      height: 300, // Give the list a fixed height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
      ),
      child: FutureBuilder<List<User>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No students found.'));
          }

          final allStudents = snapshot.data!;

          // Filter the students based on the search query
          final filteredStudents = allStudents.where((student) {
            final query = _searchQuery.toLowerCase();
            final fullName =
                '${student.firstname} ${student.lastname}'.toLowerCase();
            final email = student.email.toLowerCase();
            return fullName.contains(query) || email.contains(query);
          }).toList();

          if (filteredStudents.isEmpty) {
            return Center(child: Text('No students match your search.'));
          }

          // Build the list of checkboxes
          return ListView.builder(
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              final isSelected =
                  _selectedStudentIds.contains(student.userId);

              return CheckboxListTile(
                title: Text('${student.firstname} ${student.lastname}'),
                subtitle: Text(student.email),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedStudentIds.add(student.userId);
                    } else {
                      _selectedStudentIds.remove(student.userId);
                    }
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  // Common decoration for all form fields
  InputDecoration _buildInputDecoration(
    String hintText, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue, width: 2.0),
      ),
    );
  }

  // --- 8. UPDATED: Create Section Function ---
  Future<void> createSection() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Update this to your section creation endpoint
    final url = Uri.parse("http://localhost:3000/api/sections");

    final Map<String, dynamic> payload = {
      'action': 'create-section',
      'section_name': _sectionNameController.text,
      'students': _selectedStudentIds, // Send the list of selected IDs
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Section created successfully!")),
        );
        Navigator.of(context).pop(); // Go back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['error'] ?? 'Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Network Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
