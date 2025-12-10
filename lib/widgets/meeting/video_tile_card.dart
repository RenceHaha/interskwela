import 'package:flutter/material.dart';
import 'meeting_theme.dart';

/// A video tile card that displays a participant's video with their name
class VideoTileCard extends StatelessWidget {
  final Widget? videoWidget;
  final String participantName;
  final bool isMuted;
  final bool isActiveSpeaker;
  final bool isLocal;
  final String? avatarText;
  final Color? avatarColor;

  const VideoTileCard({
    this.videoWidget,
    required this.participantName,
    this.isMuted = false,
    this.isActiveSpeaker = false,
    this.isLocal = false,
    this.avatarText,
    this.avatarColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActiveSpeaker
              ? MeetingTheme.activeSpeakerBorder
              : MeetingTheme.defaultBorder,
          width: isActiveSpeaker ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video or Avatar placeholder
            if (videoWidget != null)
              videoWidget!
            else
              _buildAvatarPlaceholder(),

            // Name tag overlay
            Positioned(left: 8, bottom: 8, child: _buildNameTag()),

            // Mute indicator
            if (isMuted)
              Positioned(right: 8, bottom: 8, child: _buildMuteIndicator()),

            // Local indicator
            if (isLocal)
              Positioned(right: 8, top: 8, child: _buildLocalIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: avatarColor ?? MeetingTheme.cardColor,
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: MeetingTheme.controlButtonColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              avatarText ??
                  (participantName.isNotEmpty
                      ? participantName[0].toUpperCase()
                      : '?'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MeetingTheme.nameTagColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            participantName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isLocal) ...[
            const SizedBox(width: 4),
            const Text(
              '(You)',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMuteIndicator() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MeetingTheme.mutedColor,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.mic_off, color: Colors.white, size: 14),
    );
  }

  Widget _buildLocalIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: MeetingTheme.controlButtonActiveColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'You',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
