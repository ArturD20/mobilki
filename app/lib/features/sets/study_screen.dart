import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sets_service.dart';

class StudyScreen extends StatefulWidget {
  final String? setId; // Teraz opcjonalne
  final String? setTitle;
  final String? fromGlobalSetId; // Opcjonalne ID zestawu globalnego (dla wirtualnych kopii)
  final List<String>? onlyIds; // if provided, limit study to these IDs
  const StudyScreen({super.key, this.setId, this.setTitle, this.fromGlobalSetId, this.onlyIds});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<Map<String, dynamic>> _cards = [];
  int _index = 0;
  int correctCount = 0;
  int wrongCount = 0;
  final List<String> _wrongIds = [];
  bool _isLoading = true;
  String? _resolvedGlobalSetId; // Przechowuje ID globalne, jeśli zestaw jest wirtualny
  String? _currentSetId; // Przechowuje aktualne ID zestawu użytkownika (może być null na początku)

  @override
  void initState() {
    super.initState();
    _currentSetId = widget.setId;
    _checkIfVirtualAndLoadProgress();
  }

  Future<void> _checkIfVirtualAndLoadProgress() async {
    // 1. Jeśli mamy globalSetId, ale nie mamy setId, sprawdźmy czy zestaw już istnieje
    if (_currentSetId == null && widget.fromGlobalSetId != null) {
      _resolvedGlobalSetId = widget.fromGlobalSetId;
      try {
        final existingId = await SetsService.findSetIdByGlobalId(widget.fromGlobalSetId!);
        if (existingId != null) {
          _currentSetId = existingId;
        }
      } catch (e) {
        debugPrint('Błąd szukania istniejącego zestawu: $e');
      }
    } 
    // 2. Jeśli mamy setId, sprawdźmy czy jest wirtualny
    else if (_currentSetId != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('sets').doc(_currentSetId).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['isVirtual'] == true) {
            _resolvedGlobalSetId = data['fromGlobalSetId'];
          }
        }
      } catch (e) {
        debugPrint('Błąd sprawdzania wirtualności zestawu: $e');
      }
    }

    // 3. Załaduj postęp (tylko jeśli mamy setId)
    if (_currentSetId != null) {
      await _loadProgress();
    } else {
      // Jeśli nie mamy setId, to znaczy że to nowa gra z globalnego zestawu
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProgress() async {
    if (widget.onlyIds != null || _currentSetId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final progress = await SetsService.getSessionProgress(_currentSetId!);
    if (progress != null && mounted) {
      setState(() {
        _index = progress['index'] as int? ?? 0;
        correctCount = progress['correct'] as int? ?? 0;
        wrongCount = progress['wrong'] as int? ?? 0;
        final wIds = progress['wrongIds'] as List?;
        if (wIds != null) {
          _wrongIds.addAll(wIds.map((e) => e.toString()));
        }
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<String> _ensureSetId() async {
    if (_currentSetId != null) return _currentSetId!;
    
    if (_resolvedGlobalSetId == null) {
      throw StateError('Brak setId i brak globalSetId - nie można zapisać postępu');
    }

    // Tworzymy wirtualną kopię zestawu (tylko nagłówek)
    final newId = await SetsService.copyGlobalSet(_resolvedGlobalSetId!);
    setState(() {
      _currentSetId = newId;
    });
    return newId;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _finish() async {
    if (!mounted) return;
    
    // Jeśli użytkownik nic nie zrobił (nie ma setId), to po prostu wychodzimy
    if (_currentSetId == null) {
       Navigator.of(context).pop();
       return;
    }

    final setId = await _ensureSetId();
    
    // Czyścimy postęp sesji, bo zestaw został ukończony
    await SetsService.clearSessionProgress(setId);

    // Zapisujemy wynik ostatniej sesji
    await SetsService.updateSetLatestResult(
      setId: setId,
      correct: correctCount,
      wrong: wrongCount,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/studySummary',
      arguments: {
        'setId': setId,
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
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    if (widget.onlyIds == null) {
      // Zapisujemy postęp w tle, tworząc zestaw jeśli trzeba
      try {
        final setId = await _ensureSetId();
        await SetsService.updateSessionProgress(
          setId: setId,
          index: _index,
          correct: correctCount,
          wrong: wrongCount,
          wrongIds: _wrongIds,
        );
      } catch (e) {
        debugPrint('Błąd zapisu postępu: $e');
      }
    }
  }

  Future<void> _onCorrect() async {
    setState(() => correctCount++);
    try {
      final setId = await _ensureSetId();
      await SetsService.updateSetStatistics(setId: setId, correct: 1, wrong: 0);
    } catch (e) {
      debugPrint('Błąd aktualizacji statystyk: $e');
    }
    _nextCard();
  }

  Future<void> _onWrong() async {
    setState(() {
      wrongCount++;
      final cid = (_cards.isNotEmpty && _index < _cards.length) ? (_cards[_index]['id'] as String?) : null;
      if (cid != null && !_wrongIds.contains(cid)) {
        _wrongIds.add(cid);
      }
    });
    try {
      final setId = await _ensureSetId();
      await SetsService.updateSetStatistics(setId: setId, correct: 0, wrong: 1);
    } catch (e) {
      debugPrint('Błąd aktualizacji statystyk: $e');
    }
    _nextCard();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.setTitle ?? 'Gra';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Gra: $title')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _resolvedGlobalSetId != null 
            ? SetsService.globalCardsStream(_resolvedGlobalSetId!) 
            : (_currentSetId != null ? SetsService.cardsStream(_currentSetId!) : const Stream.empty()),
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
          
          // Walidacja indeksu po załadowaniu kart
          if (_cards.isEmpty) {
            _index = 0;
          } else if (_index >= _cards.length) {
            // Jeśli zapisany indeks jest poza zakresem (np. usunięto karty), zacznij od końca lub zresetuj
            _index = _cards.length - 1; 
            // Opcjonalnie: można zresetować postęp jeśli dane są niespójne
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
    if (_offset.dx > 120) {
      widget.onCorrect();
    } else if (_offset.dx < -120) {
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
