import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:idea_app/models/idea_combination.dart';
import 'package:idea_app/utils/constants.dart';
import 'package:intl/intl.dart';

class CombinationCard extends StatelessWidget {
  final IdeaCombination combination;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;
  final List<String>? originalIdeas; // 元のアイデア内容のリスト

  const CombinationCard({
    Key? key,
    required this.combination,
    this.onFavoriteToggle,
    this.onDelete,
    this.originalIdeas,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final formattedDate = dateFormat.format(combination.createdAt);

    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分（お気に入りボタンとメニュー）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 日付表示
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                // お気に入りボタンとメニュー
                Row(
                  children: [
                    // お気に入りボタン
                    if (onFavoriteToggle != null)
                      IconButton(
                        icon: Icon(
                          combination.isFavorite
                              ? AppConstants.favoriteIcon
                              : AppConstants.favoriteBorderIcon,
                          color: combination.isFavorite ? Colors.red : null,
                        ),
                        onPressed: onFavoriteToggle,
                        tooltip: 'お気に入り',
                      ),
                    // 削除メニュー
                    if (onDelete != null)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteConfirmation(context);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(AppConstants.deleteIcon, color: Colors.red),
                                SizedBox(width: 8),
                                Text(AppConstants.deleteLabel),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 組み合わせ内容
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 組み合わせ内容
                Text(
                  combination.combinedContent,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                
                // 元のアイデアを表示（あれば）
                if (originalIdeas != null && originalIdeas!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '元のアイデア:',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ...originalIdeas!.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.key + 1}. ',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(
      duration: AppConstants.mediumAnimationDuration,
    )
    .slideY(
      begin: 0.2,
      curve: Curves.easeOutQuad,
      duration: AppConstants.mediumAnimationDuration,
    );
  }

  // 削除確認ダイアログを表示
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('この組み合わせを削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppConstants.cancelLabel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onDelete != null) {
                onDelete!();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(AppConstants.deleteLabel),
          ),
        ],
      ),
    );
  }
} 