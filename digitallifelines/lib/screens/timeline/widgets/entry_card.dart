import 'package:flutter/material.dart';

import '../../../models/entry.dart';
import '../../../models/field.dart';
import '../../../theme/app_theme.dart';

class EntryCard extends StatelessWidget {
  final Entry entry;
  final List<TimelineField> fields;
  final Map<int, String> valuesByFieldId;
  final VoidCallback onToggleFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EntryCard({
    super.key,
    required this.entry,
    required this.fields,
    required this.valuesByFieldId,
    required this.onToggleFavorite,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(entry.createdAt);
    final titleField = fields.isNotEmpty ? fields.first : null;
    final titleValue = titleField == null
        ? ''
        : (valuesByFieldId[titleField.id] ?? '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isFavorite
              ? AppColors.accent.withValues(alpha: 0.5)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleValue.isEmpty
                            ? 'Life Point #${entry.id}'
                            : titleValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: entry.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    entry.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: entry.isFavorite
                        ? AppColors.accent
                        : AppColors.mutedText,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...fields.map((field) {
              final value = valuesByFieldId[field.id] ?? '';
              if (value.trim().isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${field.name}: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.appBarText,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year} $hh:$min';
  }
}
