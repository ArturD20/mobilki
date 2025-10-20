import 'package:flutter/material.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/sets/create_set_screen.dart';
import '../features/sets/add_cards_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings s) {
  switch (s.name) {
    case '/login':
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case '/home':
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    case '/createSet':
      return MaterialPageRoute(builder: (_) => const CreateSetScreen());
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
    case '/':
    default:
      return MaterialPageRoute(builder: (_) => const AuthGate());
  }
}
