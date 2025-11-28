import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'sets_service.dart';

class LanguageSetsScreen extends StatelessWidget {
  static const routeName = '/language-sets';
  const LanguageSetsScreen({super.key});

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
            'Błąd: Nie można wczytać zestawów.\nNie przekazano wymaganego języka.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Zestawy: $language'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: SetsService.setsByLanguageStream(language),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Wystąpił błąd: ${snapshot.error}'),
                  );
                }
                
                final allDocs = snapshot.data?.docs ?? [];
                final customSets = allDocs.where((d) => d.data()['fromGlobalSetId'] == null).toList();
                final startedGlobalSets = allDocs.where((d) => d.data()['fromGlobalSetId'] != null).toList();
                
                final startedGlobalSetIds = startedGlobalSets
                    .map((d) => d.data()['fromGlobalSetId'] as String)
                    .toSet();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customSets.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('Moje zestawy', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: customSets.length,
                        itemBuilder: (context, index) {
                          final doc = customSets[index];
                          final data = doc.data();
                          final title = data['title'] as String? ?? 'Brak tytułu';
                          final cards = data['cards'] as int? ?? 0;

                          return _SetTile(
                            title: title,
                            subtitle: '$cards fiszek',
                            onTap: () {
                              Navigator.of(context).pushNamed('/studySet', arguments: {
                                'setId': doc.id,
                                'title': title,
                              });
                            },
                          );
                        },
                      ),
                    ],

                    if (startedGlobalSets.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('Rozpoczęte zestawy', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: startedGlobalSets.length,
                        itemBuilder: (context, index) {
                          final doc = startedGlobalSets[index];
                          final data = doc.data();
                          final title = data['title'] as String? ?? 'Brak tytułu';
                          final cards = data['cards'] as int? ?? 0;

                          return _SetTile(
                            title: title,
                            subtitle: '$cards fiszek',
                            icon: Icons.school,
                            onTap: () {
                              Navigator.of(context).pushNamed('/studySet', arguments: {
                                'setId': doc.id,
                                'title': title,
                              });
                            },
                          );
                        },
                      ),
                    ],
                    
                    if (customSets.isEmpty && startedGlobalSets.isEmpty)
                       const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Text('Brak rozpoczętych lub własnych zestawów dla tego języka.'),
                      ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text('Dostępne zestawy', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: SetsService.globalSetsByLanguageStream(language),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Wystąpił błąd: ${snapshot.error}'),
                          );
                        }
                        final allGlobalDocs = snapshot.data?.docs ?? [];
                        
                        final docs = allGlobalDocs.where((d) => !startedGlobalSetIds.contains(d.id)).toList();

                        if (docs.isEmpty) {
                          if (startedGlobalSets.isNotEmpty) {
                             return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('Wszystkie dostępne zestawy zostały już rozpoczęte.'),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Brak dostępnych zestawów.'),
                                if (kDebugMode)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        try {
                                          await SetsService.seedGlobalSets();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Zestawy przykładowe załadowane!')),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Błąd: $e')),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.upload),
                                      label: const Text('Dev: Wgraj przykładowe'),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            final title = data['title'] as String? ?? 'Brak tytułu';
                            final cards = data['cards'] as int? ?? 0;

                            return _SetTile(
                              title: title,
                              subtitle: '$cards fiszek',
                              icon: Icons.public,
                              onTap: () {
                                Navigator.of(context).pushNamed('/studySet', arguments: {
                                  'globalSetId': doc.id,
                                  'title': title,
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;

  const _SetTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.folder_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }
}

