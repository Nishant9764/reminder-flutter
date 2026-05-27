import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_input_widget.dart';
import '../widgets/toast_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lumina',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${provider.activeTasks.length} active reminders',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 26),
                          TaskInputWidget(
                            onAddTask: (text, deadline) async {
                              await provider.addTask(text, deadline);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Task List
                    Expanded(
                      child: provider.tasks.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 6, 20, 120),
                              itemCount: provider.tasks.length,
                              itemBuilder: (context, index) {
                                final task = provider.tasks[index];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _TaskCard(task: task),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // Toast Overlay
              if (provider.currentToast != null)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 30,
                  child: ToastWidget(
                    toast: provider.currentToast!,
                    onDismiss: provider.dismissToast,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: task.isOverdue
              ? AppTheme.danger.withValues(alpha: 0.35)
              : AppTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => provider.toggleTask(task.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: task.completed
                    ? const LinearGradient(
                        colors: [
                          AppTheme.accentDeep,
                          AppTheme.accentLight,
                        ],
                      )
                    : null,
                border: Border.all(
                  color: task.completed
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: task.completed
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 14),

          // Task content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.text,
                  style: TextStyle(
                    color: task.completed
                        ? Colors.white.withValues(alpha: 0.35)
                        : AppTheme.textPrimary,
                    fontSize: 15,
                    height: 1.45,
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.deadline != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: task.isOverdue
                          ? AppTheme.dangerGlow
                          : AppTheme.accentGlow,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 12,
                          color: task.isOverdue
                              ? AppTheme.danger
                              : AppTheme.accentLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d • h:mm a').format(task.deadline!),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: task.isOverdue
                                ? AppTheme.danger
                                : AppTheme.accentLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Delete button
          GestureDetector(
            onTap: () => provider.deleteTask(task.id),
            child: Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nights_stay_rounded,
              size: 58,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            const SizedBox(height: 20),
            const Text(
              'No reminders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Capture thoughts, deadlines, and important moments beautifully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
