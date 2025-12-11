import 'package:flutter/material.dart';
import 'package:interskwela/student/screens/classes_screen.dart';
import 'package:interskwela/teacher/screens/classes_screen.dart';
import 'package:interskwela/teacher/screens/class_screen.dart';
import 'package:interskwela/widgets/sidebar.dart';
import 'package:interskwela/models/sidebar_menu_item.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  String activeMenu = 'Dashboard';

  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    MenuItem(icon: Icons.folder_shared_outlined, label: 'Classes'),
    MenuItem(icon: Icons.archive_outlined, label: 'Archived Classes'),
  ];

  void handleMenuSelected(String menuName) {
    setState(() {
      activeMenu = menuName;
    });
  }

  Widget _getScreen() {
    switch (activeMenu) {
      case 'Classes':
        return StudentClassesScreen();
      default:
        return const Center(child: Text('Main Content Area'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            items: menuItems,
            activeMenu: activeMenu,
            onMenuSelected: handleMenuSelected,
          ),
          Expanded(child: _getScreen()),
        ],
      ),
    );
  }
}
