import 'dart:math';
import 'package:idea_app/models/idea.dart';
import 'package:idea_app/models/idea_combination.dart';
import 'package:idea_app/services/database_service.dart';

class IdeaService {
  final DatabaseService _databaseService = DatabaseService();
  
  // 新しいアイデアを保存
  Future<Idea> saveIdea(String content) async {
    final now = DateTime.now();
    final idea = Idea(
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    
    final id = await _databaseService.insertIdea(idea);
    return idea.copyWith(id: id);
  }
  
  // 全てのアイデアを取得
  Future<List<Idea>> getAllIdeas() async {
    return await _databaseService.getAllIdeas();
  }
  
  // アイデアを更新
  Future<Idea> updateIdea(Idea idea, String content) async {
    final updatedIdea = idea.copyWith(
      content: content,
      updatedAt: DateTime.now(),
    );
    
    await _databaseService.updateIdea(updatedIdea);
    return updatedIdea;
  }
  
  // アイデアを削除
  Future<void> deleteIdea(int id) async {
    await _databaseService.deleteIdea(id);
  }
  
  // アイデアの組み合わせを生成
  Future<List<IdeaCombination>> generateIdeaCombinations(int count) async {
    final ideas = await getAllIdeas();
    
    // アイデアが2つ未満の場合は組み合わせを生成できない
    if (ideas.length < 2) {
      return [];
    }
    
    final random = Random();
    final List<IdeaCombination> combinations = [];
    
    // 指定された数の組み合わせを生成
    for (int i = 0; i < count; i++) {
      // ランダムに2つのアイデアを選択
      final ideaIndices = _getRandomUniqueIndices(ideas.length, 2, random);
      final selectedIdeas = [
        ideas[ideaIndices[0]],
        ideas[ideaIndices[1]],
      ];
      
      final ideaIds = selectedIdeas.map((idea) => idea.id!).toList();
      final combinationTemplate = _getCombinationTemplate(random);
      final combinedContent = _formatCombination(
        selectedIdeas[0].content,
        selectedIdeas[1].content,
        combinationTemplate,
      );
      
      final combination = IdeaCombination(
        ideaIds: ideaIds,
        combinedContent: combinedContent,
        createdAt: DateTime.now(),
      );
      
      combinations.add(combination);
    }
    
    return combinations;
  }
  
  // 生成した組み合わせを保存
  Future<IdeaCombination> saveCombination(IdeaCombination combination) async {
    final id = await _databaseService.insertIdeaCombination(combination);
    return combination.copyWith(id: id);
  }
  
  // 複数の組み合わせを一括保存
  Future<List<IdeaCombination>> saveCombinations(List<IdeaCombination> combinations) async {
    final savedCombinations = <IdeaCombination>[];
    
    for (final combination in combinations) {
      final savedCombination = await saveCombination(combination);
      savedCombinations.add(savedCombination);
    }
    
    return savedCombinations;
  }
  
  // 全ての組み合わせを取得
  Future<List<IdeaCombination>> getAllCombinations() async {
    return await _databaseService.getAllIdeaCombinations();
  }
  
  // お気に入りの組み合わせを取得
  Future<List<IdeaCombination>> getFavoriteCombinations() async {
    return await _databaseService.getFavoriteIdeaCombinations();
  }
  
  // 組み合わせをお気に入り登録/解除
  Future<IdeaCombination> toggleFavorite(IdeaCombination combination) async {
    final updatedCombination = combination.copyWith(
      isFavorite: !combination.isFavorite,
    );
    
    await _databaseService.updateIdeaCombination(updatedCombination);
    return updatedCombination;
  }
  
  // 組み合わせを削除
  Future<void> deleteCombination(int id) async {
    await _databaseService.deleteIdeaCombination(id);
  }
  
  // ユーティリティメソッド ----------------------
  
  // 重複しないランダムなインデックスを取得
  List<int> _getRandomUniqueIndices(int max, int count, Random random) {
    final Set<int> indices = {};
    
    while (indices.length < count) {
      indices.add(random.nextInt(max));
    }
    
    return indices.toList();
  }
  
  // 組み合わせテンプレートをランダムに取得
  String _getCombinationTemplate(Random random) {
    final templates = [
      "「{0}」と「{1}」を組み合わせると、新しいアイデアが生まれるかもしれません。",
      "「{0}」の概念を「{1}」に適用すると、どのような可能性が見えてくるでしょうか？",
      "「{0}」の特性と「{1}」の機能性を融合させるとどうなりますか？",
      "「{0}」の問題を「{1}」のアプローチで解決してみてはどうでしょう？",
      "「{0}」をベースに「{1}」の要素を取り入れた新製品を考えられますか？",
      "「{0}」の対象者に「{1}」のサービスを提供すると何が起こりますか？",
      "「{0}」の世界観で「{1}」を再解釈するとどうなりますか？",
      "もし「{0}」と「{1}」が出会ったら、どんな化学反応が起きるでしょう？",
    ];
    
    return templates[random.nextInt(templates.length)];
  }
  
  // テンプレートに実際のアイデア内容を挿入
  String _formatCombination(String idea1, String idea2, String template) {
    return template.replaceAll('{0}', idea1).replaceAll('{1}', idea2);
  }
} 