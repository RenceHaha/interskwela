import 'package:flutter/material.dart';
import 'package:interskwela/models/user.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'account_form_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<User>> _users;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  late TabController _tabController;
  final List<String> _tabTitles = ['All', 'Students', 'Teachers', 'Admin'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _users = _fetchUsers();
    _searchController.addListener(_onSearchChanged);
    _tabController.addListener(_onTabChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _tabController.removeListener(_onTabChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<List<User>> _fetchUsers() async {
    const String url = 'http://localhost:3000/api/accounts';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception('Failed to load users: ${responseData['error']}');
      }
    } catch (e) {
      throw Exception('An error occurred: Could not connect to the server.');
    }
  }

  List<User> _getFilteredUsers(List<User> allUsers) {
    final String selectedTabTitle = _tabTitles[_tabController.index]
        .toLowerCase();
    String selectedRoleFilter;

    switch (selectedTabTitle) {
      case 'students':
        selectedRoleFilter = 'student';
        break;
      case 'teachers':
        selectedRoleFilter = 'professor';
        break;
      case 'admin':
        selectedRoleFilter = 'admin';
        break;
      case 'all':
      default:
        selectedRoleFilter = 'all';
        break;
    }

    final tabFilteredUsers = allUsers.where((user) {
      final role = user.role.toLowerCase();
      if (selectedRoleFilter == 'all') return true;
      if (selectedRoleFilter == 'professor' &&
          (role == 'professor' || role == 'teacher')) {
        return true;
      }
      return role == selectedRoleFilter;
    }).toList();

    if (_searchQuery.isEmpty) return tabFilteredUsers;

    final query = _searchQuery.toLowerCase();
    return tabFilteredUsers.where((user) {
      final fullname = '${user.firstname} ${user.lastname}'.toLowerCase();
      final email = user.email.toLowerCase();
      return fullname.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage all user accounts in the system',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildTabBar(),
              ],
            ),

            const SizedBox(height: 24),

            // Search and Stats Row
            Row(
              children: [
                Expanded(child: _buildSearchBar()),
                const SizedBox(width: 16),
                _buildRefreshButton(),
              ],
            ),

            const SizedBox(height: 20),

            // User List
            Expanded(
              child: FutureBuilder<List<User>>(
                future: _users,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState('${snapshot.error}');
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final allUsers = snapshot.data!;
                  final filteredUsers = _getFilteredUsers(allUsers);
                  final String tabText = _tabTitles[_tabController.index];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Results count
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '$tabText • ${filteredUsers.length} users',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                      // User Cards
                      Expanded(
                        child: filteredUsers.isEmpty
                            ? _buildNoResultsState()
                            : ListView.separated(
                                itemCount: filteredUsers.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  return UserListItem(
                                    user: filteredUsers[index],
                                  );
                                },
                              ),
                      ),
                    ],
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
            MaterialPageRoute(builder: (context) => const AccountFormScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TabBar(
        controller: _tabController,
        padding: const EdgeInsets.all(4),
        labelPadding: EdgeInsets.zero,
        tabAlignment: TabAlignment.start,
        tabs: _tabTitles.map((title) {
          return Tab(
            child: Container(
              width: 80,
              alignment: Alignment.center,
              child: Text(title),
            ),
          );
        }).toList(),
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          setState(() {
            _users = _fetchUsers();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(
            Icons.refresh_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add users by clicking the + button',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No matching users',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------
// USER LIST ITEM
// ---------------------------------------------------
class UserListItem extends StatefulWidget {
  final User user;

  const UserListItem({super.key, required this.user});

  @override
  State<UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<UserListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final String initial = (user.lastname != null && user.lastname!.isNotEmpty)
        ? user.lastname![0].toUpperCase()
        : '?';
    final String fullName =
        '${user.firstname} ${user.middlename ?? ''}${user.lastname}'.trim();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovering
                ? AppColors.primary.withOpacity(0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getAvatarColor(user.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: _getAvatarColor(user.role),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        RoleTag(role: user.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions Menu
              _buildActionsMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: const Offset(0, 40),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountFormScreen(user: widget.user),
              ),
            );
            if (result == true && context.mounted) {
              // Trigger refresh in parent
            }
            break;
          case 'delete':
            _showDeleteConfirmation();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete ${widget.user.firstname}\'s account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete API call
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFD4183D);
      case 'teacher':
      case 'professor':
        return AppColors.primary;
      case 'student':
      default:
        return const Color(0xFF6366F1);
    }
  }
}

// ---------------------------------------------------
// ROLE TAG
// ---------------------------------------------------
class RoleTag extends StatelessWidget {
  final String role;
  const RoleTag({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final config = _getRoleConfig(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config['bgColor'],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _formatRole(role),
        style: TextStyle(
          color: config['textColor'],
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Map<String, Color> _getRoleConfig(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return {
          'bgColor': const Color(0xFFFEE2E2),
          'textColor': const Color(0xFFDC2626),
        };
      case 'teacher':
      case 'professor':
        return {
          'bgColor': AppColors.primary.withOpacity(0.1),
          'textColor': AppColors.primary,
        };
      case 'student':
      default:
        return {
          'bgColor': const Color(0xFFEEF2FF),
          'textColor': const Color(0xFF6366F1),
        };
    }
  }

  String _formatRole(String role) {
    final r = role.toLowerCase();
    if (r == 'professor') return 'Teacher';
    return r[0].toUpperCase() + r.substring(1);
  }
}
