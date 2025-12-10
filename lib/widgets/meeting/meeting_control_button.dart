import 'package:flutter/material.dart';
import 'meeting_theme.dart';

/// A circular control button used in the meeting bottom bar
class MeetingControlButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isActive;
  final bool isMuted;
  final VoidCallback? onPressed;
  final double size;

  const MeetingControlButton({
    required this.icon,
    this.label,
    this.isActive = false,
    this.isMuted = false,
    this.onPressed,
    this.size = 48,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isMuted
                ? MeetingTheme.mutedColor
                : isActive
                ? MeetingTheme.controlButtonActiveColor
                : MeetingTheme.controlButtonColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(size / 2),
              child: Icon(
                icon,
                color: MeetingTheme.primaryTextColor,
                size: size * 0.5,
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(
            label!,
            style: TextStyle(
              color: MeetingTheme.secondaryTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// A modern "Leave Meeting" button
class LeaveMeetingButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const LeaveMeetingButton({this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: MeetingTheme.leaveButtonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
      child: const Text(
        'Leave Meeting',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}
