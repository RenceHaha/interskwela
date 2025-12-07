import 'package:flutter/material.dart';
import 'package:interskwela/models/classes.dart';
import 'package:interskwela/widgets/forms.dart';

class DropdownClasses extends StatefulWidget {
  final List<Classes> classes;
  final List<int> selectedClassIds;
  final List<int> initialSelectedClassIds;
  final ValueChanged<List<int>> onChanged;

  const DropdownClasses({
    required this.classes,
    required this.selectedClassIds,
    required this.initialSelectedClassIds,
    required this.onChanged,
    super.key,
  });

  @override
  State<DropdownClasses> createState() => _DropdownClassesState();
}

class _DropdownClassesState extends State<DropdownClasses> {
  late List<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedClassIds);
  }

  void _onItemChanged(bool? selected, int classId) {
    setState(() {
      if (selected == true) {
        _selectedIds.add(classId);
      } else {
        _selectedIds.remove(classId);
      }
      widget.onChanged(_selectedIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // const Text("Post to", style: TextStyle(fontWeight: FontWeight.w600)),
        buildSectionHeader("POST TO"),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            shape: const Border(),
            title: Text("${_selectedIds.length} Class${_selectedIds.length != 1 ? 'es' : ''} selected", style: const TextStyle(fontSize: 14)),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView(
                  shrinkWrap: true,
                  children: widget.classes.map((cls) {
                    return CheckboxListTile(
                      dense: true,
                      title: Text("${cls.subjectName} - ${cls.sectionName}"),
                      subtitle: Text(cls.classCode, style: const TextStyle(fontSize: 10)),
                      value: _selectedIds.contains(cls.classId),
                      onChanged: (selected) => _onItemChanged(selected, cls.classId),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
