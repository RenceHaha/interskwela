import 'package:flutter/material.dart';
import 'package:interskwela/models/subject.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/forms.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubjectFormScreen extends StatefulWidget {
  final Subject? subject; // Optional subject for edit mode

  const SubjectFormScreen({super.key, this.subject});

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get isEditMode => widget.subject != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _populateFields();
    }
  }

  void _populateFields() {
    final subject = widget.subject!;
    _subjectNameController.text = subject.subjectName;
    _subjectCodeController.text = subject.subjectCode;
    _descriptionController.text = subject.description;
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Subject' : 'Create New Subject'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionHeader('SUBJECT INFORMATION'),
                const SizedBox(height: 24),
                CustomTextFormField(
                  controller: _subjectNameController,
                  hintText: 'Subject Name',
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _subjectCodeController,
                  hintText: 'Subject Code',
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _descriptionController,
                  maxLines: null,
                  minLines: 3,
                  hintText: 'Description',
                ),
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
                          isEditMode ? 'Update Subject' : 'Create Subject',
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

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (isEditMode) {
        _updateSubject();
      } else {
        _createSubject();
      }
    }
  }

  Future<void> _createSubject() async {
    setState(() => _isLoading = true);

    final url = Uri.parse("http://localhost:3000/api/subjects");

    final Map<String, dynamic> payload = {
      'subject_name': _subjectNameController.text,
      'subject_code': _subjectCodeController.text,
      'description': _descriptionController.text,
      'action': 'create-subject',
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
          const SnackBar(content: Text("Subject created successfully!")),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Network Error!")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSubject() async {
    setState(() => _isLoading = true);

    final url = Uri.parse("http://localhost:3000/api/subjects");

    final Map<String, dynamic> payload = {
      'subject_id': widget.subject!.subjectId,
      'subject_name': _subjectNameController.text,
      'subject_code': _subjectCodeController.text,
      'description': _descriptionController.text,
      'action': 'update-subject',
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
          const SnackBar(content: Text("Subject updated successfully!")),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Network Error!")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
