import 'package:flutter/material.dart';
import 'package:idea_app/screens/home_screen.dart';
import 'package:idea_app/screens/combination_screen.dart';
import 'package:idea_app/screens/idea_editor_screen.dart';
import 'package:idea_app/models/idea.dart';

class AppRoutes {
  static const String home = '/';
  static const String combinations = '/combinations';
  static const String ideaEditor = '/idea/editor';

  static Map<String, WidgetBuilder> get routes => {
        home: (context) => const HomeScreen(),
        combinations: (context) => const CombinationScreen(),
        ideaEditor: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          return IdeaEditorScreen(
            idea: args?['idea'] as Idea?,
            parentId: args?['parentId'] as int?,
          );
        },
      };

  // アニメーション付きのページ遷移
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case combinations:
        return _buildRoute(const CombinationScreen(), settings);
      case ideaEditor:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          IdeaEditorScreen(
            idea: args?['idea'] as Idea?,
            parentId: args?['parentId'] as int?,
          ),
          settings,
        );
      default:
        return _buildRoute(const HomeScreen(), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
