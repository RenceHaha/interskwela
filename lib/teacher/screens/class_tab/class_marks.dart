import 'package:flutter/material.dart';

class MarksTab extends StatelessWidget {
  const MarksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // == ASSET NOTE ==
          // Replace this Icon with your Image.asset widget
          // Image.asset('assets/images/marks_placeholder.png', height: 150)
          Icon(
            Icons.calculate_outlined, // Placeholder icon
            size: 150,
            color: Colors.blue[200],
          ),
          const SizedBox(height: 24),
          Text(
            "Create assignment to see grades",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create assignment'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              // == DATABASE NOTE ==
              // This should probably switch to the Classwork tab
              // or open the "Create Assignment" dialog directly.
              print('Create assignment clicked');

              // Example: Switch to Classwork tab
              // DefaultTabController.of(context)?.animateTo(1);
            },
          ),
        ],
      ),
    );
  }
}