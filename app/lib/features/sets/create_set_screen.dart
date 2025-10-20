import 'package:flutter/material.dart';
import 'sets_service.dart';

class CreateSetScreen extends StatefulWidget {
  const CreateSetScreen({super.key});
  @override
  State<CreateSetScreen> createState() => _CreateSetScreenState();
}

class _CreateSetScreenState extends State<CreateSetScreen> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _ctrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Podaj nazwę zestawu')));
      return;
    }
    setState(() => _saving = true);
    try {
      final setId = await SetsService.addSet(title: title);
      if (!mounted) return;
      Navigator.of(context).pushNamed('/editSet', arguments: {
        'setId': setId,
        'title': title,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd zapisu: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nowy zestaw')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Nazwa zestawu',
                hintText: 'np. Angielski B2 — Phrasal verbs',
                filled: true,
                fillColor: cs.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Zapisuję…' : 'Zapisz i dodaj fiszki'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
