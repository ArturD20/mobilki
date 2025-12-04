import 'package:flutter/material.dart';
import 'sets_service.dart';
import 'leitner_scheduler.dart';
import 'study_screen.dart' show Flashcard; 

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
  int _answeredCount = 0; // ile fiszek przerobiono w tej sesji
  int? _sessionTotalDue; // ile fiszek było do powtórki na początku sesji

  void _nextCard() {
    if (_sessionTotalDue == null) return;

    setState(() {
      _answeredCount++;
    });

    // Jeśli przerobiliśmy wszystkie fiszki zaplanowane na dziś – kończymy sesję.
    if (_answeredCount >= _sessionTotalDue!) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
  }

  Future<void> _handleCorrect(LeitnerCardState current) async {
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
      body: StreamBuilder<List<LeitnerCardState>>(
        stream: SetsService.leitnerCardsStream(widget.setId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Błąd: ${snap.error}'));
          }
          final allCards = snap.data ?? [];
          final now = DateTime.now();
          final dueCards = allCards
              .where((c) => LeitnerScheduler.isDue(c, now))
              .toList();

          _cards = dueCards;

          // Ustal stałą liczbę fiszek na daną sesję (pierwsze wczytanie).
          _sessionTotalDue ??= _cards.length;
          if (_cards.isEmpty) {
            return Center(
              child: Text(
                'Brak fiszek do powtórki w tym zestawie. Spróbuj później lub ucz się klasycznie.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.outline),
              ),
            );
          }
          // Wylicz indeks aktualnej karty na podstawie liczby odpowiedzi
          // oraz aktualnej liczby kart do powtórki (modulo, żeby się "kręcić" po liście).
          if (_cards.isEmpty) {
            return Center(
              child: Text(
                'Brak fiszek do powtórki w tym zestawie. Spróbuj później lub ucz się klasycznie.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.outline),
              ),
            );
          }

          _index = _answeredCount % _cards.length;
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
                '${_answeredCount + 1} / ${_sessionTotalDue ?? _cards.length} (tylko karty do powtórki)',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}
