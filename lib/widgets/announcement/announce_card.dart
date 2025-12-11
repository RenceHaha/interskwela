import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:interskwela/themes/app_theme.dart';

class AnnounceCard extends StatefulWidget {
  final Function(String, List<PlatformFile>) onPost;
  final Function(String, List<PlatformFile>) onSettingsPress;

  const AnnounceCard({
    required this.onPost,
    required this.onSettingsPress,
    super.key,
  });

  @override
  State<AnnounceCard> createState() => AnnounceCardState();
}

class AnnounceCardState extends State<AnnounceCard> {
  bool _isExpanded = false;
  final TextEditingController _announceController = TextEditingController();
  List<PlatformFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  Widget _buildCollapsed() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = true;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Announce something to your class...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Input Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _announceController,
              autofocus: true,
              maxLines: 4,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceDim,
                hintText: 'Announce something to your class...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),

          // Attachments
          if (_selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedFiles.map((file) {
                  return _buildFileChip(file);
                }).toList(),
              ),
            ),

          // Actions Bar
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file_rounded, size: 20),
                  tooltip: "Attach files",
                  color: AppColors.textSecondary,
                  splashRadius: 20,
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.link_rounded, size: 20),
                  tooltip: "Attach links",
                  color: AppColors.textSecondary,
                  splashRadius: 20,
                ),
                IconButton(
                  onPressed: () {
                    widget.onSettingsPress(
                      _announceController.text,
                      List.from(_selectedFiles),
                    );
                  },
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  tooltip: "Announcement settings",
                  color: AppColors.textSecondary,
                  splashRadius: 20,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = false;
                      _announceController.clear();
                      _selectedFiles.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_announceController.text.isNotEmpty ||
                        _selectedFiles.isNotEmpty) {
                      widget.onPost(
                        _announceController.text,
                        List.from(_selectedFiles),
                      );

                      setState(() {
                        _isExpanded = false;
                        _announceController.clear();
                        _selectedFiles.clear();
                      });
                    }
                  },
                  child: const Text('Post'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileChip(PlatformFile file) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              file.name,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _removeFile(file),
            child: Icon(Icons.close, size: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: _buildCollapsed(),
      secondChild: _buildExpanded(),
      crossFadeState: _isExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }
}
