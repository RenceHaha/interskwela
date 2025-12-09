import 'package:flutter/material.dart';
import 'package:interskwela/models/classwork.dart';
import 'package:interskwela/teacher/screens/classworks/tabs/instructions_tab.dart';
import 'package:interskwela/teacher/screens/classworks/tabs/student_work_tab.dart';
import 'package:interskwela/themes/app_theme.dart';

class ClassworkDetailScreen extends StatefulWidget {
  final Classwork classwork;
  final int userId;

  const ClassworkDetailScreen({
    required this.classwork,
    required this.userId,
    super.key,
  });

  @override
  State<ClassworkDetailScreen> createState() => _ClassworkDetailScreenState();
}

class _ClassworkDetailScreenState extends State<ClassworkDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.classwork.title,
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "Instructions"),
            Tab(text: "Student work"),
          ],
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          InstructionsTab(classwork: widget.classwork),
          StudentWorkTab(classwork: widget.classwork),
        ],
      ),
    );
  }
}
