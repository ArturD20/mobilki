import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sets_service.dart';

class StudyScreen extends StatefulWidget {
  final String setId;
  final String? setTitle;
  final List<String>? onlyIds; // if provided, limit study to these IDs
  const StudyScreen({super.key, required this.setId, this.setTitle, this.onlyIds});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<Map<String, dynamic>> _cards = [];
  int _index = 0;
  int correctCount = 0;
  int wrongCount = 0;
  final List<String> _wrongIds = [];

  void _finish() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/studySummary',
      arguments: {
        'setId': widget.setId,
        'title': widget.setTitle,
        'total': _cards.length,
        'correct': correctCount,
        'wrong': wrongCount,
        'wrongIds': _wrongIds,
      },
    );
  }

  void _nextCard() {
    if (_index >= _cards.length - 1) {
      _finish();
      return;
    }
    setState(() => _index = _index + 1);
  }

  void _onCorrect() {
    setState(() => correctCount++);
    _nextCard();
  }

  void _onWrong() {
    setState(() {
      wrongCount++;
      final cid = (_cards.isNotEmpty && _index < _cards.length) ? (_cards[_index]['id'] as String?) : null;
      if (cid != null && !_wrongIds.contains(cid)) {
        _wrongIds.add(cid);
      }
    });
    _nextCard();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.setTitle ?? 'Gra';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Gra: $title')),
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
          var built = docs
              .map((d) => {
                    'id': d.id,
                    'front': d.data()['front'] ?? '',
                    'back': d.data()['back'] ?? '',
                  })
              .toList();
          if (widget.onlyIds != null && widget.onlyIds!.isNotEmpty) {
            final allow = widget.onlyIds!.toSet();
            built = built.where((m) => allow.contains(m['id'] as String)).toList();
          }
          _cards = built;
          if (_cards.isEmpty) {
            _index = 0;
          } else if (_index >= _cards.length) {
            _index = _cards.length - 1;
          }

          if (_cards.isEmpty) {
            return Center(
              child: Text('Brak fiszek w tym zestawie', style: TextStyle(color: cs.outline)),
            );
          }

          final card = _cards[_index];

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flashcard(
                frontText: card['front'] ?? '',
                backText: card['back'] ?? '',
                onCorrect: _onCorrect,
                onWrong: _onWrong,
              ),
              const SizedBox(height: 24),
              Text(
                '${_index + 1} / ${_cards.length}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CounterDisplay(
                      icon: Icons.close,
                      color: Colors.red,
                      label: 'Nie umiem',
                      count: wrongCount,
                    ),
                    _CounterDisplay(
                      icon: Icons.check,
                      color: Colors.green,
                      label: 'Umiem',
                      count: correctCount,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 🔹 Pojedynczy „licznik” bez klikalności
class _CounterDisplay extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _CounterDisplay({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// 🔸 Karta z pełną animacją 3D (flip) + swipe
class Flashcard extends StatefulWidget {
  final String frontText;
  final String backText;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;

  const Flashcard({
    Key? key,
    required this.frontText,
    required this.backText,
    required this.onCorrect,
    required this.onWrong,
  }) : super(key: key);

  @override
  State<Flashcard> createState() => _FlashcardState();
}

class _FlashcardState extends State<Flashcard> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  bool _flipped = false;
  Offset _offset = Offset.zero;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;
    if (_flipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    _flipped = !_flipped;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
      _angle = 0.002 * _offset.dx;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_offset.dx > 100) {
      widget.onCorrect();
    } else if (_offset.dx < -100) {
      widget.onWrong();
    }
    setState(() {
      _offset = Offset.zero;
      _angle = 0;
      _flipped = false;
      _flipController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: _flipCard,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, child) {
          final angle = _flipController.value * math.pi;
          final showingFront = angle < math.pi / 2;
          final text = showingFront ? widget.frontText : widget.backText;

          return Center(
            child: Transform.translate(
              offset: _offset,
              child: Transform.rotate(
                angle: _angle,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: Container(
                    width: size.width * 0.8,
                    height: size.height * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black26,
                          offset: Offset(0, 6),
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: showingFront
                          ? Matrix4.identity()
                          : Matrix4.rotationY(math.pi),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
