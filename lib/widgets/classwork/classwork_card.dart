import 'package:flutter/material.dart';
import 'package:interskwela/models/classwork.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:intl/intl.dart';

class ClassworkCard extends StatefulWidget {
  final Classwork classwork;
  final VoidCallback onTap;
  final String userRole;

  const ClassworkCard({
    required this.classwork,
    required this.onTap,
    required this.userRole,
    super.key,
  });

  @override
  State<ClassworkCard> createState() => _ClassworkCardState();
}

class _ClassworkCardState extends State<ClassworkCard> {
  bool _isHovering = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isAssignment =
        widget.classwork.type == 'assignment' ||
        widget.classwork.type == 'quiz';
    final isQuestion = widget.classwork.type == 'question';

    IconData iconData = Icons.assignment_outlined;
    if (isQuestion) iconData = Icons.help_outline_rounded;
    if (widget.classwork.type == 'quiz') iconData = Icons.quiz_outlined;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isExpanded
                ? AppColors.primary.withOpacity(0.4)
                : (_isHovering ? Colors.grey.shade300 : Colors.grey.shade200),
          ),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // --- HEADER ---
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(_isExpanded ? 0 : 12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isExpanded
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: _isExpanded ? Colors.white : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.classwork.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (!_isExpanded) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(
                                  widget.classwork.dateUpdated,
                                  widget.classwork.dueDate,
                                ),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Menu
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
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- EXPANDED BODY ---
            if (_isExpanded)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    Divider(height: 1, color: Colors.grey.shade200),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Instructions Preview
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Posted ${_formatDateFull(widget.classwork.dateUpdated)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.classwork.instruction ??
                                      "No instructions",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Stats (Teacher/Admin only)
                          if (widget.userRole == 'teacher' ||
                              widget.userRole == 'admin') ...[
                            Container(
                              height: 50,
                              width: 1,
                              color: Colors.grey.shade300,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                            _buildStatCounter("0", "Handed in"),
                            Container(
                              height: 50,
                              width: 1,
                              color: Colors.grey.shade300,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                            _buildStatCounter("0", "Assigned"),
                          ],
                        ],
                      ),
                    ),

                    // Footer
                    Divider(height: 1, color: Colors.grey.shade200),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: widget.onTap,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              isQuestion
                                  ? "View question"
                                  : "View instructions",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCounter(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _formatDate(DateTime created, DateTime? due) {
    if (due != null) {
      return "Due ${DateFormat('d MMM').format(due)}";
    }
    return "Posted ${DateFormat('d MMM').format(created)}";
  }

  String _formatDateFull(DateTime date) {
    return DateFormat('d MMM').format(date);
  }
}
