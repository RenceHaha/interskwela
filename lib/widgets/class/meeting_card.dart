import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:interskwela/meeting/meeting_screen.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:interskwela/models/classes.dart';

class MeetingCard extends StatelessWidget {
  final String code;
  final String username;
  final String role;
  final Classes selectedClass;

  const MeetingCard({
    required this.code,
    required this.username,
    required this.role,
    required this.selectedClass,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.video,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text('Meet'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MeetingScreen(
                        classCode: code,
                        username: username,
                        role: role,
                        selectedClass: selectedClass,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Join',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
