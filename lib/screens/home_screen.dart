import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_storage_service.dart';
import '../widgets/task_card.dart';

/// ============================================================================
/// FICHIER : lib/screens/home_screen.dart
/// ROLE    : Écran principal de l'application To-Do List.
/// EXPLICATION :
/// Ce composant gère l'affichage des tâches, la saisie utilisateur, la modale de
/// modification, la persistance locale via `TaskStorageService` et applique une
/// charte graphique moderne basée STRICTEMENT sur 2 COULEURS :
/// - Indigo (#3F51B5) : Couleur principale (Header, Bouton Ajouter, Priorités)
/// - Teal (#009688)   : Couleur secondaire (Statuts, Valider, Succès)
/// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Liste locale des tâches affichées à l'écran
  List<Task> _tasks = [];

  // Variable pour savoir si l'application est en train de charger les données au démarrage
  bool _isLoading = true;

  // Contrôleur pour lire le texte saisi dans le champ de titre
  final TextEditingController _titleController = TextEditingController();

  // Valeurs sélectionnées par défaut pour le formulaire d'ajout
  String _selectedPriority = 'Moyenne';
  String _selectedStatus = 'À faire';

  // Listes des options disponibles
  final List<String> _priorities = ['Basse', 'Moyenne', 'Haute'];
  final List<String> _statuses = ['À faire', 'En cours', 'Terminée'];

  @override
  void initState() {
    super.initState();
    // Au démarrage de l'écran, on charge automatiquement les tâches sauvegardées sur le téléphone
    _loadSavedTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// --------------------------------------------------------------------------
  /// LECTURE INITIALE : Charge les tâches depuis SharedPreferences
  /// --------------------------------------------------------------------------
  Future<void> _loadSavedTasks() async {
    // 1. Récupérer les tâches via le service
    List<Task> loadedTasks = await TaskStorageService.loadTasks();

    // 2. Mettre à jour l'état de l'application et désactiver l'indicateur de chargement
    setState(() {
      _tasks = loadedTasks;
      _isLoading = false;
    });
  }

  /// --------------------------------------------------------------------------
  /// SAUVEGARDE AUTOMATIQUE : Utilitaire pour enregistrer la liste courante
  /// --------------------------------------------------------------------------
  Future<void> _saveCurrentTasks() async {
    await TaskStorageService.saveTasks(_tasks);
  }

  /// --------------------------------------------------------------------------
  /// OPERATEUR C : Créer une tâche
  /// --------------------------------------------------------------------------
  void _addTask() {
    final String titleText = _titleController.text.trim();

    // Validation simple : le titre ne doit pas être vide
    if (titleText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Veuillez saisir un titre pour la tâche.'),
            ],
          ),
          backgroundColor: Colors.indigo.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Création de la nouvelle tâche
    final Task newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // ID unique basé sur la date/heure
      title: titleText,
      priority: _selectedPriority,
      status: _selectedStatus,
      isCompleted: _selectedStatus == 'Terminée',
    );

    // Mettre à jour la liste dans l'interface et sauvegarder
    setState(() {
      _tasks.insert(0, newTask); // Ajouter en haut de la liste
      _titleController.clear();  // Réinitialiser le champ texte
      _selectedPriority = 'Moyenne'; // Réinitialiser la priorité
      _selectedStatus = 'À faire';  // Réinitialiser le statut
    });

    _saveCurrentTasks(); // Sauvegarde locale

    // Notification utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Tâche ajoutée et sauvegardée !'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// OPERATEUR U : Basculer l'état de la case à cocher (Terminée / À faire)
  /// --------------------------------------------------------------------------
  void _toggleTaskCompleted(Task task, bool? isChecked) {
    final bool newIsCompleted = isChecked ?? false;

    setState(() {
      task.isCompleted = newIsCompleted;
      // Si la case est cochée, on met aussi à jour le statut en 'Terminée'
      if (newIsCompleted) {
        task.status = 'Terminée';
      } else if (task.status == 'Terminée') {
        task.status = 'À faire';
      }
    });

    _saveCurrentTasks(); // Sauvegarde automatique
  }

  /// --------------------------------------------------------------------------
  /// OPERATEUR U : Modifier une tâche via une boîte de dialogue pré-remplie
  /// --------------------------------------------------------------------------
  void _showEditDialog(Task task) {
    final TextEditingController editTitleController =
        TextEditingController(text: task.title);
    String editPriority = task.priority;
    String editStatus = task.status;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Colors.indigo, size: 28),
                  SizedBox(width: 8),
                  Text('Modifier la tâche', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    TextField(
                      controller: editTitleController,
                      decoration: InputDecoration(
                        labelText: 'Titre de la tâche',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Priorité
                    const Text(
                      'Priorité :',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: _priorities.map((p) {
                        final bool isSelected = editPriority == p;
                        return ChoiceChip(
                          label: Text(p),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.indigo.shade900,
                          ),
                          selected: isSelected,
                          selectedColor: Colors.indigo,
                          backgroundColor: Colors.indigo.shade50,
                          side: BorderSide.none,
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                editPriority = p;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Statut
                    const Text(
                      'Statut :',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: _statuses.map((s) {
                        final bool isSelected = editStatus == s;
                        IconData statusIcon;
                        if (s == 'Terminée') {
                          statusIcon = Icons.check_circle_outline_rounded;
                        } else if (s == 'En cours') {
                          statusIcon = Icons.sync_rounded;
                        } else {
                          statusIcon = Icons.radio_button_unchecked_rounded;
                        }

                        return ChoiceChip(
                          avatar: Icon(
                            statusIcon,
                            size: 14,
                            color: isSelected ? Colors.white : Colors.teal.shade700,
                          ),
                          label: Text(s),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.teal.shade900,
                          ),
                          selected: isSelected,
                          selectedColor: Colors.teal,
                          backgroundColor: Colors.teal.shade50,
                          side: BorderSide.none,
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                editStatus = s;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final String newTitle = editTitleController.text.trim();
                    if (newTitle.isNotEmpty) {
                      setState(() {
                        task.title = newTitle;
                        task.priority = editPriority;
                        task.status = editStatus;
                        task.isCompleted = editStatus == 'Terminée';
                      });
                      _saveCurrentTasks(); // Sauvegarde automatique
                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Tâche modifiée avec succès !'),
                          backgroundColor: Colors.teal,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// --------------------------------------------------------------------------
  /// OPERATEUR D : Supprimer une tâche avec confirmation
  /// --------------------------------------------------------------------------
  void _confirmDeleteTask(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.indigo, size: 26),
              SizedBox(width: 8),
              Text('Confirmation'),
            ],
          ),
          content: Text('Voulez-vous vraiment supprimer la tâche "${task.title}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  _tasks.removeWhere((item) => item.id == task.id);
                });
                _saveCurrentTasks(); // Sauvegarde automatique
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Tâche supprimée !'),
                    backgroundColor: Colors.indigo.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  /// --------------------------------------------------------------------------
  /// OPERATEUR R : Afficher les détails d'une tâche
  /// --------------------------------------------------------------------------
  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.flag_rounded, size: 18, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text('Priorité : ${task.priority}', style: const TextStyle(fontSize: 15)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.bubble_chart_outlined, size: 18, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text('Statut : ${task.status}', style: const TextStyle(fontSize: 15)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    task.isCompleted ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                    size: 18,
                    color: task.isCompleted ? Colors.teal : Colors.indigo,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'État : ${task.isCompleted ? 'Terminée ✔' : 'En cours ⏳'}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Mes Tâches', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.indigo),
                  SizedBox(height: 12),
                  Text('Chargement des tâches sauvegardées...'),
                ],
              ),
            )
          : Column(
              children: [
                // 1. Formulaire d'ajout de tâche (en haut avec bouton "Ajouter" placé tout en face)
                _buildAddTaskForm(),

                const SizedBox(height: 4),

                // 2. Liste des tâches (en dessous du formulaire)
                Expanded(
                  child: _tasks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _tasks.length,
                          padding: const EdgeInsets.only(top: 4, bottom: 16),
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return TaskCard(
                              task: task,
                              onToggleCompleted: (value) => _toggleTaskCompleted(task, value),
                              onView: () => _showTaskDetails(task),
                              onEdit: () => _showEditDialog(task),
                              onDelete: () => _confirmDeleteTask(task),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// Widget construisant le formulaire d'ajout en haut de l'écran avec bouton "Ajouter" en face de la saisie
  Widget _buildAddTaskForm() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row avec le champ de texte et le bouton "Ajouter" placé tout en face
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Que devez-vous faire ?',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.add_task_rounded, color: Colors.indigo),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _addTask,
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Ajouter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Options de personnalisation : Priorité (Thème Indigo) & Statut (Thème Teal)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              // Sélection Priorité (Thème Indigo)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Priorité : ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                  ),
                  Wrap(
                    spacing: 4,
                    children: _priorities.map((p) {
                      final isSelected = _selectedPriority == p;
                      return ChoiceChip(
                        label: Text(p),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.indigo.shade900,
                        ),
                        selected: isSelected,
                        selectedColor: Colors.indigo,
                        backgroundColor: Colors.indigo.shade50,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPriority = p;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Sélection Statut (Thème Teal avec icônes)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Statut : ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                  ),
                  Wrap(
                    spacing: 4,
                    children: _statuses.map((s) {
                      final isSelected = _selectedStatus == s;
                      IconData statusIcon;
                      if (s == 'Terminée') {
                        statusIcon = Icons.check_circle_outline_rounded;
                      } else if (s == 'En cours') {
                        statusIcon = Icons.sync_rounded;
                      } else {
                        statusIcon = Icons.radio_button_unchecked_rounded;
                      }

                      return ChoiceChip(
                        avatar: Icon(
                          statusIcon,
                          size: 14,
                          color: isSelected ? Colors.white : Colors.teal.shade700,
                        ),
                        label: Text(s),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.teal.shade900,
                        ),
                        selected: isSelected,
                        selectedColor: Colors.teal,
                        backgroundColor: Colors.teal.shade50,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedStatus = s;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget affiché lorsque la liste de tâches est vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, size: 64, color: Colors.indigo.shade200),
          const SizedBox(height: 12),
          const Text(
            'Aucune tâche enregistrée !',
            style: TextStyle(fontSize: 17, color: Color(0xFF475569), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ajoutez-en une via la barre ci-dessus.',
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
