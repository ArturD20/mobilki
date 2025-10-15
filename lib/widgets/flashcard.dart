import 'package:flutter/material.dart';
import 'dart:math' as math;

class Flashcard extends StatefulWidget {
  final String frontText;
  final String backText;
  final VoidCallback onNext;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;

  const Flashcard({
    Key? key,
    required this.frontText,
    required this.backText,
    required this.onNext,
    required this.onCorrect,
    required this.onWrong,
  }) : super(key: key);

  @override
  State<Flashcard> createState() => _FlashcardState();
}

class _FlashcardState extends State<Flashcard> with SingleTickerProviderStateMixin {
  bool _flipped = false;
  Offset _offset = Offset.zero;
  double _angle = 0;

  void _flipCard() => setState(() => _flipped = !_flipped);

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center( // 👈 Wycentrowanie karty
      child: GestureDetector(
        onTap: _flipCard,
        onPanUpdate: _handleDragUpdate,
        onPanEnd: _handleDragEnd,
        child: Transform.translate(
          offset: _offset,
          child: Transform.rotate(
            angle: _angle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black26,
                    offset: Offset(0, 6),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => RotationYTransition(turns: anim, child: child),
                child: Text(
                  _flipped ? widget.backText : widget.frontText,
                  key: ValueKey(_flipped),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animacja obrotu karty (efekt 3D)
class RotationYTransition extends AnimatedWidget {
  final Widget child;
  const RotationYTransition({Key? key, required Animation<double> turns, required this.child})
      : super(key: key, listenable: turns);

  @override
  Widget build(BuildContext context) {
    final turns = listenable as Animation<double>;
    final angle = turns.value * math.pi;
    final isFront = angle < math.pi / 2;
    return Transform(
      transform: Matrix4.rotationY(angle),
      alignment: Alignment.center,
      child: isFront
          ? child
          : Transform(
              transform: Matrix4.rotationY(math.pi),
              alignment: Alignment.center,
              child: child,
            ),
    );
  }
}
