import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_combination.dart';
import '../models/user_stats.dart';
import '../services/ai_idea_combination_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/share_dialog.dart';

class CombinationScreen extends StatefulWidget {
  const CombinationScreen({Key? key}) : super(key: key);

  @override
  State<CombinationScreen> createState() => _CombinationScreenState();
}

class _CombinationScreenState extends State<CombinationScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<AICombination>> _combinationsFuture;
  bool _isGenerating = false;
  late TabController _tabController;
  late Future<UserStats> _userStatsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCombinations();
    _loadUserStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCombinations() {
    final combinationService =
        Provider.of<Future<AIIdeaCombinationService>>(context, listen: false);
    _combinationsFuture =
        combinationService.then((service) => service.getCombinations());
  }

  void _loadUserStats() {
    final combinationService =
        Provider.of<Future<AIIdeaCombinationService>>(context, listen: false);
    _userStatsFuture =
        combinationService.then((service) => service.getUserStats());
  }

  Future<void> _showShareDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ShareDialog(
        onShareComplete: () {
          // シェア完了後にユーザー統計を再読込
          _loadUserStats();
        },
      ),
    );
  }

  Future<void> _generateNewCombinations() async {
    if (!mounted) return;
    if (_isGenerating) return;

    final combinationService =
        await Provider.of<Future<AIIdeaCombinationService>>(context,
            listen: false);

    // ユーザー統計情報を取得して、AI使用可能かチェック
    final stats = await combinationService.getUserStats();
    if (!stats.canUseAI) {
      if (!mounted) return;

      // 使用制限に達している場合はシェアダイアログを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('今月のAI使用回数制限に達しました。SNSでシェアして追加の使用回数を獲得できます。'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );

      await _showShareDialog();
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // 3つの新しい組み合わせを生成
      final combinations = await combinationService.generateCombinations(3);

      if (combinations.isNotEmpty) {
        // 生成された組み合わせを保存
        await combinationService.saveCombinations(combinations);
        // リストを更新
        _loadCombinations();
        // ユーザー統計を更新
        _loadUserStats();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('組み合わせの生成に失敗しました。アイデアが少なすぎる可能性があります。')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _toggleFavorite(AICombination combination) async {
    if (combination.id == null) return;

    final combinationService =
        await Provider.of<Future<AIIdeaCombinationService>>(context,
            listen: false);

    try {
      await combinationService.toggleFavorite(combination.id!);
      _loadCombinations(); // リストを更新
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('お気に入り設定の更新に失敗しました: $e')),
      );
    }
  }

  Future<void> _saveAsNewIdea(AICombination combination) async {
    final combinationService =
        await Provider.of<Future<AIIdeaCombinationService>>(context,
            listen: false);

    try {
      final newIdea = await combinationService.saveAsNewIdea(combination);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('新しいアイデアとして保存しました'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存に失敗しました: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildUsageInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FutureBuilder<UserStats>(
        future: _userStatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('AI使用可能回数を確認中...');
          }

          if (snapshot.hasError) {
            return Text('エラー: ${snapshot.error}');
          }

          final stats = snapshot.data;
          if (stats == null) {
            return const Text('AI使用情報が取得できません');
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '今月の残りAI使用回数: ${stats.remainingUsage}回',
                style: TextStyle(
                  color: stats.canUseAI
                      ? Theme.of(context).textTheme.bodyMedium?.color
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!stats.canUseAI)
                TextButton.icon(
                  onPressed: _showShareDialog,
                  icon: const Icon(Icons.share),
                  label: const Text('シェアして回数追加'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アイデア組み合わせ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCombinations,
            tooltip: '更新',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showShareDialog,
            tooltip: 'シェアして回数を増やす',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'すべて'),
            Tab(text: 'お気に入り'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildUsageInfo(),
          Expanded(
            child: _isGenerating
                ? const LoadingIndicator(message: '新しいアイデアの組み合わせを生成中...')
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCombinationList(false), // すべての組み合わせ
                      _buildCombinationList(true), // お気に入りのみ
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<UserStats>(
        future: _userStatsFuture,
        builder: (context, snapshot) {
          final bool canUseAI = snapshot.data?.canUseAI ?? false;
          return FloatingActionButton.extended(
            onPressed: canUseAI ? _generateNewCombinations : _showShareDialog,
            icon: Icon(canUseAI ? Icons.shuffle : Icons.share),
            label: Text(canUseAI ? '新しい組み合わせを生成' : 'シェアして回数を増やす'),
            backgroundColor: canUseAI
                ? Theme.of(context).colorScheme.primary
                : Colors.orange,
          );
        },
      ),
    );
  }

  Widget _buildCombinationList(bool favoritesOnly) {
    return FutureBuilder<List<AICombination>>(
      future: _combinationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: '組み合わせを読み込み中...');
        }

        if (snapshot.hasError) {
          return EmptyState(
            title: 'エラーが発生しました',
            message: '${snapshot.error}',
            actionLabel: '再試行',
            onAction: _loadCombinations,
          );
        }

        final allCombinations = snapshot.data ?? [];

        // お気に入りタブの場合はフィルタリング
        final combinations = favoritesOnly
            ? allCombinations.where((c) => c.isFavorite).toList()
            : allCombinations;

        if (combinations.isEmpty) {
          return EmptyState(
            title: favoritesOnly ? 'お気に入りの組み合わせがありません' : 'アイデアの組み合わせがありません',
            message: favoritesOnly
                ? 'ハートアイコンをタップして、お気に入りの組み合わせを追加しましょう。'
                : '「新しい組み合わせを生成」ボタンをタップして、AIによるアイデアの組み合わせを作成してみましょう。',
            actionLabel: favoritesOnly ? '全ての組み合わせを見る' : '組み合わせを生成',
            onAction: favoritesOnly
                ? () => _tabController.animateTo(0)
                : _generateNewCombinations,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: combinations.length,
          itemBuilder: (context, index) {
            final combination = combinations[index];
            return _buildCombinationCard(combination);
          },
        );
      },
    );
  }

  Widget _buildCombinationCard(AICombination combination) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 元のアイデア情報
            Row(
              children: [
                Expanded(
                  child: _buildSourceIdeaChip(
                    combination.ideaA?.content ?? '元アイデア1',
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSourceIdeaChip(
                    combination.ideaB?.content ?? '元アイデア2',
                    theme.colorScheme.secondary.withOpacity(0.2),
                    theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 生成されたアイデア
            Text(
              combination.combinedContent,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (combination.reasoning != null &&
                combination.reasoning!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                combination.reasoning!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],

            // アクションボタン
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    combination.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: combination.isFavorite ? Colors.red : null,
                  ),
                  onPressed: () => _toggleFavorite(combination),
                  tooltip: combination.isFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
                ),
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  onPressed: () => _saveAsNewIdea(combination),
                  tooltip: '新しいアイデアとして保存',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceIdeaChip(
      String content, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        content,
        style: TextStyle(color: textColor, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
