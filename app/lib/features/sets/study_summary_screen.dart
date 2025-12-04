import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'study_screen.dart';

class StudySummaryScreen extends StatefulWidget {
  final String setId;
  final String? setTitle;
  final int totalCards;
  final int? correct;
  final int? wrong;
  final List<String>? wrongIds;

  const StudySummaryScreen({
    super.key,
    required this.setId,
    this.setTitle,
    required this.totalCards,
    this.correct,
    this.wrong,
    this.wrongIds,
  });

  @override
  State<StudySummaryScreen> createState() => _StudySummaryScreenState();
}

class _StudySummaryScreenState extends State<StudySummaryScreen> {
  late ConfettiController _confettiController;
  late ConfettiController _sadConfettiController;
  bool _isPerfectScore = false;
  bool _isPerfectFail = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _sadConfettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Sprawdź czy użytkownik zdobył 100% poprawnych
    _isPerfectScore = widget.correct != null && 
                      widget.wrong != null && 
                      widget.correct == widget.totalCards && 
                      widget.wrong == 0;
    
    // Sprawdź czy użytkownik zdobył 100% błędnych (0% poprawnych)
    _isPerfectFail = widget.correct != null && 
                     widget.wrong != null && 
                     widget.correct == 0 && 
                     widget.wrong == widget.totalCards;
    
    if (_isPerfectScore) {
      // Uruchom confetti po krótkiej chwili
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _confettiController.play();
        }
      });
    } else if (_isPerfectFail) {
      // Uruchom smutne "confetti" po krótkiej chwili
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _sadConfettiController.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _sadConfettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = widget.setTitle ?? 'Zestaw';
    return Scaffold(
      appBar: AppBar(title: const Text('Podsumowanie')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                if (_isPerfectScore) ...[
                  const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    'Gratulacje!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.amber.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '100% poprawnych odpowiedzi! 🎉',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isPerfectFail) ...[
                  const Text(
                    '😢',
                    style: TextStyle(fontSize: 80),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nie poddawaj się!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '0% poprawnych odpowiedzi... Spróbuj jeszcze raz!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Ukończono naukę'),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.totalCards} fiszek',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (widget.correct != null || widget.wrong != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.correct != null)
                          Row(children: [
                            const Icon(Icons.check, color: Colors.green),
                            const SizedBox(width: 6),
                            Text('Umiem: ${widget.correct!}')
                          ]),
                        if (widget.wrong != null)
                          Row(children: [
                            const Icon(Icons.close, color: Colors.red),
                            const SizedBox(width: 6),
                            Text('Nie umiem: ${widget.wrong!}')
                          ]),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            if (widget.wrongIds != null && widget.wrongIds!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => StudyScreen(
                          setId: widget.setId,
                          setTitle: widget.setTitle,
                          onlyIds: widget.wrongIds,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.replay_circle_filled),
                  label: const Text('Ucz się tylko błędnych'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => StudyScreen(setId: widget.setId, setTitle: widget.setTitle),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Jeszcze raz'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text('Wróć do menu'),
              ),
            ),
              ],
            ),
          ),
          // Efekt confetti - wyświetlany tylko gdy 100% poprawnych
          if (_isPerfectScore)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow,
                  Colors.red,
                ],
              ),
            ),
          // Spadające kropelki - wyświetlane gdy 100% źle (0% poprawnych)
          if (_isPerfectFail)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _sadConfettiController,
                blastDirection: 3.14 / 2, // Prosty spadek w dół
                particleDrag: 0.02,
                emissionFrequency: 0.1,
                numberOfParticles: 25,
                gravity: 0.4,
                shouldLoop: false,
                colors: const [
                  Color(0xFF64B5F6), // Jasnoniebieski - woda
                  Color(0xFF42A5F5), // Niebieski - woda
                  Color(0xFF90CAF9), // Bardzo jasny niebieski
                ],
                createParticlePath: (size) {
                  // Kształt kropli wody 💧
                  final path = Path();
                  final width = size.width;
                  final height = size.height;
                  
                  // Górna część kropli (okrąg)
                  path.moveTo(width / 2, 0);
                  path.quadraticBezierTo(width * 0.8, height * 0.3, width / 2, height * 0.6);
                  
                  // Dolna część kropli (zaostrzony koniec)
                  path.quadraticBezierTo(width / 2, height, width / 2, height);
                  path.quadraticBezierTo(width / 2, height * 0.6, width * 0.2, height * 0.3);
                  path.quadraticBezierTo(width / 2, 0, width / 2, 0);
                  
                  return path;
                },
              ),
            ),
        ],
      ),
    );
  }
}
