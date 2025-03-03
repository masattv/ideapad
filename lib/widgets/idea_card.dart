import 'package:flutter/material.dart';
import 'package:idea_app/models/idea.dart';
import 'package:idea_app/config/themes.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class IdeaCard extends StatelessWidget {
  final Idea idea;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const IdeaCard({
    Key? key,
    required this.idea,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Slidable(
      key: ValueKey(idea.id ?? 0),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '編集',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: colorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '削除',
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _truncateText(idea.content, 120),
                  style: theme.textTheme.bodyLarge,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(idea.updatedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (idea.tags.isNotEmpty)
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 4,
                          runSpacing: 4,
                          children: idea.tags
                              .take(3)
                              .map((tag) => _buildTag(tag, theme))
                              .toList(),
                        ),
                      ),
                  ],
                ),
                if (idea.parentId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_tree,
                          size: 16,
                          color: colorScheme.primary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '子アイデア',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppThemes.accentBlueLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemes.accentBlueLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppThemes.accentBlueLight,
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}
