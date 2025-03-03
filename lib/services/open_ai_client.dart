import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIClient {
  final String _apiKey;
  final String? _organizationId;
  final Duration _timeout;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  OpenAIClient({
    required String apiKey,
    String? organizationId,
    Duration? timeout,
  })  : _apiKey = apiKey,
        _organizationId = organizationId,
        _timeout = timeout ?? const Duration(seconds: 30);

  factory OpenAIClient.fromEnv() {
    return OpenAIClient(
      apiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
      organizationId: dotenv.env['OPENAI_ORGANIZATION_ID'],
    );
  }

  Future<Map<String, String>> generateIdeaCombination(
      String ideaA, String ideaB) async {
    final prompt = '''
2つのアイデアを組み合わせて、新しい独創的なアイデアを生成してください。
以下の形式でJSON形式の結果を返してください：
{
  "combinedIdea": "組み合わせたアイデア",
  "reasoning": "組み合わせの理由や説明"
}

アイデア1: $ideaA
アイデア2: $ideaB
''';

    final response = await _complete(prompt);
    return _extractJsonFromText(response);
  }

  Future<List<String>> suggestTags(String content) async {
    final prompt = '''
以下のアイデアに関連するタグを5つ以内で提案してください。
タグは短く、具体的で、検索やフィルタリングに役立つものにしてください。
JSONの配列形式で返してください。

アイデア: $content
''';

    final response = await _complete(prompt);
    final json = _extractJsonFromText(response);
    if (json.containsKey('tags')) {
      return List<String>.from(jsonDecode(json['tags']!));
    }
    return [];
  }

  Future<String> _complete(String prompt) async {
    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            if (_organizationId != null)
              'OpenAI-Organization': _organizationId!,
          },
          body: jsonEncode({
            'model': 'gpt-4-turbo-preview',
            'messages': [
              {
                'role': 'system',
                'content': '''
あなたは創造的なアイデアを生み出すAIアシスタントです。
常に日本語で応答してください。
応答はJSON形式で返してください。
''',
              },
              {
                'role': 'user',
                'content': prompt,
              },
            ],
            'temperature': 0.7,
            'max_tokens': 500,
            'response_format': {'type': 'json_object'},
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('APIリクエストが失敗しました: ${response.statusCode}');
    }

    final responseData = jsonDecode(utf8.decode(response.bodyBytes));
    return responseData['choices'][0]['message']['content'] as String;
  }

  Map<String, String> _extractJsonFromText(String text) {
    try {
      // 文字列全体をJSONとしてパース
      final Map<String, dynamic> json = jsonDecode(text);
      return json.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('JSONの解析に失敗しました: $e');
      print('解析対象のテキスト: $text');
      return {
        'error': 'JSONの解析に失敗しました',
        'text': text,
      };
    }
  }
}

// APIエラー用の例外クラス
class APIException implements Exception {
  final String message;
  final int statusCode;
  final String body;

  APIException(this.message, this.statusCode, this.body);

  @override
  String toString() => message;
}
