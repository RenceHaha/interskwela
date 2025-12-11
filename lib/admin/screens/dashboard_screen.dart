import 'package:flutter/material.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'totalStudents': 0,
    'totalTeachers': 0,
    'totalClasses': 0,
    'totalSubjects': 0,
    'totalSections': 0,
  };

  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch users count
      final usersResponse = await http.get(
        Uri.parse('http://localhost:3000/api/accounts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (usersResponse.statusCode == 200) {
        final List<dynamic> users = json.decode(usersResponse.body);
        int students = users
            .where((u) => u['role']?.toLowerCase() == 'student')
            .length;
        int teachers = users
            .where(
              (u) =>
                  u['role']?.toLowerCase() == 'teacher' ||
                  u['role']?.toLowerCase() == 'professor',
            )
            .length;

        setState(() {
          _stats['totalUsers'] = users.length;
          _stats['totalStudents'] = students;
          _stats['totalTeachers'] = teachers;
        });
      }

      // Fetch classes count
      final classesResponse = await http.get(
        Uri.parse('http://localhost:3000/api/classes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (classesResponse.statusCode == 200) {
        final List<dynamic> classes = json.decode(classesResponse.body);
        setState(() {
          _stats['totalClasses'] = classes.length;
        });
      }

      // Fetch subjects count
      final subjectsResponse = await http.get(
        Uri.parse('http://localhost:3000/api/subjects'),
        headers: {'Content-Type': 'application/json'},
      );

      if (subjectsResponse.statusCode == 200) {
        final List<dynamic> subjects = json.decode(subjectsResponse.body);
        setState(() {
          _stats['totalSubjects'] = subjects.length;
        });
      }

      // Fetch sections count
      final sectionsResponse = await http.get(
        Uri.parse('http://localhost:3000/api/sections'),
        headers: {'Content-Type': 'application/json'},
      );

      if (sectionsResponse.statusCode == 200) {
        final List<dynamic> sections = json.decode(sectionsResponse.body);
        setState(() {
          _stats['totalSections'] = sections.length;
        });
      }

      // Generate sample recent activity
      _recentActivity = [
        {
          'action': 'New student registered',
          'time': '2 minutes ago',
          'icon': Icons.person_add,
        },
        {
          'action': 'Class "Math 101" created',
          'time': '15 minutes ago',
          'icon': Icons.class_,
        },
        {
          'action': 'Assignment posted',
          'time': '1 hour ago',
          'icon': Icons.assignment,
        },
        {
          'action': 'New teacher added',
          'time': '2 hours ago',
          'icon': Icons.school,
        },
        {
          'action': 'Section "Grade 10-A" updated',
          'time': '3 hours ago',
          'icon': Icons.edit,
        },
      ];
    } catch (e) {
      print('Error fetching dashboard data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Stats Cards
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // Two Column Layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Actions
                        Expanded(flex: 3, child: _buildQuickActions()),
                        const SizedBox(width: 24),

                        // Recent Activity
                        Expanded(flex: 2, child: _buildRecentActivity()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s what\'s happening with your school today.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Total Users',
          value: _stats['totalUsers'].toString(),
          icon: Icons.people_outline,
          color: const Color(0xFF6366F1),
          subtitle: 'All registered accounts',
        ),
        _buildStatCard(
          title: 'Students',
          value: _stats['totalStudents'].toString(),
          icon: Icons.school_outlined,
          color: const Color(0xFF10B981),
          subtitle: 'Active students',
        ),
        _buildStatCard(
          title: 'Teachers',
          value: _stats['totalTeachers'].toString(),
          icon: Icons.person_outline,
          color: const Color(0xFFF59E0B),
          subtitle: 'Teaching staff',
        ),
        _buildStatCard(
          title: 'Classes',
          value: _stats['totalClasses'].toString(),
          icon: Icons.folder_shared_outlined,
          color: const Color(0xFFEC4899),
          subtitle: 'Active classes',
        ),
        _buildStatCard(
          title: 'Subjects',
          value: _stats['totalSubjects'].toString(),
          icon: Icons.menu_book_outlined,
          color: const Color(0xFF8B5CF6),
          subtitle: 'Available subjects',
        ),
        _buildStatCard(
          title: 'Sections',
          value: _stats['totalSections'].toString(),
          icon: Icons.grid_view_outlined,
          color: const Color(0xFF14B8A6),
          subtitle: 'Student sections',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(Icons.trending_up, color: Colors.green.shade400, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
            children: [
              Icon(Icons.flash_on, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                icon: Icons.person_add_outlined,
                label: 'Add User',
                color: const Color(0xFF6366F1),
                onTap: () {},
              ),
              _buildActionButton(
                icon: Icons.create_new_folder_outlined,
                label: 'Create Class',
                color: const Color(0xFFEC4899),
                onTap: () {},
              ),
              _buildActionButton(
                icon: Icons.add_box_outlined,
                label: 'Add Subject',
                color: const Color(0xFF8B5CF6),
                onTap: () {},
              ),
              _buildActionButton(
                icon: Icons.group_add_outlined,
                label: 'Add Section',
                color: const Color(0xFF14B8A6),
                onTap: () {},
              ),
              _buildActionButton(
                icon: Icons.campaign_outlined,
                label: 'Announcement',
                color: const Color(0xFFF59E0B),
                onTap: () {},
              ),
              _buildActionButton(
                icon: Icons.settings_outlined,
                label: 'Settings',
                color: const Color(0xFF64748B),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
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
                  Icon(Icons.history, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recentActivity.map(
            (activity) => _buildActivityItem(
              icon: activity['icon'] as IconData,
              action: activity['action'] as String,
              time: activity['time'] as String,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String action,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
