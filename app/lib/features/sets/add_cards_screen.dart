import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // dialog generowania fiszek (ilość + temat obok siebie)
  Future<void> _showGenerateDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final numberCtrl = TextEditingController(text: '10');
        final topicCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Generuj fiszki'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: topicCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      enableSuggestions: true,
                      autocorrect: true,
                      decoration: const InputDecoration(
                        labelText: 'Temat',
                        hintText: 'np. warzywa, czasowniki nieregularne',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: numberCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Ilość',
                        hintText: 'max 100',
                        counterText: '',
                      ),
                      maxLength: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Anuluj')),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(numberCtrl.text) ?? 0;
                Navigator.of(ctx).pop({'count': v, 'topic': topicCtrl.text});
              },
              child: const Text('Generuj'),
            ),
          ],
        );
      },
    );

    final topic = (result?['topic'] as String?)?.trim() ?? '';
    final rawCount = result?['count'] as int?;
    if (rawCount == null || rawCount <= 0) return;
    final count = rawCount.clamp(1, 100);

    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wpisz temat fiszek')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await SetsService.generateCardsViaLLM(setId: widget.setId, count: count, topic: topic);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wygenerowano $count fiszek')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd generowania: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  void _finishSet() => _goHome();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Powrót do głównego ekranu',
          onPressed: _goHome,
        ),
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
            textCapitalization: TextCapitalization.sentences,
            enableSuggestions: true,
            autocorrect: true,
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
            textCapitalization: TextCapitalization.sentences,
            enableSuggestions: true,
            autocorrect: true,
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
              onPressed: _saving ? null : _showGenerateDialog,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Generuj fiszki (LLM)'),
            ),
          ),
          const SizedBox(height: 12),
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