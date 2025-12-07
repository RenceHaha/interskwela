import 'package:flutter/material.dart';
import 'package:interskwela/widgets/dashboard_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      color: Color(0XFFF6F8FA),
      child: 
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Overview", style: TextStyle(fontSize: 20),),
          Expanded(
            child: Wrap(
              spacing: 24,
              children: [
                DashboardCard(label: 'Total Users', icon: Icons.people, value: 2),
                DashboardCard(label: 'Total Users', icon: Icons.people, value: 2),
                DashboardCard(label: 'Total Users', icon: Icons.people, value: 2),
                DashboardCard(label: 'Total Users', icon: Icons.people, value: 2),
              ],
            ),
          ),

          
        ],
      ),
    );
  }
}