import 'package:flutter/material.dart';
import 'package:interskwela/models/user.dart';
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
  final List<Tab> _tabs = [
    const Tab(text: 'All'),
    const Tab(text: 'Students'),
    const Tab(text: 'Professors'), // Keep 'Professors' for internal logic
    const Tab(text: 'Admin'),
  ];
  // A separate list for display if you want 'Teachers' instead of 'Professors' in the UI
  final List<String> _tabTitles = [
    'All',
    'Students',
    'Teachers', // Display 'Teachers'
    'Admin',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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

  Widget _buildSearchBar() {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 12), child: Icon(Icons.search, color: Colors.grey[600], size: 20,)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        ),
        style: TextStyle(
          fontSize: 12,
        ),
      ),
    );
  }

  Future<List<User>> _fetchUsers() async {
    const String url = 'http://localhost:3000/api/accounts';
    try {
      final response = await http
          .get(Uri.parse(url), headers: <String, String>{
        'Content-Type': 'application/json'
      });
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception('Failed to load users: ${responseData['error']}');
      }
    } catch (e) {
      print('Error during api call $e');
      throw Exception('An error occurred: Could not connect to the server.');
    }
  }

  List<User> _getFilteredUsers(List<User> allUsers) {
    // Use _tabTitles for display, but map back to internal role names for logic
    final String selectedTabTitle = _tabTitles[_tabController.index].toLowerCase();
    String selectedRoleFilter;

    switch (selectedTabTitle) {
      case 'students':
        selectedRoleFilter = 'student';
        break;
      case 'teachers': // Map 'Teachers' display to 'professor' for filtering
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
      if (selectedRoleFilter == 'all') {
        return true;
      }
      // Handle 'professor' and 'teacher' interchangeably for the 'Teachers' tab
      if (selectedRoleFilter == 'professor' && (role == 'professor' || role == 'teacher')) {
        return true;
      }
      return role == selectedRoleFilter;
    }).toList();

    if (_searchQuery.isEmpty) {
      return tabFilteredUsers;
    }

    final query = _searchQuery.toLowerCase();
    return tabFilteredUsers.where((user) {
      final fullname =
          '${user.firstname} ${user.lastname}'.toLowerCase();
      final email = user.email.toLowerCase();
      return fullname.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        height: 48, // Slightly taller for the pill effect
                        decoration: BoxDecoration(
                          color: Colors.grey[200], // Light grey background for the overall pill
                          borderRadius: BorderRadius.circular(25), // Rounded corners
                        ),
                        child: TabBar(
                          controller: _tabController,
                          // Use _tabTitles for displaying tab names
                          padding: EdgeInsets.all(4),
                          labelPadding: EdgeInsets.zero,
                          tabAlignment: TabAlignment.start,
                          tabs: _tabTitles.map((title) {
                            return Tab(
                              child: Container(
                                width: 80, // <-- SET YOUR FIXED WIDTH HERE
                                alignment: Alignment.center,
                                child: Text(title),
                              ),
                            );
                          }).toList(),
                          isScrollable: true,
                          dividerColor: Colors.transparent,
                          // Custom indicator
                          indicator: BoxDecoration(
                            color: Color(0xFF1C3353), // Darker background for the selected tab
                            borderRadius: BorderRadius.circular(25), // Rounded corners for the indicator
                          ),
                          indicatorSize: TabBarIndicatorSize.tab, // Make indicator fill the tab space
                          
                          // Label styles
                          labelColor: Colors.white, // Text color for selected tab
                          unselectedLabelColor: Colors.grey[800], // Text color for unselected tabs
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // --- MODIFIED TAB BAR CONTAINER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                    ]
                  ),

                  Expanded(
                    child: FutureBuilder<List<User>>(
                      future: _users,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No users found.'));
                        }

                        final allUsers = snapshot.data!;
                        final filteredUsers = _getFilteredUsers(allUsers);
                        
                        final String tabText = _tabTitles[_tabController.index];


                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$tabText (${filteredUsers.length})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                _buildSearchBar(),
                              ],
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: ListView.separated(
                                itemCount: filteredUsers.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  // --- THIS IS WHERE THE ERROR WAS ---
                                  // Now UserListItem is defined below
                                  return UserListItem(user: user);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AccountFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      )
    );
  }
}

// ---------------------------------------------------
// HELPER WIDGETS
// (These are now included in the same file)
// ---------------------------------------------------

// --- WIDGET FOR THE USER CARD ---
class UserListItem extends StatelessWidget {
  final User user; // This uses your User model

  const UserListItem({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Assumes your User model has:
    // user.firstname, user.lastname, user.middlename
    // user.email (String)
    // user.role (String)

    final String initial = (user.lastname != null && user.lastname!.isNotEmpty)
        ? user.lastname![0].toUpperCase()
        : '?';
    final String fullName =
        '${user.lastname}, ${user.firstname} ${user.middlename ?? ''}';

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          // --- 1. Avatar ---
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFE0E7FF),
            child: Text(
              initial,
              style: TextStyle(
                color: Color(0xFF4338CA),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // --- 2. Title (Name + Role) ---
          title: Wrap(
            // Use Wrap to prevent overflow on small screens
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                fullName, // Use field from your model
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              RoleTag(role: user.role), // Use field from your model
            ],
          ),

          // --- 3. Subtitle (Email + Joined Date) ---
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(user.email,
                  style: TextStyle(color: Colors.grey[600])), // Use field
              SizedBox(height: 2),
            ],
          ),

          // --- 4. Trailing Icons ---
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.grey[700]),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET FOR THE ROLE TAG ---
class RoleTag extends StatelessWidget {
  final String role;
  const RoleTag({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    double borderRadius = 5.0; // Default

    switch (role.toLowerCase()) { // Use toLowerCase for consistency
      case 'admin':
        bgColor = Color(0xFFD4183D);
        textColor = Colors.white;
        break;
      case 'teacher':
      case 'professor': // Added 'professor' as an alias
        bgColor = Color(0xFF1F2937);
        textColor = Colors.white;
        break;
      case 'student':
      default:
        bgColor = Color(0xFFECEEF2);
        textColor = Colors.black;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}