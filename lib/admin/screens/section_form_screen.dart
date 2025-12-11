import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interskwela/models/user.dart';
import 'package:interskwela/themes/app_theme.dart';

class SectionsFormScreen extends StatefulWidget {
  final Map<String, dynamic>? section; // Optional section for edit mode

  const SectionsFormScreen({super.key, this.section});

  @override
  State<SectionsFormScreen> createState() => _SectionFormScreenState();
}

class _SectionFormScreenState extends State<SectionsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _sectionNameController = TextEditingController();
  final _searchController = TextEditingController();

  late Future<List<User>> _studentsFuture;
  final List<int> _selectedStudentIds = [];
  String _searchQuery = '';

  bool get isEditMode => widget.section != null;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _fetchStudents();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    if (isEditMode) {
      _populateFields();
    }
  }

  void _populateFields() {
    final section = widget.section!;
    _sectionNameController.text = section['section_name'] ?? '';
    // Pre-select students if they exist in section data
    if (section['students'] != null) {
      _selectedStudentIds.addAll(
        (section['students'] as List).map((s) => s['user_id'] as int),
      );
    }
  }

  @override
  void dispose() {
    _sectionNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<User>> _fetchStudents() async {
    const String url = 'http://localhost:3000/api/accounts';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'action': 'get-students'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      throw Exception('Could not connect to the server.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Section' : 'Create New Section'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('SECTION DETAILS'),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _sectionNameController,
                  hintText: 'Section Name',
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('STUDENTS'),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 8),
                _buildStudentSelector(),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : Text(
                          isEditMode ? 'Update Section' : 'Create Section',
                          style: const TextStyle(
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary,
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: _buildInputDecoration(
        'Search students...',
        suffixIcon: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: FutureBuilder<List<User>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No students found.'));
          }

          final allStudents = snapshot.data!;

          final filteredStudents = allStudents.where((student) {
            final query = _searchQuery.toLowerCase();
            final fullName = '${student.firstname} ${student.lastname}'
                .toLowerCase();
            final email = student.email.toLowerCase();
            return fullName.contains(query) || email.contains(query);
          }).toList();

          if (filteredStudents.isEmpty) {
            return const Center(child: Text('No students match your search.'));
          }

          return ListView.builder(
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              final isSelected = _selectedStudentIds.contains(student.userId);

              return CheckboxListTile(
                title: Text('${student.firstname} ${student.lastname}'),
                subtitle: Text(student.email),
                value: isSelected,
                activeColor: AppColors.primary,
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

  InputDecoration _buildInputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (isEditMode) {
        _updateSection();
      } else {
        _createSection();
      }
    }
  }

  Future<void> _createSection() async {
    setState(() => _isLoading = true);

    final url = Uri.parse("http://localhost:3000/api/sections");

    final Map<String, dynamic> payload = {
      'action': 'create-section',
      'section_name': _sectionNameController.text,
      'students': _selectedStudentIds,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Section created successfully!")),
        );
        Navigator.of(context).pop(true);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Server error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSection() async {
    setState(() => _isLoading = true);

    final url = Uri.parse("http://localhost:3000/api/sections");

    final Map<String, dynamic> payload = {
      'action': 'update-section',
      'section_id': widget.section!['section_id'],
      'section_name': _sectionNameController.text,
      'students': _selectedStudentIds,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Section updated successfully!")),
        );
        Navigator.of(context).pop(true);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Server error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
