import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:interskwela/models/user.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/forms.dart';

class AccountFormScreen extends StatefulWidget {
  final User? user; // Optional user for edit mode

  const AccountFormScreen({super.key, this.user});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedRole;
  final List<String> _roles = ['Student', 'Teacher', 'Admin'];

  bool get isEditMode => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _populateFields();
    }
  }

  void _populateFields() {
    final user = widget.user!;
    _firstNameController.text = user.firstname;
    _middleNameController.text = user.middlename ?? '';
    _lastNameController.text = user.lastname ?? '';
    _suffixController.text = user.suffix ?? '';
    _dobController.text = user.dob ?? '';
    _addressController.text = user.address ?? '';
    _contactController.text = user.contact ?? '';
    _emailController.text = user.email;
    _selectedRole = user.role.isNotEmpty
        ? user.role[0].toUpperCase() + user.role.substring(1).toLowerCase()
        : null;
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Account' : 'Create New Account'),
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
                buildSectionHeader('PERSONAL DETAILS'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _firstNameController,
                        hintText: 'First Name',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _lastNameController,
                        hintText: 'Last Name',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _middleNameController,
                        hintText: 'Middle Name (Optional)',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _suffixController,
                        hintText: 'Suffix (Optional)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDatePicker(),

                const SizedBox(height: 24),
                buildSectionHeader('RESIDENTIAL ADDRESS'),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _addressController,
                  hintText: 'Street Address',
                ),

                const SizedBox(height: 24),
                buildSectionHeader('CONTACT DETAILS'),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _contactController,
                  hintText: 'Contact Number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 24),
                buildSectionHeader('ACCOUNT ROLE'),
                const SizedBox(height: 16),
                _buildRoleDropdown(),

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
                          isEditMode ? 'Update Account' : 'Create Account',
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

  Widget _buildDatePicker() {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      decoration: buildInputDecoration(
        'Date of Birth',
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );

        if (pickedDate != null) {
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

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: buildInputDecoration('Role'),
      items: _roles.map((String role) {
        return DropdownMenuItem<String>(value: role, child: Text(role));
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

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (isEditMode) {
        _updateAccount();
      } else {
        _createAccount();
      }
    }
  }

  Future<void> _createAccount() async {
    setState(() => _isLoading = true);

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
      'action': 'create-users',
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
          const SnackBar(content: Text("Account created successfully!")),
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

  Future<void> _updateAccount() async {
    setState(() => _isLoading = true);

    final url = Uri.parse("http://localhost:3000/api/accounts");

    final Map<String, dynamic> payload = {
      'user_id': widget.user!.userId,
      'firstname': _firstNameController.text,
      'middlename': _middleNameController.text,
      'lastname': _lastNameController.text,
      'suffix': _suffixController.text,
      'dob': _dobController.text,
      'address': _addressController.text,
      'contact': _contactController.text,
      'email': _emailController.text,
      'role': _selectedRole,
      'action': 'update-user',
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
          const SnackBar(content: Text("Account updated successfully!")),
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
