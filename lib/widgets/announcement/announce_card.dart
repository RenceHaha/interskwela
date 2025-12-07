import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:interskwela/widgets/announcement/attachment_file.dart';

class AnnounceCard extends StatefulWidget {
  final Function(String, List<PlatformFile>) onPost; 
  final Function(String, List<PlatformFile>) onSettingsPress; 

  const AnnounceCard({
    required this.onPost,
    required this.onSettingsPress,
    super.key
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = true;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF1C3353),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Announce something to your class',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _announceController,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Announce Something to your class',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedFiles.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedFiles.map((file) {
                  return AttachmentFile(fileName: file.name, onDelete: () => _removeFile(file));
                }).toList(),
              ),

            const SizedBox(height: 16),
            Row(
              children: [
                
                IconButton(
                  onPressed: _pickFiles, 
                  icon: const Icon(Icons.attach_file),
                  tooltip: "Attach files",
                ),
                
                
                IconButton(
                  onPressed: () {}, 
                  icon: const Icon(Icons.link),
                  tooltip: "Attach links",
                ),

                IconButton(
                  onPressed: () {
                    // Pass copy of files
                    widget.onSettingsPress(_announceController.text, List.from(_selectedFiles));
                  }, 
                  icon: const Icon(Icons.display_settings),
                  tooltip: "Announcement settings",
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
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C3353),
                    foregroundColor: Colors.white
                  ),
                  onPressed: () {
                    if (_announceController.text.isNotEmpty || _selectedFiles.isNotEmpty) {
                      // == FIX: Pass a COPY of the list using List.from() ==
                      widget.onPost(_announceController.text, List.from(_selectedFiles));
                      
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: _buildCollapsed(),
      secondChild: _buildExpanded(),
      crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }
}