import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../sets/sets_service.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statystyki'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SetsService.mySetsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Brak zestawów do wyświetlenia statystyk.'));
          }

          // Obliczanie statystyk
          int totalStarted = 0;
          int totalCompleted = 0;
          int totalCorrect = 0;
          int totalWrong = 0;

          final List<Map<String, dynamic>> setStats = [];

          for (var doc in docs) {
            final data = doc.data();
            final title = data['title'] ?? '(bez nazwy)';
            
            // Do ogólnych statystyk używamy skumulowanych liczników
            final correct = (data['correctCount'] as int?) ?? 0;
            final wrong = (data['wrongCount'] as int?) ?? 0;
            final totalCards = (data['cards'] as int?) ?? 0;

            // Do statystyk zestawu używamy wyników z ostatniej sesji (jeśli są),
            // a jeśli nie ma (np. stary zestaw), to bierzemy skumulowane (lub 0).
            // Ale uwaga: jeśli użytkownik chce widzieć "poprawność danego zestawu"
            // to najlepiej pokazać wynik ostatniej próby (latestCorrect/latestWrong).
            // Jeśli ich nie ma, to znaczy że zestaw nie był robiony w nowym trybie,
            // więc możemy pokazać 0 lub stare dane.
            // Przyjmijmy: latest > sessionProgress > cumulative (jako fallback).
            
            int setCorrect = (data['latestCorrect'] as int?) ?? 0;
            int setWrong = (data['latestWrong'] as int?) ?? 0;
            
            // Jeśli nie ma latest, sprawdźmy czy jest sesja w toku
            if (setCorrect == 0 && setWrong == 0 && data.containsKey('sessionProgress')) {
               final sp = data['sessionProgress'] as Map<String, dynamic>?;
               if (sp != null) {
                 setCorrect = (sp['correct'] as int?) ?? 0;
                 setWrong = (sp['wrong'] as int?) ?? 0;
               }
            }

            // Jeśli nadal 0, a mamy stare dane skumulowane i to jedyne dane, to pokażmy je (opcjonalnie)
            // Ale user chciał "aktualizuj poprawność", więc lepiej pokazywać bieżący stan.
            // Jeśli zestaw nie był ruszany, to 0/0 jest ok.

            // Zakładamy, że zestaw jest rozpoczęty, jeśli ma jakiekolwiek odpowiedzi (historycznie)
            if (correct + wrong > 0) {
              totalStarted++;
              // Zakładamy, że zestaw jest ukończony, jeśli suma odpowiedzi >= liczbie kart
              if (correct + wrong >= totalCards && totalCards > 0) {
                totalCompleted++;
              }

              // Do listy zestawów dodajemy wyniki "lokalne" (ostatnia sesja)
              // Ale tylko jeśli coś w tej sesji zrobiono. Jeśli nie, to pokazujemy "0% (0/0)" lub historię?
              // User: "aktualizuj poprawność danego zestawu... sprawdzaj tą poprawnosc na podstawie zestawow fiszek"
              // Interpretacja: Pokaż wynik ostatniego podejścia do tego zestawu.
              
              // Jeśli latestCorrect/Wrong są puste, ale correctCount > 0, to znaczy że to stare dane.
              // Możemy je wyświetlić jako fallback, ale zaznaczmy że to historia?
              // Prościej: użyjmy latest, a jak 0 to session, a jak 0 to cumulative (dla wstecznej kompatybilności).
              
              int displayCorrect = setCorrect;
              int displayWrong = setWrong;
              
              // Fallback dla starych danych (przed wprowadzeniem latest)
              if (displayCorrect == 0 && displayWrong == 0 && (correct > 0 || wrong > 0)) {
                 // Tu jest ryzyko, że cumulative jest ogromne (wiele podejść).
                 // Ale lepsze to niż 0.
                 // Jednak user chciał "jak jest 5 fiszek to sprawdzaj na podstawie zestawu".
                 // Cumulative może mieć 50 poprawnych przy 5 fiszkach. To zepsuje wykres.
                 // Więc lepiej pokazać 0 lub spróbować oszacować.
                 // Zostawmy 0 jeśli nie ma latest/session, bo to wymusi na userze zrobienie zestawu od nowa by mieć ładne statystyki.
                 // Albo: jeśli cumulative <= totalCards, to użyjmy cumulative.
                 if (correct + wrong <= totalCards) {
                   displayCorrect = correct;
                   displayWrong = wrong;
                 }
              }

              setStats.add({
                'title': title,
                'correct': displayCorrect,
                'wrong': displayWrong,
                'total': displayCorrect + displayWrong, // To będzie suma z ostatniej sesji
                'totalCards': totalCards, // Całkowita liczba kart w zestawie
              });

              totalCorrect += correct;
              totalWrong += wrong;
            }
          }

          final totalAnswers = totalCorrect + totalWrong;
          final correctPercent = totalAnswers > 0 ? ((totalCorrect / totalAnswers) * 100).toStringAsFixed(1) : '0.0';
          final wrongPercent = totalAnswers > 0 ? ((totalWrong / totalAnswers) * 100).toStringAsFixed(1) : '0.0';

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Ogólne statystyki
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Ogólne wyniki', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Poprawne', style: TextStyle(color: Colors.green)),
                              Text('$correctPercent%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                              Text('($totalCorrect)'),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Niepoprawne', style: TextStyle(color: Colors.red)),
                              Text('$wrongPercent%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                              Text('($totalWrong)'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rozpoczęte zestawy:'),
                          Text('$totalStarted', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ukończone zestawy:'),
                          Text('$totalCompleted', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Statystyki zestawów', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // Lista statystyk dla poszczególnych zestawów
              if (setStats.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Brak danych o nauce dla Twoich zestawów.'),
                )
              else
                ...setStats.map((stat) {
                  final sTotal = stat['total'] as int;
                  final sCorrect = stat['correct'] as int;
                  final sWrong = stat['wrong'] as int;
                  final sTotalCards = stat['totalCards'] as int; // Używamy całkowitej liczby kart w zestawie jako bazy
                  
                  // Procent poprawności w ramach ostatniej sesji
                  final sCorrectPercent = sTotal > 0 ? ((sCorrect / sTotal) * 100).toStringAsFixed(1) : '0.0';
                  
                  // Postęp w zestawie (ile zrobiono z całości)
                  final progressValue = sTotalCards > 0 ? sTotal / sTotalCards : 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(stat['title']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          // Pasek postępu pokazuje ile kart z zestawu przerobiono w tej sesji
                          LinearProgressIndicator(
                            value: progressValue > 1.0 ? 1.0 : progressValue,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              // Kolor paska zależy od poprawności
                              (sTotal > 0 && (sCorrect / sTotal) > 0.8) ? Colors.green : Colors.orange
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Wynik: $sCorrectPercent% poprawnych ($sCorrect/$sTotal)'),
                          if (sTotal < sTotalCards)
                             Text('Postęp: $sTotal / $sTotalCards fiszek', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: Text(
                        'Błędy: $sWrong',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
