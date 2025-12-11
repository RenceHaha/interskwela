import 'package:flutter/material.dart';
import 'package:interskwela/models/classes.dart';
import 'meeting_theme.dart';
import 'video_tile_card.dart';

/// A responsive grid layout for displaying video tiles
class VideoGrid extends StatelessWidget {
  final List<VideoTileCard> tiles;
  final int maxColumns;
  final double spacing;

  const VideoGrid({
    required this.tiles,
    this.maxColumns = 5,
    this.spacing = 8,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _calculateColumns(constraints.maxWidth);
        final rows = (tiles.length / columns).ceil();

        return Container(
          padding: EdgeInsets.all(spacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(rows, (rowIndex) {
              final startIndex = rowIndex * columns;
              final endIndex = (startIndex + columns).clamp(0, tiles.length);
              final rowTiles = tiles.sublist(startIndex, endIndex);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing / 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: rowTiles.map((tile) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing / 2,
                          ),
                          child: tile,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  int _calculateColumns(double width) {
    if (tiles.length <= 1) return 1;
    if (tiles.length <= 2) return 2;
    if (tiles.length <= 4) return 2;
    if (tiles.length <= 6) return 3;
    if (tiles.length <= 9) return 3;
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return maxColumns;
  }
}

/// A welcome screen shown before joining the meeting
class MeetingWelcomeScreen extends StatelessWidget {
  final String classCode;
  final String message;
  final Classes selectedClass;

  const MeetingWelcomeScreen({
    required this.classCode,
    required this.message,
    required this.selectedClass,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: MeetingTheme.backgroundGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with glow effect
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MeetingTheme.controlButtonColor,
                boxShadow: [
                  BoxShadow(
                    color: MeetingTheme.controlButtonActiveColor.withOpacity(
                      0.3,
                    ),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.video_call,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Welcome text
            Text(
              '${selectedClass.sectionName} - ${selectedClass.subjectName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Status message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: MeetingTheme.surfaceColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: MeetingTheme.secondaryTextColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Instruction text
            Text(
              'Click "Join Meeting" to enter the class',
              style: TextStyle(
                color: MeetingTheme.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page indicator dots for video grid pagination
class PageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;

  const PageIndicator({
    required this.pageCount,
    required this.currentPage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          final isActive = index == currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? MeetingTheme.controlButtonActiveColor
                  : MeetingTheme.controlButtonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
