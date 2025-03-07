import 'package:flutter/material.dart';
import 'package:idea_app/config/routes.dart';
import 'package:idea_app/config/themes.dart';
import 'package:idea_app/models/idea.dart';
import 'package:idea_app/services/database_service.dart';
import 'package:idea_app/widgets/idea_card.dart';
import 'package:idea_app/widgets/empty_state.dart';
import 'package:idea_app/widgets/loading_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Idea> _ideas = [];
  bool _isLoading = true;
  String _searchQuery = '';
  List<String> _selectedTags = [];
  final List<String> _availableTags = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  Future<void> _loadIdeas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ideas = await _databaseService.getAllIdeas();
      final Set<String> tags = {};
      for (final idea in ideas) {
        tags.addAll(idea.tags);
      }

      setState(() {
        _ideas = ideas;
        _availableTags.clear();
        _availableTags.addAll(tags.toList()..sort());
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('アイデアの読み込みに失敗しました: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Idea> get _filteredIdeas {
    if (_searchQuery.isEmpty && _selectedTags.isEmpty) {
      return _ideas;
    }

    return _ideas.where((idea) {
      final matchesQuery = _searchQuery.isEmpty ||
          idea.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final hasTags = _selectedTags.isEmpty ||
          _selectedTags.every((tag) => idea.tags.contains(tag));
      return matchesQuery && hasTags;
    }).toList();
  }

  void _navigateToCreateIdea() {
    Navigator.pushNamed(
      context,
      AppRoutes.ideaEditor,
      arguments: {'idea': null, 'parentId': null},
    ).then((_) => _loadIdeas());
  }

  void _navigateToCombinations() {
    Navigator.pushNamed(context, AppRoutes.combinations);
  }

  // 詳細画面への遷移
  void _navigateToIdeaDetails(Idea idea) {
    Navigator.pushNamed(
      context,
      AppRoutes.ideaEditor,
      arguments: {'idea': idea, 'parentId': null},
    ).then((_) => _loadIdeas());
  }

  // 編集画面への遷移
  void _navigateToEditIdea(Idea idea) {
    Navigator.pushNamed(
      context,
      AppRoutes.ideaEditor,
      arguments: {'idea': idea, 'parentId': null},
    ).then((_) => _loadIdeas());
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

    if (confirmed != true) return;

    try {
      await _databaseService.softDeleteIdea(idea.id!);
      if (!mounted) return;

      setState(() {
        _ideas.removeWhere((i) => i.id == idea.id);
        _filteredIdeas.removeWhere((i) => i.id == idea.id);
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }

  // 削除の取り消し処理
  Future<void> _undoDelete(Idea idea) async {
    try {
      final updatedIdea = idea.copyWith(isDeleted: false);
      await _databaseService.updateIdea(updatedIdea);
      _loadIdeas(); // 一覧を再読み込み
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作の取り消しに失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator()
                  : _filteredIdeas.isEmpty
                      ? EmptyState(
                          title: 'アイデアがありません',
                          message: _searchQuery.isNotEmpty ||
                                  _selectedTags.isNotEmpty
                              ? '検索条件を変更してください'
                              : 'アイデアを追加してみましょう',
                          actionLabel: 'アイデアを追加',
                          onAction: _navigateToCreateIdea,
                        )
                      : _buildIdeaList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            _navigateToCombinations();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateIdea,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: _availableTags.isEmpty ? 80 : 140,
      borderRadius: 0,
      blur: 10,
      alignment: Alignment.center,
      border: 0,
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
            TextField(
              decoration: InputDecoration(
                hintText: 'アイデアを検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
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
                  _searchQuery = value;
                });
              },
            ),
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
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
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
        ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(
            begin: 0.1, end: 0, duration: 300.ms, delay: (50 * index).ms);
      },
    );
  }
}
