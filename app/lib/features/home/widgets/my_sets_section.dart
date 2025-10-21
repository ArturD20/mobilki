import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../sets/sets_service.dart';

class MySetsSection extends StatelessWidget {
  const MySetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SetsService.mySetsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Błąd: ${snap.error}'),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _EmptyState(
            message: 'Nie masz jeszcze zestawów.',
            action: () => Navigator.of(context).pushNamed('/createSet'),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final title = (d['title'] as String?) ?? '(bez nazwy)';
            final cards = (d['cards'] as int?) ?? 0;
            return _SetTile(
              title: title,
              subtitle: '$cards fiszek',
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/studySet',
                  arguments: {'setId': docs[i].id, 'title': title},
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SetTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _SetTile({required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: cs.surfaceVariant.withOpacity(0.25),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
      leading: const Icon(Icons.folder_outlined),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback action;
  const _EmptyState({required this.message, required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          const SizedBox(width: 8),
          FilledButton(onPressed: action, child: const Text('Dodaj')),
        ],
      ),
    );
  }
}
