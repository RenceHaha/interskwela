import 'package:flutter/material.dart';
import 'package:interskwela/admin/screens/dashboard_screen.dart';
import 'package:interskwela/admin/screens/sections_screen.dart';
// import 'sidebar.dart';
import 'screens/classes_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/subjects_screen.dart';
import 'package:interskwela/models/sidebar_menu_item.dart';
import 'package:interskwela/widgets/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String activeMenu = 'Dashboard';

  int? userId;

  final List<MenuItem> menuItems = const [
    MenuItem(icon: Icons.dashboard, label: 'Dashboard'),
    MenuItem(icon: Icons.menu_book, label: 'Sections'),
    MenuItem(icon: Icons.abc_rounded, label: 'Classes'),
    MenuItem(icon: Icons.abc_rounded, label: 'Subjects'),
    MenuItem(icon: Icons.people, label: 'Accounts'),
  ];

  @override
  void initState(){
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState((){
      userId = prefs.getInt('userId');
    });

    print("User id logged in: $userId");
  }

  void handleMenuSelected(String menuName) {
    setState(() {
      activeMenu = menuName;
    });
  }

  Widget _getScreen() {
    switch (activeMenu) {
      case 'Dashboard':
        return DashboardScreen();
      case 'Classes':
        return AdminClassesScreen();
      case 'Accounts':
        return AccountsScreen();
      case 'Sections':
        return SectionsScreen();
      case 'Subjects':
        return SubjectsScreen();
      default:
        return const Center(child: Text('Main Content Area'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // AdminSidebar(
          //   activeMenu: activeMenu,
          //   onMenuSelected: handleMenuSelected,
          // ),
          Sidebar(
            items: menuItems, 
            activeMenu: activeMenu, 
            onMenuSelected: handleMenuSelected
          ),
          Expanded(child: _getScreen()),
        ],
      ),
    );
  }
}