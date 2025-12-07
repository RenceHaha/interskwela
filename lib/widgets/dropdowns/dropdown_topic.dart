import 'package:flutter/material.dart';
import 'package:interskwela/widgets/forms.dart';
import 'package:interskwela/models/topic.dart';

class DropdownTopic extends StatefulWidget {
  final List<Topic> topics;
  final Topic? selectedTopic;
  final ValueChanged<Topic?> onChanged;
  final ValueChanged<String>? onAddTopic; // New Callback

  const DropdownTopic({
    required this.topics,
    this.selectedTopic,
    required this.onChanged,
    this.onAddTopic, // Optional
    super.key,
  });

  @override
  State<DropdownTopic> createState() => _DropdownTopicState();
}

class _DropdownTopicState extends State<DropdownTopic> {
  
  void _handleSelection(int? topicId) {
    if (topicId == null) {
      widget.onChanged(null);
    } else {
      final selected = widget.topics.firstWhere(
        (t) => t.topicId == topicId,
        orElse: () => widget.topics.first,
      );
      widget.onChanged(selected);
    }
  }

  // Shows a dialog to type the new topic name
  Future<void> _showAddTopicDialog() async {
    String newTopicName = "";
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Topic", style: TextStyle(color: Color(0xFF1C3353))),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Enter topic name",
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => newTopicName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C3353),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (newTopicName.trim().isNotEmpty) {
                  widget.onAddTopic?.call(newTopicName.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  // Custom Radio Item to avoid deprecation issues
  Widget _buildRadioItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF1C3353) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.black : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? currentSelectedId = widget.selectedTopic?.topicId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildSectionHeader("TOPIC"),
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
                widget.selectedTopic?.topicName ?? "No topic", 
                style: TextStyle(
                  fontSize: 14, 
                  color: widget.selectedTopic == null ? Colors.grey[600] : Colors.black
                )
              ),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Option to clear topic
                      _buildRadioItem(
                        label: "No topic",
                        isSelected: currentSelectedId == null,
                        onTap: () => _handleSelection(null),
                      ),
                      
                      // List of available topics
                      ...widget.topics.map((topic) {
                        return _buildRadioItem(
                          label: topic.topicName,
                          isSelected: currentSelectedId == topic.topicId,
                          onTap: () => _handleSelection(topic.topicId),
                        );
                      }),

                      // Add Topic Button (Only if callback is provided)
                      if (widget.onAddTopic != null) ...[
                        const Divider(height: 1),
                        InkWell(
                          onTap: _showAddTopicDialog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(Icons.add, color: Color(0xFF1C3353), size: 20),
                                SizedBox(width: 12),
                                Text(
                                  "Create new topic",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1C3353),
                                    fontSize: 14
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]
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