import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_idea_combination_service.dart';
import '../models/user_stats.dart';

/// SNSシェアダイアログ
class ShareDialog extends StatelessWidget {
  final VoidCallback? onShareComplete;

  const ShareDialog({Key? key, this.onShareComplete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AIポイントを獲得'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SNSでシェアして、AI使用回数を増やしましょう！\n'
            'シェアすると100回分のAI使用ポイントが追加されます。',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareButton(
                context,
                'Twitter',
                Icons.chat,
                Colors.blue,
                _shareToTwitter,
              ),
              _buildShareButton(
                context,
                'Facebook',
                Icons.facebook,
                Colors.indigo,
                _shareToFacebook,
              ),
              _buildShareButton(
                context,
                'LINE',
                Icons.message,
                Colors.green,
                _shareToLINE,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }

  /// シェアボタンのウィジェットを作成
  Widget _buildShareButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    Future<void> Function(BuildContext) onPressed,
  ) {
    return InkWell(
      onTap: () => onPressed(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Twitterでシェア
  Future<void> _shareToTwitter(BuildContext context) async {
    const text = 'アイデアパッドでアイデアを管理しています！ #アイデアパッド #アイデア管理';
    final uri = Uri.parse('https://twitter.com/intent/tweet?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await _completeShare(context);
    } else {
      _showError(context, 'Twitterを開けませんでした');
    }
  }

  /// Facebookでシェア
  Future<void> _shareToFacebook(BuildContext context) async {
    final uri = Uri.parse(
        'https://www.facebook.com/sharer/sharer.php?u=https://example.com/ideapad');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await _completeShare(context);
    } else {
      _showError(context, 'Facebookを開けませんでした');
    }
  }

  /// LINEでシェア
  Future<void> _shareToLINE(BuildContext context) async {
    const text = 'アイデアパッドでアイデアを管理しています！';
    final uri = Uri.parse('https://line.me/R/msg/text/?$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await _completeShare(context);
    } else {
      _showError(context, 'LINEを開けませんでした');
    }
  }

  /// シェア完了時の処理
  Future<void> _completeShare(BuildContext context) async {
    try {
      final service =
          Provider.of<Future<AIIdeaCombinationService>>(context, listen: false);
      final aiService = await service;
      final stats = await aiService.addShareBonus();

      if (!context.mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('シェアありがとうございます！${UserStats.shareBonus}回分のAI使用ポイントが追加されました。'),
          backgroundColor: Colors.green,
        ),
      );

      onShareComplete?.call();
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'ポイント追加に失敗しました: $e');
    }
  }

  /// エラー表示
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
