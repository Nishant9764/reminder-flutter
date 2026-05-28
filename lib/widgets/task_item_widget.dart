// lib/widgets/task_item_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

/// Animated task row.
///
/// Animations:
///   • Fade + slide-up entrance on first render
///   • Spring-scale on checkbox tap
///   • Opacity fade + CSS-like strikethrough on completion (hardware-accelerated)
///   • Slide-right + fade-out on deletion before widget is removed
class TaskItemWidget extends StatefulWidget {
  final Task         task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget>
    with SingleTickerProviderStateMixin {
  // Entrance animation
  late final AnimationController _entranceCtrl;
  late final Animation<double>   _entranceFade;
  late final Animation<Offset>   _entranceSlide;

  bool _removing = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 360),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve:  Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));

    // Stagger entrance slightly so list items don't all pop in at once
    WidgetsBinding.instance.addPostFrameCallback((_) => _entranceCtrl.forward());
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleDelete() async {
    setState(() => _removing = true);
    await Future.delayed(const Duration(milliseconds: 330));
    if (mounted) widget.onDelete();
  }

  // ── Deadline formatting ────────────────────────────────────────────────────

  String _formatDeadline(DateTime d) {
    final now      = DateTime.now();
    final today    = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dDay     = DateTime(d.year, d.month, d.day);
    final h        = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final min      = d.minute.toString().padLeft(2, '0');
    final amPm     = d.hour < 12 ? 'AM' : 'PM';
    final time     = '$h:$min $amPm';

    if (dDay == today)    return 'Today · $time';
    if (dDay == tomorrow) return 'Tomorrow · $time';
    return '${d.month}/${d.day}/${d.year} · $time';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final task    = widget.task;
    final overdue = task.isOverdue;

    final accentColor = task.completed
        ? AppTheme.accent.withOpacity(0.28)
        : overdue
            ? AppTheme.danger
            : AppTheme.accent;

    return FadeTransition(
      opacity: _entranceFade,
      child: SlideTransition(
        position: _entranceSlide,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 340),
          opacity:  _removing ? 0 : (task.completed ? 0.42 : 1.0),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 320),
            curve:    Curves.easeIn,
            offset:   _removing ? const Offset(0.07, 0) : Offset.zero,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: task.completed
                    ? Colors.white.withOpacity(0.013)
                    : Colors.white.withOpacity(0.028),
                border: Border.all(
                  color: task.completed
                      ? Colors.white.withOpacity(0.04)
                      : Colors.white.withOpacity(0.065),
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left accent bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width:  2.5,
                      height: task.deadline != null ? 62 : 44,
                      decoration: BoxDecoration(
                        color:         accentColor,
                        borderRadius:  BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(width: 13),

                    // Checkbox
                    _SpringCheckbox(
                      completed: task.completed,
                      onTap:     widget.onToggle,
                    ),

                    const SizedBox(width: 13),

                    // Task text + deadline
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Task text with animated strikethrough
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 320),
                              style: GoogleFonts.dmSans(
                                fontSize:   14.5,
                                fontWeight: task.completed
                                    ? FontWeight.w400
                                    : FontWeight.w500,
                                color: task.completed
                                    ? Colors.white.withOpacity(0.3)
                                    : AppTheme.textPrimary,
                                letterSpacing: -0.2,
                                height: 1.35,
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor:
                                    Colors.white.withOpacity(0.25),
                                decorationThickness: 1.5,
                              ),
                              child: Text(
                                task.text,
                                maxLines:     2,
                                overflow:     TextOverflow.ellipsis,
                              ),
                            ),

                            // Deadline line
                            if (task.deadline != null) ...[
                              const SizedBox(height: 4),
                              _DeadlineLine(
                                label:     _formatDeadline(task.deadline!),
                                overdue:   overdue,
                                completed: task.completed,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Delete button — always visible at low opacity
                    _DeleteButton(onTap: _handleDelete),

                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── _SpringCheckbox ───────────────────────────────────────────────────────────

class _SpringCheckbox extends StatefulWidget {
  final bool         completed;
  final VoidCallback onTap;

  const _SpringCheckbox({required this.completed, required this.onTap});

  @override
  State<_SpringCheckbox> createState() => _SpringCheckboxState();
}

class _SpringCheckboxState extends State<_SpringCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 380),
    );
    // Bounce: shrink → overshoot → settle
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.78), weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.78, end: 1.22)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0), weight: 30),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:     _onTap,
      behavior:  HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve:    Curves.easeOut,
          width:    22,
          height:   22,
          decoration: BoxDecoration(
            gradient: widget.completed
                ? const LinearGradient(
                    colors: [AppTheme.accentDeep, AppTheme.accentLight],
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                  )
                : null,
            color: widget.completed ? null : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(7),
            border: widget.completed
                ? null
                : Border.all(color: Colors.white.withOpacity(0.22)),
            boxShadow: widget.completed
                ? [
                    BoxShadow(
                      color:      AppTheme.accent.withOpacity(0.48),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: widget.completed
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

// ── _DeadlineLine ─────────────────────────────────────────────────────────────

class _DeadlineLine extends StatelessWidget {
  final String label;
  final bool   overdue, completed;

  const _DeadlineLine({
    required this.label,
    required this.overdue,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? Colors.white.withOpacity(0.18)
        : overdue
            ? AppTheme.danger
            : Colors.white.withOpacity(0.32);

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 11, color: color.withOpacity(0.7)),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 11.5, color: color),
        ),
        if (overdue && !completed) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color:  AppTheme.danger.withOpacity(0.1),
              border: Border.all(color: AppTheme.danger.withOpacity(0.22)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'OVERDUE',
              style: GoogleFonts.dmSans(
                fontSize:   9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: AppTheme.danger,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── _DeleteButton ─────────────────────────────────────────────────────────────

class _DeleteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _hovering
                ? AppTheme.danger.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            size:  16,
            color: _hovering
                ? AppTheme.danger
                : Colors.white.withOpacity(0.22),
          ),
        ),
      ),
    );
  }
}
