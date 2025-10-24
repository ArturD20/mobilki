import 'package:flutter/material.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/sets/create_set_screen.dart';
import '../features/sets/add_cards_screen.dart';
import '../features/sets/study_screen.dart';
import '../features/sets/study_summary_screen.dart';
import '../features/language_selection/language_selection_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings s) {
  switch (s.name) {
    case '/login':
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case '/home':
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    case '/createSet':
      return MaterialPageRoute(builder: (_) => const CreateSetScreen());
    case '/languageSelection':
      return MaterialPageRoute(builder: (_) => const LanguageSelectionScreen());
    case '/editSet': {
      final args = s.arguments;
      if (args is Map && args['setId'] is String) {
        return MaterialPageRoute(
          builder: (_) => AddCardsScreen(
            setId: args['setId'] as String,
            setTitle: args['title'] as String?,
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Brak wymaganych argumentów dla /editSet (setId).')),
        ),
      );
    }
    case '/studySummary': {
      final args = s.arguments;
      if (args is Map && args['setId'] is String && args['total'] is int) {
        // parse optional wrongIds list
        List<String>? wrongIds;
        final w = args['wrongIds'];
        if (w is List) {
          wrongIds = w.map((e) => e.toString()).toList();
        }
        return MaterialPageRoute(
          builder: (_) => StudySummaryScreen(
            setId: args['setId'] as String,
            setTitle: args['title'] as String?,
            totalCards: args['total'] as int,
            correct: (args['correct'] is int) ? args['correct'] as int : null,
            wrong: (args['wrong'] is int) ? args['wrong'] as int : null,
            wrongIds: wrongIds,
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Brak wymaganych argumentów dla /studySummary (setId, total).')),
        ),
      );
    }
    case '/studySet': {
      final args = s.arguments;
      if (args is Map && args['setId'] is String) {
        return MaterialPageRoute(
          builder: (_) => StudyScreen(
            setId: args['setId'] as String,
            setTitle: args['title'] as String?,
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Brak wymaganych argumentów dla /studySet (setId).')),
        ),
      );
    }
    case '/':
    default:
      return MaterialPageRoute(builder: (_) => const AuthGate());
  }
}
