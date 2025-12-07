import 'package:flutter/material.dart';
import 'package:interskwela/models/rubric.dart';
import 'package:interskwela/widgets/forms.dart';
import 'package:interskwela/widgets/rubric_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DropdownRubric extends StatefulWidget {
  final List<Rubric> rubrics;
  final Rubric? selectedRubric;
  final ValueChanged<Rubric?> onChanged;
  final VoidCallback onRefreshRequired; 
  final int userId;

  const DropdownRubric({
    required this.rubrics,
    this.selectedRubric,
    required this.onChanged,
    required this.onRefreshRequired,
    required this.userId,
    super.key,
  });

  @override
  State<DropdownRubric> createState() => _DropdownRubricState();
}

class _DropdownRubricState extends State<DropdownRubric> {
  
  Future<void> _openRubricDialog({Rubric? existing}) async {
    final bool? success = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RubricDialog(
        userId: widget.userId,
        existingRubric: existing,
      ),
    );

    if (success == true) {
      widget.onRefreshRequired();
    }
  }

  Future<void> _deleteRubric(Rubric rubric) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Rubric"),
        content: Text("Are you sure you want to delete '${rubric.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/api/rubrics'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'action': 'delete-rubric',
            'rubric_id': rubric.id
          }),
        );

        if (response.statusCode == 200) {
          if (widget.selectedRubric?.id == rubric.id) {
            widget.onChanged(null); 
          }
          widget.onRefreshRequired();
        }
      } catch (e) {
        print("Error deleting rubric: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildSectionHeader("RUBRIC"),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: const Border(),
              title: Text(
                widget.selectedRubric?.name ?? "No rubric selected",
                style: TextStyle(
                  fontSize: 14,
                  color: widget.selectedRubric == null ? Colors.grey[600] : Colors.black,
                ),
              ),
              trailing: widget.selectedRubric != null 
                ? IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Color(0xFF1C3353)),
                    tooltip: "Edit selected rubric",
                    onPressed: () => _openRubricDialog(existing: widget.selectedRubric),
                  )
                : null,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        dense: true,
                        title: const Text("No rubric", style: TextStyle(color: Colors.grey)),
                        onTap: () => widget.onChanged(null),
                      ),
                      ...widget.rubrics.map((rubric) {
                        return ListTile(
                          dense: true,
                          title: Text(rubric.name),
                          subtitle: Text("${rubric.totalPoints} pts", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          onTap: () => widget.onChanged(rubric),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                                onPressed: () => _openRubricDialog(existing: rubric),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                onPressed: () => _deleteRubric(rubric),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.add, size: 18, color: Color(0xFF1C3353)),
                        title: const Text("Create new rubric", style: TextStyle(color: Color(0xFF1C3353), fontWeight: FontWeight.bold)),
                        onTap: () => _openRubricDialog(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}