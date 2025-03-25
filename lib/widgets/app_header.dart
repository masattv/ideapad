import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';
import 'package:idea_app/services/ai_idea_combination_service.dart';
import 'package:idea_app/models/user_stats.dart';
import 'package:idea_app/widgets/share_dialog.dart';

/// アプリ全体で使用する共通ヘッダーコンポーネント
/// SNSシェア機能とAI使用回数表示を含む
class AppHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;

  const AppHeader({
    Key? key,
    required this.title,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return FutureBuilder<UserStats>(
      future: _getUserStats(context),
      builder: (context, snapshot) {
        final int remainingUsage = snapshot.data?.remainingUsage ?? 0;
        final bool isLowUsage = remainingUsage <= 3; // AI使用回数が3回以下かどうか

        return GlassmorphicContainer(
          width: double.infinity,
          height: 60,
          borderRadius: 0,
          blur: 10,
          alignment: Alignment.center,
          border: 0,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ]
                : [
                    Colors.white.withOpacity(0.7),
                    Colors.white.withOpacity(0.4),
                  ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ]
                : [
                    Colors.white.withOpacity(0.7),
                    Colors.white.withOpacity(0.4),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showBackButton)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                else
                  const SizedBox(width: 24),

                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // SNSシェアボタン
                _buildShareButton(context, isLowUsage, remainingUsage),
              ],
            ),
          ),
        );
      },
    );
  }

  // シェアボタンを構築
  Widget _buildShareButton(
      BuildContext context, bool isLowUsage, int remainingUsage) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showShareDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isLowUsage
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLowUsage
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.share,
              size: 18,
              color: isLowUsage
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              isLowUsage ? 'SNSシェアで使用回数10回追加' : 'シェア',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isLowUsage
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
                fontWeight: isLowUsage ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // シェアダイアログを表示
  Future<void> _showShareDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => ShareDialog(
        onShareComplete: () {
          // シェア完了後に画面を更新するためにsetStateを呼ぶ
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'シェアありがとうございます！${UserStats.shareBonus}回分のAI使用ポイントが追加されました。'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  // ユーザー統計情報を取得
  Future<UserStats> _getUserStats(BuildContext context) async {
    try {
      final combinationService =
          Provider.of<Future<AIIdeaCombinationService>>(context, listen: false);
      final service = await combinationService;
      return service.getUserStats();
    } catch (e) {
      // エラーが発生した場合はデフォルト値を返す
      return UserStats();
    }
  }
}
