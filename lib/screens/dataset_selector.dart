import 'package:flutter/material.dart';
import '../data/datasets.dart';
import 'flashcard_screen.dart';
import 'create_set_screen.dart';

class DatasetSelector extends StatelessWidget {
  const DatasetSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main content area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Wybierz zestaw fiszek",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ...datasets.map((dataset) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FlashcardScreen(dataset: dataset),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            dataset.name,
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Bottom-aligned generate button (blue)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateSetScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Generuj zestaw'),
                  style: ElevatedButton.styleFrom(
                    // TUTAJ DODAJEMY FOREGROUNDCOLOR
                    foregroundColor: Colors.white, 

                    // textStyle używamy tylko do ustawienia rozmiaru czcionki
                    textStyle: const TextStyle(fontSize: 18), 
                    
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
