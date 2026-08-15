// ============================================================================
// FICHIER : lib/models/task.dart
// ROLE    : Représente le modèle de données d'une Tâche (Task).
// EXPLICATION :
// En Flutter/Dart, une classe Modèle permet de structurer les informations.
// Pour sauvegarder une tâche dans les préférences du téléphone (SharedPreferences),
// on ne peut pas enregistrer directement un objet Dart. On doit le transformer
// en un dictionnaire (Map), puis en texte (JSON). Inversement, lors de la lecture,
// on transforme le texte JSON en Map, puis en objet Task.
// ============================================================================


class Task {
  // Propriétés d'une tâche
  final String id;          // Identifiant unique (ex: horodatage)
  String title;             // Titre / Description de la tâche
  String priority;          // Priorité : 'Basse', 'Moyenne', 'Haute'
  String status;            // Statut : 'À faire', 'En cours', 'Terminée'
  bool isCompleted;         // État de coché (true = terminée, false = non terminée)

  // Constructeur principal pour créer une tâche
  Task({
    required this.id,
    required this.title,
    this.priority = 'Moyenne',
    this.status = 'À faire',
    this.isCompleted = false,
  });

  /// --------------------------------------------------------------------------
  /// METHODE : toJson()
  /// ROLE    : Convertit l'objet Task en un Map (dictionnaire clé/valeur).
  /// PORTEE  : Étape 1 pour la sauvegarde. Le Map sera ensuite converti en JSON.
  /// --------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,                     // Clé 'id' associée à la valeur de id
      'title': title,               // Clé 'title' associée à la valeur de title
      'priority': priority,         // Clé 'priority' associée à la valeur de priority
      'status': status,             // Clé 'status' associée à la valeur de status
      'isCompleted': isCompleted,   // Clé 'isCompleted' (true/false)
    };
  }

  /// --------------------------------------------------------------------------
  /// FACTORY CONSTRUCTOR : Task.fromJson(...)
  /// ROLE    : Reconstruit une tâche à partir d'un Map décodé depuis du JSON.
  /// PORTEE  : Étape 2 pour la lecture/chargement des données sauvegardées.
  /// --------------------------------------------------------------------------
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      priority: json['priority'] as String? ?? 'Moyenne',
      status: json['status'] as String? ?? 'À faire',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// Méthode utilitaire pour créer une copie modifiée d'une tâche existante
  Task copyWith({
    String? id,
    String? title,
    String? priority,
    String? status,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
