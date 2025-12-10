import 'package:flutter/material.dart';
import 'meeting_theme.dart';

/// The top header bar for the meeting screen
class MeetingHeader extends StatelessWidget {
  final String meetingCode;
  final String? meetingTitle;
  final int participantCount;
  final bool isRecording;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;

  const MeetingHeader({
    required this.meetingCode,
    this.meetingTitle,
    this.participantCount = 0,
    this.isRecording = false,
    this.onBack,
    this.onSettings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MeetingTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: MeetingTheme.defaultBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: MeetingTheme.controlButtonColor,
                padding: const EdgeInsets.all(10),
              ),
            ),

            const Spacer(),

            // Center - meeting info
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_view,
                      color: MeetingTheme.secondaryTextColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meetingTitle ?? meetingCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: MeetingTheme.controlButtonActiveColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Right - recording indicator and settings
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRecording) _buildRecordingIndicator(),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onSettings,
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: MeetingTheme.controlButtonColor,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MeetingTheme.leaveButtonColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: MeetingTheme.leaveButtonColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: MeetingTheme.leaveButtonColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'REC',
            style: TextStyle(
              color: MeetingTheme.leaveButtonColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
