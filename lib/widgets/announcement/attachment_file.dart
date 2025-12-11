import 'package:flutter/material.dart';
import 'package:interskwela/themes/app_theme.dart';

class AttachmentFile extends StatelessWidget {
  final String fileName;
  final Function() onDelete;

  const AttachmentFile({
    required this.fileName,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
            color: Colors.grey[400],
            onPressed: () => onDelete(),
          ),
        ],
      ),
    );
  }
}
