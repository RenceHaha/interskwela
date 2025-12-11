import 'package:flutter/material.dart';
import 'package:interskwela/themes/app_theme.dart';

class MarksTab extends StatelessWidget {
  const MarksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                "Create assignment to see grades",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                "Grades will appear here once students submit their work",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Button
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create assignment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // Switch to Classwork tab
                  DefaultTabController.of(context).animateTo(1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
