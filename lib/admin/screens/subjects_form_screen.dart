import 'package:flutter/material.dart';
import 'package:interskwela/widgets/forms.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubjectFormScreen extends StatefulWidget {
  const SubjectFormScreen({super.key});

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {

  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; 
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose(){
    _subjectNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Subject'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionHeader('SUBJECT INFORMATION'),
                SizedBox(height: 24),
                CustomTextFormField(
                  controller: _subjectNameController, 
                  hintText: 'Subject Name'),
                SizedBox(height: 16),
                CustomTextFormField(
                  controller: _subjectCodeController, 
                  hintText: 'Subject Code'),
                SizedBox(height: 16), 
                CustomTextFormField(
                  controller: _descriptionController,
                  maxLines: null,
                  minLines: 3, 
                  hintText: 'Description'),
                SizedBox(height: 16),
                ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      if (_formKey.currentState!.validate()) {
                        // Form is valid, proceed with submission
                        print('Form is valid!');
                        print('Subject Name: ${_subjectNameController.text}');
                        print('Subject Code: ${_subjectCodeController.text}');

                        createSubject();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1C3353), // Your app's theme color
                      minimumSize: Size(double.infinity, 50), // Full width
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                    ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                    : Text(
                      'Create Subject',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            )
          )
        )
      )
    );
  }

  Future<void> createSubject() async{
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse("http://localhost:3000/api/subjects");
    
    final Map<String, dynamic> payload = {
      'subject_name': _subjectNameController.text,
      'subject_code': _subjectCodeController.text,
      'description': _descriptionController.text,
      'action': 'create-subject'
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type' : 'application/json'},
        body: jsonEncode(payload),
      );
      
      if(!mounted) return;

      final data = jsonDecode(response.body);
      if(response.statusCode == 200) {
        print("Response: ${data}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Subject created successfully!")),
        );

        Navigator.of(context).pop();
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
        print("Error Response: ${data['error']}");
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network Error!"))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}