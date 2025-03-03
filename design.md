# アイデアパッドアプリケーション設計書

## 1. アプリケーション構造

### 1.1 ディレクトリ構造
```
idea_app/
├── lib/
│   ├── main.dart              # アプリケーションのエントリーポイント
│   ├── app.dart               # アプリケーションのルート設定
│   ├── config/                # アプリ設定
│   │   ├── themes.dart        # テーマ設定
│   │   └── routes.dart        # ルート定義
│   ├── models/                # データモデル
│   │   ├── idea.dart          # アイデアモデル
│   │   └── idea_combination.dart # アイデア組み合わせモデル
│   ├── services/              # サービス
│   │   ├── database_service.dart  # データベース操作
│   │   └── idea_service.dart  # アイデア関連ロジック
│   ├── screens/               # 画面
│   │   ├── home_screen.dart   # トップ画面
│   │   └── combination_screen.dart # 組み合わせ提案画面
│   ├── widgets/               # ウィジェット
│   │   ├── idea_card.dart     # アイデアカード
│   │   ├── idea_form.dart     # アイデア入力フォーム
│   │   └── combination_card.dart # 組み合わせカード
│   └── utils/                 # ユーティリティ
│       ├── constants.dart     # 定数
│       └── idea_algorithm.dart # アイデア組み合わせアルゴリズム
```

### 1.2 データフロー
1. ユーザーがアイデアを入力
2. アイデアがデータベースに保存
3. 保存されたアイデアが一覧表示
4. 組み合わせページへの遷移時にアイデアデータを取得
5. アルゴリズムによってアイデアの組み合わせを生成
6. 組み合わせ結果を表示

## 2. データモデル設計

### 2.1 Ideaモデル
```dart
class Idea {
  final int? id;  // 自動生成ID（null = 未保存）
  final String content;  // アイデア内容
  final DateTime createdAt;  // 作成日時
  final DateTime updatedAt;  // 更新日時
  final List<String> tags;  // タグ（オプション）
  
  // コンストラクタ、変換メソッドなど
}
```

### 2.2 IdeaCombinationモデル
```dart
class IdeaCombination {
  final int? id;  // 自動生成ID
  final List<int> ideaIds;  // 組み合わせたアイデアのID
  final String combinedContent;  // 組み合わせ内容
  final DateTime createdAt;  // 作成日時
  final bool isFavorite;  // お気に入りフラグ
  
  // コンストラクタ、変換メソッドなど
}
```

## 3. データベース設計

### 3.1 テーブル設計
1. **ideas テーブル**
   - id: INTEGER PRIMARY KEY AUTOINCREMENT
   - content: TEXT NOT NULL
   - created_at: TEXT NOT NULL
   - updated_at: TEXT NOT NULL
   - tags: TEXT

2. **idea_combinations テーブル**
   - id: INTEGER PRIMARY KEY AUTOINCREMENT
   - idea_ids: TEXT NOT NULL  // JSONシリアライズされたID配列
   - combined_content: TEXT NOT NULL
   - created_at: TEXT NOT NULL
   - is_favorite: INTEGER NOT NULL DEFAULT 0

### 3.2 SQLite初期化
```dart
final String createIdeasTable = '''
  CREATE TABLE ideas(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    tags TEXT
  )
''';

final String createIdeaCombinationsTable = '''
  CREATE TABLE idea_combinations(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    idea_ids TEXT NOT NULL,
    combined_content TEXT NOT NULL,
    created_at TEXT NOT NULL,
    is_favorite INTEGER NOT NULL DEFAULT 0
  )
''';
```

## 4. 画面設計

### 4.1 ホーム画面
- **レイアウト**:
  - AppBar: アプリ名と設定ボタン
  - 入力フォーム: テキストフィールドと送信ボタン
  - アイデア一覧: スクロール可能なリスト（最新順）
  - FAB: 組み合わせページへの遷移ボタン

- **状態管理**:
  - アイデアリスト（読み込み中、エラー、データ表示）
  - 入力フォームの状態（空、入力中、送信中）

### 4.2 組み合わせ提案画面
- **レイアウト**:
  - AppBar: 「アイデア組み合わせ」タイトルと戻るボタン
  - 組み合わせ一覧: カード形式のリスト
  - 各カード: 組み合わせ内容、元アイデア、お気に入りボタン
  - リフレッシュボタン: 新しい組み合わせを生成

- **状態管理**:
  - 組み合わせリスト（生成中、表示中）
  - お気に入り状態

## 5. アルゴリズム設計

### 5.1 アイデア組み合わせアルゴリズム
1. ランダム選択方式:
   - DBから2〜3個のアイデアをランダムに選択
   - 選択されたアイデアを特定のパターンで組み合わせ
   - 組み合わせパターン例:
     - 「AとBを組み合わせると...」
     - 「Aの特徴をBに適用すると...」
     - 「AをBの文脈で考えると...」

2. キーワード抽出方式（拡張機能）:
   - 各アイデアからキーワードを抽出
   - 関連性の高いキーワードを持つアイデア同士を組み合わせ
   - より意味のある組み合わせを生成

## 6. テーマとスタイル

### 6.1 カラーパレット
- プライマリカラー: #6200EA (深い紫)
- セカンダリカラー: #03DAC6 (ティール)
- バックグラウンド: #FFFFFF (白) / #121212 (ダークモード)
- カードカラー: #F5F5F5 (薄いグレー) / #1E1E1E (ダークモード)
- アクセントカラー: #FF4081 (ピンク)

### 6.2 タイポグラフィ
- アプリ名: Montserrat, Bold, 24sp
- 見出し: Roboto, Medium, 20sp
- 本文: Roboto, Regular, 16sp
- アイデアテキスト: Roboto, Regular, 18sp
- ボタンテキスト: Roboto, Medium, 14sp

### 6.3 アニメーション
- ページ遷移: スライドトランジション
- カード表示: フェードイン + スケールアニメーション
- ボタン: リップルエフェクト
- 保存完了: スケールアウト + チェックマークアニメーション

## 7. エラーハンドリング

### 7.1 想定されるエラー
- データベース接続エラー
- データ保存失敗
- 空のアイデア入力
- データ読み込みタイムアウト

### 7.2 エラー表示方法
- スナックバー: 一時的なエラー通知
- ダイアログ: 重大なエラーで操作が必要な場合
- インライン表示: フォーム入力エラーなど

## 8. 将来の拡張性

### 8.1 今後追加予定の機能
- ユーザーアカウント
- クラウド同期
- より高度なAIアルゴリズム
- アイデアのカテゴリ分け
- アイデアの共有機能
- 統計・分析機能 

## 9. 追加機能設計（アップデート）

### 9.1 データモデル拡張

#### 9.1.1 Ideaモデル拡張
```dart
class Idea {
  final int? id;  // 自動生成ID（null = 未保存）
  final String content;  // アイデア内容
  final DateTime createdAt;  // 作成日時
  final DateTime updatedAt;  // 更新日時
  final List<String> tags;  // タグ（オプション）
  final int? parentId;  // 親アイデアのID（null = ルートアイデア）
  final bool isDeleted;  // 削除フラグ
  
  // コンストラクタ、変換メソッドなど
}
```

#### 9.1.2 IdeaTreeモデル（新規）
```dart
class IdeaTree {
  final Idea rootIdea;  // ルートアイデア
  final List<IdeaTree> children;  // 子アイデアのツリー
  
  // ツリー操作メソッド
  void addChild(Idea child);
  void removeChild(int childId);
  IdeaTree? findSubtree(int ideaId);
  List<Idea> flatten();
}
```

#### 9.1.3 AICombinationモデル（新規）
```dart
class AICombination {
  final int id;  // 自動生成ID
  final List<int> ideaIds;  // 組み合わせたアイデアのID
  final String combinedContent;  // 組み合わせ内容
  final String reasoning;  // AI推論プロセス
  final DateTime createdAt;  // 作成日時
  final bool isFavorite;  // お気に入りフラグ
  
  // コンストラクタ、変換メソッドなど
}
```

### 9.2 データベース拡張

#### 9.2.1 ideasテーブル拡張
```sql
ALTER TABLE ideas ADD COLUMN parent_id INTEGER;
ALTER TABLE ideas ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;
```

#### 9.2.2 ai_combinationsテーブル（新規）
```sql
CREATE TABLE ai_combinations(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  idea_ids TEXT NOT NULL,
  combined_content TEXT NOT NULL,
  reasoning TEXT,
  created_at TEXT NOT NULL,
  is_favorite INTEGER NOT NULL DEFAULT 0
);
```

### 9.3 画面・機能設計

#### 9.3.1 アイデア削除機能
- **実装場所**: `idea_card.dart`内にスワイプ削除またはコンテキストメニュー実装
- **フロー**:
  1. ユーザーがアイデアカードで削除アクション実行
  2. 確認ダイアログ表示
  3. 確認後、データベースでis_deletedフラグを1に更新
  4. UIからアイデアを削除（アニメーションとともに）
  5. スナックバーで削除完了通知と取り消しオプション提供

#### 9.3.2 ツリー形式アイデア表示
- **新規ファイル**: `idea_tree_view.dart`
- **レイアウト**:
  - 階層構造が視覚的に分かるインデントとライン表示
  - 展開/折りたたみ可能な子アイデアリスト
  - アイデア追加ボタンは各アイデアの下部に配置
- **状態管理**:
  - 展開状態の追跡
  - 親子関係の維持
  - ドラッグアンドドロップによる再構成（オプション）

#### 9.3.3 子アイデア追加機能
- **実装場所**: `idea_card.dart`内に子アイデア追加ボタン実装
- **フロー**:
  1. 親アイデアで「子アイデア追加」ボタンタップ
  2. 子アイデア入力モーダル表示
  3. 子アイデア入力後、parent_idを設定して保存
  4. ツリービューの更新と視覚的フィードバック

#### 9.3.4 AIアイデア集約機能
- **新規画面**: `idea_consolidation_screen.dart`
- **レイアウト**:
  - ツリー選択インターフェース
  - 集約処理進行状況インジケータ
  - 結果表示領域（元アイデアと集約結果の比較）
  - 保存・編集ボタン
- **フロー**:
  1. ユーザーがツリーを選択して「集約」ボタンタップ
  2. ツリー内のすべてのアイデアをAIに送信
  3. AIが関連性を分析して統合アイデアを生成
  4. 生成結果を表示し、ユーザーが編集可能
  5. 保存して新アイデアとして登録するオプション

#### 9.3.5 AIアイデア組み合わせ機能強化
- **更新ファイル**: `idea_service.dart`, `combination_screen.dart`
- **実装**:
  - OpenAI APIクライアント実装
  - プロンプトテンプレート設計
  - API呼び出しとレスポンス処理
  - エラーハンドリングとフォールバック機能

### 9.4 UI/UX刷新

#### 9.4.1 Nomad eSIM風デザイン要素
- **カラースキーム**:
  - プライマリ: #0B0F1F（ダークネイビー）
  - セカンダリ: #3B82F6（ブルー）
  - アクセント: #10B981（グリーン）
  - バックグラウンド: グラデーション（#0F172A → #1E293B）
  - テキスト: #F8FAFC（ライト）/ #94A3B8（セカンダリ）

- **UI要素**:
  - フロスト効果を持つカード（半透明）
  - 柔らかなシャドウ効果
  - 薄いボーダーライン
  - ミニマルなアイコン
  - 丸みを帯びたコーナー

- **タイポグラフィ**:
  - メインフォント: SF Pro Display / Roboto
  - 見出し: 太字、明瞭、大きめのサイズ
  - 本文: ライト、適切な行間

#### 9.4.2 アニメーション強化
- Hero遷移アニメーション
- スクロールインタラクション（視差効果）
- マイクロインタラクション（ボタンタップ、カード展開など）
- スムーズなローディングトランジション

### 9.5 AIサービス設計

#### 9.5.1 アイデア集約サービス
```dart
class IdeaConsolidationService {
  final OpenAIClient _openAIClient;
  
  Future<AICombination> consolidateIdeas(List<Idea> ideas) async {
    // ツリー構造をテキスト形式に変換
    final String treePrompt = _buildTreePrompt(ideas);
    
    // OpenAI APIにリクエスト
    final response = await _openAIClient.complete(
      prompt: "以下のアイデアツリーを一つの統合されたアイデアにまとめてください。\n"
              "それぞれの要素を活かしつつ、より発展させた形で提案してください。\n\n"
              "$treePrompt\n\n"
              "統合アイデア: ",
      maxTokens: 300,
      temperature: 0.7,
    );
    
    // レスポンス処理
    return _processConsolidationResponse(ideas, response);
  }
  
  // その他のヘルパーメソッド
}
```

#### 9.5.2 アイデア組み合わせサービス
```dart
class AIIdeaCombinationService {
  final OpenAIClient _openAIClient;
  
  Future<List<AICombination>> generateCombinations(List<Idea> ideas, int count) async {
    // アイデアペアの選択
    final pairs = _selectIdeaPairs(ideas, count);
    
    List<AICombination> results = [];
    for (var pair in pairs) {
      // OpenAI APIにリクエスト
      final response = await _openAIClient.complete(
        prompt: "以下の2つのアイデアを独創的に組み合わせた新しいアイデアを生成してください。\n"
                "アイデア1: ${pair[0].content}\n"
                "アイデア2: ${pair[1].content}\n\n"
                "組み合わせアイデア: ",
        maxTokens: 200,
        temperature: 0.8,
      );
      
      // レスポンス処理
      results.add(_processCombinationResponse(pair, response));
    }
    
    return results;
  }
  
  // その他のヘルパーメソッド
}
```

### 9.6 システムアーキテクチャ更新

#### 9.6.1 依存性注入
```dart
final serviceLocator = GetIt.instance;

void setupDependencies() {
  // APIクライアント
  serviceLocator.registerLazySingleton<OpenAIClient>(
    () => OpenAIClient(apiKey: dotenv.env['OPENAI_API_KEY']!),
  );
  
  // データベースサービス
  serviceLocator.registerLazySingleton<DatabaseService>(
    () => DatabaseService(),
  );
  
  // アイデアサービス
  serviceLocator.registerLazySingleton<IdeaService>(
    () => IdeaService(serviceLocator<DatabaseService>()),
  );
  
  // AIサービス
  serviceLocator.registerLazySingleton<AIIdeaCombinationService>(
    () => AIIdeaCombinationService(serviceLocator<OpenAIClient>()),
  );
  
  serviceLocator.registerLazySingleton<IdeaConsolidationService>(
    () => IdeaConsolidationService(serviceLocator<OpenAIClient>()),
  );
}
```

#### 9.6.2 新規パッケージ追加
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.8.3
  provider: ^6.0.5
  http: ^1.1.0
  json_annotation: ^4.8.1
  intl: ^0.18.1
  flutter_dotenv: ^5.1.0
  get_it: ^7.6.0
  flutter_slidable: ^3.0.0
  animated_tree_view: ^2.1.0
  flutter_animate: ^4.2.0
  glassmorphism: ^3.0.0
  shimmer: ^3.0.0
  lottie: ^2.6.0
  flutter_markdown: ^0.6.17
  cached_network_image: ^3.2.3
``` 