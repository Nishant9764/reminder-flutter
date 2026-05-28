// lib/widgets/toast_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

/// Animated toast notification widget.
/// Slides in from below and fades in on mount.
/// Parent is responsible for placement (Positioned inside a Stack).
class ToastWidget extends StatefulWidget {
  final ToastData toast;
  final VoidCallback onDismiss;

  const ToastWidget({
    super.key,
    required this.toast,
    required this.onDismiss,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>  _fade;
  late final Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  // ── Colour helpers ─────────────────────────────────────────────────────────

  Color get _border {
    switch (widget.toast.type) {
      case 'success': return AppTheme.success.withOpacity(0.3);
      case 'warning': return AppTheme.warning.withOpacity(0.3);
      case 'error':   return AppTheme.danger.withOpacity(0.3);
      default:        return AppTheme.accent.withOpacity(0.32);
    }
  }

  Color get _bg {
    switch (widget.toast.type) {
      case 'success': return AppTheme.successGlow;
      case 'warning': return AppTheme.warningGlow;
      case 'error':   return AppTheme.dangerGlow;
      default:        return AppTheme.accentGlow;
    }
  }

  Color get _iconColor {
    switch (widget.toast.type) {
      case 'success': return AppTheme.success;
      case 'warning': return AppTheme.warning;
      case 'error':   return AppTheme.danger;
      default:        return AppTheme.accentLight;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: _bg,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 32,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_outlined, size: 15, color: _iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.toast.message,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    color: const Color(0xFFE2E8F0),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: widget.onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
