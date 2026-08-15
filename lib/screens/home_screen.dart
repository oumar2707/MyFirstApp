import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_storage_service.dart';
import '../widgets/task_card.dart';

/// ============================================================================
/// FICHIER : lib/screens/home_screen.dart
/// ROLE    : Écran principal de la To-Do Liste (Design Material 3 Haut de Gamme)
/// CHARTE  : Couleur unique de sélection (Deep Indigo #4F46E5) pour tous les éléments et filtres.
/// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Couleur unique de sélection pour TOUS les filtres et éléments actifs
  static const Color primarySelectionColor = Color(0xFF4F46E5);

  List<Task> _tasks = [];
  bool _isLoading = true;

  // Contrôleur pour le formulaire d'ajout
  final TextEditingController _titleController = TextEditingController();

  // Contrôleur pour la recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Options du formulaire
  String _selectedPriority = 'Moyenne';
  String _selectedStatus = 'À faire';

  // Filtre sélectionné de la liste ('Toutes', 'À faire', 'En cours', 'Terminée')
  String _activeFilter = 'Toutes';

  final List<String> _priorities = ['Basse', 'Moyenne', 'Haute'];
  final List<String> _statuses = ['À faire', 'En cours', 'Terminée'];
  final List<String> _filterTabs = ['Toutes', 'À faire', 'En cours', 'Terminée'];

  @override
  void initState() {
    super.initState();
    _loadSavedTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Chargement des tâches depuis SharedPreferences
  Future<void> _loadSavedTasks() async {
    List<Task> loadedTasks = await TaskStorageService.loadTasks();
    setState(() {
      _tasks = loadedTasks;
      _isLoading = false;
    });
  }

  /// Enregistrement local des tâches
  Future<void> _saveCurrentTasks() async {
    await TaskStorageService.saveTasks(_tasks);
  }

  /// Ajouter une nouvelle tâche
  void _addTask() {
    final String titleText = _titleController.text.trim();

    if (titleText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Veuillez entrer le titre de la tâche.'),
            ],
          ),
          backgroundColor: primarySelectionColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final Task newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleText,
      priority: _selectedPriority,
      status: _selectedStatus,
      isCompleted: _selectedStatus == 'Terminée',
    );

    setState(() {
      _tasks.insert(0, newTask);
      _titleController.clear();
      _selectedPriority = 'Moyenne';
      _selectedStatus = 'À faire';
    });

    _saveCurrentTasks();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Tâche ajoutée avec succès !'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: primarySelectionColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Basculer l'état terminé
  void _toggleTaskCompleted(Task task, bool? isChecked) {
    final bool newIsCompleted = isChecked ?? false;

    setState(() {
      task.isCompleted = newIsCompleted;
      if (newIsCompleted) {
        task.status = 'Terminée';
      } else if (task.status == 'Terminée') {
        task.status = 'À faire';
      }
    });

    _saveCurrentTasks();
  }

  /// Dialogue de modification
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
                  Icon(Icons.edit_note_rounded, color: primarySelectionColor, size: 26),
                  SizedBox(width: 10),
                  Text('Modifier la tâche', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primarySelectionColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Priorité (Couleur unifiée de sélection)
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
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                          selected: isSelected,
                          selectedColor: primarySelectionColor,
                          backgroundColor: const Color(0xFFF1F5F9),
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

                    // Statut (Couleur unifiée de sélection)
                    const Text(
                      'Statut :',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: _statuses.map((s) {
                        final bool isSelected = editStatus == s;
                        return ChoiceChip(
                          label: Text(s),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                          selected: isSelected,
                          selectedColor: primarySelectionColor,
                          backgroundColor: const Color(0xFFF1F5F9),
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
                    backgroundColor: primarySelectionColor,
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
                      _saveCurrentTasks();
                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Tâche modifiée avec succès !'),
                          backgroundColor: primarySelectionColor,
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

  /// Dialogue de confirmation de suppression
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
              Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 26),
              SizedBox(width: 10),
              Text('Supprimer la tâche'),
            ],
          ),
          content: Text('Voulez-vous vraiment supprimer "${task.title}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  _tasks.removeWhere((item) => item.id == task.id);
                });
                _saveCurrentTasks();
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Tâche supprimée !'),
                    backgroundColor: const Color(0xFFEF4444),
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

  /// Dialogue des détails de la tâche (Lire)
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
              const Icon(Icons.task_alt_rounded, color: primarySelectionColor),
              const SizedBox(width: 10),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.flag_rounded, size: 18, color: primarySelectionColor),
                  const SizedBox(width: 10),
                  Text('Priorité : ${task.priority}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, size: 18, color: primarySelectionColor),
                  const SizedBox(width: 10),
                  Text('Statut : ${task.status}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primarySelectionColor,
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

  /// Obtenir la liste filtrée des tâches selon la recherche et le filtre actif
  List<Task> get _filteredTasks {
    return _tasks.where((task) {
      // Filtrer par recherche
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filtrer par onglet de statut
      bool matchesFilter = true;
      if (_activeFilter == 'À faire') {
        matchesFilter = task.status == 'À faire' && !task.isCompleted;
      } else if (_activeFilter == 'En cours') {
        matchesFilter = task.status == 'En cours' && !task.isCompleted;
      } else if (_activeFilter == 'Terminée') {
        matchesFilter = task.status == 'Terminée' || task.isCompleted;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = _tasks.length;
    final int completedCount = _tasks.where((t) => t.isCompleted || t.status == 'Terminée').length;
    final int inProgressCount = totalCount - completedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primarySelectionColor),
              )
            : Column(
                children: [
                  // 1. Header Moderne avec Gradient et Statistiques
                  _buildModernHeader(totalCount, inProgressCount, completedCount),

                  // 2. Formulaire d'ajout de tâche
                  _buildAddTaskForm(),

                  // 3. Barre de Recherche & Barre de Filtres à COULEUR UNIQUE DE SÉLECTION
                  _buildFilterBar(),

                  // 4. Liste des Tâches
                  Expanded(
                    child: _filteredTasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _filteredTasks.length,
                            padding: const EdgeInsets.only(top: 8, bottom: 20),
                            itemBuilder: (context, index) {
                              final task = _filteredTasks[index];
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
      ),
    );
  }

  /// En-tête moderne avec gradient et indicateurs statistiques
  Widget _buildModernHeader(int total, int inProgress, int completed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3730A3), primarySelectionColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Mes Tâches',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cards de Statistiques
          Row(
            children: [
              _buildStatChip('Total', total.toString(), Colors.white.withValues(alpha: 0.2)),
              const SizedBox(width: 10),
              _buildStatChip('En cours', inProgress.toString(), Colors.white.withValues(alpha: 0.2)),
              const SizedBox(width: 10),
              _buildStatChip('Terminées', completed.toString(), Colors.white.withValues(alpha: 0.25)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formulaire d'ajout de tâche épuré
  Widget _buildAddTaskForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saisie texte + Bouton Ajouter
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Que devez-vous faire ?',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.add_task_rounded, color: primarySelectionColor, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primarySelectionColor, width: 1.8),
                    ),
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _addTask,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primarySelectionColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Options de sélection (Priorité & Statut) - Couleur de sélection unique Indigo
          Row(
            children: [
              // Priorité
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    const Text(
                      'Priorité: ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    ..._priorities.map((p) {
                      final isSelected = _selectedPriority == p;
                      return ChoiceChip(
                        label: Text(p),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                        selected: isSelected,
                        selectedColor: primarySelectionColor,
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPriority = p;
                            });
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Barre de Recherche et Onglets de Filtres avec une SEULE COULEUR DE SÉLECTION (Primary Indigo)
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // Champ de recherche
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher une tâche...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primarySelectionColor, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Onglets de filtrage à couleur unique de sélection (primarySelectionColor)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterTabs.map((tab) {
                final isSelected = _activeFilter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(tab),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                    selected: isSelected,
                    selectedColor: primarySelectionColor, // SEULE COULEUR POUR LES ÉLÉMENTS SÉLECTIONNÉS
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? primarySelectionColor : const Color(0xFFE2E8F0),
                    ),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _activeFilter = tab;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primarySelectionColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 54,
              color: primarySelectionColor,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucune tâche trouvée',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF334155),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ajoutez-en une ci-dessus ou modifiez vos filtres.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

