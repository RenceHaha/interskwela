import 'package:flutter/material.dart';
import 'meeting_theme.dart';
import 'meeting_control_button.dart';

/// The bottom control bar for the meeting screen
class MeetingControlBar extends StatelessWidget {
  final bool isMicMuted;
  final bool isCameraMuted;
  final bool isScreenSharing;
  final bool isJoined;
  final VoidCallback? onMicToggle;
  final VoidCallback? onCameraToggle;
  final VoidCallback? onScreenShare;
  final VoidCallback? onChat;
  final VoidCallback? onParticipants;
  final VoidCallback? onMore;
  final VoidCallback? onLeave;
  final VoidCallback? onJoin;

  const MeetingControlBar({
    this.isMicMuted = false,
    this.isCameraMuted = false,
    this.isScreenSharing = false,
    this.isJoined = false,
    this.onMicToggle,
    this.onCameraToggle,
    this.onScreenShare,
    this.onChat,
    this.onParticipants,
    this.onMore,
    this.onLeave,
    this.onJoin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: MeetingTheme.controlBarColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - zoom controls placeholder
            const SizedBox(width: 100),

            // Center - main controls
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MeetingControlButton(
                    icon: isMicMuted ? Icons.mic_off : Icons.mic,
                    isMuted: isMicMuted,
                    onPressed: isJoined ? onMicToggle : null,
                  ),
                  const SizedBox(width: 16),
                  MeetingControlButton(
                    icon: isCameraMuted ? Icons.videocam_off : Icons.videocam,
                    isMuted: isCameraMuted,
                    onPressed: isJoined ? onCameraToggle : null,
                  ),
                  const SizedBox(width: 16),
                  MeetingControlButton(
                    icon: Icons.screen_share,
                    isActive: isScreenSharing,
                    onPressed: isJoined ? onScreenShare : null,
                  ),
                  const SizedBox(width: 16),
                  MeetingControlButton(
                    icon: Icons.chat_bubble_outline,
                    onPressed: onChat,
                  ),
                  const SizedBox(width: 16),
                  MeetingControlButton(
                    icon: Icons.people_outline,
                    onPressed: onParticipants,
                  ),
                  const SizedBox(width: 16),
                  MeetingControlButton(
                    icon: Icons.more_horiz,
                    onPressed: onMore,
                  ),
                ],
              ),
            ),

            // Right side - leave/join button
            SizedBox(
              width: 140,
              child: isJoined
                  ? LeaveMeetingButton(onPressed: onLeave)
                  : ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MeetingTheme.joinButtonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Join Meeting',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
