import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'sets_service.dart';
import 'leitner_scheduler.dart';
import 'study_screen.dart' show Flashcard; // reuse existing Flashcard widget

class LeitnerStudyScreen extends StatefulWidget {
  final String setId;
  final String? setTitle;

  const LeitnerStudyScreen({super.key, required this.setId, this.setTitle});

  @override
  State<LeitnerStudyScreen> createState() => _LeitnerStudyScreenState();
}

class _LeitnerStudyScreenState extends State<LeitnerStudyScreen> {
  List<LeitnerCardState> _cards = [];
  int _index = 0;

  void _nextCard() {
    if (_cards.isEmpty) return;
    setState(() {
      if (_index >= _cards.length - 1) {
        _index = 0;
      } else {
        _index++;
      }
    });
  }

  Future<void> _handleCorrect(LeitnerCardState current) async {
  print('LEITNER_CORRECT ${current.id}');
  final updated = LeitnerScheduler.onCorrect(current, DateTime.now());
  await SetsService.updateCardLeitnerState(
    setId: widget.setId,
    cardId: current.id,
    box: updated.box,
    nextReviewAt: updated.nextReviewAt!,
  );
  _nextCard();
}

  Future<void> _handleWrong(LeitnerCardState current) async {
    final updated = LeitnerScheduler.onWrong(current, DateTime.now());
    await SetsService.updateCardLeitnerState(
      setId: widget.setId,
      cardId: current.id,
      box: updated.box,
      nextReviewAt: updated.nextReviewAt!,
    );
    _nextCard();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = widget.setTitle ?? 'Zestaw';

    return Scaffold(
      appBar: AppBar(
        title: Text('Leitner: $title'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SetsService.cardsStream(widget.setId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Błąd: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
            final now = DateTime.now();
            final allCards =
              docs.map((d) => LeitnerCardState.fromDoc(d)).toList();
            final dueCards = allCards
              .where((c) => LeitnerScheduler.isDue(c, now))
              .toList();

          _cards = dueCards;
          if (_cards.isEmpty) {
            return Center(
              child: Text(
                'Brak fiszek do powtórki w tym zestawie. Spróbuj później lub ucz się klasycznie.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.outline),
              ),
            );
          }
          if (_index >= _cards.length) _index = 0;
          final card = _cards[_index];

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flashcard(
                frontText: card.front,
                backText: card.back,
                onCorrect: () => _handleCorrect(card),
                onWrong: () => _handleWrong(card),
              ),
              const SizedBox(height: 24),
              Text(
                '${_index + 1} / ${_cards.length} (tylko karty do powtórki)',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}
