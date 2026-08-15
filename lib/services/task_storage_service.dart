import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

// ============================================================================
// FICHIER : lib/services/task_storage_service.dart
// ROLE    : Gère la sauvegarde et le chargement des tâches sur le téléphone.
// EXPLICATION DU FONCTIONNEMENT DE LA PERSISTANCE :
// 
// 1. SharedPreferences ne peut stocker directement que des types simples :
//    (int, double, bool, String, List<String>).
// 2. Comme nos tâches sont des objets complexes (Task), nous les convertissons
//    en texte au format JSON (JavaScript Object Notation).
// 
// PROCESSUS DE SAUVEGARDE :
//    Objet Task  --->  Map<String, dynamic> (toJson)  --->  Texte JSON (jsonEncode)  --->  SharedPreferences
// 
// PROCESSUS DE LECTURE :
//    SharedPreferences  --->  Texte JSON  --->  Map<String, dynamic> (jsonDecode)  --->  Objet Task (Task.fromJson)
// ============================================================================


class TaskStorageService {
  // Clé unique utilisée dans SharedPreferences pour identifier notre liste de tâches
  static const String _storageKey = 'my_todolist_tasks';

  /// --------------------------------------------------------------------------
  /// METHODE : saveTasks
  /// ROLE    : Sauvegarde la liste de tâches courante sur le téléphone.
  /// --------------------------------------------------------------------------
  static Future<void> saveTasks(List<Task> tasks) async {
    // 1. Obtenir l'instance de SharedPreferences (accès au stockage local de l'appareil)
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 2. Transformer chaque objet Task en une chaîne de texte au format JSON
    List<String> jsonList = tasks.map((task) {
      // a) Convertir la Task en Dictionnaire/Map
      Map<String, dynamic> map = task.toJson();
      // b) Encoder le Map en texte JSON avec jsonEncode()
      return jsonEncode(map);
    }).toList();

    // 3. Sauvegarder la liste de chaînes de caractères sous la clé '_storageKey'
    await prefs.setStringList(_storageKey, jsonList);
  }

  /// --------------------------------------------------------------------------
  /// METHODE : loadTasks
  /// ROLE    : Charge et restitue la liste des tâches sauvegardées.
  /// --------------------------------------------------------------------------
  static Future<List<Task>> loadTasks() async {
    // 1. Obtenir l'instance de SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 2. Récupérer la liste de chaînes de texte sauvegardée
    List<String>? jsonList = prefs.getStringList(_storageKey);

    // 3. Si aucune donnée n'a été enregistrée auparavant, on renvoie une liste vide []
    if (jsonList == null || jsonList.isEmpty) {
      return [];
    }

    // 4. Transformer chaque texte JSON en objet Task
    List<Task> tasks = jsonList.map((jsonString) {
      // a) Décoder le texte JSON pour obtenir un Map avec jsonDecode()
      Map<String, dynamic> map = jsonDecode(jsonString) as Map<String, dynamic>;
      // b) Reconstruire l'objet Task à partir du Map avec Task.fromJson()
      return Task.fromJson(map);
    }).toList();

    // 5. Renvoyer la liste d'objets Task prêts à être affichés
    return tasks;
  }
}
