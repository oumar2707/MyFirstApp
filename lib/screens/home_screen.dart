import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_storage_service.dart';
import '../widgets/task_card.dart';

/// ============================================================================
/// FICHIER : lib/screens/home_screen.dart
/// ROLE    : Écran principal (Barre de recherche flottante & Bulles de stats cliquables)
/// CHARTE  : Indigo #4F46E5, Filtre par défaut "Toutes", Bulles interactives.
/// ============================================================================

/// Peintre sur-mesure dessinant un arc concave vers le bas dans lequel s'insère le bouton central
class DownwardNotchedDockPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final Color shadowColor;

  DownwardNotchedDockPainter({
    required this.color,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double baseTop = 14.0;      // Ligne du haut de la barre
    final double cornerR = 24.0;     // Arrondi des coins
    final double c = size.width / 2; // Centre X
    final double notchR = 28.0;      // Rayon de l'arc concave (vers le bas)
    const double fillet = 14.0;      // Raccordement fluide

    final Path path = Path();

    // 1. Coin haut-gauche
    path.moveTo(cornerR, baseTop);

    // 2. Ligne supérieure gauche vers l'encoche
    path.lineTo(c - notchR - fillet, baseTop);

    // 3. Raccordement adouci vers l'arc en bas
    path.cubicTo(
      c - notchR - (fillet * 0.5), baseTop,
      c - notchR, baseTop + 4,
      c - notchR, baseTop + 12,
    );

    // 4. ARC ORIENTÉ VERS LE BAS (CONCAVE) ENVELOPPANT LE BOUTON
    path.arcToPoint(
      Offset(c + notchR, baseTop + 12),
      radius: Radius.circular(notchR),
      clockwise: false, // Incurvé vers le bas
    );

    // 5. Raccordement adouci remontant de l'encoche
    path.cubicTo(
      c + notchR, baseTop + 4,
      c + notchR + (fillet * 0.5), baseTop,
      c + notchR + fillet, baseTop,
    );

    // 6. Ligne supérieure droite
    path.lineTo(size.width - cornerR, baseTop);

    // 7. Coin haut-droit
    path.arcToPoint(
      Offset(size.width, baseTop + cornerR),
      radius: Radius.circular(cornerR),
    );

    // 8. Côté droit
    path.lineTo(size.width, size.height - cornerR);

    // 9. Coin bas-droit
    path.arcToPoint(
      Offset(size.width - cornerR, size.height),
      radius: Radius.circular(cornerR),
    );

    // 10. Ligne inférieure
    path.lineTo(cornerR, size.height);

    // 11. Coin bas-gauche
    path.arcToPoint(
      Offset(0, size.height - cornerR),
      radius: Radius.circular(cornerR),
    );

    // 12. Côté gauche
    path.lineTo(0, baseTop + cornerR);

    // 13. Coin haut-gauche
    path.arcToPoint(
      Offset(cornerR, baseTop),
      radius: Radius.circular(cornerR),
    );

    // Ombre portée sous la barre et l'encoche
    final Paint shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(path.shift(const Offset(0, 5)), shadowPaint);

    // Fond blanc
    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Bordure Indigo fine
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
    _loadSavedTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Chargement des tâches depuis SharedPreferences
  Future<void> _loadSavedTasks() async {
    List<Task> loadedTasks = await TaskStorageService.loadTasks();
    setState(() {
      _tasks = loadedTasks;
      _isLoading = false;
      _activeFilter = 'Toutes'; // Filtre "Toutes" garanti au démarrage
    });
  }

  /// Enregistrement local des tâches
  Future<void> _saveCurrentTasks() async {
    await TaskStorageService.saveTasks(_tasks);
  }

  /// Méthode d'ajout de tâche
  void _addNewTask(String title, String priority, String status) {
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
      return;
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
                        decoration: InputDecoration(
                          hintText: 'Que devez-vous accomplir ?',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: primarySelectionColor, width: 2),
                          ),
                        ),
                      ),
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
                            _addNewTask(
                              bottomTitleController.text,
                              bottomPriority,
                              bottomStatus,
                            );
                            Navigator.of(sheetContext).pop();
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
    final TextEditingController editTitleController =
        TextEditingController(text: task.title);
    String editPriority = task.priority;
    String editStatus = task.status;

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
    final int completedCount = _tasks.where((t) => t.isCompleted || t.status == 'Terminée').length;
    final int inProgressCount = totalCount - completedCount;

    return GestureDetector(
      // FERMETURE DU CLAVIER AU CLIC EN DEHORS
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),

        // DOCK INFÉRIEUR FLOTTANT AVEC ARC EN BAS (CONCAVE)
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. FOND DE LA BARRE AVEC L'ARC EN BAS SUR-MESURE
                CustomPaint(
                  size: const Size(double.infinity, 68),
                  painter: DownwardNotchedDockPainter(
                    color: Colors.white,
                    borderColor: primarySelectionColor.withValues(alpha: 0.18),
                    shadowColor: primarySelectionColor.withValues(alpha: 0.22),
                  ),
                ),

                // 2. BOUTONS INTERACTIFS DE FILTRAGE
                Positioned(
                  top: 14,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // BOUTON 1 : TOUTES
                      _buildDockNavItem(
                        icon: Icons.format_list_bulleted_rounded,
                        label: 'Toutes',
                        isSelected: _activeFilter == 'Toutes',
                        onTap: () => setState(() => _activeFilter = 'Toutes'),
                      ),

                      // BOUTON 2 : À FAIRE
                      _buildDockNavItem(
                        icon: Icons.radio_button_unchecked_rounded,
                        label: 'À faire',
                        isSelected: _activeFilter == 'À faire',
                        onTap: () => setState(() => _activeFilter = 'À faire'),
                      ),

                      // ESPACE LIBÉRÉ RÉSERVÉ À L'ARC EN BAS
                      const SizedBox(width: 58),

                      // BOUTON 3 : EN COURS
                      _buildDockNavItem(
                        icon: Icons.hourglass_top_rounded,
                        label: 'En cours',
                        isSelected: _activeFilter == 'En cours',
                        onTap: () => setState(() => _activeFilter = 'En cours'),
                      ),

                      // BOUTON 4 : TERMINÉE
                      _buildDockNavItem(
                        icon: Icons.check_circle_rounded,
                        label: 'Terminée',
                        isSelected: _activeFilter == 'Terminée',
                        onTap: () => setState(() => _activeFilter = 'Terminée'),
                      ),
                    ],
                  ),
                ),

                // 3. BOUTON D'AJOUT LOGÉ DE MANIÈRE HARMONIEUSE SUR L'ARC EN BAS
                Positioned(
                  top: 0,
                  child: GestureDetector(
                    onTap: _showAddTaskBottomSheet,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primarySelectionColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primarySelectionColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: primarySelectionColor),
                )
              : Column(
                  children: [
                    // 1. Header avec Gradient et Statistiques (Bulles cliquables)
                    _buildModernHeader(totalCount, inProgressCount, completedCount),

                    // 2. BARRE DE RECHERCHE FLOTTANTE UNIQUE EN HAUT
                    _buildTopFloatingSearchBar(),

                    // 3. Liste des Tâches
                    Expanded(
                      child: _filteredTasks.isEmpty
                          ? _buildEmptyState()
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
        ),
      ),
    );
  }

  /// Item interactif pour le Dock
  Widget _buildDockNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primarySelectionColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? primarySelectionColor : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primarySelectionColor : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// En-tête moderne avec gradient et indicateurs statistiques sous forme de bulles cliquables
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

          // Cards/Bulles de Statistiques désormais 100% Cliquables
          Row(
            children: [
              _buildStatChip(
                label: 'Total',
                value: total.toString(),
                isSelected: _activeFilter == 'Toutes',
                onTap: () => setState(() => _activeFilter = 'Toutes'),
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                label: 'En cours',
                value: inProgress.toString(),
                isSelected: _activeFilter == 'En cours',
                onTap: () => setState(() => _activeFilter = 'En cours'),
              ),
              const SizedBox(width: 10),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primarySelectionColor : Colors.white.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// BARRE DE RECHERCHE FLOTTANTE UNIQUE EN HAUT
  Widget _buildTopFloatingSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primarySelectionColor.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primarySelectionColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Rechercher une tâche...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: primarySelectionColor, size: 24),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20, color: Color(0xFF94A3B8)),
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
            'Ajoutez-en une via le bouton central ci-dessous.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
