import 'package:flutter/material.dart';
import 'package:interskwela/models/classwork.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/widgets/classwork/rubric_card.dart';
import 'package:intl/intl.dart';

class InstructionsTab extends StatelessWidget {
  final Classwork classwork;

  const InstructionsTab({required this.classwork, super.key});

  @override
  Widget build(BuildContext context) {
    // Determine icon based on type
    IconData iconData = Icons.assignment;
    if (classwork.type == 'question') iconData = Icons.help_outline;
    if (classwork.type == 'quiz') iconData = Icons.assignment_turned_in;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            classwork.title,
                            style: const TextStyle(
                              fontSize: 24,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.more_vert),
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  classwork.author_firstname +
                                  " " +
                                  classwork
                                      .author_lastname, // Replace with author name if available
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text:
                                  " • ${_formatDateFull(classwork.dateUpdated)}",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${_formatPoints(classwork.points)} points",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          if (classwork.dueDate != null)
                            Text(
                              "Due ${_formatDateFull(classwork.dueDate!)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // --- Description ---
            if (classwork.instruction != null &&
                classwork.instruction!.isNotEmpty) ...[
              Text(
                classwork.instruction!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- Rubric Pill (Mock UI) ---
            // Only show if there is actually a rubric connected (logic can be added)
            if (classwork.rubric_id != null) ...[
              RubricCard(classwork: classwork),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- Class Comments ---
            Row(
              children: const [
                Icon(Icons.people_outline, size: 20, color: Colors.black54),
                SizedBox(width: 8),
                Text(
                  "Class comments",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Add class comment...",
                              border: InputBorder.none,
                              hintStyle: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateFull(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  String _formatPoints(double? points) {
    if (points == null) return "0";
    return points.truncateToDouble() == points
        ? points.truncate().toString()
        : points.toString();
  }
}
