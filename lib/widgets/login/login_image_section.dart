import 'package:flutter/material.dart';

class ImageSection extends StatelessWidget {

  const ImageSection({super.key});
  
  @override
  Widget build(BuildContext context) {
    // 1. Expanded must be the direct child of the Row (which is the parent of this widget)
    return Expanded(
      flex: 4, 
      child: Padding( // 2. Apply Padding inside the Expanded widget
        padding: const EdgeInsets.all(12),
        child: Container(
          // The background color/gradient around the main login box
          decoration: BoxDecoration(
            // This is a placeholder for the pink/purple gradient shown in the image background
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient( // Added 'const' for efficiency
              colors: [Color(0xFFF9A8D4), Color(0xFF6366F1)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }
}