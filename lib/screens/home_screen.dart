// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_input_widget.dart';
import '../widgets/task_list_widget.dart';
import '../widgets/toast_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Ambient glow background ────────────────────────────────────────
          const Positioned.fill(child: _AmbientBackground()),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: _Header(provider: provider),
                ),

                const SizedBox(height: 20),

                // Notification permission banner
                if (!provider.loading && !provider.notifGranted)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: const _NotifBanner(),
                  ),

                // Task capture input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TaskInputWidget(
                    onAddTask: (text, deadline) =>
                        provider.addTask(text, deadline),
                  ),
                ),

                // Divider — only shown when tasks exist
                if (provider.tasks.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.06),
                            Colors.white.withOpacity(0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 10),

                // Task list
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TaskListWidget(provider: provider),
                  ),
                ),
              ],
            ),
          ),

          // ── Toast overlay ──────────────────────────────────────────────────
          if (provider.currentToast != null)
            Positioned(
              bottom: 28,
              left:   20,
              right:  20,
              child: SafeArea(
                child: ToastWidget(
                  toast:     provider.currentToast!,
                  onDismiss: provider.dismissToast,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Ambient background ────────────────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GlowPainter(), child: const SizedBox.expand());
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-centre indigo glow
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 0.65,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.08),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );

    // Bottom-right violet glow
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.9, 0.8),
          radius: 0.55,
          colors: [
            const Color(0xFFA855F7).withOpacity(0.045),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );

    // Left mid cyan tint
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.9, 0.2),
          radius: 0.45,
          colors: [
            const Color(0xFF06B6D4).withOpacity(0.025),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => false;
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TaskProvider provider;
  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand row with stat badges
        Row(
          children: [
            // Gradient "Lumina" wordmark
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFF1F5F9), Color(0xFF818CF8)],
                begin:  Alignment.centerLeft,
                end:    Alignment.centerRight,
              ).createShader(bounds),
              child: Text(
                'Lumina',
                style: GoogleFonts.syne(
                  fontSize:   32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: Colors.white, // masked by ShaderMask
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Active count
            if (provider.activeTasks.isNotEmpty)
              _StatBadge(
                label:       '${provider.activeTasks.length} active',
                color:       AppTheme.accentLight,
                bgColor:     AppTheme.accentGlow,
                borderColor: AppTheme.accent.withOpacity(0.28),
              ),

            const SizedBox(width: 6),

            // Overdue count
            if (provider.overdueCount > 0)
              _StatBadge(
                label:       '${provider.overdueCount} overdue',
                color:       AppTheme.danger,
                bgColor:     AppTheme.dangerGlow,
                borderColor: AppTheme.danger.withOpacity(0.28),
              ),
          ],
        ),

        const SizedBox(height: 6),

        // Sub-row: tagline + clear button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your focus, distilled.',
              style: GoogleFonts.dmSans(
                fontSize:   13,
                fontWeight: FontWeight.w300,
                fontStyle:  FontStyle.italic,
                color: Colors.white.withOpacity(0.27),
              ),
            ),
            if (provider.completedTasks.isNotEmpty)
              _ClearDoneButton(
                count: provider.completedTasks.length,
                onTap: provider.clearCompleted,
              ),
          ],
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final Color  color, bgColor, borderColor;

  const _StatBadge({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color:  bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize:   11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

class _ClearDoneButton extends StatefulWidget {
  final int          count;
  final VoidCallback onTap;
  const _ClearDoneButton({required this.count, required this.onTap});

  @override
  State<_ClearDoneButton> createState() => _ClearDoneButtonState();
}

class _ClearDoneButtonState extends State<_ClearDoneButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressing = true),
      onTapUp:     (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
        decoration: BoxDecoration(
          color: _pressing
              ? AppTheme.danger.withOpacity(0.08)
              : Colors.transparent,
          border: Border.all(
            color: _pressing
                ? AppTheme.danger.withOpacity(0.28)
                : Colors.white.withOpacity(0.07),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Clear ${widget.count} done',
          style: GoogleFonts.dmSans(
            fontSize: 11.5,
            color: _pressing
                ? AppTheme.danger
                : Colors.white.withOpacity(0.28),
          ),
        ),
      ),
    );
  }
}

// ── Notification permission banner ────────────────────────────────────────────

class _NotifBanner extends StatelessWidget {
  const _NotifBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color:  AppTheme.warning.withOpacity(0.07),
        border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 14, color: AppTheme.warning),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.dmSans(
                    fontSize: 12.5, color: AppTheme.textSecondary),
                children: [
                  TextSpan(
                    text: 'Notifications blocked — ',
                    style: TextStyle(
                      color:      AppTheme.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(
                      text: 'in-app alerts will be used instead.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
