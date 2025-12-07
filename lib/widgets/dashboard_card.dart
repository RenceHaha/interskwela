import 'package:flutter/material.dart';

class DashboardCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final int value;

  const DashboardCard({
    required this.label,
    required this.icon,
    required this.value,
    super.key
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            children: [
              Text(widget.label),
              Icon(widget.icon),
            ],
          ),
          Text(widget.value.toString()),
        ],
      )
    );
  }
}