import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_combination.dart';
import '../services/ai_idea_combination_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';

class CombinationScreen extends StatefulWidget {
  const CombinationScreen({Key? key}) : super(key: key);

  @override
  State<CombinationScreen> createState() => _CombinationScreenState();
}

class _CombinationScreenState extends State<CombinationScreen> {
  late Future<List<AICombination>> _combinationsFuture;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadCombinations();
  }

  void _loadCombinations() {
    final combinationService =
        Provider.of<AIIdeaCombinationService>(context, listen: false);
    _combinationsFuture = combinationService.getCombinations();
  }

  Future<void> _generateNewCombinations() async {
    if (!mounted) return;
    if (_isGenerating) return;

    final combinationService =
        Provider.of<AIIdeaCombinationService>(context, listen: false);

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
      } else {
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
        Provider.of<AIIdeaCombinationService>(context, listen: false);

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
        Provider.of<AIIdeaCombinationService>(context, listen: false);

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
        ],
      ),
      body: _isGenerating
          ? const LoadingIndicator(message: '新しいアイデアの組み合わせを生成中...')
          : FutureBuilder<List<AICombination>>(
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

                final combinations = snapshot.data ?? [];
                if (combinations.isEmpty) {
                  return EmptyState(
                    title: 'アイデアの組み合わせがありません',
                    message:
                        '「新しい組み合わせを生成」ボタンをタップして、AIによるアイデアの組み合わせを作成してみましょう。',
                    actionLabel: '組み合わせを生成',
                    onAction: _generateNewCombinations,
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
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateNewCombinations,
        icon: const Icon(Icons.shuffle),
        label: const Text('新しい組み合わせを生成'),
      ),
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
              combination.generatedIdea,
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
