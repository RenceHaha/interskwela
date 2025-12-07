import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // We need this package for date formatting
import 'package:http/http.dart' as http;
import 'package:interskwela/widgets/forms.dart';

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({super.key});
  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  // A global key for the form to handle validation
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; 
  // --- Controllers for each text field ---
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _dobController = TextEditingController(); // For the date
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();

  // State for the dropdown
  String? _selectedRole;
  final List<String> _roles = ['Student', 'Teacher', 'Admin'];

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- Main build method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA), // Light grey background
      appBar: AppBar(
        title: const Text('Create New Account'),
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
                // --- Personal Details Section ---
                buildSectionHeader('PERSONAL DETAILS'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _firstNameController,
                        hintText: 'First Name',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _lastNameController,
                        hintText: 'Last Name',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _middleNameController,
                        hintText: 'Middle Name (Optional)',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _suffixController,
                        hintText: 'Suffix (Optional)',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildDatePicker(), // Date of Birth field

                // --- Residential Address Section ---
                SizedBox(height: 24),
                buildSectionHeader('RESIDENTIAL ADDRESS'),
                SizedBox(height: 16),
                CustomTextFormField(
                  controller: _addressController,
                  hintText: 'Street Address',
                ),

                // --- Contact Details Section ---
                SizedBox(height: 24),
                buildSectionHeader('CONTACT DETAILS'),
                SizedBox(height: 16),
                CustomTextFormField(
                  controller: _contactController,
                  hintText: 'Contact Number',
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                CustomTextFormField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                ),

                // --- Account Role Section ---
                SizedBox(height: 24),
                buildSectionHeader('ACCOUNT ROLE'),
                SizedBox(height: 16),
                _buildRoleDropdown(), // Role dropdown

                // --- Submit Button ---
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    if (_formKey.currentState!.validate()) {
                      // Form is valid, proceed with submission
                      print('Form is valid!');
                      print('First Name: ${_firstNameController.text}');
                      print('Role: $_selectedRole');

                      createAccount();
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
                    'Create Account',
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

  // Reusable widget for the Date of Birth field
  Widget _buildDatePicker() {
    return TextFormField(
      controller: _dobController,
      readOnly: true, // Makes the field non-editable
      decoration: buildInputDecoration(
        'Date of Birth',
        suffixIcon: Icon(Icons.calendar_month_outlined),
      ),
      onTap: () async {
        // Show the date picker when tapped
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );

        if (pickedDate != null) {
          // Format the date and set it in the controller
          String formattedDate = DateFormat('MM/dd/yyyy').format(pickedDate);
          setState(() {
            _dobController.text = formattedDate;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Date of Birth is required';
        }
        return null;
      },
    );
  }

  // Reusable widget for the Role dropdown
  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: buildInputDecoration('Role'),
      items: _roles.map((String role) {
        return DropdownMenuItem<String>(
          value: role,
          child: Text(role),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedRole = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a role';
        }
        return null;
      },
    );
  }

  Future<void> createAccount() async{
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse("http://localhost:3000/api/accounts");
    
    final Map<String, dynamic> payload = {
      'firstname': _firstNameController.text,
      'middlename': _middleNameController.text,
      'lastname': _lastNameController.text,
      'suffix': _suffixController.text,
      'dob': _dobController.text,
      'address': _addressController.text,
      'contact': _contactController.text,
      'email': _emailController.text,
      'role': _selectedRole,
      'action': 'create-users'
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
          SnackBar(content: Text("Account created successfully!")),
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

