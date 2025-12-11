import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../themes/app_theme.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Model class for AI-generated assignment content
class GeneratedAssignment {
  final String title;
  final String instruction;

  GeneratedAssignment({required this.title, required this.instruction});

  factory GeneratedAssignment.fromJson(Map<String, dynamic> json) {
    return GeneratedAssignment(
      title: _stripMarkdown(json['title'] ?? ''),
      instruction: _stripMarkdown(json['instruction'] ?? ''),
    );
  }

  /// Remove markdown formatting characters from text
  static String _stripMarkdown(String text) {
    return text
        // Remove headers (### Header)
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        // Remove bold (**text** or __text__)
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        // Remove italic (*text* or _text_) - be careful with underscores
        .replaceAll(RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'), r'$1')
        // Remove inline code (`code`)
        .replaceAll(RegExp(r'`(.+?)`'), r'$1')
        // Replace markdown bullets with proper bullets
        .replaceAll(RegExp(r'^[\-\*]\s+', multiLine: true), '• ')
        // Clean up escape sequences
        .replaceAll('\\n', '\n')
        .replaceAll('\\t', '\t')
        .trim();
  }

  Map<String, dynamic> toJson() => {'title': title, 'instruction': instruction};
}

class ChatBotScreen extends StatefulWidget {
  final String creationMode;
  final Function(GeneratedAssignment)? onAssignmentGenerated;
  final List<ChatMessage>? messages; // External messages for persistence
  final Function(List<ChatMessage>)?
  onMessagesChanged; // Callback when messages change

  const ChatBotScreen({
    super.key,
    this.creationMode = 'assignment',
    this.onAssignmentGenerated,
    this.messages,
    this.onMessagesChanged,
  });

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessage> _messages;
  final List<PlatformFile> _attachedFiles = [];
  bool _isLoading = false;
  bool _hasStartedChat = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Gemini API configuration
  static const String _geminiApiKey = 'AIzaSyC2Y21CV5TbYRGg8Y0pxVvNgLJLPf6BuZw';
  late GenerativeModel _model;
  late GenerativeModel _jsonModel; // Model for JSON responses
  late ChatSession _chatSession;

  // Suggested prompts based on creation mode
  List<String> get _suggestedPrompts {
    if (widget.creationMode == 'assignment') {
      return [
        "Create an assignment about programming basics",
        "Generate a writing assignment",
        "Make a research assignment",
        "Create a practical coding task",
      ];
    }
    return [
      "Help me create a lesson plan",
      "Generate quiz questions",
      "Summarize this document",
      "Explain a concept simply",
    ];
  }

  @override
  void initState() {
    super.initState();
    // Use external messages if provided, otherwise create empty list
    _messages = widget.messages != null ? List.from(widget.messages!) : [];
    _hasStartedChat = _messages.isNotEmpty;

    _initializeGemini();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scroll to bottom if there are existing messages
    if (_messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  /// Notify parent when messages change (for persistence)
  void _notifyMessagesChanged() {
    widget.onMessagesChanged?.call(_messages);
  }

  void _initializeGemini() {
    // Regular chat model
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _geminiApiKey,
      systemInstruction: Content.system(
        'You are a helpful AI teaching assistant. You help teachers with lesson planning, '
        'creating assignments, generating quiz questions, summarizing documents, and explaining concepts. '
        'Be concise, helpful, and educational in your responses.',
      ),
    );

    // JSON model for structured assignment generation
    _jsonModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    _chatSession = _model.startChat();
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _hasStartedChat = false;
    });
    _chatSession = _model.startChat();
    _notifyMessagesChanged(); // Sync with parent
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _attachedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty && _attachedFiles.isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      files: List.from(_attachedFiles),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _hasStartedChat = true;
      _isLoading = true;
      _attachedFiles.clear();
      _messageController.clear();
    });
    _notifyMessagesChanged(); // Sync with parent

    _scrollToBottom();

    try {
      // For assignment mode, generate structured JSON content
      if (widget.creationMode == 'assignment') {
        final assignment = await _generateAssignment(text, userMessage.files);

        setState(() {
          _messages.add(
            ChatMessage(
              text: '',
              isUser: false,
              timestamp: DateTime.now(),
              generatedAssignment: assignment,
            ),
          );
          _isLoading = false;
        });
        _notifyMessagesChanged(); // Sync with parent
      } else {
        // Regular chat response
        final response = await _callGeminiApi(text, userMessage.files);

        setState(() {
          _messages.add(
            ChatMessage(
              text: response,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _notifyMessagesChanged(); // Sync with parent
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry, I encountered an error. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
        _isLoading = false;
      });
      _notifyMessagesChanged(); // Sync with parent
      debugPrint('Error sending message: $e');
    }
  }

  /// Generate assignment content as structured JSON
  Future<GeneratedAssignment> _generateAssignment(
    String message,
    List<PlatformFile> files,
  ) async {
    try {
      List<Part> parts = [];

      // Add file parts first
      for (var file in files) {
        if (file.bytes != null) {
          final mimeType = _getMimeType(file.extension);
          if (mimeType != null) {
            parts.add(DataPart(mimeType, file.bytes!));
            parts.add(TextPart('(Attached file: ${file.name})'));
          }
        }
      }

      // Assignment generation prompt - NO MARKDOWN
      final prompt =
          '''
Based on the following request, create a practical assignment for students.

IMPORTANT FORMATTING RULES:
- DO NOT use any markdown formatting (no **, ##, ###, *, _, etc.)
- Use plain text only
- Use line breaks to separate sections
- Use "•" for bullet points if needed
- Write in a clear, professional tone

The instruction should include:
- Overview/Introduction
- Objectives (what students will learn)
- Requirements (what they need to do)
- Deliverables (what to submit)

Request: ${message.isNotEmpty ? message : "Create an assignment based on the attached document."}

Return ONLY valid JSON in this exact format:
{
  "title": "Assignment title here",
  "instruction": "Plain text instruction with proper line breaks"
}
''';

      parts.add(TextPart(prompt));

      final content = Content.multi(parts);
      final response = await _jsonModel.generateContent([content]);

      final jsonText = response.text ?? '{}';

      // Parse the JSON response
      try {
        final jsonData = jsonDecode(jsonText);
        return GeneratedAssignment.fromJson(jsonData);
      } catch (e) {
        // If JSON parsing fails, try to extract content
        debugPrint('JSON parse error: $e');
        debugPrint('Raw response: $jsonText');
        return GeneratedAssignment(
          title: 'Generated Assignment',
          instruction: jsonText,
        );
      }
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      rethrow;
    }
  }

  Future<String> _callGeminiApi(
    String message,
    List<PlatformFile> files,
  ) async {
    try {
      List<Part> parts = [];

      for (var file in files) {
        if (file.bytes != null) {
          final mimeType = _getMimeType(file.extension);
          if (mimeType != null) {
            parts.add(DataPart(mimeType, file.bytes!));
            parts.add(TextPart('(Attached file: ${file.name})'));
          }
        }
      }

      if (message.isNotEmpty) {
        parts.add(TextPart(message));
      } else if (files.isNotEmpty) {
        parts.add(TextPart('Please analyze the attached file(s).'));
      }

      final content = Content.multi(parts);
      final response = await _chatSession.sendMessage(content);

      return response.text ?? 'No response received from AI.';
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      rethrow;
    }
  }

  String? _getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'txt':
        return 'text/plain';
      default:
        return null;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSuggestedPrompt(String prompt) {
    _messageController.text = prompt;
    _sendMessage(prompt);
  }

  /// Use the generated assignment - applies to form via callback without closing chat
  void _useGeneratedAssignment(GeneratedAssignment assignment) {
    if (widget.onAssignmentGenerated != null) {
      // Use callback - chat stays open
      widget.onAssignmentGenerated!(assignment);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Content applied to form!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // No callback, use Navigator.pop as fallback
      Navigator.pop(context, assignment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _hasStartedChat ? _buildChatArea() : _buildWelcomeScreen(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.creationMode == 'assignment'
                    ? 'Assignment Generator'
                    : 'Powered by Gemini',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          onPressed: _resetChat,
          tooltip: 'New conversation',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // Animated AI Logo
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                        const Color(0xFF7B68EE),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            widget.creationMode == 'assignment'
                ? 'Generate Assignment'
                : 'Ask anything',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.creationMode == 'assignment'
                ? 'Upload a file or describe what kind of assignment you need'
                : 'Upload files or ask questions to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _suggestedPrompts.map((prompt) {
              return _buildSuggestedPromptChip(prompt);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPromptChip(String prompt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleSuggestedPrompt(prompt),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            prompt,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    // If this is an AI response with generated assignment, show a card
    if (!isUser && message.generatedAssignment != null) {
      return _buildAssignmentCard(message.generatedAssignment!);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (message.files.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.files.map((file) {
                        return _buildFileChip(file, removable: false);
                      }).toList(),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : message.isError
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : null,
                      bottomLeft: !isUser ? const Radius.circular(4) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser
                          ? Colors.white
                          : message.isError
                          ? Colors.red.shade700
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.secondary,
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build a clickable card for generated assignment content
  Widget _buildAssignmentCard(GeneratedAssignment assignment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _useGeneratedAssignment(assignment),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.05),
                        AppColors.primaryLight.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.assignment,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Generated Assignment',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 12,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to use',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      const Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Divider
                      Container(height: 1, color: Colors.grey.shade200),
                      const SizedBox(height: 16),

                      // Instruction
                      const Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assignment.instruction,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 16),

                      // Action hint
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Click to apply this content to your form',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(
                20,
              ).copyWith(bottomLeft: const Radius.circular(4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.creationMode == 'assignment'
                      ? 'Generating assignment...'
                      : 'Thinking...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachedFiles.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _attachedFiles.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: entry.key < _attachedFiles.length - 1 ? 8 : 0,
                        ),
                        child: _buildFileChip(
                          entry.value,
                          removable: true,
                          onRemove: () => _removeFile(entry.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickFiles,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.attach_file,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: widget.creationMode == 'assignment'
                            ? 'Describe the assignment you need...'
                            : 'Ask me anything...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      onSubmitted: (_) => _sendMessage(_messageController.text),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading
                        ? null
                        : () => _sendMessage(_messageController.text),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isLoading
                              ? [Colors.grey.shade300, Colors.grey.shade400]
                              : [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: _isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileChip(
    PlatformFile file, {
    bool removable = false,
    VoidCallback? onRemove,
  }) {
    IconData iconData;
    Color iconColor;

    switch (file.extension?.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'png':
      case 'jpg':
      case 'jpeg':
        iconData = Icons.image;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 18, color: iconColor),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              file.name,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (removable) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<PlatformFile> files;
  final DateTime timestamp;
  final bool isError;
  final GeneratedAssignment? generatedAssignment;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.files = const [],
    required this.timestamp,
    this.isError = false,
    this.generatedAssignment,
  });
}
