// lib/widgets/task_input_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Two-row task capture component.
///
/// Row 1 — text input bar with Add button and Deadline toggle.
/// Row 2 — expandable deadline row with [Date] and [Time] chip buttons.
///          Tapping each opens Flutter's themed native picker dialog.
class TaskInputWidget extends StatefulWidget {
  final void Function(String text, DateTime? deadline) onAddTask;

  const TaskInputWidget({super.key, required this.onAddTask});

  @override
  State<TaskInputWidget> createState() => _TaskInputWidgetState();
}

class _TaskInputWidgetState extends State<TaskInputWidget>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _focused = false;
  bool _showDeadline = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // AnimationController for the deadline row slide-in
  late final AnimationController _rowCtrl;
  late final Animation<double> _rowFade;

  // ── Computed deadline DateTime ─────────────────────────────────────────────

  DateTime? get _deadline {
    if (_selectedDate == null) return null;
    final t = _selectedTime ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      t.hour,
      t.minute,
    );
  }

  String get _deadlineLabel {
    final d = _deadline;
    if (d == null) return 'Deadline';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dDay = DateTime(d.year, d.month, d.day);
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    final amPm = d.hour < 12 ? 'AM' : 'PM';
    final time = '$h:$min $amPm';
    if (dDay == today) return 'Today · $time';
    if (dDay == tomorrow) return 'Tomorrow · $time';
    return '${d.month}/${d.day} · $time';
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _rowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _rowFade = CurvedAnimation(parent: _rowCtrl, curve: Curves.easeInOut);

    _controller
        .addListener(() => setState(() {})); // re-render for button state
    _focusNode
        .addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _rowCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAddTask(text, _deadline);
    _controller.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _showDeadline = false;
    });
    _rowCtrl.reverse();
    _focusNode.requestFocus();
  }

  void _toggleDeadlineRow() {
    setState(() => _showDeadline = !_showDeadline);
    if (_showDeadline) {
      _rowCtrl.forward();
    } else {
      _rowCtrl.reverse();
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      builder: AppTheme.pickerThemeBuilder,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: AppTheme.pickerThemeBuilder,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _clearDeadline() {
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  bool get _canSubmit => _controller.text.trim().isNotEmpty;
  bool get _hasDeadline => _deadline != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Row 1: Text input ──────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.fromLTRB(18, 7, 7, 7),
          decoration: BoxDecoration(
            color: _focused
                ? AppTheme.accent.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.026),
            border: Border.all(
              color: _focused ? AppTheme.borderFocused : AppTheme.border,
            ),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: Radius.circular(_showDeadline ? 0 : 16),
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Leading plus icon
              Icon(
                Icons.add,
                size: 18,
                color: _focused
                    ? AppTheme.accentLight.withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(width: 10),

              // Text field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onSubmitted: (_) => _submit(),
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Capture a thought…',
                    hintStyle: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  cursorColor: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 8),

              // Deadline toggle button
              _DeadlineToggle(
                isOpen: _showDeadline,
                hasDeadline: _hasDeadline,
                label: _deadlineLabel,
                onTap: _toggleDeadlineRow,
              ),
              const SizedBox(width: 6),

              // Add button
              _AddButton(enabled: _canSubmit, onTap: _submit),
            ],
          ),
        ),

        // ── Row 2: Expandable deadline picker ──────────────────────────────
        SizeTransition(
          sizeFactor: _rowFade,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _rowFade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.05),
                border: Border(
                  left: BorderSide(color: AppTheme.accent.withValues(alpha: 0.3)),
                  right: BorderSide(color: AppTheme.accent.withValues(alpha: 0.3)),
                  bottom: BorderSide(color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  // Date chip
                  _PickerChip(
                    icon: Icons.calendar_today_outlined,
                    label: _selectedDate != null
                        ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                        : 'Pick date',
                    isSet: _selectedDate != null,
                    onTap: _pickDate,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'at',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),

                  // Time chip
                  _PickerChip(
                    icon: Icons.schedule_outlined,
                    label: _selectedTime != null
                        ? () {
                            final t = _selectedTime!;
                            final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
                            final min = t.minute.toString().padLeft(2, '0');
                            final p = t.period == DayPeriod.am ? 'AM' : 'PM';
                            return '$h:$min $p';
                          }()
                        : 'Pick time',
                    isSet: _selectedTime != null,
                    onTap: _pickTime,
                  ),

                  const Spacer(),

                  // Clear button
                  if (_hasDeadline)
                    GestureDetector(
                      onTap: _clearDeadline,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DeadlineToggle extends StatelessWidget {
  final bool isOpen, hasDeadline;
  final String label;
  final VoidCallback onTap;

  const _DeadlineToggle({
    required this.isOpen,
    required this.hasDeadline,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = isOpen || hasDeadline;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color:
              active ? AppTheme.accent.withValues(alpha: 0.18) : Colors.transparent,
          border: Border.all(
            color:
                active ? AppTheme.accent.withValues(alpha: 0.4) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 12,
              color: active
                  ? AppTheme.accentLight
                  : Colors.white.withValues(alpha: 0.28),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: active
                    ? AppTheme.accentLight
                    : Colors.white.withValues(alpha: 0.28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _AddButton({required this.enabled, required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: widget.enabled
              ? const LinearGradient(
                  colors: [AppTheme.accentDeep, AppTheme.accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.enabled ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(11),
          boxShadow: widget.enabled
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: _pressed ? 0.2 : 0.42),
                    blurRadius: _pressed ? 6 : 14,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        transform: Matrix4.identity()..scale(_pressed ? 0.92 : 1.0),
        transformAlignment: Alignment.center,
        child: Icon(
          Icons.add,
          size: 16,
          color: widget.enabled ? Colors.white : Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

class _PickerChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSet;
  final VoidCallback onTap;

  const _PickerChip({
    required this.icon,
    required this.label,
    required this.isSet,
    required this.onTap,
  });

  @override
  State<_PickerChip> createState() => _PickerChipState();
}

class _PickerChipState extends State<_PickerChip> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSet
              ? AppTheme.accent.withValues(alpha: _pressing ? 0.2 : 0.12)
              : Colors.white.withValues(alpha: _pressing ? 0.08 : 0.04),
          border: Border.all(
            color: widget.isSet
                ? AppTheme.accent.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 12,
              color: widget.isSet
                  ? AppTheme.accentLight
                  : Colors.white.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: widget.isSet
                    ? AppTheme.accentLight
                    : Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
