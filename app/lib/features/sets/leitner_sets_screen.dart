import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'sets_service.dart';
import 'leitner_study_screen.dart';

class LeitnerSetsScreen extends StatelessWidget {
  static const routeName = '/leitner-sets';

  const LeitnerSetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ucz się systemem Leitnera'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SetsService.mySetsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Nie masz jeszcze żadnych zestawów. Utwórz zestaw, aby zacząć naukę.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.outline),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = data['title'] as String? ?? 'Bez nazwy';
              final cardsCount = data['cards'] as int? ?? 0;

              return Card(
                color: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Fiszki: $cardsCount'),
                  trailing: const Icon(Icons.play_circle_outline),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LeitnerStudyScreen(
                          setId: doc.id,
                          setTitle: title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
