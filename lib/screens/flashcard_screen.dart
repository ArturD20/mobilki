import 'package:flutter/material.dart';
import '../data/datasets.dart';
import '../widgets/flashcard.dart';
import 'dart:math';

class FlashcardScreen extends StatefulWidget {
  final Dataset dataset;

  const FlashcardScreen({super.key, required this.dataset});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late List<WordPair> shuffledWords;
  int index = 0;
  int correct = 0;
  int wrong = 0;

  @override
  void initState() {
    super.initState();
    shuffledWords = List.of(widget.dataset.words)..shuffle(Random());
  }

  void nextCard() {
    setState(() {
      index = (index + 1) % shuffledWords.length;
    });
  }

  void handleCorrect() {
    setState(() => correct++);
    nextCard();
  }

  void handleWrong() {
    setState(() => wrong++);
    nextCard();
  }

  @override
  Widget build(BuildContext context) {
    final word = shuffledWords[index];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dataset.name),
        backgroundColor: Colors.blueAccent,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flashcard(
            frontText: word.pl,
            backText: word.en,
            onNext: nextCard,
            onCorrect: handleCorrect,
            onWrong: handleWrong,
          ),
          const SizedBox(height: 40),
          Text(
            "Poprawne: $correct | Błędne: $wrong",
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
