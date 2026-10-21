import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/milestone.dart';

class MilestoneTile extends StatelessWidget {
  const MilestoneTile({
    super.key,
    required this.milestone,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
  });

  final Milestone milestone;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final done = milestone.done;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.green : Colors.white,
                border: Border.all(color: done ? AppColors.green : AppColors.borderHi, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: done ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              milestone.text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? AppColors.textMute : AppColors.text,
              ),
            ),
          ),
          if (done)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text('DONE',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .6, color: AppColors.green)),
            ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              tooltip: 'Edit task',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.textDim),
            ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: AppColors.textMute),
            ),
          ),
        ],
      ),
    );
  }
}
