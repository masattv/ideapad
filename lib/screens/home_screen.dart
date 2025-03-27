// 必要なパッケージのインポート
import 'package:flutter/material.dart'; // Flutterの基本的なウィジェット
import 'package:idea_app/config/routes.dart'; // アプリのルート定義
import 'package:idea_app/config/themes.dart'; // アプリのテーマ設定
import 'package:idea_app/models/idea.dart'; // アイデアモデルクラス
import 'package:idea_app/services/database_service.dart'; // データベース操作用サービス
import 'package:idea_app/widgets/idea_card.dart'; // アイデアカードウィジェット
import 'package:idea_app/widgets/empty_state.dart'; // 空の状態を表示するウィジェット
import 'package:idea_app/widgets/loading_indicator.dart'; // ローディング表示用ウィジェット
import 'package:flutter_animate/flutter_animate.dart'; // アニメーション用パッケージ
import 'package:glassmorphism/glassmorphism.dart'; // ガラスモーフィズム効果用パッケージ

// ホーム画面のStatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ホーム画面のState管理クラス
class _HomeScreenState extends State<HomeScreen> {
  // データベースサービスのインスタンス
  final DatabaseService _databaseService = DatabaseService();
  // アイデアのリスト
  List<Idea> _ideas = [];
  // ローディング状態
  bool _isLoading = true;
  // 検索クエリ
  String _searchQuery = '';
  // 選択されたタグのリスト
  List<String> _selectedTags = [];
  // 利用可能なタグのリスト
  final List<String> _availableTags = [];
  // 選択されているナビゲーションインデックス
  int _selectedIndex = 0;

  @override
  // 初期化処理
  void initState() {
    super.initState();
    _loadIdeas(); // アイデアの読み込み
  }

  // アイデアをデータベースから読み込む
  Future<void> _loadIdeas() async {
    setState(() {
      _isLoading = true; // ローディング状態を開始
    });

    try {
      final ideas = await _databaseService.getAllIdeas(); // 全アイデアを取得
      final Set<String> tags = {}; // タグの重複を除去するためのSet
      // 各アイデアからタグを収集
      for (final idea in ideas) {
        tags.addAll(idea.tags);
      }

      setState(() {
        _ideas = ideas; // アイデアリストを更新
        _availableTags.clear(); // タグリストをクリア
        _availableTags.addAll(tags.toList()..sort()); // ソートしたタグリストを追加
        _isLoading = false; // ローディング状態を終了
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // エラー時もローディング状態を終了
      });
      _showErrorSnackBar('アイデアの読み込みに失敗しました: $e'); // エラーメッセージを表示
    }
  }

  // エラーメッセージをSnackBarで表示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 検索条件に基づいてフィルタリングされたアイデアリストを取得
  List<Idea> get _filteredIdeas {
    if (_searchQuery.isEmpty && _selectedTags.isEmpty) {
      return _ideas; // 検索条件がない場合は全アイデアを返す
    }

    return _ideas.where((idea) {
      // 検索クエリとタグでフィルタリング
      final matchesQuery = _searchQuery.isEmpty ||
          idea.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final hasTags = _selectedTags.isEmpty ||
          _selectedTags.every((tag) => idea.tags.contains(tag));
      return matchesQuery && hasTags;
    }).toList();
  }

  // アイデア作成画面への遷移
  void _navigateToCreateIdea() {
    Navigator.pushNamed(
      context,
      AppRoutes.ideaEditor,
      arguments: {'idea': null, 'parentId': null},
    ).then((_) => _loadIdeas()); // 画面から戻ったらアイデアを再読み込み
  }

  // アイデア組み合わせ画面への遷移
  void _navigateToCombinations() {
    Navigator.pushNamed(context, AppRoutes.combinations);
  }

  // アイデア詳細画面への遷移
  void _navigateToIdeaDetails(Idea idea) {
    Navigator.pushNamed(
      context,
      AppRoutes.ideaEditor,
      arguments: {'idea': idea, 'parentId': null},
    ).then((_) => _loadIdeas()); // 画面から戻ったらアイデアを再読み込み
  }

  // アイデア編集画面への遷移
  void _navigateToEditIdea(Idea idea) {
    Navigator.pushNamed(
      context,
      AppRoutes.ideaEditor,
      arguments: {'idea': idea, 'parentId': null},
    ).then((_) => _loadIdeas()); // 画面から戻ったらアイデアを再読み込み
  }

  // アイデアの削除処理
  Future<void> _deleteIdea(Idea idea) async {
    // 確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイデアの削除'),
        content: const Text('このアイデアを削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return; // キャンセルされた場合は処理を中断

    try {
      // アイデアの論理削除を実行
      await _databaseService.softDeleteIdea(idea.id!);
      if (!mounted) return;

      setState(() {
        // UIからアイデアを削除
        _ideas.removeWhere((i) => i.id == idea.id);
        _filteredIdeas.removeWhere((i) => i.id == idea.id);
      });

      // 削除完了のSnackBarを表示（元に戻すオプション付き）
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('アイデアを削除しました'),
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: () => _undoDelete(idea),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // エラー時のSnackBarを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }

  // 削除の取り消し処理
  Future<void> _undoDelete(Idea idea) async {
    try {
      // 削除フラグを戻してアイデアを更新
      final updatedIdea = idea.copyWith(isDeleted: false);
      await _databaseService.updateIdea(updatedIdea);
      _loadIdeas(); // 一覧を再読み込み
    } catch (e) {
      if (!mounted) return;
      // エラー時のSnackBarを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作の取り消しに失敗しました: $e')),
      );
    }
  }

  @override
  // UIの構築
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context), // 検索バーを構築
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator() // ローディング中はインジケータを表示
                  : _filteredIdeas.isEmpty
                      ? EmptyState(
                          // アイデアがない場合は空の状態を表示
                          title: 'アイデアがありません',
                          message: _searchQuery.isNotEmpty ||
                                  _selectedTags.isNotEmpty
                              ? '検索条件を変更してください'
                              : 'アイデアを追加してみましょう',
                          actionLabel: 'アイデアを追加',
                          onAction: _navigateToCreateIdea,
                        )
                      : _buildIdeaList(), // アイデアリストを表示
            ),
          ],
        ),
      ),
      // 下部ナビゲーションバー
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            _navigateToCombinations(); // 組み合わせ画面に遷移
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'アイデア',
          ),
          NavigationDestination(
            icon: Icon(Icons.shuffle),
            selectedIcon: Icon(Icons.shuffle_on),
            label: '組み合わせ',
          ),
        ],
      ),
      // 新規作成用のフローティングアクションボタン
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateIdea,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 検索バーウィジェットの構築
  Widget _buildSearchBar(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: _availableTags.isEmpty ? 80 : 140, // タグの有無で高さを調整
      borderRadius: 0,
      blur: 10,
      alignment: Alignment.center,
      border: 0,
      // ガラスモーフィズム効果のグラデーション設定
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withOpacity(0.1),
          const Color(0xFFFFFFFF).withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withOpacity(0.5),
          const Color((0xFFFFFFFF)).withOpacity(0.5),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 検索テキストフィールド
            TextField(
              decoration: InputDecoration(
                hintText: 'アイデアを検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        // 検索クエリがある場合はクリアボタンを表示
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value; // 検索クエリを更新
                });
              },
            ),
            // タグフィルター
            if (_availableTags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag); // タグを選択
                            } else {
                              _selectedTags.remove(tag); // タグの選択を解除
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // アイデアリストウィジェットの構築
  Widget _buildIdeaList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredIdeas.length,
      itemBuilder: (context, index) {
        final idea = _filteredIdeas[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IdeaCard(
            idea: idea,
            onTap: () => _navigateToIdeaDetails(idea),
            onEdit: () => _navigateToEditIdea(idea),
            onDelete: () => _deleteIdea(idea),
          ),
        )
            .animate() // アニメーション効果を追加
            .fadeIn(duration: 300.ms, delay: (50 * index).ms) // フェードイン
            .slideY(
                // 上からスライドイン
                begin: 0.1,
                end: 0,
                duration: 300.ms,
                delay: (50 * index).ms);
      },
    );
  }
}
