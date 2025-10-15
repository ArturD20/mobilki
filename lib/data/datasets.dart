class WordPair {
  final String pl;
  final String en;

  WordPair({required this.pl, required this.en});
}

class Dataset {
  final String id;
  final String name;
  final List<WordPair> words;

  Dataset({required this.id, required this.name, required this.words});
}

// Przykładowe zestawy fiszek
final datasets = [
  Dataset(
    id: 'basic',
    name: 'Podstawowe słowa',
    words: [
      WordPair(pl: 'kot', en: 'cat'),
      WordPair(pl: 'pies', en: 'dog'),
      WordPair(pl: 'dom', en: 'house'),
      WordPair(pl: 'samochód', en: 'car'),
      WordPair(pl: 'drzewo', en: 'tree'),
    ],
  ),
  Dataset(
    id: 'food',
    name: 'Jedzenie',
    words: [
      WordPair(pl: 'jabłko', en: 'apple'),
      WordPair(pl: 'chleb', en: 'bread'),
      WordPair(pl: 'ser', en: 'cheese'),
      WordPair(pl: 'mleko', en: 'milk'),
      WordPair(pl: 'pomidor', en: 'tomato'),
    ],
  ),
  Dataset(
    id: 'colors',
    name: 'Kolory',
    words: [
      WordPair(pl: 'czerwony', en: 'red'),
      WordPair(pl: 'zielony', en: 'green'),
      WordPair(pl: 'niebieski', en: 'blue'),
      WordPair(pl: 'żółty', en: 'yellow'),
      WordPair(pl: 'czarny', en: 'black'),
    ],
  ),
];
