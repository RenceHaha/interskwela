import 'package:flutter/material.dart';
import 'package:interskwela/models/classwork.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:open_file/open_file.dart'; // Import open_file
import 'package:http/http.dart' as http; // Added for API calls
import 'dart:convert';

class StudentClassworkDetailScreen extends StatefulWidget {
  final Classwork classwork;
  final int userId;

  const StudentClassworkDetailScreen({
    required this.classwork,
    required this.userId,
    super.key,
  });

  @override
  State<StudentClassworkDetailScreen> createState() => _StudentClassworkDetailScreenState();
}

class _StudentClassworkDetailScreenState extends State<StudentClassworkDetailScreen> {
  // Mock State for "Your Work"
  bool _isSubmitted = false;
  bool _isSubmitting = false; // Loading state for submission
  List<PlatformFile> _myFiles = []; 

  // --- ACTIONS ---

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any, 
      );

      if (result != null) {
        setState(() {
          _myFiles.addAll(result.files);
        });
      }
    } catch (e) {
      print("Error picking files: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to pick files")),
      );
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _myFiles.remove(file);
    });
  }

  Future<void> _openFile(PlatformFile file) async {
    if (file.path != null) {
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open file: ${result.message}")),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot open file (no path available)")),
      );
    }
  }

  Future<void> _submitWork() async {
    setState(() => _isSubmitting = true);

    try {
      // TODO: Replace with actual API call to 'submit-work'
      // Example payload: 
      // { 
      //   action: 'submit-work', 
      //   user_id: widget.userId, 
      //   class_work_id: widget.classwork.id, 
      //   files: _myFiles (need to convert to base64) 
      // }
      
      // Simulating network request
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isSubmitted = true;
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Work submitted successfully!")),
        );
      }
    } catch (e) {
      print("Error submitting work: $e");
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit work")),
        );
      }
    }
  }

  Future<void> _unsubmitWork() async {
    setState(() => _isSubmitting = true);
    // Simulating unsubmit network request
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isSubmitted = false;
        _isSubmitting = false;
      });
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            _buildClassworkIcon(),
            const SizedBox(width: 12),
            Text(
              widget.classwork.type == 'question' ? 'Question' : 'Assignment',
              style: const TextStyle(color: Colors.black87, fontSize: 18),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          
          final mainContent = _buildMainContent();
          final sidebar = _buildSidebar();

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: mainContent,
                  ),
                ),
                Container(
                  width: 360,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: sidebar,
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  mainContent,
                  const Divider(height: 40, thickness: 1),
                  sidebar,
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildClassworkIcon() {
    IconData iconData = Icons.assignment;
    Color color = Colors.grey.shade700;
    
    if (widget.classwork.type == 'question') iconData = Icons.help_outline;
    if (widget.classwork.type == 'quiz') iconData = Icons.assignment_turned_in;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.classwork.title,
          style: const TextStyle(
            fontSize: 32,
            color: AppColors.primary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black54, fontSize: 14),
            children: [
              const TextSpan(
                text: "Teacher Name", 
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              TextSpan(text: " • ${_formatDateFull(widget.classwork.dateUpdated)}"),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${_formatPoints(widget.classwork.points)} points",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            if (widget.classwork.dueDate != null)
              Text(
                "Due ${_formatDateFull(widget.classwork.dueDate!)}",
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        if (widget.classwork.instruction != null)
          Text(
            widget.classwork.instruction!,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
          ),
        
        const SizedBox(height: 40),
        const Divider(),
        const SizedBox(height: 24),

        Row(
          children: const [
            Icon(Icons.people_outline, size: 20, color: Colors.black54),
            SizedBox(width: 12),
            Text("Class comments", style: TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_comment_outlined, size: 18),
          label: const Text("Add comment"),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    // Determine button text based on state and attachments
    String submitButtonText;
    if (_isSubmitted) {
      submitButtonText = "Unsubmit";
    } else {
      submitButtonText = _myFiles.isNotEmpty ? "Hand in" : "Mark as Done";
    }

    return Column(
      children: [
        // "Your work" Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Your work", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
                  Text(
                    _isSubmitted ? "Handed in" : "Assigned",
                    style: TextStyle(
                      fontSize: 12, 
                      color: _isSubmitted ? Colors.black54 : Colors.green, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // --- FILE LIST ---
              if (_myFiles.isNotEmpty)
                ..._myFiles.map((file) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => _openFile(file), // CLICK TO OPEN FILE
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file.name, 
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(decoration: TextDecoration.underline),
                            )
                          ),
                          // Only show delete button if not yet submitted
                          if (!_isSubmitted)
                            InkWell(
                              onTap: () => _removeFile(file),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.close, size: 16, color: Colors.grey),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                )),

              if (!_isSubmitted) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickFiles, // OPEN FILE PICKER
                    icon: const Icon(Icons.add),
                    label: const Text("Add or create"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting 
                    ? null 
                    : (_isSubmitted ? _unsubmitWork : _submitWork),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSubmitted ? Colors.white : AppColors.primary,
                    foregroundColor: _isSubmitted ? Colors.black87 : Colors.white,
                    elevation: 0,
                    side: _isSubmitted ? BorderSide(color: Colors.grey.shade300) : null,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ) 
                    : Text(submitButtonText),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // "Private comments" Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.person_outline, size: 18, color: Colors.black54),
                  SizedBox(width: 8),
                  Text("Private comments", style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  alignment: Alignment.centerLeft,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text("Add comment to Teacher", style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateFull(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  String _formatPoints(double? points) {
    if (points == null) return "0";
    return points.truncateToDouble() == points ? points.truncate().toString() : points.toString();
  }
}