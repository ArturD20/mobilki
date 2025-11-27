import 'package:cloud_firestore/cloud_firestore.dart';

/// Konfiguracja systemu Leitnera: 5 pudełek, dni przerw.
class LeitnerConfig {
  static const int minBox = 1;
  static const int maxBox = 5;

  /// Indeksy: box -> days; 0 ignorujemy.
  static const List<int> boxIntervalsDays = [0, 1, 2, 4, 7, 14];

  static int intervalDaysForBox(int box) {
    if (box < minBox) box = minBox;
    if (box > maxBox) box = maxBox;
    return boxIntervalsDays[box];
  }
}

/// Prosty stan Leitnera powiązany z kartą.
class LeitnerCardState {
  final String id;
  final String front;
  final String back;
  final int box;
  final DateTime? nextReviewAt;

  const LeitnerCardState({
    required this.id,
    required this.front,
    required this.back,
    required this.box,
    required this.nextReviewAt,
  });

  factory LeitnerCardState.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final box = (data['leitnerBox'] is int) ? data['leitnerBox'] as int : LeitnerConfig.minBox;
    final ts = data['nextReviewAt'];
    DateTime? next;
    if (ts is Timestamp) {
      next = ts.toDate();
    } else if (ts is DateTime) {
      next = ts;
    } else {
      next = null;
    }
    return LeitnerCardState(
      id: doc.id,
      front: (data['front'] ?? '') as String,
      back: (data['back'] ?? '') as String,
      box: box,
      nextReviewAt: next,
    );
  }
}

class LeitnerScheduler {
  /// Czy karta jest dzisiaj do powtórki (lub spóźniona).
  static bool isDue(LeitnerCardState state, DateTime now) {
    if (state.nextReviewAt == null) {
      // Brak daty => potraktuj jako do nauki.
      return true;
    }
    return !state.nextReviewAt!.isAfter(now);
  }

  /// Awans po poprawnej odpowiedzi (demotion rule B: +1 box, max 5).
  static LeitnerCardState onCorrect(LeitnerCardState current, DateTime now) {
    var newBox = current.box + 1;
    if (newBox > LeitnerConfig.maxBox) newBox = LeitnerConfig.maxBox;
    final days = LeitnerConfig.intervalDaysForBox(newBox);
    final next = now.add(Duration(days: days));
    return LeitnerCardState(
      id: current.id,
      front: current.front,
      back: current.back,
      box: newBox,
      nextReviewAt: next,
    );
  }

  /// Pomyłka: zejście o 1 pudełko, min 1; przerwa wg nowego pudełka.
  static LeitnerCardState onWrong(LeitnerCardState current, DateTime now) {
    var newBox = current.box - 1;
    if (newBox < LeitnerConfig.minBox) newBox = LeitnerConfig.minBox;
    final days = LeitnerConfig.intervalDaysForBox(newBox);
    final next = now.add(Duration(days: days));
    return LeitnerCardState(
      id: current.id,
      front: current.front,
      back: current.back,
      box: newBox,
      nextReviewAt: next,
    );
  }
}
