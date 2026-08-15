import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

/// ============================================================================
/// FICHIER : lib/main.dart
/// APPLICATION : To-Do Liste Mobile Android (Flutter / Dart)
/// ROLE : Point d'entrée principal de l'application.
/// EXPLICATION DEBUTANT :
/// - `main()` est la première fonction exécutée au lancement de l'application sur Android.
/// - `runApp(const MyApp())` démarre l'arborescence des widgets Flutter.
/// - `MaterialApp` définit le titre, le thème visuel (couleurs, polices) et la première page (`HomeScreen`).
/// - Une couleur de sélection unique (Deep Indigo #4F46E5) est configurée pour garantir une unité visuelle parfaite.
/// ============================================================================

void main() {
  // Initialisation obligatoire des liaisons de widgets Flutter avant le lancement
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Couleur de sélection unifiée pour tous les filtres, puces et boutons actifs
    const Color primaryColor = Color(0xFF4F46E5);

    return MaterialApp(
      // Titre de l'application Android
      title: 'To-Do Liste',

      // Masque la bannière "DEBUG" en haut à droite
      debugShowCheckedModeBanner: false,

      // Thème Material 3 moderne avec couleur unique de sélection
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: primaryColor,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          selectedColor: primaryColor,
          secondarySelectedColor: primaryColor,
          backgroundColor: const Color(0xFFF1F5F9),
          side: BorderSide.none,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),

      // Page d'accueil principale de l'application
      home: const HomeScreen(),
    );
  }
}



