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
    IconData iconData = Icons.assignment_outlined;
    if (classwork.type == 'question') iconData = Icons.help_outline_rounded;
    if (classwork.type == 'quiz') iconData = Icons.quiz_outlined;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
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
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              classwork.title,
                              style: const TextStyle(
                                fontSize: 22,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.more_horiz,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            "${classwork.author_firstname} ${classwork.author_lastname}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            " • ${_formatDateFull(classwork.dateUpdated)}",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.star_outline,
                            "${_formatPoints(classwork.points)} points",
                          ),
                          if (classwork.dueDate != null) ...[
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              Icons.schedule_outlined,
                              "Due ${_formatDateFull(classwork.dueDate!)}",
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 20),

            // --- Description ---
            if (classwork.instruction != null &&
                classwork.instruction!.isNotEmpty) ...[
              Text(
                classwork.instruction!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- Rubric ---
            if (classwork.rubric_id != null) ...[
              RubricCard(classwork: classwork),
              const SizedBox(height: 24),
            ],

            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 20),

            // --- Class Comments ---
            Row(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                const Text(
                  "Class comments",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDim,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Add class comment...",
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
