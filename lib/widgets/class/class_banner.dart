import 'package:flutter/material.dart';
import 'package:interskwela/models/classes.dart';

class ClassHeaderBanner extends StatelessWidget {
  final Classes classInfo;
  const ClassHeaderBanner({
    required this.classInfo,
    super.key
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        image: DecorationImage(
          // image: AssetImage(classInfo.image),
          image: NetworkImage( classInfo.bannerUrl != null ? 'http://localhost:3000/${classInfo.bannerUrl}'  : 'http://localhost:3000/banner/banner_default.jpg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${classInfo.subjectCode } - ${classInfo.subjectName}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            classInfo.sectionName,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}