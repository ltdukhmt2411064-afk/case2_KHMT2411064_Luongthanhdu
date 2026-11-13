import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/date_formatter.dart';

Color statusColor(String status) {
  switch (status) {
    case 'in_progress':
      return Colors.orange.shade700;
    case 'done':
      return Colors.green.shade600;
    default:
      return Colors.blueGrey;
  }
}

Color priorityColor(String priority) {
  switch (priority) {
    case 'high':
      return Colors.red.shade600;
    case 'low':
      return Colors.teal;
    default:
      return Colors.amber.shade800;
  }
}

class LabelChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const LabelChip({super.key, required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return LabelChip(
      text: TaskLabels.statuses[status] ?? status,
      color: statusColor(status),
    );
  }
}

class PriorityChip extends StatelessWidget {
  final String priority;
  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    return LabelChip(
      text: TaskLabels.priorities[priority] ?? priority,
      color: priorityColor(priority),
      icon: Icons.flag,
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
                  color: task.status == 'done' ? Colors.grey : null,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusChip(status: task.status),
                  PriorityChip(priority: task.priority),
                  if (task.myRole != 'owner')
                    LabelChip(
                      text: TaskLabels.roles[task.myRole] ?? task.myRole,
                      color: Colors.indigo,
                      icon: Icons.group_outlined,
                    ),
                ],
              ),
              if (task.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      overdue ? Icons.warning_amber_rounded : Icons.event_outlined,
                      size: 16,
                      color: overdue ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Hạn: ${DateFormatter.formatDate(task.dueDate)}'
                      '${overdue ? ' (quá hạn)' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: overdue ? Colors.red : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
