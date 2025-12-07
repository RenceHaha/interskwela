import 'package:flutter/material.dart';
import 'package:interskwela/models/user.dart';
import 'package:interskwela/widgets/forms.dart';

class DropdownStudents extends StatefulWidget {
  final List<User> students;
  final List<int> selectedStudentIds;
  final List<int> initialSelectedStudentIds;
  final ValueChanged<List<int>> onChanged;

  const DropdownStudents({
    required this.students,
    required this.selectedStudentIds,
    this.initialSelectedStudentIds = const [],
    required this.onChanged,
    super.key,
  });

  @override
  State<DropdownStudents> createState() => _DropdownStudentsState();
}

class _DropdownStudentsState extends State<DropdownStudents> {
  late List<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    
    // == LOGIC: SELECT ALL BY DEFAULT ==
    // If no initial selection is passed (empty), default to ALL students.
    if (widget.initialSelectedStudentIds.isEmpty && widget.students.isNotEmpty) {
      _selectedIds = widget.students.map((s) => s.userId).toList();
      
      // Sync with parent after the first frame so parent state isn't empty
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(_selectedIds);
      });
    } else {
      _selectedIds = List.from(widget.initialSelectedStudentIds);
    }
  }

  // Handle "Select All" toggle
  void _onSelectAll(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds = widget.students.map((s) => s.userId).toList();
      } else {
        _selectedIds.clear();
      }
      widget.onChanged(_selectedIds);
    });
  }

  // Handle Individual Student toggle
  void _onItemChanged(bool? selected, int userId) {
    setState(() {
      if (selected == true) {
        _selectedIds.add(userId);
      } else {
        _selectedIds.remove(userId);
      }
      widget.onChanged(_selectedIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if every student is currently selected
    final bool isAllSelected = widget.students.isNotEmpty && 
                               _selectedIds.length == widget.students.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildSectionHeader("ASSIGN TO"),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            shape: const Border(),
            // Dynamic Title
            title: Text(
              isAllSelected 
                ? "All Students" 
                : "${_selectedIds.length} Student${_selectedIds.length != 1 ? 's' : ''} selected", 
              style: const TextStyle(fontSize: 14)
            ),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // == SELECT ALL OPTION ==
                    CheckboxListTile(
                      dense: true,
                      title: const Text("Select All", style: TextStyle(fontWeight: FontWeight.bold)),
                      value: isAllSelected,
                      onChanged: _onSelectAll,
                      activeColor: const Color(0xFF1C3353),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const Divider(height: 1),
                    
                    // == STUDENT LIST ==
                    ...widget.students.map((st) {
                      return CheckboxListTile(
                        dense: true,
                        title: Text("${st.firstname} ${st.middlename ?? ""}${st.lastname} ${st.suffix ?? ""}"),
                        value: _selectedIds.contains(st.userId),
                        onChanged: (selected) => _onItemChanged(selected, st.userId),
                        activeColor: const Color(0xFF1C3353),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}