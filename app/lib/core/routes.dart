import 'package:flutter/material.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/login_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings s) {
  switch (s.name) {
    case '/login':
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case '/':
    default:
      return MaterialPageRoute(builder: (_) => const AuthGate());
  }
}
