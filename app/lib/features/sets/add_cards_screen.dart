import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sets_service.dart';

class AddCardsScreen extends StatefulWidget {
  final String setId;
  final String? setTitle;
  const AddCardsScreen({super.key, required this.setId, this.setTitle});

  @override
  State<AddCardsScreen> createState() => _AddCardsScreenState();
}

class _AddCardsScreenState extends State<AddCardsScreen> {
  final _front = TextEditingController();
  final _back = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    final f = _front.text.trim();
    final b = _back.text.trim();
    if (f.isEmpty || b.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzupełnij obie strony fiszki')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await SetsService.addCard(setId: widget.setId, front: f, back: b);
      _front.clear();
      _back.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zapisu fiszki: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _finishSet() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setTitle == null
            ? 'Dodaj fiszki'
            : 'Dodaj fiszki — ${widget.setTitle}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _front,
            enabled: !_saving,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Przód (pytanie/słowo)',
              filled: true,
              fillColor: cs.surfaceVariant.withOpacity(0.25),
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _back,
            enabled: !_saving,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveCard(),
            decoration: InputDecoration(
              labelText: 'Tył (odpowiedź/tłumaczenie)',
              filled: true,
              fillColor: cs.surfaceVariant.withOpacity(0.25),
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveCard,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_saving ? 'Zapisuję…' : 'Dodaj fiszkę'),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Twoje fiszki',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: SetsService.cardsStream(widget.setId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Text('Błąd: ${snap.error}');
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Text('Brak fiszek. Dodaj pierwszą 🙂',
                    style: TextStyle(color: cs.outline));
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  return ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: cs.surfaceVariant.withOpacity(0.2),
                    title: Text(d['front'] ?? ''),
                    subtitle: Text(d['back'] ?? ''),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _finishSet,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Zatwierdź zestaw i wróć do strony głównej'),
            ),
          ),
        ],
      ),
    );
  }
}
