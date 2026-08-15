# 📋 To-Do Liste

Une application mobile moderne et performante pour gérer vos tâches quotidiennes. Construite avec **Flutter**, elle offre une expérience utilisateur fluide avec persistance des données locale.

---

## 📑 Table des matières

- [Fonctionnalités](#-fonctionnalités)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Structure du projet](#-structure-du-projet)
- [Utilisation](#-utilisation)
- [Dépendances](#-dépendances)
- [Architecture](#-architecture)
- [Contribution](#-contribution)
- [License](#-license)

---

## ✨ Fonctionnalités

- ✅ **Création de tâches** - Ajoutez facilement de nouvelles tâches
- ✏️ **Édition** - Modifiez vos tâches existantes
- 🗑️ **Suppression** - Supprimez les tâches complétées
- 💾 **Persistance locale** - Vos tâches sont sauvegardées automatiquement
- 📱 **Interface intuitive** - Design moderne et ergonomique
- ⚡ **Performance optimisée** - Application légère et réactive

---

## 🔧 Prérequis

| Composant | Version | Lien |
|-----------|---------|------|
| **Flutter SDK** | 3.12.2+ | [flutter.dev](https://flutter.dev) |
| **Dart SDK** | Inclus avec Flutter | - |
| **Android SDK** | API 21+ | [Android Studio](https://developer.android.com/studio) |
| **Java Development Kit** | 17+ | [openjdk.java.net](https://openjdk.java.net/) |

---

## 📦 Installation

### 1. Cloner le repository

```bash
git clone https://github.com/your-username/to_do_liste.git
cd to_do_liste
```

### 2. Installer les dépendances Flutter

```bash
flutter pub get
```

### 3. Vérifier l'installation

```bash
flutter doctor
```

Assurez-vous que tous les éléments sont cochés ✓.

### 4. Lancer l'application

**Sur un appareil Android/Émulateur :**
```bash
flutter run
```

**Sur la plateforme spécifique :**
```bash
# Android
flutter run -d android

# Windows (si configuré)
flutter run -d windows
```

---

## 📂 Structure du projet

```
to_do_liste/
├── lib/
│   ├── main.dart                 # Point d'entrée principal
│   ├── models/
│   │   └── task.dart            # Modèle de données (Tâche)
│   ├── screens/
│   │   └── home_screen.dart     # Écran principal
│   ├── services/
│   │   └── task_storage_service.dart  # Service de persistance
│   └── widgets/
│       └── task_card.dart       # Composant personnalisé
├── test/
│   └── widget_test.dart         # Tests des widgets
├── pubspec.yaml                 # Configuration des dépendances
├── analysis_options.yaml        # Configuration Linter
└── README.md                    # Documentation
```

---

## 🚀 Utilisation

### Lancer l'app en mode debug

```bash
flutter run
```

### Build APK pour Android

```bash
flutter build apk --release
```

### Build pour production

```bash
flutter build apk --release
flutter build appbundle --release  # Pour Google Play Store
```

---

## 📚 Dépendances

| Paquet | Version | Utilité |
|--------|---------|---------|
| `flutter` | SDK | Framework UI |
| `cupertino_icons` | ^1.0.8 | Icônes iOS/Cupertino |
| `shared_preferences` | ^2.3.2 | Stockage local persistant |

**Dev Dependencies :**
- `flutter_test` - Framework de test Flutter
- `flutter_lints` - Linter recommandé

---

## 🏗️ Architecture

L'application suit une architecture **modulaire et scalable** :

```
Models (Données)
    ↓
Services (Logique métier)
    ↓
Screens (Présentation)
    ↓
Widgets (Composants UI)
```

### Couches principales

- **Models** - Définissent les structures de données
- **Services** - Gèrent la persistance et la logique métier
- **Screens** - Pages principales de l'application
- **Widgets** - Composants réutilisables

---

## 🤝 Contribution

Les contributions sont bienvenues ! Pour contribuer :

1. **Fork** le repository
2. Créez une **branche feature** (`git checkout -b feature/AmazingFeature`)
3. **Commit** vos changements (`git commit -m 'Add AmazingFeature'`)
4. **Push** vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une **Pull Request**

### Standards de code

- Respectez les conventions Dart/Flutter
- Utilisez `flutter analyze` pour vérifier le linting
- Formatez avec `flutter format`

---

## 📄 License

Ce projet est sous License MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 🔗 Ressources utiles

- [Documentation Flutter](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Best Practices](https://flutter.dev/docs/reference/best-practices)
- [Pub.dev - Flutter Packages](https://pub.dev/)

---

## 📧 Support

Pour toute question ou problème, n'hésitez pas à ouvrir une **issue** ou contacter le développeur.

---

**Made with ❤️ using Flutter**
