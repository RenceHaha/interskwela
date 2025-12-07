import 'package:flutter/material.dart';
import 'package:interskwela/widgets/forms.dart';

/// Simple model for dropdown options
class DropdownOption {
  final int id;
  final String label;
  final String? subtitle;

  const DropdownOption({
    required this.id,
    required this.label,
    this.subtitle,
  });
}

class SingleSelectDropdown extends StatelessWidget {
  final String label; // e.g., "POST TO"
  final List<DropdownOption> options;
  final int? selectedValue;
  final ValueChanged<int?> onChanged;
  final String? hintText;

  const SingleSelectDropdown({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.hintText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          buildSectionHeader(label),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedValue,
              isExpanded: true,
              hint: Text(hintText ?? "Select option", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: options.map((opt) {
                return DropdownMenuItem<int>(
                  value: opt.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        opt.label,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (opt.subtitle != null)
                        Text(
                          opt.subtitle!,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}