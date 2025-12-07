import 'package:flutter/material.dart';
import 'package:interskwela/models/criteria.dart';
import 'package:interskwela/models/rubric.dart';
import 'package:interskwela/widgets/forms.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RubricDialog extends StatefulWidget {
  final Rubric? existingRubric;
  final int userId;

  const RubricDialog({
    this.existingRubric,
    required this.userId,
    super.key,
  });

  @override
  State<RubricDialog> createState() => _RubricDialogState();
}

class _RubricDialogState extends State<RubricDialog> {
  final TextEditingController _nameController = TextEditingController();
  List<Criteria> _criteriaList = [];
  final List<int> _deletedCriteriaIds = []; 
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRubric != null) {
      _nameController.text = widget.existingRubric!.name;
      _criteriaList = widget.existingRubric!.criteria.map((c) => c.copyWith()).toList();
    } else {
      _addCriterion();
    }
  }

  void _addCriterion() {
    setState(() {
      _criteriaList.add(Criteria(
        criteriaTitle: '',
        points: 10.0,
        creatorId: widget.userId,
      ));
    });
  }

  void _removeCriterion(int index) {
    setState(() {
      final item = _criteriaList[index];
      if (item.criteriaId != 0) {
        _deletedCriteriaIds.add(item.criteriaId);
      }
      _criteriaList.removeAt(index);
    });
  }

  void _updateCriterion(int index, Criteria newValue) {
    setState(() {
      _criteriaList[index] = newValue;
    });
  }

  double get _totalPoints => _criteriaList.fold(0.0, (sum, item) => sum + item.points);

  String _formatNumber(double n) {
    return n.truncateToDouble() == n ? n.truncate().toString() : n.toString();
  }

  Future<void> _saveRubric() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      const String url = 'http://localhost:3000/api/rubrics';

      // CASE 1: CREATE NEW RUBRIC (Bulk Insert)
      if (widget.existingRubric == null) {
        // Prepare payload matching your API's "createRubric" function
        final List<Map<String, dynamic>> criteriasPayload = _criteriaList.map((c) => {
          'criteria_title': c.criteriaTitle,
          'criteria_description': c.criteriaDescription,
          'points': c.points,
        }).toList();

        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'action': 'create-rubric',
            'rubric_name': _nameController.text,
            'user_id': widget.userId,
            'criterias': criteriasPayload, // Send list
          }),
        );

        if (response.statusCode != 200) {
          final err = jsonDecode(response.body);
          throw Exception(err['error'] ?? "Failed to create rubric");
        }
      } 
      
      // CASE 2: EDIT EXISTING RUBRIC
      else {
        final int rubricId = widget.existingRubric!.id;

        // 1. Update Name
        await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'action': 'edit-rubric',
            'rubric_id': rubricId,
            'rubric_name': _nameController.text,
          }),
        );

        // 2. Loop through criteria
        for (var criterion in _criteriaList) {
          if (criterion.criteriaId == 0) {
            // ADD NEW row to existing rubric
            await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'action': 'add-criteria',
                'rubric_id': rubricId,
                'criteria_title': criterion.criteriaTitle,
                'criteria_description': criterion.criteriaDescription,
                'points': criterion.points,
              }),
            );
          } else {
            // EDIT existing row
             await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'action': 'edit-criteria',
                'criteria_id': criterion.criteriaId,
                'criteria_title': criterion.criteriaTitle,
                'criteria_description': criterion.criteriaDescription,
                'points': criterion.points,
              }),
            );
          }
        }

        // 3. Handle Deletions (Bulk Delete if possible, or loop)
        if (_deletedCriteriaIds.isNotEmpty) {
          await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'delete-criteria',
              'criteriaIds': _deletedCriteriaIds, // Send array as per your API
            }),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); 
      }

    } catch (e) {
      print("Error saving rubric: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingRubric == null ? "Create Rubric" : "Edit Rubric",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C3353)),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
              ],
            ),
            const Divider(),
            
            TextFormField(
              controller: _nameController,
              decoration: buildInputDecoration("Rubric Name (e.g. Essay Grading)"),
            ),
            const SizedBox(height: 16),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ..._criteriaList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final criterion = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: criterion.criteriaTitle,
                                      decoration: buildInputDecoration("Title"),
                                      onChanged: (val) => _updateCriterion(index, criterion.copyWith(criteriaTitle: val)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: _formatNumber(criterion.points),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: buildInputDecoration("Pts"),
                                      textAlign: TextAlign.center,
                                      onChanged: (val) {
                                        final newPoints = double.tryParse(val) ?? 0.0;
                                        _updateCriterion(index, criterion.copyWith(points: newPoints));
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removeCriterion(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: criterion.criteriaDescription,
                                decoration: buildInputDecoration("Description (Optional)"),
                                maxLines: 2,
                                onChanged: (val) => _updateCriterion(index, criterion.copyWith(criteriaDescription: val)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addCriterion,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Criterion"),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Points: ${_formatNumber(_totalPoints)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C3353),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _isSaving ? null : _saveRubric,
                  child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Save Rubric"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}