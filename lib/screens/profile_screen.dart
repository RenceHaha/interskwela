import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:interskwela/models/user.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/change_password_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  User? _user;

  // Edit controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/accounts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'get-user-info', 'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _user = User.fromJson(data);
            _populateControllers();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    if (_user == null) return;
    _firstNameController.text = _user!.firstname;
    _middleNameController.text = _user!.middlename ?? '';
    _lastNameController.text = _user!.lastname;
    _emailController.text = _user!.email;
    _contactController.text = _user!.contact ?? '';
    _addressController.text = _user!.address;
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/accounts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'update-user',
          'user_id': _user!.userId,
          'firstname': _firstNameController.text,
          'middlename': _middleNameController.text,
          'lastname': _lastNameController.text,
          'email': _emailController.text,
          'contact': _contactController.text,
          'address': _addressController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditing = false);
        _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Network error')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildProfileContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'User not found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final initials = '${_user!.firstname[0]}${_user!.lastname[0]}'
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_user!.firstname} ${_user!.lastname}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user!.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _user!.role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              _buildHeaderButton(
                icon: _isEditing ? Icons.close : Icons.edit_outlined,
                onTap: () {
                  setState(() {
                    _isEditing = !_isEditing;
                    if (!_isEditing) _populateControllers();
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildHeaderButton(
                icon: Icons.lock_outline,
                onTap: () => showChangePasswordDialog(context, _user!.userId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (_isEditing)
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Name Row
          Row(
            children: [
              Expanded(
                child: _buildInfoField(
                  label: 'First Name',
                  value: _user!.firstname,
                  controller: _firstNameController,
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoField(
                  label: 'Middle Name',
                  value: _user!.middlename ?? '-',
                  controller: _middleNameController,
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoField(
                  label: 'Last Name',
                  value: _user!.lastname,
                  controller: _lastNameController,
                  icon: Icons.badge_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contact Row
          Row(
            children: [
              Expanded(
                child: _buildInfoField(
                  label: 'Email Address',
                  value: _user!.email,
                  controller: _emailController,
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoField(
                  label: 'Contact Number',
                  value: _user!.contact ?? '-',
                  controller: _contactController,
                  icon: Icons.phone_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Address
          _buildInfoField(
            label: 'Address',
            value: _user!.address,
            controller: _addressController,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 20),

          // Date of Birth (read-only)
          Row(
            children: [
              Expanded(
                child: _buildInfoField(
                  label: 'Date of Birth',
                  value: _user!.dob,
                  icon: Icons.cake_outlined,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoField(
                  label: 'Role',
                  value: _user!.role,
                  icon: Icons.work_outline,
                  readOnly: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    TextEditingController? controller,
    bool readOnly = false,
  }) {
    final isEditable = _isEditing && !readOnly && controller != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditable)
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceDim,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontSize: 14),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
