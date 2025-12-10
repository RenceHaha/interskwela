import 'package:flutter/material.dart';
import 'package:interskwela/models/classwork.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:intl/intl.dart';

class ClassworkCard extends StatefulWidget {
  final Classwork classwork;
  final VoidCallback onTap;
  final String userRole; // Added to determine view mode

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

    // Icon Selection
    IconData iconData = Icons.assignment;
    if (isQuestion) iconData = Icons.help_outline;
    if (widget.classwork.type == 'quiz') iconData = Icons.assignment_turned_in;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isExpanded || _isHovering
                ? AppColors.primary.withOpacity(0.5)
                : Colors.grey.shade200,
          ),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // --- HEADER (Always Visible) ---
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(8),
                topRight: const Radius.circular(8),
                bottomLeft: Radius.circular(_isExpanded ? 0 : 8),
                bottomRight: Radius.circular(_isExpanded ? 0 : 8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Icon Circle
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isExpanded
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),

                    // Title
                    Expanded(
                      child: Text(
                        widget.classwork.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // Date / Menu
                    if (!_isExpanded) ...[
                      Text(
                        _formatDate(
                          widget.classwork.dateUpdated,
                          widget.classwork.dueDate,
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onPressed: () {}, // Add edit/delete menu logic here
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

            // --- EXPANDED BODY ---
            if (_isExpanded)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side: Instructions
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Posted ${_formatDateFull(widget.classwork.dateUpdated)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.classwork.instruction ??
                                      "No instructions",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // --- SHOW STATS ONLY FOR TEACHER/ADMIN ---
                          if (widget.userRole == 'teacher' ||
                              widget.userRole == 'admin') ...[
                            // Divider
                            Container(
                              height: 60,
                              width: 1,
                              color: Colors.grey.shade300,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                            ),

                            // Right side: Counters
                            _buildStatCounter("0", "Handed in"),
                            Container(
                              height: 60,
                              width: 1,
                              color: Colors.grey.shade300,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                            ),
                            _buildStatCounter("0", "Assigned"),
                          ],
                        ],
                      ),
                    ),

                    // Footer Button (View Instructions)
                    const Divider(height: 1),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: TextButton(
                          onPressed: widget.onTap, // Go to full details page
                          child: Text(
                            isQuestion ? "View question" : "View instructions",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
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
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
