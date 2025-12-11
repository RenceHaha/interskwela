import 'package:flutter/material.dart';
import 'package:interskwela/models/classes.dart';
import 'package:interskwela/teacher/screens/class_tab/class_marks.dart';
import 'package:interskwela/teacher/screens/class_tab/class_stream_tab.dart';
import 'package:interskwela/teacher/screens/class_tab/class_people_tab.dart';
import 'package:interskwela/teacher/screens/class_tab/class_work_tab.dart';

class AdminClassScreen extends StatefulWidget {
  final Classes specificCLass;
  final int userId;
  final String username;

  const AdminClassScreen({
    required this.specificCLass,
    required this.userId,
    required this.username,
    super.key,
  });

  @override
  State<AdminClassScreen> createState() => _AdminClassScreenState();
}

class _AdminClassScreenState extends State<AdminClassScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.specificCLass.subjectCode} - ${widget.specificCLass.sectionName}',
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Stream'),
              Tab(text: 'Classwork'),
              Tab(text: 'People'),
              Tab(text: 'Marks'),
            ],
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: The logic is now encapsulated here
            ClassStreamTab(
              specificClass: widget.specificCLass,
              userId: widget.userId,
              username: widget.username,
            ),

            // TAB 2: Classwork (Create a separate file for this later)
            ClassworkTab(
              currentClass: widget.specificCLass,
              userId: widget.userId,
            ),

            // TAB 3: People
            PeopleTab(specificClass: widget.specificCLass),

            // TAB 4: Marks
            MarksTab(),
          ],
        ),
      ),
    );
  }
}
