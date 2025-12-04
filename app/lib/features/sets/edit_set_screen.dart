import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'sets_service.dart';

class EditSetScreen extends StatefulWidget {
  final String setId;
  final String initialTitle;

  const EditSetScreen({
    super.key,
    required this.setId,
    required this.initialTitle,
  });

  @override
  State<EditSetScreen> createState() => _EditSetScreenState();
}

class _EditSetScreenState extends State<EditSetScreen> {
  late TextEditingController _titleController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _checkAndMaterialize();
  }

  Future<void> _checkAndMaterialize() async {
    try {
      await SetsService.materializeSet(widget.setId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd konwersji zestawu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) return;
    await SetsService.updateSetTitle(widget.setId, newTitle);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zapisano tytuł')),
      );
    }
  }

  void _addCard() {
    _showCardDialog();
  }

  void _editCard(String cardId, String currentFront, String currentBack) {
    _showCardDialog(cardId: cardId, front: currentFront, back: currentBack);
  }

  void _showCardDialog({String? cardId, String? front, String? back}) {
    final frontCtrl = TextEditingController(text: front);
    final backCtrl = TextEditingController(text: back);
    final isEditing = cardId != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edytuj fiszkę' : 'Dodaj fiszkę'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: frontCtrl,
              decoration: const InputDecoration(labelText: 'Przód (Pytanie)'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: backCtrl,
              decoration: const InputDecoration(labelText: 'Tył (Odpowiedź)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              final f = frontCtrl.text.trim();
              final b = backCtrl.text.trim();
              if (f.isNotEmpty && b.isNotEmpty) {
                if (isEditing) {
                  await SetsService.updateCard(
                    setId: widget.setId,
                    cardId: cardId,
                    front: f,
                    back: b,
                  );
                } else {
                  await SetsService.addCard(
                    setId: widget.setId,
                    front: f,
                    back: b,
                  );
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(String cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń fiszkę'),
        content: const Text('Czy na pewno chcesz usunąć tę fiszkę?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SetsService.deleteCard(widget.setId, cardId);
    }
  }

  Future<void> _deleteSet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń zestaw'),
        content: const Text('Czy na pewno chcesz usunąć cały zestaw? Ta operacja jest nieodwracalna.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Usuń zestaw'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SetsService.deleteSet(widget.setId);
      if (mounted) {
        Navigator.of(context).pop(); // Wróć do poprzedniego ekranu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zestaw został usunięty')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edycja zestawu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Usuń cały zestaw',
            onPressed: _deleteSet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Nazwa zestawu',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _saveTitle,
                        icon: const Icon(Icons.save),
                        tooltip: 'Zapisz nazwę',
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: SetsService.cardsStream(widget.setId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('Brak fiszek w zestawie'));
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final front = data['front'] as String? ?? '';
                          final back = data['back'] as String? ?? '';

                          return ListTile(
                            title: Text(front),
                            subtitle: Text(back),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editCard(doc.id, front, back),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCard(doc.id),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: const Icon(Icons.add),
      ),
    );
  }
}
