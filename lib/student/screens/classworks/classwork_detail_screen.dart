import 'package:flutter/material.dart';
import 'package:interskwela/models/classwork.dart';
import 'package:interskwela/teacher/screens/classworks/tabs/instructions_tab.dart';
import 'package:interskwela/themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SubmittedFile {
  final int attachmentId;
  final String filePath;
  final String fileName;

  SubmittedFile({
    required this.attachmentId,
    required this.filePath,
    required this.fileName,
  });

  factory SubmittedFile.fromJson(Map<String, dynamic> json) {
    return SubmittedFile(
      attachmentId: json['attachment_id'],
      filePath: json['file_path'],
      fileName: json['file_name'],
    );
  }
}

class StudentClassworkDetailScreen extends StatefulWidget {
  final Classwork classwork;
  final int userId;

  const StudentClassworkDetailScreen({
    required this.classwork,
    required this.userId,
    super.key,
  });

  @override
  State<StudentClassworkDetailScreen> createState() =>
      _StudentClassworkDetailScreenState();
}

class _StudentClassworkDetailScreenState
    extends State<StudentClassworkDetailScreen> {
  // Mock State for "Your Work"
  bool _isSubmitted = false;
  bool _isSubmitting = false; // Loading state for submission
  List<PlatformFile> _myFiles = []; // Local files to be uploaded
  List<SubmittedFile> _serverFiles = []; // Files fetched from server
  int? _submissionId; // To track if we have an existing submission

  @override
  void initState() {
    super.initState();
    _getSubmittedWork();
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to pick files")));
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

  Future<void> _openServerFile(SubmittedFile file) async {
    // Construct the full URL. Assumes backend serves files statically or via an endpoint.
    // Adjust base URL as needed.
    final uri = Uri.parse('http://localhost:3000${file.filePath}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch ${file.fileName}")),
        );
      }
    }
  }

  Future<void> _getSubmittedWork() async {
    try {
      final url = Uri.parse('http://localhost:3000/api/classworks');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'get-submitted-work',
          'user_id': widget.userId,
          'class_work_id': widget.classwork.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Submitted work response: $data");

        // The API returns: {"work": [...], "submission_id": ...} or similar
        // based on the user request example.
        if (data['submission_id'] != null) {
          int subId = data['submission_id'];
          List<dynamic> filesJson = data['work'] ?? [];

          setState(() {
            _submissionId = subId;
            _isSubmitted = true; // existing submission found
            _serverFiles = filesJson
                .map((json) => SubmittedFile.fromJson(json))
                .toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching submitted work: $e");
    }
  }

  Future<void> _submitWork() async {
    setState(() => _isSubmitting = true);

    try {
      List<Map<String, String>> attachments = [];

      for (var file in _myFiles) {
        String? base64String;
        try {
          if (file.bytes != null) {
            base64String = base64Encode(file.bytes!);
          } else if (file.path != null) {
            final bytes = await File(file.path!).readAsBytes();
            base64String = base64Encode(bytes);
          }
        } catch (e) {
          print("Error reading file ${file.name}: $e");
        }

        if (base64String != null) {
          attachments.add({'name': file.name, 'base64': base64String});
        }
      }

      final url = Uri.parse('http://localhost:3000/api/classworks');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'submit-work',
          'user_id': widget.userId,
          'class_work_id': widget.classwork.id,
          'attachments': attachments,
        }),
      );

      if (response.statusCode == 200) {
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
      } else {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to submit work")),
          );
        }
      }
    } catch (e) {
      print("Error submitting work: $e");
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to submit work")));
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

          final mainContent = InstructionsTab(classwork: widget.classwork);
          final sidebar = _buildSidebar();

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: mainContent,
                  ),
                ),
                Container(
                  width: 360,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade200),
                    ),
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
              TextSpan(
                text:
                    widget.classwork.author_firstname +
                    " " +
                    widget.classwork.author_lastname,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              TextSpan(
                text: " • ${_formatDateFull(widget.classwork.dateUpdated)}",
              ),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        if (widget.classwork.instruction != null)
          Text(
            widget.classwork.instruction!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
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
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your work",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  Text(
                    _isSubmitted ? "Handed in" : "Assigned",
                    style: TextStyle(
                      fontSize: 12,
                      color: _isSubmitted ? Colors.black54 : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- FILE LIST ---
              if (_myFiles.isNotEmpty)
                ..._myFiles.map(
                  (file) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () => _openFile(file), // CLICK TO OPEN FILE
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            // Only show delete button if not yet submitted
                            if (!_isSubmitted)
                              InkWell(
                                onTap: () => _removeFile(file),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // --- SERVER FILES (Submitted) ---
              if (_serverFiles.isNotEmpty)
                ..._serverFiles.map(
                  (file) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () => _openServerFile(file), // CLICK TO OPEN URL
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file.fileName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

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
                    backgroundColor: _isSubmitted
                        ? Colors.white
                        : AppColors.primary,
                    foregroundColor: _isSubmitted
                        ? Colors.black87
                        : Colors.white,
                    elevation: 0,
                    side: _isSubmitted
                        ? BorderSide(color: Colors.grey.shade300)
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.person_outline, size: 18, color: Colors.black54),
                  SizedBox(width: 8),
                  Text(
                    "Private comments",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
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
                child: const Text(
                  "Add comment to Teacher",
                  style: TextStyle(fontSize: 13),
                ),
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
    return points.truncateToDouble() == points
        ? points.truncate().toString()
        : points.toString();
  }
}
