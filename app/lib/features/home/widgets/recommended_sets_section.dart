import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../sets/sets_service.dart';

class RecommendedSetsSection extends StatelessWidget {
  const RecommendedSetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Polecane zestawy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            if (kDebugMode)
              TextButton(
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
                child: const Text('Dev: Wgraj'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: SetsService.globalSetsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Błąd: ${snapshot.error}');
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Brak polecanych zestawów.'),
              );
            }

            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final data = docs[i].data();
                  final title = data['title'] ?? 'Bez nazwy';
                  final lang = data['language'] ?? 'Inny';
                  final cardsCount = data['cards'] ?? 0;

                  return Container(
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(lang, style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Text('$cardsCount fiszek', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: () async {
                              try {
                                await SetsService.copyGlobalSet(docs[i].id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Dodano zestaw "$title" do Twoich!')),
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
                            child: const Text('Dodaj'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
