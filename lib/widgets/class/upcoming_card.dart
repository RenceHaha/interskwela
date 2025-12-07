import 'package:flutter/material.dart';
class UpcomingCard extends StatelessWidget {
  const UpcomingCard({super.key});

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
            const Text('Upcoming', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Not work due in soon',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}