import 'package:flutter/material.dart';
import 'study_screen.dart';

class StudySummaryScreen extends StatelessWidget {
  final String setId;
  final String? setTitle;
  final int totalCards;
  final int? correct;
  final int? wrong;
  final List<String>? wrongIds;

  const StudySummaryScreen({
    super.key,
    required this.setId,
    this.setTitle,
    required this.totalCards,
    this.correct,
    this.wrong,
    this.wrongIds,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = setTitle ?? 'Zestaw';
    return Scaffold(
      appBar: AppBar(title: const Text('Podsumowanie')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Ukończono naukę'),
                  const SizedBox(height: 8),
                  Text(
                    '$totalCards fiszek',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (correct != null || wrong != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (correct != null)
                          Row(children: [
                            const Icon(Icons.check, color: Colors.green),
                            const SizedBox(width: 6),
                            Text('Umiem: ${correct!}')
                          ]),
                        if (wrong != null)
                          Row(children: [
                            const Icon(Icons.close, color: Colors.red),
                            const SizedBox(width: 6),
                            Text('Nie umiem: ${wrong!}')
                          ]),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            if (wrongIds != null && wrongIds!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => StudyScreen(
                          setId: setId,
                          setTitle: setTitle,
                          onlyIds: wrongIds,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.replay_circle_filled),
                  label: const Text('Ucz się tylko błędnych'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => StudyScreen(setId: setId, setTitle: setTitle),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Jeszcze raz'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text('Wróć do menu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
