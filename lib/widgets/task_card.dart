import 'package:flutter/material.dart';
import '../models/task.dart';

/// ============================================================================
/// FICHIER : lib/widgets/task_card.dart
/// ROLE    : Widget réutilisable pour afficher l'élément visuel d'une seule tâche.
/// EXPLICATION :
/// Reçoit une tâche `task` et des fonctions de rappel (callbacks).
/// Respecte scrupuleusement la charte graphique à 2 COULEURS :
/// - Indigo (Couleur Principale : Priorité, Titre, Actions)
/// - Teal (Couleur Secondaire : Statut, Validation, Succès)
/// ============================================================================

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onToggleCompleted;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleCompleted,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  /// Retourne l'icône associée au statut de la tâche
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Terminée':
        return Icons.check_circle_outline_rounded;
      case 'En cours':
        return Icons.sync_rounded;
      case 'À faire':
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = task.isCompleted || task.status == 'Terminée';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      decoration: BoxDecoration(
        color: isDone ? Colors.white.withValues(alpha: 0.75) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? Colors.teal.shade100 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? Colors.transparent
                : Colors.indigo.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne principale : Checkbox + Titre + Boutons d'action
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Case à cocher (Couleur Teal)
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: isDone,
                    onChanged: onToggleCompleted,
                    activeColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    side: BorderSide(
                      color: isDone ? Colors.teal : const Color(0xFF94A3B8),
                      width: 1.5,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Titre de la tâche
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.teal.shade400,
                      color: isDone ? const Color(0xFF64748B) : const Color(0xFF1E293B),
                    ),
                  ),
                ),

                // Actions rapides (Voir, Modifier, Supprimer)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 19),
                      color: Colors.indigo.shade400,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Voir les détails',
                      onPressed: onView,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      color: Colors.indigo.shade600,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Modifier',
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 19),
                      color: const Color(0xFF94A3B8),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Supprimer',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Ligne de badges (Priorité et Statut - Charte à 2 couleurs Indigo et Teal)
            Padding(
              padding: const EdgeInsets.only(left: 42.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Badge de Priorité (Thème Indigo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.indigo.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          size: 13,
                          color: Colors.indigo.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Priorité : ${task.priority}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge de Statut (Thème Teal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.teal.shade50 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDone ? Colors.teal.shade200 : const Color(0xFFCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(task.status),
                          size: 13,
                          color: isDone ? Colors.teal.shade700 : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          task.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDone ? Colors.teal.shade900 : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

