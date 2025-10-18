import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false; String? error;

  Future<void> _login() async {
    setState((){loading=true; error=null;});
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(), password: pass.text);
    } on FirebaseAuthException catch(e){ setState(()=> error=e.message); }
    finally { if(mounted) setState(()=>loading=false); }
  }
  Future<void> _register() async {
    setState((){loading=true; error=null;});
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(), password: pass.text);
    } on FirebaseAuthException catch(e){ setState(()=> error=e.message); }
    finally { if(mounted) setState(()=>loading=false); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logging in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 12),
          if(error!=null) Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          if(loading) const CircularProgressIndicator() else Row(children: [
            ElevatedButton(onPressed: _login, child: const Text('Login')),
            const SizedBox(width: 12),
            OutlinedButton(onPressed: _register, child: const Text('Register')),
          ]),
        ]),
      ),
    );
  }
}
