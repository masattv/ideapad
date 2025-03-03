import 'dart:math';
import 'package:idea_app/models/idea.dart';
import 'package:idea_app/models/idea_combination.dart';

class IdeaAlgorithm {
  // ランダムな組み合わせを生成
  static List<IdeaCombination> generateRandomCombinations(
    List<Idea> ideas,
    int count,
  ) {
    if (ideas.length < 2) {
      return [];
    }

    final random = Random();
    final List<IdeaCombination> combinations = [];
    final Set<String> usedCombinations = {}; // 重複チェック用

    // 必要な数の組み合わせを生成するか、全ての組み合わせを試すまでループ
    int attempts = 0;
    final maxAttempts = ideas.length * ideas.length; // 最大試行回数

    while (combinations.length < count && attempts < maxAttempts) {
      attempts++;
      
      // ランダムに2つのアイデアを選択
      final idea1Index = random.nextInt(ideas.length);
      int idea2Index;
      
      do {
        idea2Index = random.nextInt(ideas.length);
      } while (idea2Index == idea1Index); // 同じアイデアを選ばないようにする
      
      final idea1 = ideas[idea1Index];
      final idea2 = ideas[idea2Index];
      
      // 組み合わせのキーを作成（重複チェック用）
      final combinationKey = '${idea1.id}-${idea2.id}';
      final reverseCombinationKey = '${idea2.id}-${idea1.id}';
      
      // 既に同じ組み合わせがある場合はスキップ
      if (usedCombinations.contains(combinationKey) || 
          usedCombinations.contains(reverseCombinationKey)) {
        continue;
      }
      
      usedCombinations.add(combinationKey);
      
      // テンプレートを選択
      final template = _getRandomTemplate(random);
      
      // 組み合わせコンテンツを生成
      final combinedContent = _applyCombinationTemplate(
        template,
        idea1.content,
        idea2.content,
      );
      
      // 組み合わせオブジェクトを作成
      final combination = IdeaCombination(
        ideaIds: [idea1.id!, idea2.id!],
        combinedContent: combinedContent,
        createdAt: DateTime.now(),
      );
      
      combinations.add(combination);
    }
    
    return combinations;
  }
  
  // 類似性に基づく組み合わせを生成（将来的な拡張用）
  static List<IdeaCombination> generateSimilarityCombinations(
    List<Idea> ideas,
    int count,
  ) {
    // 実際の実装では、テキスト分析や単語の類似性を計算するアルゴリズムを使用
    // 現時点ではランダム生成と同じ動作
    return generateRandomCombinations(ideas, count);
  }
  
  // ランダムなテンプレートを取得
  static String _getRandomTemplate(Random random) {
    final templates = [
      "「{0}」と「{1}」を組み合わせると、新しいアイデアが生まれるかもしれません。",
      "「{0}」の概念を「{1}」に適用すると、どのような可能性が見えてくるでしょうか？",
      "「{0}」の特性と「{1}」の機能性を融合させるとどうなりますか？",
      "「{0}」の問題を「{1}」のアプローチで解決してみてはどうでしょう？",
      "「{0}」をベースに「{1}」の要素を取り入れた新製品を考えられますか？",
      "「{0}」の対象者に「{1}」のサービスを提供すると何が起こりますか？",
      "「{0}」の世界観で「{1}」を再解釈するとどうなりますか？",
      "もし「{0}」と「{1}」が出会ったら、どんな化学反応が起きるでしょう？",
      "「{0}」のユーザー体験に「{1}」の要素を加えるとどうなりますか？",
      "「{0}」のコンセプトと「{1}」のデザインを融合させてみましょう。",
      "「{0}」の市場に「{1}」のビジネスモデルを導入したらどうなりますか？",
      "「{0}」の技術で「{1}」の課題を解決できないでしょうか？",
    ];
    
    return templates[random.nextInt(templates.length)];
  }
  
  // テンプレートにアイデアを適用
  static String _applyCombinationTemplate(
    String template,
    String idea1,
    String idea2,
  ) {
    return template
        .replaceAll('{0}', idea1)
        .replaceAll('{1}', idea2);
  }
  
  // キーワード抽出（将来的な拡張用）
  static List<String> _extractKeywords(String text) {
    // 実際の実装では、形態素解析や自然言語処理を使用してキーワードを抽出
    // 現時点では簡易的な実装
    final words = text.split(' ');
    return words.where((word) => word.length > 1).toList();
  }
} 