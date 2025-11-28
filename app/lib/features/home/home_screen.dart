import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../sets/sets_service.dart';
import 'widgets/my_sets_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = (u.displayName?.trim().isNotEmpty == true)
        ? u.displayName!.trim()
        : (u.email?.trim().isNotEmpty == true ? u.email!.trim() : 'Uczeń');

    return Scaffold(
      appBar: AppBar(
        title: Text('Cześć, $name'),
        actions: [
          IconButton(
            tooltip: 'Wyloguj',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/createSet'),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj zestaw'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/languageSelection');
            },
            icon: const Icon(Icons.language),
            label: const Text('Wybór języka'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/leitnerSets');
            },
            icon: const Icon(Icons.school),
            label: const Text('Ucz się systemem Leitnera'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/statistics');
            },
            icon: const Icon(Icons.bar_chart),
            label: const Text('Statystyki'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Rozpoczęte zestawy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const MySetsSection(),
        ],
      ),
    ); 
  }
}
