import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wybór języka'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Wybierz język, którego chcesz się uczyć',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildLanguageCard(
                    context,
                    language: 'Angielski',
                    flag: '🇬🇧',
                    color: Colors.blue.shade50,
                    iconColor: Colors.blue,
                  ),
                  _buildLanguageCard(
                    context,
                    language: 'Hiszpański',
                    flag: '🇪🇸',
                    color: Colors.orange.shade50,
                    iconColor: Colors.orange,
                  ),
                  _buildLanguageCard(
                    context,
                    language: 'Niemiecki',
                    flag: '🇩🇪',
                    color: Colors.amber.shade50,
                    iconColor: Colors.amber.shade800,
                  ),
                  _buildLanguageCard(
                    context,
                    language: 'Francuski',
                    flag: '🇫🇷',
                    color: Colors.indigo.shade50,
                    iconColor: Colors.indigo,
                  ),
                  _buildLanguageCard(
                    context,
                    language: 'Włoski',
                    flag: '🇮🇹',
                    color: Colors.green.shade50,
                    iconColor: Colors.green,
                  ),
                  _buildLanguageCard(
                    context,
                    language: 'Japoński',
                    flag: '🇯🇵',
                    color: Colors.red.shade50,
                    iconColor: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context, {
    required String language,
    required String flag,
    required Color color,
    required Color iconColor,
  }) {
    return Card(
      elevation: 3,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Nawigacja do zestawów w danym języku
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Wybrano: $language'),
              duration: const Duration(seconds: 2),
            ),
          );
          // Możesz tutaj dodać nawigację, np.:
          // Navigator.of(context).pushNamed('/sets', arguments: language);
        },
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  flag,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  language,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
