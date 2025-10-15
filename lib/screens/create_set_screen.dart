import 'package:flutter/material.dart';

class CreateSetScreen extends StatefulWidget {
  const CreateSetScreen({super.key});

  @override
  State<CreateSetScreen> createState() => _CreateSetScreenState();
}

class _CreateSetScreenState extends State<CreateSetScreen> {
  bool _manualMode = false; // false = generuj, true = ręczny
  final TextEditingController _topicController = TextEditingController();
  int _numberOfCards = 5;

  // Lista fiszek do ręcznego dodawania
  List<Map<String, TextEditingController>> _flashcards = [];

  void _addFlashcard() {
    setState(() {
      _flashcards.add({
        "front": TextEditingController(),
        "back": TextEditingController(),
      });
    });
  }

  void _removeFlashcard(int index) {
    setState(() {
      _flashcards.removeAt(index);
    });
  }

  void _submitGeneratedSet() {
    String topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wpisz tematykę zestawu")),
      );
      return;
    }

    // TODO: Wyślij dane do backendu lub generuj zestaw lokalnie
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Wygenerowano $_numberOfCards fiszek w tematyce '$topic'")),
    );

    _topicController.clear();
  }

  void _submitManualSet() {
    List<Map<String, String>> cards = [];
    for (var f in _flashcards) {
      String front = f["front"]!.text.trim();
      String back = f["back"]!.text.trim();
      if (front.isNotEmpty && back.isNotEmpty) {
        cards.add({"front": front, "back": back});
      }
    }

    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dodaj przynajmniej jedną fiszkę")),
      );
      return;
    }

    // TODO: Wyślij dane do backendu lub zapisz lokalnie
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Stworzono zestaw z ${cards.length} fiszkami")),
    );

    // Wyczyść listę
    setState(() {
      _flashcards.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _addFlashcard(); // dodaj jedną fiszkę domyślnie w trybie manualnym
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tworzenie zestawu fiszek"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tryb: Generuj / Ręczny
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Generuj zestaw"),
                  selected: !_manualMode,
                  onSelected: (selected) {
                    setState(() {
                      _manualMode = !selected;
                    });
                  },
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text("Stwórz zestaw"),
                  selected: _manualMode,
                  onSelected: (selected) {
                    setState(() {
                      _manualMode = selected;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Formularz w zależności od trybu
            _manualMode ? _buildManualForm() : _buildGenerateForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _topicController,
          decoration: const InputDecoration(
            labelText: "Tematyka",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text("Ilość fiszek:"),
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: _numberOfCards,
              items: [5, 10, 15, 20, 30]
                  .map((e) => DropdownMenuItem<int>(value: e, child: Text("$e")))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _numberOfCards = value;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitGeneratedSet,
          child: const Text("Generuj zestaw"),
        ),
      ],
    );
  }

  Widget _buildManualForm() {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _flashcards.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _flashcards[index]["front"],
                          decoration: const InputDecoration(
                            labelText: "Angielski",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _flashcards[index]["back"],
                          decoration: const InputDecoration(
                            labelText: "Polski",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeFlashcard(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _addFlashcard,
                child: const Text("Dodaj fiszkę"),
              ),
              ElevatedButton(
                onPressed: _submitManualSet,
                child: const Text("Stwórz zestaw"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
