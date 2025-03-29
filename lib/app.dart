import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // 未使用のためコメントアウト(2025/03/28)
import 'package:idea_app/config/routes.dart';
import 'package:idea_app/config/themes.dart';
// import 'package:idea_app/screens/home_screen.dart'; // 未使用のためコメントアウト(2025/03/28)
// import 'package:idea_app/screens/onboarding_screen.dart'; // 未使用のためコメントアウト(2025/03/28)
import 'package:provider/provider.dart';
import 'package:idea_app/services/database_service.dart';
import 'package:idea_app/services/open_ai_client.dart';
import 'package:idea_app/services/ai_idea_combination_service.dart';
import 'package:idea_app/services/user_stats_service.dart';
import 'package:idea_app/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        Provider<OpenAIClient>(
          create: (_) => OpenAIClient.fromEnv(),
        ),
        Provider<Future<UserStatsService>>(
          create: (context) async {
            debugPrint('Initializing UserStatsService...');
            final databaseService = context.read<DatabaseService>();
            final db = await databaseService.database;
            final service = await UserStatsService.getInstance(db);
            debugPrint('UserStatsService initialized');
            return service;
          },
        ),
        Provider<Future<AIIdeaCombinationService>>(
          create: (context) async {
            debugPrint('Initializing AIIdeaCombinationService...');
            final databaseService = context.read<DatabaseService>();
            final openAIClient = context.read<OpenAIClient>();
            final userStatsService =
                await context.read<Future<UserStatsService>>();
            final service = AIIdeaCombinationService(
              openAIClient,
              databaseService,
              userStatsService,
            );
            debugPrint('AIIdeaCombinationService initialized');
            return service;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeService(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return FutureBuilder<String>(
            future: _getInitialRoute(),
            builder: (context, snapshot) {
              debugPrint('FutureBuilder state: ${snapshot.connectionState}');
              debugPrint('FutureBuilder error: ${snapshot.error}');

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('アプリを準備中...'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text('アプリの起動中にエラーが発生しました'),
                          const SizedBox(height: 8),
                          Text(snapshot.error.toString(),
                              style: const TextStyle(fontSize: 12)),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const App()),
                              );
                            },
                            child: const Text('再試行'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return MaterialApp(
                title: 'アイデアパッド',
                theme: AppThemes.lightTheme(),
                darkTheme: AppThemes.darkTheme(),
                themeMode: themeService.themeMode,
                debugShowCheckedModeBanner: false,
                navigatorKey: App.navigatorKey,
                onGenerateRoute: AppRoutes.generateRoute,
                initialRoute: snapshot.data ?? AppRoutes.onboarding,
              );
            },
          );
        },
      ),
    );
  }

  Future<String> _getInitialRoute() async {
    try {
      debugPrint('Getting initial route...');

      // サービスの初期化を待つ
      debugPrint('Waiting for services to initialize...');
      final context = navigatorKey.currentContext;
      if (context != null) {
        final userStatsFuture = context.read<Future<UserStatsService>>();
        final aiServiceFuture =
            context.read<Future<AIIdeaCombinationService>>();
        await Future.wait([userStatsFuture, aiServiceFuture]);
        debugPrint('Services initialized successfully');
      }

      final isFirstLaunch = await _checkFirstLaunch();
      debugPrint('Is first launch: $isFirstLaunch');
      final route = isFirstLaunch ? AppRoutes.onboarding : AppRoutes.home;
      debugPrint('Selected route: $route');
      return route;
    } catch (e) {
      debugPrint('Error getting initial route: $e');
      return AppRoutes.onboarding;
    }
  }

  Future<bool> _checkFirstLaunch() async {
    try {
      debugPrint('Checking first launch...');
      final prefs = await SharedPreferences.getInstance();
      final bool isFirstLaunch = !prefs.containsKey('onboarding_completed');
      debugPrint('First launch check result: $isFirstLaunch');
      return isFirstLaunch;
    } catch (e) {
      debugPrint('Error checking first launch: $e');
      return true;
    }
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
