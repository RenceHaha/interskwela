import 'package:flutter/material.dart';
import 'package:interskwela/themes/app_theme.dart';

class TopicHeader extends StatelessWidget {
  final String topicName;
  final VoidCallback? onMorePressed;

  const TopicHeader({
    required this.topicName,
    this.onMorePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                topicName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: AppColors.primary, 
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: onMorePressed ?? () {},
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.primary),
        const SizedBox(height: 16),
      ],
    );
  }
}