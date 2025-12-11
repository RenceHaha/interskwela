import 'package:flutter/material.dart';
import 'package:interskwela/themes/app_theme.dart';

class TopicHeader extends StatelessWidget {
  final String topicName;
  final VoidCallback? onMorePressed;

  const TopicHeader({required this.topicName, this.onMorePressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topicName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (onMorePressed != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onMorePressed,
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
          const SizedBox(height: 8),
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
