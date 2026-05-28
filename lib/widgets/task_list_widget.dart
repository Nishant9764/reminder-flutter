// lib/widgets/task_list_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'task_item_widget.dart';

/// Renders the full task list split into Active and Completed sections.
/// The completed section is collapsible (chevron toggle).
class TaskListWidget extends StatefulWidget {
  final TaskProvider provider;

  const TaskListWidget({super.key, required this.provider});

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget>
    with SingleTickerProviderStateMixin {
  bool _showCompleted = false;

  late final AnimationController _chevronCtrl;
  late final Animation<double>   _chevronTurn;

  @override
  void initState() {
    super.initState();
    _chevronCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 240),
    );
    _chevronTurn = Tween<double>(begin: 0, end: 0.25)
        .animate(CurvedAnimation(parent: _chevronCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _chevronCtrl.dispose();
    super.dispose();
  }

  void _toggleCompleted() {
    setState(() => _showCompleted = !_showCompleted);
    _showCompleted ? _chevronCtrl.forward() : _chevronCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final provider  = widget.provider;
    final active    = provider.activeTasks;
    final completed = provider.completedTasks;

    // ── Empty state ──────────────────────────────────────────────────────────
    if (provider.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dashed ring icon
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(painter: _EmptyRingPainter()),
            ),
            const SizedBox(height: 18),
            Text(
              'Nothing here yet',
              style: GoogleFonts.dmSans(
                fontSize:   15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.22),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Use the bar above to capture a reminder',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color:    Colors.white.withOpacity(0.13),
              ),
            ),
          ],
        ),
      );
    }

    // ── Task list ────────────────────────────────────────────────────────────
    return ListView(
      padding:  const EdgeInsets.only(bottom: 40),
      children: [
        // Active tasks
        ...active.map((task) => TaskItemWidget(
              key:      ValueKey('active_${task.id}'),
              task:     task,
              onToggle: () => provider.toggleTask(task.id),
              onDelete: () => provider.deleteTask(task.id),
            )),

        // Completed section
        if (completed.isNotEmpty) ...[
          if (active.isNotEmpty) const SizedBox(height: 10),

          // Section header (collapsible)
          GestureDetector(
            onTap: _toggleCompleted,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  RotationTransition(
                    turns: _chevronTurn,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size:  18,
                      color: Colors.white.withOpacity(0.28),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Completed (${completed.length})',
                    style: GoogleFonts.dmSans(
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.85,
                      color: Colors.white.withOpacity(0.28),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Completed items (animated reveal)
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve:    Curves.easeInOut,
            child: _showCompleted
                ? Column(
                    children: completed
                        .map((task) => TaskItemWidget(
                              key:      ValueKey('done_${task.id}'),
                              task:     task,
                              onToggle: () => provider.toggleTask(task.id),
                              onDelete: () => provider.deleteTask(task.id),
                            ))
                        .toList(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

// ── Empty state painter ───────────────────────────────────────────────────────

class _EmptyRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final paint = Paint()
      ..color  = Colors.white.withOpacity(0.12)
      ..style  = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Dashed circle
    const dashCount = 18;
    const gap       = 0.15;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * 3.14159;
      final sweepAngle = (1 / dashCount) * 2 * 3.14159 * (1 - gap);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Inner cross
    final crossPaint = Paint()
      ..color       = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0
      ..strokeCap   = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - 10, center.dy),
      Offset(center.dx + 10, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 10),
      Offset(center.dx, center.dy + 10),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(_EmptyRingPainter old) => false;
}
