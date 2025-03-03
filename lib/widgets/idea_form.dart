import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:idea_app/utils/constants.dart';

class IdeaForm extends StatefulWidget {
  final Function(String) onSubmit;

  const IdeaForm({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<IdeaForm> createState() => _IdeaFormState();
}

class _IdeaFormState extends State<IdeaForm> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // フォーム送信処理
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(_textController.text);
      
      if (!mounted) return;
      
      // 送信後にフォームをクリア
      _textController.clear();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // アイデア入力フィールド
          TextFormField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: AppConstants.ideaInputHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              ),
              fillColor: Theme.of(context).cardColor,
              filled: true,
            ),
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return ErrorMessages.emptyContentError;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          
          // 送信ボタン
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppConstants.ideaAddButtonLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          )
          .animate()
          .fadeIn(
            duration: AppConstants.shortAnimationDuration,
          ),
        ],
      ),
    );
  }
} 