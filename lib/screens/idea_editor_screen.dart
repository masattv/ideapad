import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:idea_app/models/idea.dart';
import 'package:idea_app/services/database_service.dart';
import 'package:idea_app/config/themes.dart';
import 'package:provider/provider.dart';

class IdeaEditorScreen extends StatefulWidget {
  final Idea? idea; // 編集の場合は既存のアイデア、新規作成の場合はnull
  final int? parentId; // 親アイデアのID（子アイデア作成時のみ）

  const IdeaEditorScreen({
    Key? key,
    this.idea,
    this.parentId,
  }) : super(key: key);

  @override
  State<IdeaEditorScreen> createState() => _IdeaEditorScreenState();
}

class _IdeaEditorScreenState extends State<IdeaEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isProcessing = false;
  final List<String> _selectedTags = [];
  final List<String> _suggestedTags = [
    'アイデア',
    'ビジネス',
    'テクノロジー',
    'アート',
    'デザイン',
    '課題解決',
    '未来',
    '革新',
    'サービス',
    '製品',
  ];

  bool get _isEditMode => widget.idea != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      _contentController.text = widget.idea!.content;
      _selectedTags.addAll(widget.idea!.tags);
      _tagsController.text = _selectedTags.join(', ');
    }

    _loadSuggestedTags();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedTags() async {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    try {
      final ideas = await databaseService.getAllIdeas();

      // すべてのタグを集める
      final tagsSet = <String>{};
      for (final idea in ideas) {
        tagsSet.addAll(idea.tags);
      }

      // 既存のタグがある場合は優先的に表示
      if (tagsSet.isNotEmpty) {
        setState(() {
          _suggestedTags.clear();
          _suggestedTags.addAll(tagsSet.toList()..sort());
        });
      }
    } catch (e) {
      // エラーの場合はデフォルトタグを使用
      debugPrint('タグの読み込みに失敗しました: $e');
    }
  }

  Future<void> _saveIdea() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final content = _contentController.text.trim();
    final now = DateTime.now();

    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);

      if (_isEditMode) {
        // 既存のアイデアを更新
        final updatedIdea = widget.idea!.copyWith(
          content: content,
          updatedAt: now,
          tags: _selectedTags,
        );

        await databaseService.updateIdea(updatedIdea);
        _showSuccessSnackBar('アイデアを更新しました');
      } else {
        // 新しいアイデアを作成
        final newIdea = Idea(
          content: content,
          createdAt: now,
          updatedAt: now,
          tags: _selectedTags,
          parentId: widget.parentId,
        );

        await databaseService.insertIdea(newIdea);
        _showSuccessSnackBar('アイデアを保存しました');
      }

      if (mounted) {
        Navigator.pop(context, true); // 変更があったことを伝える
      }
    } catch (e) {
      _showErrorSnackBar('エラーが発生しました: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagsController.text = _selectedTags.join(', ');
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
      _tagsController.text = _selectedTags.join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'アイデアを編集' : 'アイデアを追加'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          TextButton.icon(
            onPressed: _isProcessing ? null : _saveIdea,
            icon: _isProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(Icons.save, color: colorScheme.onPrimary),
            label: Text(
              _isProcessing ? '保存中...' : '保存',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.parentId != null)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: AppThemes.accentBlueLight.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_tree,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '子アイデアを作成しています',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // アイデア入力フィールド
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'アイデア内容',
                  hintText: 'あなたのアイデアを入力してください...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'アイデア内容を入力してください';
                  }
                  return null;
                },
                textInputAction: TextInputAction.newline,
              ),

              const SizedBox(height: 24),

              // タグ入力フィールド
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'タグ',
                  hintText: 'カンマ区切りでタグを入力（例: アイデア, 技術）',
                  suffixIcon: Icon(Icons.tag),
                ),
                onFieldSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    final tags = value.split(',').map((e) => e.trim()).toList();
                    setState(() {
                      _selectedTags.clear();
                      _selectedTags.addAll(tags.where((tag) => tag.isNotEmpty));
                      _tagsController.text = _selectedTags.join(', ');
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // 選択済みタグ
              if (_selectedTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                        deleteIconColor: colorScheme.onPrimary,
                        backgroundColor: colorScheme.primary,
                        labelStyle: TextStyle(
                          color: colorScheme.onPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fade(duration: 200.ms).scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                    duration: 200.ms),

              // タグ候補
              if (_suggestedTags.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'タグを選択:',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestedTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _addTag(tag);
                            } else {
                              _removeTag(tag);
                            }
                          },
                          selectedColor: colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ).animate().fade(duration: 300.ms, delay: 100.ms).slide(
                    begin: const Offset(0, 0.1),
                    end: const Offset(0, 0),
                    duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
