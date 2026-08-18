import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'auth_service.dart';

// ============================================================================
// FICHIER : lib/services/task_storage_service.dart
// ROLE    : Gère la sauvegarde et le chargement des tâches ISOLÉES PAR UTILISATEUR.
// EXPLICATION DU FONCTIONNEMENT :
// Chaque utilisateur possède sa propre clé SharedPreferences `user_tasks_{userId}`.
// Ainsi, la création d'un nouveau compte démarre toujours avec une liste vide.
// ============================================================================

class TaskStorageService {
  /// Obtenir la clé de stockage spécifique à un utilisateur
  static String _getUserStorageKey(String? userId) {
    if (userId == null || userId.trim().isEmpty) {
      return 'guest_todolist_tasks';
    }
    return 'user_tasks_${userId.trim()}';
  }

  /// Sauvegarder les tâches pour un utilisateur spécifique
  static Future<void> saveUserTasks(String? userId, List<Task> tasks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = _getUserStorageKey(userId);

    List<String> jsonList = tasks.map((task) {
      return jsonEncode(task.toJson());
    }).toList();

    await prefs.setStringList(key, jsonList);
  }

  /// Charger les tâches spécifiques à un utilisateur
  static Future<List<Task>> loadUserTasks(String? userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final String key = _getUserStorageKey(userId);

    List<String>? jsonList = prefs.getStringList(key);

    if (jsonList == null || jsonList.isEmpty) {
      return [];
    }

    return jsonList.map((jsonString) {
      Map<String, dynamic> map = jsonDecode(jsonString) as Map<String, dynamic>;
      return Task.fromJson(map);
    }).toList();
  }

  /// Sauvegarder les tâches pour l'utilisateur actuellement connecté
  static Future<void> saveTasks(List<Task> tasks) async {
    final currentUser = await AuthService.getCurrentUser();
    await saveUserTasks(currentUser?.id, tasks);
  }

  /// Charger les tâches pour l'utilisateur actuellement connecté
  static Future<List<Task>> loadTasks() async {
    final currentUser = await AuthService.getCurrentUser();
    return await loadUserTasks(currentUser?.id);
  }
}
