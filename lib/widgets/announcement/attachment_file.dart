import 'package:flutter/material.dart';

class AttachmentFile extends StatefulWidget {

  final String fileName;
  final Function() onDelete; 

  const AttachmentFile({
    required this.fileName,
    required this.onDelete,
    super.key
  });

  @override
  State<AttachmentFile> createState() => _AttachmentFileState();
}

class _AttachmentFileState extends State<AttachmentFile> {
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        widget.fileName,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: widget.onDelete,
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}