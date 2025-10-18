# Flashcards (Mobilki) — README

Krótki, praktyczny przewodnik dla zespołu: co jest czym, jak postawić środowisko (Flutter + Firebase), jak odpalać aplikację i emulatory, gdzie pisać kod i jak dodawać nowe ekrany/feature’y.

---

## Spis treści

- [Architektura i flow](#architektura-i-flow)
- [Struktura katalogów](#struktura-katalogów)
- [Wymagania wstępne](#wymagania-wstępne)
- [Setup środowiska (krok po kroku)](#setup-środowiska-krok-po-kroku)
- [Konfiguracja iOS (CocoaPods)](#konfiguracja-ios-cocoapods)
- [Uruchamianie aplikacji](#uruchamianie-aplikacji)
- [Firebase Emulators (Auth/Firestore/Storage)](#firebase-emulators-authfirestorestorage)
- [Gdzie pisać kod (konwencje)](#gdzie-pisać-kod-konwencje)
- [Tworzenie nowego ekranu — szybkie how-to](#tworzenie-nowego-ekranu--szybkie-how-to)
- [Dodawanie paczek](#dodawanie-paczek)
- [Najczęstsze problemy i szybkie fixy](#najczęstsze-problemy-i-szybkie-fixy)

---

## Architektura i flow

- **`AuthGate`** (guard) decyduje, czy pokazać logowanie (`LoginScreen`), czy właściwą aplikację (np. `HomeScreen`) w zależności od `FirebaseAuth.currentUser`.
- **Routing**: prosto i jawnie, przez mapę `routes` w `MaterialApp` (w `lib/main.dart`).
  Domyślne trasy:

  - `/` → `AuthGate`
  - `/login` → `LoginScreen`

- **Firebase init**: w `lib/core/firebase_init.dart`.
  Korzysta z wygenerowanego `firebase_options.dart` i (opcjonalnie) łączy z **Emulatorem Auth** wg ustawień w `lib/core/env.dart`.

---

## Struktura katalogów

```
lib/
  core/
    env.dart                  # Flagi i adresy emulatorów Firebase
    firebase_init.dart        # Inicjalizacja Firebase (i ewentualnie emulatorów)
    firebase_options.dart     # Wygenerowane przez `flutterfire configure` (NIE edytować)
    routes.dart               # Generator tras
  features/
    auth/
      auth_gate.dart          # Bramka logowania na start
      login_screen.dart       # Ekran logowania
    home/
      home_screen.dart        # Ekran po zalogowaniu (placeholder)
  widgets/                    # Re-używalne widżety UI
  main.dart                   # Wejście aplikacji, MaterialApp,

firebase/
  functions/                  # Cloud Functions (Python)

ios/, android/                # Projekty natywne
firebase.json                 # Konfiguracja emulatorów Firebase
firestore.rules               # Reguły Firestore
firestore.indexes.json        # Indeksy Firestore
storage.rules                 # Reguły Storage
```

**Najważniejsze pliki:**

- `lib/core/firebase_options.dart` — _auto-generated_, trzyma klucze i identyfikatory projektu Firebase.
- `lib/core/env.dart` — szybka konfiguracja emulatorów (host/port, flaga `useEmulators`).
- `lib/core/firebase_init.dart` — jedna funkcja `initFirebase()` odpalana w `main()`.

---

## Wymagania wstępne

- **Flutter** 3.x (sprawdź: `flutter --version`, `flutter doctor`)
- **Dart** (instaluje się z Flutterem)
- **Xcode** (na macOS) i **CocoaPods** (`sudo gem install cocoapods`)
- **Android Studio** / SDK (jeśli budujesz na Androida)
- **Node.js + npm** (do `firebase-tools`)
- Dostęp do projektu **Firebase** (konsola Firebase)

---

## Setup środowiska (krok po kroku)

1. **Klon repo i zależności Fluttera**

```bash
git clone <repo>
cd app
flutter clean
flutter pub get
```

2. **Instalacja CLI do Firebase (globalnie)**

```bash
npm i -g firebase-tools
firebase login
```

3. **Instalacja FlutterFire CLI (jeśli nie masz)**

```bash
dart pub global activate flutterfire_cli
# upewnij się, że ~/.pub-cache/bin jest w PATH
```

4. **Powiązanie projektu z Firebase i wygenerowanie opcji**

> _Jeśli `lib/core/firebase_options.dart` już istnieje i jest aktualny — pomiń ten krok._

```bash
flutterfire configure \
  --platforms=ios,android \
  --out=lib/core/firebase_options.dart
```

5. **Ustawienia emulatorów w kodzie**
   `lib/core/env.dart`:

```dart
class Env {
  static const bool useEmulators = true;   // podczas dev
  static const String authHost = 'localhost';
  static const int authPort = 9099;
}
```

6. **Inicjalizacja Firebase w appce**
   `lib/core/firebase_init.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
// emulator Auth (tylko w debug + gdy useEmulators==true)
```

---

## Konfiguracja iOS (CocoaPods)

1. **Minimalny target iOS**
   W `ios/Podfile`:

```ruby
platform :ios, '17.0'
```

2. **Instalacja podów**

```bash
cd ios
pod repo update
pod install
cd ..
```

---

## Uruchamianie aplikacji

**iOS (symulator iPhone 15 Pro):**

```bash
open -a Simulator
xcrun simctl boot "iPhone 15 Pro"
flutter run -d "iPhone 15 Pro"
```

**Android (jeśli emulator jest uruchomiony):**

```bash
flutter devices
flutter run -d <ID_URZĄDZENIA>
```

**Czyszczenie i ponowne pobranie paczek (gdy coś się sypie):**

```bash
flutter clean
flutter pub get
```

---

## Firebase Emulators (Auth/Firestore/Storage)

> W repo są pliki `firebase.json`, `firestore.rules`, `storage.rules`, więc emulatory są skonfigurowane.

**Start emulatorów:**

```bash
# w katalogu z firebase.json (firebase/)
firebase emulators:start
```

Domyślnie:

- **Auth**: `localhost:9099`
- **Firestore**: `localhost:8080`
- **Storage**: `localhost:9199`

**App → Emulator Auth**: sterowane przez `Env.useEmulators` i `FirebaseAuth.instance.useAuthEmulator(...)` w `firebase_init.dart`.

> Jeśli chcesz też spiąć Firestore/Storage z emulatorami, można dorobić:

```dart
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
```

(pamiętaj o pakietach i imporcie — i tylko dla `kDebugMode`).

---

## Gdzie pisać kod (konwencje)

- **Ekrany/feature’y**: `lib/features/<nazwa_feature>/`

  - `..._screen.dart` — główny ekran
  - `..._controller.dart` / `..._service.dart` — logika (opcjonalnie)
  - `widgets/` — widżety specyficzne dla feature’a

- **Wspólne widżety**: `lib/widgets/`
- **Init/konfiguracje**: `lib/core/`
- **Routing**:
  `lib/core/routes.dart` i `onGenerateRoute`

- **Nazewnictwo**: `snake_case` dla plików, `PascalCase` dla klas, `lowerCamelCase` dla zmiennych/metod.

---

jasne — tu jest poprawiona sekcja „Tworzenie nowego ekranu” pod **`onGenerateRoute`** (tak jak masz w `lib/core/routes.dart`).

---

## Tworzenie nowego ekranu — szybkie how-to (`profile`)

1. **Stwórz plik**: `lib/features/profile/profile_screen.dart`

```dart
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('My profile')),
    );
  }
}
```

2. **Zarejestruj trasę** w `lib/core/routes.dart`
   Dodaj import i case:

```dart
import 'package:flutter/material.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/login_screen.dart';
import '../features/profile/profile_screen.dart'; // <— NOWY IMPORT

Route<dynamic> onGenerateRoute(RouteSettings s) {
  switch (s.name) {
    case '/login':
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case '/profile': // <— NOWA TRASA
      return MaterialPageRoute(builder: (_) => const ProfileScreen());
    case '/':
    default:
      return MaterialPageRoute(builder: (_) => const AuthGate());
  }
}
```

> Upewnij się, że w `lib/main.dart` masz import do `routes.dart` i przekazujesz `onGenerateRoute` do `MaterialApp`:
>
> ```dart
> import 'core/routes.dart';
> // ...
> MaterialApp(
>   initialRoute: '/',
>   onGenerateRoute: onGenerateRoute,
> )
> ```

3. **Nawigacja** z dowolnego miejsca w UI:

```dart
Navigator.of(context).pushNamed('/profile');
```

**Tip (opcjonalnie):** możesz dodać stałe na nazwy tras, np. w `lib/core/routes.dart`:

```dart
class AppRoutes {
  static const root = '/';
  static const login = '/login';
  static const profile = '/profile';
}
```

i wtedy:

```dart
Navigator.of(context).pushNamed(AppRoutes.profile);
```

---

## Dodawanie paczek

**Nowy pakiet:**

```bash
flutter pub add <nazwa_pakietu>
```

**Aktualizacja zależności:**

```bash
flutter pub get
```

**Sprawdzenie nowszych wersji (bez łamania constraintów):**

```bash
flutter pub outdated
```

---

## Najczęstsze problemy i szybkie fixy

- **`firebase_options.dart` nie istnieje**
  → Uruchom `flutterfire configure --out=lib/core/firebase_options.dart`

- **iOS: ostrzeżenie Base Configuration od CocoaPods**
  → Dodaj `#include? "Pods/Target Support Files/Pods-Runner/..."` do `ios/Flutter/*.xcconfig` (sekcja wyżej).

- **iOS: minimalny target za niski (np. 11.0)**
  → W `ios/Podfile`: `platform :ios, '13.0'`, potem `pod repo update && pod install`.

- **Build się sypie po zmianach w podach / pluginach**
  → `flutter clean && flutter pub get && cd ios && pod install && cd ..`

- **Aplikacja nie widzi emulatorów**
  → Upewnij się, że **emulatory działają** (`firebase emulators:start`) oraz że `Env.useEmulators = true` i host/porty są poprawne (`env.dart`).
  Na iOS **localhost** w symulatorze działa normalnie (to host Maca).

- **Po `signOut()` zostaje stary ekran**
  → Użyj `Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);` (zrobione w `HomeScreen`).

---
