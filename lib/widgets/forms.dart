import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Shared Input Decoration ---
// This is moved out as a top-level function or a static method
// as it doesn't need to be part of a widget class.
InputDecoration buildInputDecoration(
  String hintText, {
  Widget? suffixIcon,
  bool enabled = true,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: Colors.grey[500]),
    filled: true,
    fillColor: enabled ? Colors.white : Colors.grey[200],
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.blue, width: 2.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.red, width: 1.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.red, width: 2.0),
    ),
  );
}

// --- Reusable Section Header Widget ---
// Can be a simple function or a StatelessWidget
Widget buildSectionHeader(String title) {
  return Text(
    title,
    style: TextStyle(
      color: Colors.grey[700],
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 0.8,
    ),
  );
}

// --- Reusable Text Form Field Widget ---
// This is a StatelessWidget that takes all necessary properties.
class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.minLines,
    this.maxLines = 1,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final int? minLines;
  final int? maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    // Use multiline keyboard if maxLines is null (unlimited) or > 1
    final isMultiline = maxLines == null || (maxLines != null && maxLines! > 1);

    return TextFormField(
      controller: controller,
      keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
      textInputAction: isMultiline
          ? TextInputAction.newline
          : TextInputAction.next,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,

      style: TextStyle(color: readOnly ? Colors.grey[600] : Colors.black),

      decoration: buildInputDecoration(
        hintText,
        enabled: !readOnly,
      ), // Use the shared function
      validator: (value) {
        if (value == null || value.isEmpty) {
          // Allow optional fields
          if (hintText.contains('(Optional)')) {
            return null;
          }
          return '$hintText is required';
        }
        return null;
      },
    );
  }
}

// --- Reusable Dropdown Form Field Widget ---
class CustomRoleDropdownFormField extends StatelessWidget {
  const CustomRoleDropdownFormField({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
  });

  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedItem,
      decoration: buildInputDecoration('Role'),
      items: items.map((String role) {
        return DropdownMenuItem<String>(value: role, child: Text(role));
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a role';
        }
        return null;
      },
    );
  }
}

class CustomDatePickerFormField extends StatelessWidget {
  const CustomDatePickerFormField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true, // Prevents keyboard from opening
      decoration: buildInputDecoration(
        hintText,
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900), // Adjust as needed
          lastDate: DateTime(2100), // Adjust as needed
        );

        if (pickedDate != null) {
          // Format the date (e.g., 2025-11-23)
          String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
          controller.text = formattedDate; // Update the controller
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (hintText.contains('(Optional)')) {
            return null;
          }
          return '$hintText is required';
        }
        return null;
      },
    );
  }
}
