import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

/// ============================================================================
/// FICHIER : lib/main.dart
/// ROLE    : Point d'entrée principal de l'application Flutter.
/// EXPLICATION :
/// La fonction `main()` initialise l'application et lance `runApp()`.
/// Le widget `MyApp` configure le thème Material 3 avec une charte à 2 couleurs
/// (Indigo et Teal) et définit `HomeScreen` comme page d'accueil principale.
/// ============================================================================

void main() {
  // S'assure que la liaison des widgets Flutter est bien initialisée
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Titre de l'application
      title: 'To-Do Liste',

      // Masquer la bannière "DEBUG" en haut à droite
      debugShowCheckedModeBanner: false,

      // Configuration du Thème Material 3 - Charte graphique à 2 Couleurs (Indigo & Teal)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          secondary: Colors.teal,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
      ),

      // Écran de démarrage de l'application
      home: const HomeScreen(),
    );
  }
}

