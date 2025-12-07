// lib/widgets/class_card.dart

import 'package:flutter/material.dart';
// import '../theme/app_colors.dart'; // No longer needed for this widget
// import 'dart:ui'; // No longer needed for BackdropFilter

class ClassCard extends StatelessWidget {
  final String? bannerUrl; // Optional: for a network image
  final Color? bannerPlaceholderColor; // Optional: for a solid color
  final String classCode;
  final String description;
  final String subjectCode;
  final String subjectName;
  final String sectionName;
  final String teacherName;
  final int classId;

  const ClassCard({
    required this.teacherName,
    required this.subjectCode,
    required this.subjectName,
    required this.sectionName,
    required this.description,
    required this.classId,
    required this.classCode,
    this.bannerUrl,
    this.bannerPlaceholderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Ensures content respects the border radius
      child: Container(
        width: 300,
        // height: 180, // Remove fixed height for more flexible content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Image/Color that fills the entire width
            Container(
              height: 120, // Height for the image/color part
              decoration: BoxDecoration(
                // Use a DecorationImage if 'image' is a path to an actual image
                image: DecorationImage(
                  image: NetworkImage(bannerUrl ?? 'http://localhost:3000/banner/banner_default.jpg'),
                  fit: BoxFit.cover, // Ensure it covers the area
                ),
                // If 'image' path were actually a solid color or you wanted a fallback,
                // you might also use 'color' here, but DecorationImage is better for your case.
                // For example, if image was 'assets/images/bg_pattern_pink.png',
                // it would look like a solid pink block because the pattern is subtle.
              ),
            ),
            
            // Bottom Section: Text and Badge
            Padding(
              padding: const EdgeInsets.all(16.0), // Padding for the content below the image
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center, // Vertically align items in the row
                children: [
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$subjectCode - $subjectName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$sectionName | $teacherName',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
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
}