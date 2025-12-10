import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:interskwela/meeting/meeting_screen.dart';

class MeetingCard extends StatelessWidget {
  final String code;
  final String username;
  final String role;

  const MeetingCard({
    required this.code,
    required this.username,
    required this.role,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Class code', style: TextStyle(color: Colors.grey)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.video),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeetingScreen(
                          classCode: code,
                          username: username,
                          role: role,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
