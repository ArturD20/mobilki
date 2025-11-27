import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'sets_service.dart';

/// Ekran pokazujący zestawy dla wybranego języka,
/// uruchamiający naukę systemem Leitnera (czyli tylko fiszki "do powtórki").
class LeitnerLanguageSetsScreen extends StatelessWidget {
  static const routeName = '/leitner-language-sets';

  const LeitnerLanguageSetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Object? arguments = ModalRoute.of(context)?.settings.arguments;
    final String language;

    if (arguments is String) {
      language = arguments;
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Błąd')),
        body: const Center(
          child: Text(
            'Błąd: Nie można wczytać zestawów (Leitner).\nBrak przekazanego języka.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Leitner: $language'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SetsService.setsByLanguageStream(language),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Wystąpił błąd: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs;
          if (docs == null || docs.isEmpty) {
            return Center(
              child: Text(
                'Brak zestawów dla języka "$language".',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = data['title'] as String? ?? 'Brak tytułu';
              final cards = data['cards'] as int? ?? 0;

              return Card(
                elevation: 2,
                color: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Fiszki: $cards (nauka Leitner)'),
                  trailing: const Icon(Icons.play_circle_outline, size: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed('/studySet', arguments: {
                      'setId': doc.id,
                      'title': title,
                    });
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
