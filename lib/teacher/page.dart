import 'package:flutter/material.dart';
import 'package:interskwela/teacher/screens/classes_screen.dart';
import 'package:interskwela/teacher/screens/class_screen.dart';
import 'package:interskwela/widgets/sidebar.dart';
import 'package:interskwela/models/sidebar_menu_item.dart';

class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key});

  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  String activeMenu = 'Dashboard';

  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    MenuItem(icon: Icons.folder_shared_outlined, label: 'Classes'),
    MenuItem(icon: Icons.folder_outlined, label: 'To Review'),
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
        return TeacherClassessScreen();
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
