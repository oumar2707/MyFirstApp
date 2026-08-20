import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user_model.dart';
import '../services/task_storage_service.dart';
import '../services/auth_service.dart';
import '../widgets/task_card.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// ============================================================================
/// FICHIER : lib/screens/home_screen.dart
/// ROLE    : Écran principal (Barre de recherche flottante & Barre inférieure pleine largeur style YouTube)
/// CHARTE  : Indigo #4F46E5, Barre inférieure occupant tout l'espace bas.
/// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Couleur unique de sélection et d'action principale (Deep Indigo #4F46E5)
  static const Color primarySelectionColor = Color(0xFF4F46E5);

  List<Task> _tasks = [];
  bool _isLoading = true;
  UserModel? _currentUser;
  int _selectedTabIndex = 0; // 0: Tâches, 1: Stats, 2: Profil, 3: Paramètres

  // Contrôleur pour la recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // FILTRE PAR DÉFAUT : "Toutes" (Toujours activé au démarrage)
  String _activeFilter = 'Toutes';

  final List<String> _priorities = ['Basse', 'Moyenne', 'Haute'];
  final List<String> _statuses = ['À faire', 'En cours', 'Terminée'];

  @override
  void initState() {
    super.initState();
    _loadInitialUserData();
  }

  Future<void> _loadInitialUserData() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
    await _loadSavedTasks();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Chargement des tâches depuis SharedPreferences pour l'utilisateur actuel
  Future<void> _loadSavedTasks() async {
    List<Task> loadedTasks = await TaskStorageService.loadUserTasks(_currentUser?.id);
    if (mounted) {
      setState(() {
        _tasks = loadedTasks;
        _isLoading = false;
        _activeFilter = 'Toutes';
      });
    }
  }

  /// Enregistrement local des tâches sous la clé de l'utilisateur actuel
  Future<void> _saveCurrentTasks() async {
    await TaskStorageService.saveUserTasks(_currentUser?.id, _tasks);
  }

  /// Méthode d'ajout de tâche avec contrôle de doublon
  bool _addNewTask(String title, String priority, String status) {
    final String cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
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
      return false;
    }

    // Vérification si une tâche avec le même nom existe déjà (insensible à la casse)
    final bool isDuplicate = _tasks.any(
      (t) => t.title.trim().toLowerCase() == cleanTitle.toLowerCase(),
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Une tâche avec ce titre existe déjà !')),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return false;
    }

    final Task newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: cleanTitle,
      priority: priority,
      status: status,
      isCompleted: status == 'Terminée',
    );

    setState(() {
      _tasks.insert(0, newTask);
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

    return true;
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

  /// Modal Bottom Sheet fluide pour créer une nouvelle tâche
  void _showAddTaskBottomSheet() {
    final TextEditingController bottomTitleController = TextEditingController();
    String bottomPriority = 'Moyenne';
    String bottomStatus = 'À faire';
    String? sheetErrorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 25,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poignée supérieure
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // En-tête
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primarySelectionColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_task_rounded,
                              color: primarySelectionColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Nouvelle Tâche',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Champ texte
                      TextField(
                        controller: bottomTitleController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                        onChanged: (_) {
                          if (sheetErrorMessage != null) {
                            setSheetState(() {
                              sheetErrorMessage = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Que devez-vous accomplir ?',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: sheetErrorMessage != null ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                              width: sheetErrorMessage != null ? 2 : 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: sheetErrorMessage != null ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                              width: sheetErrorMessage != null ? 2 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: sheetErrorMessage != null ? const Color(0xFFEF4444) : primarySelectionColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      // Signal d'erreur visuel
                      if (sheetErrorMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sheetErrorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Priorité
                      const Text(
                        'Priorité :',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _priorities.map((p) {
                          final bool isSelected = bottomPriority == p;
                          return ChoiceChip(
                            label: Text(p),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                            selected: isSelected,
                            selectedColor: primarySelectionColor,
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            showCheckmark: false,
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() {
                                  bottomPriority = p;
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
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _statuses.map((s) {
                          final bool isSelected = bottomStatus == s;
                          return ChoiceChip(
                            label: Text(s),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                            selected: isSelected,
                            selectedColor: primarySelectionColor,
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            showCheckmark: false,
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() {
                                  bottomStatus = s;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Bouton d'ajout
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final String rawTitle = bottomTitleController.text.trim();
                            if (rawTitle.isEmpty) {
                              setSheetState(() {
                                sheetErrorMessage = 'Veuillez entrer le titre de la tâche.';
                              });
                              return;
                            }

                            // Vérification d'unicité directement avant d'ajouter
                            final bool isDuplicate = _tasks.any(
                              (t) => t.title.trim().toLowerCase() == rawTitle.toLowerCase(),
                            );

                            if (isDuplicate) {
                              setSheetState(() {
                                sheetErrorMessage = 'Une tâche intitulée "$rawTitle" existe déjà !';
                              });
                              return;
                            }

                            final bool isAdded = _addNewTask(
                              rawTitle,
                              bottomPriority,
                              bottomStatus,
                            );
                            if (isAdded) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 22),
                          label: const Text(
                            'Ajouter la tâche',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primarySelectionColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: primarySelectionColor.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Dialogue de modification
  void _showEditDialog(Task task) {
    final TextEditingController editTitleController = TextEditingController(text: task.title);
    String editPriority = task.priority;
    String editStatus = task.status;
    String? editErrorMessage;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: AlertDialog(
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
                        onChanged: (_) {
                          if (editErrorMessage != null) {
                            setDialogState(() {
                              editErrorMessage = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Titre de la tâche',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: editErrorMessage != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                              width: editErrorMessage != null ? 2 : 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: editErrorMessage != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                              width: editErrorMessage != null ? 2 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: editErrorMessage != null ? const Color(0xFFEF4444) : primarySelectionColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      if (editErrorMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  editErrorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

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
                      if (newTitle.isEmpty) {
                        setDialogState(() {
                          editErrorMessage = 'Veuillez entrer le titre de la tâche.';
                        });
                        return;
                      }

                      // Contrôle de doublon uniquement si le titre a changé
                      if (newTitle.toLowerCase() != task.title.trim().toLowerCase()) {
                        final bool isDuplicate = _tasks.any(
                          (t) => t != task && t.id != task.id && t.title.trim().toLowerCase() == newTitle.toLowerCase(),
                        );

                        if (isDuplicate) {
                          setDialogState(() {
                            editErrorMessage = 'Une autre tâche s\'intitule déjà "$newTitle" !';
                          });
                          return;
                        }
                      }

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
                    },
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
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

  /// Dialogue des détails de la tâche
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

  /// Obtenir la liste filtrée des tâches selon la recherche et le filtre actif ("Toutes" par défaut)
  List<Task> get _filteredTasks {
    return _tasks.where((task) {
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase());

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
    final int todoCount = _tasks.where((t) => t.status == 'À faire' && !t.isCompleted).length;
    final int inProgressCount = _tasks.where((t) => t.status == 'En cours' && !t.isCompleted).length;
    final int completedCount = _tasks.where((t) => t.isCompleted || t.status == 'Terminée').length;
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      // FERMETURE DU CLAVIER AU CLIC EN DEHORS
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),

        // BARRE INFÉRIEURE STYLE YOUTUBE (PLEINE LARGEUR OCCUPANT TOUT L'ESPACE EN BAS)
        bottomNavigationBar: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkTheme ? 0.3 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 1. TÂCHES
                  _buildYouTubeNavItem(
                    icon: _selectedTabIndex == 0 ? Icons.task_alt_rounded : Icons.task_alt_outlined,
                    label: 'Tâches',
                    isSelected: _selectedTabIndex == 0,
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    isDarkTheme: isDarkTheme,
                  ),

                  // 2. STATS
                  _buildYouTubeNavItem(
                    icon: _selectedTabIndex == 1 ? Icons.bar_chart_rounded : Icons.bar_chart_outlined,
                    label: 'Stats',
                    isSelected: _selectedTabIndex == 1,
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    isDarkTheme: isDarkTheme,
                  ),

                  // 3. BOUTON (+) CENTRAL AU BEAU MILIEU (AGRANDI LÉGÈREMENT)
                  Expanded(
                    child: InkWell(
                      onTap: _showAddTaskBottomSheet,
                      splashColor: primarySelectionColor.withValues(alpha: 0.1),
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primarySelectionColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primarySelectionColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. PROFIL
                  _buildYouTubeNavItem(
                    icon: _selectedTabIndex == 2 ? Icons.person_rounded : Icons.person_outline_rounded,
                    label: 'Profil',
                    isSelected: _selectedTabIndex == 2,
                    onTap: () => setState(() => _selectedTabIndex = 2),
                    isDarkTheme: isDarkTheme,
                  ),

                  // 5. PARAMÈTRES
                  _buildYouTubeNavItem(
                    icon: _selectedTabIndex == 3 ? Icons.settings_rounded : Icons.settings_outlined,
                    label: 'Paramètres',
                    isSelected: _selectedTabIndex == 3,
                    onTap: () => setState(() => _selectedTabIndex = 3),
                    isDarkTheme: isDarkTheme,
                  ),
                ],
              ),
            ),
          ),
        ),

        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: primarySelectionColor),
                )
              : IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    // ONGLET 0 : TÂCHES
                    Column(
                      children: [
                        // 1. Header avec Gradient et Statistiques (Bulles cliquables - Filtre unique)
                        _buildModernHeader(totalCount, todoCount, inProgressCount, completedCount),

                        // 2. BARRE DE RECHERCHE FLOTTANTE UNIQUE EN HAUT
                        _buildTopFloatingSearchBar(isDarkTheme),

                        // 3. Liste des Tâches
                        Expanded(
                          child: _filteredTasks.isEmpty
                              ? _buildEmptyState(isDarkTheme)
                              : ListView.builder(
                                  itemCount: _filteredTasks.length,
                                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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

                    // ONGLET 1 : STATS
                    _buildStatsView(isDarkTheme),

                    // ONGLET 2 : PROFIL
                    ProfileScreen(
                      user: _currentUser,
                      tasks: _tasks,
                      onProfileUpdated: _loadCurrentUser,
                    ),

                    // ONGLET 3 : PARAMÈTRES
                    SettingsScreen(
                      onTasksCleared: () {
                        setState(() {
                          _tasks = [];
                        });
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Item interactif style YouTube pour la barre de navigation inférieure
  Widget _buildYouTubeNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkTheme,
  }) {
    final Color activeColor = primarySelectionColor;
    final Color inactiveColor = isDarkTheme ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: primarySelectionColor.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }



  /// En-tête moderne avec gradient et indicateurs statistiques sous forme de bulles cliquables
  Widget _buildModernHeader(int total, int todo, int inProgress, int completed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3730A3), primarySelectionColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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

          // Cards/Bulles de Statistiques désormais 100% Cliquables (Total, À faire, En cours, Terminées)
          Row(
            children: [
              _buildStatChip(
                label: 'Total',
                value: total.toString(),
                isSelected: _activeFilter == 'Toutes',
                onTap: () => setState(() => _activeFilter = 'Toutes'),
              ),
              const SizedBox(width: 6),
              _buildStatChip(
                label: 'À faire',
                value: todo.toString(),
                isSelected: _activeFilter == 'À faire',
                onTap: () => setState(() => _activeFilter = 'À faire'),
              ),
              const SizedBox(width: 6),
              _buildStatChip(
                label: 'En cours',
                value: inProgress.toString(),
                isSelected: _activeFilter == 'En cours',
                onTap: () => setState(() => _activeFilter = 'En cours'),
              ),
              const SizedBox(width: 6),
              _buildStatChip(
                label: 'Terminées',
                value: completed.toString(),
                isSelected: _activeFilter == 'Terminée',
                onTap: () => setState(() => _activeFilter = 'Terminée'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bulle de statistique cliquable avec illumination lors de la sélection
  Widget _buildStatChip({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isSelected ? primarySelectionColor : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primarySelectionColor : Colors.white.withValues(alpha: 0.95),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// BARRE DE RECHERCHE FLOTTANTE UNIQUE EN HAUT
  Widget _buildTopFloatingSearchBar(bool isDarkTheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkTheme ? const Color(0xFF334155) : primarySelectionColor.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primarySelectionColor.withValues(alpha: isDarkTheme ? 0.05 : 0.15),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkTheme ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDarkTheme ? Colors.white : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher une tâche...',
          hintStyle: TextStyle(color: isDarkTheme ? Colors.white54 : const Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: primarySelectionColor, size: 24),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 20, color: isDarkTheme ? Colors.white54 : const Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// État vide
  Widget _buildEmptyState(bool isDarkTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primarySelectionColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 54,
              color: primarySelectionColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Aucune tâche trouvée',
            style: TextStyle(
              fontSize: 16,
              color: isDarkTheme ? Colors.white70 : const Color(0xFF334155),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajoutez-en une via le bouton central ci-dessous.',
            style: TextStyle(fontSize: 13, color: isDarkTheme ? Colors.white54 : const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  /// Vue des Statistiques et de la Progression (Onglet 1)
  Widget _buildStatsView(bool isDarkTheme) {
    final int total = _tasks.length;
    final int completed = _tasks.where((t) => t.isCompleted || t.status == 'Terminée').length;
    final int inProgress = _tasks.where((t) => t.status == 'En cours' && !t.isCompleted).length;
    final int todo = _tasks.where((t) => t.status == 'À faire' && !t.isCompleted).length;
    final double completionPercentage = total > 0 ? (completed / total) : 0.0;

    final int highPriority = _tasks.where((t) => t.priority == 'Haute').length;
    final int mediumPriority = _tasks.where((t) => t.priority == 'Moyenne').length;
    final int lowPriority = _tasks.where((t) => t.priority == 'Basse').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la page Statistiques
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: primarySelectionColor, size: 28),
              const SizedBox(width: 10),
              Text(
                'Statistiques & Progression',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkTheme ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Carte de progression globale
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3730A3), primarySelectionColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primarySelectionColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Taux d\'accomplissement',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${(completionPercentage * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: completionPercentage,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '$completed sur $total tâche(s) terminée(s)',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Grille des statuts
          Text(
            'Répartition par Statut',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkTheme ? Colors.white70 : const Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('À faire', todo.toString(), Icons.pending_actions_rounded, const Color(0xFFF59E0B), isDarkTheme),
              const SizedBox(width: 12),
              _buildStatCard('En cours', inProgress.toString(), Icons.sync_rounded, const Color(0xFF3B82F6), isDarkTheme),
              const SizedBox(width: 12),
              _buildStatCard('Terminées', completed.toString(), Icons.task_alt_rounded, const Color(0xFF10B981), isDarkTheme),
            ],
          ),
          const SizedBox(height: 24),

          // Priorités
          Text(
            'Répartition par Priorité',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkTheme ? Colors.white70 : const Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildPriorityRow('Haute', highPriority, total, const Color(0xFFEF4444), isDarkTheme),
                const Divider(height: 20),
                _buildPriorityRow('Moyenne', mediumPriority, total, const Color(0xFFF59E0B), isDarkTheme),
                const Divider(height: 20),
                _buildPriorityRow('Basse', lowPriority, total, const Color(0xFF10B981), isDarkTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color, bool isDarkTheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkTheme ? Colors.white : const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: isDarkTheme ? Colors.white60 : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityRow(String label, int count, int total, Color color, bool isDarkTheme) {
    final double pct = total > 0 ? (count / total) : 0.0;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDarkTheme ? Colors.white : const Color(0xFF1E293B))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: isDarkTheme ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkTheme ? Colors.white : const Color(0xFF1E293B))),
      ],
    );
  }
}
