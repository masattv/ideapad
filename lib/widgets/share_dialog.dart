// 必要なパッケージをインポート
import 'package:flutter/material.dart'; // Flutterの基本的なウィジェットを使用するためのパッケージ
import 'package:provider/provider.dart'; // 状態管理のためのパッケージ
import 'package:url_launcher/url_launcher.dart'; // URLを開くためのパッケージ
import '../services/ai_idea_combination_service.dart'; // AIアイデア組み合わせサービスを使用
import '../models/user_stats.dart'; // ユーザー統計情報モデルを使用
import 'package:idea_app/services/user_stats_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// SNSシェアダイアログを表示するウィジェット
/// シェアボタンを押すとAIポイントが付与される仕組みを提供
class ShareDialog extends StatelessWidget {
  // シェア完了時に実行されるコールバック関数
  final VoidCallback onShareComplete;

  // コンストラクタ - シェア完了時のコールバックを受け取る
  const ShareDialog({
    Key? key,
    required this.onShareComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isLargeScreen ? 500 : double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            const Text(
              'シェアしてAI使用回数を増やそう',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),

            const SizedBox(height: 16),

            // 説明文
            Text(
              'アイデアパッドをSNSでシェアすると、AI使用回数が${UserStats.shareBonus}回分増えます！',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // SNSボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareButton(
                  context: context,
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () => _shareToSNS(context, 'facebook'),
                  delay: 300,
                ),
                _buildShareButton(
                  context: context,
                  icon: Icons.textsms,
                  label: 'LINE',
                  color: const Color(0xFF06C755),
                  onTap: () => _shareToSNS(context, 'line'),
                  delay: 400,
                ),
                _buildShareButton(
                  context: context,
                  icon: Icons.camera_alt,
                  label: 'Instagram',
                  color: const Color(0xFFE4405F),
                  onTap: () => _shareToSNS(context, 'instagram'),
                  delay: 500,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // キャンセルボタン
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'キャンセル',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// シェアボタンのウィジェットを作成するヘルパーメソッド
  /// label: ボタンのラベル
  /// icon: アイコン
  /// color: ボタンの色
  /// onPressed: タップ時の処理
  Widget _buildShareButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color,
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ],
        ).animate().fadeIn(delay: Duration(milliseconds: delay)),
      ),
    );
  }

  /// SNSへのシェア処理
  Future<void> _shareToSNS(BuildContext context, String platform) async {
    // シェアURLを構築（実際のアプリでは適切なURLに変更）
    const String appStoreUrl = 'https://example.com/app';
    const String shareText = 'アイデアパッドで簡単にアイデア管理！';

    String url = '';

    switch (platform) {
      case 'facebook':
        url = 'https://www.facebook.com/sharer/sharer.php?u=$appStoreUrl';
        break;
      case 'line':
        url =
            'https://social-plugins.line.me/lineit/share?url=$appStoreUrl&text=$shareText';
        break;
      case 'instagram':
        // Instagramはディープリンクでのシェアが制限されているため、
        // 実際の実装ではクリップボードにコピーするなどの代替手段が必要
        url = 'https://www.instagram.com/';
        break;
      default:
        url = appStoreUrl;
    }

    // URLを開く
    if (await _launchURL(url)) {
      // シェア完了としてカウント
      await _incrementShareCount(context);
      onShareComplete();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// URLを開く処理
  Future<bool> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// シェア回数を増やす
  Future<void> _incrementShareCount(BuildContext context) async {
    try {
      final userStatsFuture = Provider.of<Future<UserStatsService>>(
        context,
        listen: false,
      );
      final userStatsService = await userStatsFuture;
      await userStatsService.addShareBonus();
      debugPrint('シェアボーナスを追加しました');
    } catch (e) {
      debugPrint('シェアボーナスの追加に失敗しました: $e');
    }
  }
}
