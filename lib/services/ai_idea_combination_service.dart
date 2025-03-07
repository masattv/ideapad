import 'dart:math';
import '../models/idea.dart';
import '../models/ai_combination.dart';
import '../models/user_stats.dart';
import 'open_ai_client.dart';
import 'database_service.dart';
import 'user_stats_service.dart';

class AIIdeaCombinationService {
  final OpenAIClient _openAiClient;
  final DatabaseService _databaseService;
  final UserStatsService _userStatsService;

  AIIdeaCombinationService(
    this._openAiClient,
    this._databaseService,
    this._userStatsService,
  );

  // データベースからすべての組み合わせを取得
  Future<List<AICombination>> getCombinations() async {
    try {
      return await _databaseService.getAllAICombinations();
    } catch (e) {
      print('組み合わせの取得中にエラーが発生しました: $e');
      return [];
    }
  }

  // 現在のAI使用状況を取得
  Future<UserStats> getUserStats() {
    return _userStatsService.getUserStats();
  }

  // ランダムなアイデアのペアを選択するプライベートメソッド
  List<List<Idea>> _selectIdeaPairs(List<Idea> ideas, int count) {
    if (ideas.length < 2) {
      throw ArgumentError('アイデアの組み合わせを生成するには、少なくとも2つのアイデアが必要です');
    }

    final random = Random();
    final Set<String> selectedPairHashes = {};
    final List<List<Idea>> pairs = [];

    // 必要な数のユニークなペアを選択
    while (pairs.length < count &&
        pairs.length < ideas.length * (ideas.length - 1) ~/ 2) {
      // ランダムな2つのインデックスを取得
      int indexA = random.nextInt(ideas.length);
      int indexB;
      do {
        indexB = random.nextInt(ideas.length);
      } while (indexA == indexB);

      // ペアのハッシュを作成（順序に依存しない）
      final pairHash = [ideas[indexA].id, ideas[indexB].id]
          .whereType<int>() // nullではないidのみをフィルタリング
          .toList()
        ..sort(); // IDを昇順にソート
      final hash = pairHash.join('_');

      // まだ選択されていないユニークなペアの場合、追加
      if (!selectedPairHashes.contains(hash)) {
        selectedPairHashes.add(hash);
        pairs.add([ideas[indexA], ideas[indexB]]);
      }
    }

    return pairs;
  }

  // 組み合わせを生成するメソッド
  Future<List<AICombination>> generateCombinations(int count) async {
    try {
      // AI使用可能かどうかチェック
      final userStats = await _userStatsService.getUserStats();
      if (!userStats.canUseAI) {
        throw Exception('今月のAI使用回数制限に達しました。SNSでシェアして追加の使用回数を獲得してください。');
      }

      // 生成可能な最大数を制限（残りの回数以上は生成しない）
      final actualCount = min(count, userStats.remainingUsage);

      // すべてのアイデアを取得
      final ideas = await _databaseService.getAllIdeas();

      if (ideas.length < 2) {
        throw Exception('アイデアの組み合わせを生成するには、少なくとも2つのアイデアが必要です');
      }

      // ランダムなアイデアのペアを選択
      final ideaPairs = _selectIdeaPairs(ideas, actualCount);
      final combinations = <AICombination>[];

      // 各ペアに対して組み合わせを生成
      for (final pair in ideaPairs) {
        try {
          // AI使用回数をインクリメント（各ペアごとに1回とカウント）
          await _userStatsService.incrementAIUsage();

          // OpenAI APIを使用してアイデアを組み合わせる
          final result = await _openAiClient.generateIdeaCombination(
              pair[0].content, pair[1].content);

          // 組み合わせ結果をモデルに変換
          final combination = AICombination(
            ideaIds: [pair[0].id, pair[1].id].whereType<int>().toList(),
            combinedContent: result['combinedIdea'] ?? '',
            reasoning: result['reasoning'],
            createdAt: DateTime.now(),
            isFavorite: false,
            ideaA: pair[0],
            ideaB: pair[1],
          );

          combinations.add(combination);
        } catch (e) {
          print('組み合わせの生成中にエラーが発生しました: $e');
          // エラーが発生しても処理を継続し、他のペアの組み合わせを試みる
        }
      }

      return combinations;
    } catch (e) {
      print('組み合わせの生成プロセス中にエラーが発生しました: $e');
      rethrow;
    }
  }

  // SNSでシェアして追加使用回数を獲得
  Future<UserStats> addShareBonus() async {
    return await _userStatsService.addShareBonus();
  }

  // 生成された組み合わせをデータベースに保存
  Future<List<AICombination>> saveCombinations(
      List<AICombination> combinations) async {
    final savedCombinations = <AICombination>[];

    for (final combination in combinations) {
      try {
        final id = await _databaseService.insertAICombination(combination);
        savedCombinations.add(combination.copyWith(id: id));
      } catch (e) {
        print('組み合わせの保存中にエラーが発生しました: $e');
        // エラーが発生しても処理を継続し、他の組み合わせを保存する
      }
    }

    return savedCombinations;
  }

  // 組み合わせのお気に入り状態を切り替える
  Future<void> toggleFavorite(int combinationId) async {
    try {
      // 現在の組み合わせを取得
      final combination =
          await _databaseService.getAICombination(combinationId);
      if (combination != null) {
        // お気に入り状態を反転させて更新
        final updatedCombination =
            combination.copyWith(isFavorite: !combination.isFavorite);
        await _databaseService.updateAICombination(updatedCombination);
      }
    } catch (e) {
      print('お気に入り状態の切り替え中にエラーが発生しました: $e');
      rethrow;
    }
  }

  // 組み合わせを新しいアイデアとして保存
  Future<Idea> saveAsNewIdea(AICombination combination) async {
    final now = DateTime.now();
    final newIdea = Idea(
      content: combination.combinedContent,
      tags: ['AI組み合わせ', 'アイデア融合'],
      createdAt: now,
      updatedAt: now,
    );

    try {
      final id = await _databaseService.insertIdea(newIdea);
      return newIdea.copyWith(id: id);
    } catch (e) {
      print('新しいアイデアとして保存中にエラーが発生しました: $e');
      rethrow;
    }
  }
}
