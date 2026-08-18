import 'package:flutter/material.dart';
import '../models/task.dart';

/// ============================================================================
/// FICHIER : lib/widgets/task_card.dart
/// ROLE    : Carte de tâche épurée avec menu contextuel (PopupMenuButton)
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

  /// Retourne l'icône associée au statut
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Terminée':
        return Icons.check_circle_rounded;
      case 'En cours':
        return Icons.autofps_select_rounded;
      case 'À faire':
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  /// Couleur du badge de priorité
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Haute':
        return const Color(0xFFEF4444); // Rouge subtil
      case 'Moyenne':
        return const Color(0xFFF59E0B); // Ambre / Orange
      case 'Basse':
      default:
        return const Color(0xFF10B981); // Émeraude / Vert
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = task.isCompleted || task.status == 'Terminée';
    const Color primarySelectionColor = Color(0xFF4F46E5); // Couleur de sélection unifiée (Indigo)
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final Color cardBg = isDarkTheme
        ? (isDone ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFF1E293B))
        : (isDone ? Colors.white.withValues(alpha: 0.8) : Colors.white);

    final Color borderColor = isDarkTheme
        ? (isDone ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFF334155))
        : (isDone ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0));

    final Color titleColor = isDarkTheme
        ? (isDone ? Colors.white38 : Colors.white)
        : (isDone ? const Color(0xFF94A3B8) : const Color(0xFF1E293B));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? Colors.transparent
                : primarySelectionColor.withValues(alpha: isDarkTheme ? 0.02 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onView,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de la carte : Checkbox + Titre + Menu Contextuel placé en haut à droite
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Case à cocher moderne
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: isDone,
                        onChanged: onToggleCompleted,
                        activeColor: primarySelectionColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        side: BorderSide(
                          color: isDone ? primarySelectionColor : (isDarkTheme ? Colors.white54 : const Color(0xFF94A3B8)),
                          width: 1.8,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Titre de la tâche
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: isDarkTheme ? Colors.white38 : const Color(0xFF94A3B8),
                          color: titleColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // MENU CONTEXTUEL : Remplace les 3 boutons d'action individuels pour un design épuré
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDarkTheme ? Colors.white60 : const Color(0xFF64748B),
                        size: 20,
                      ),
                      tooltip: 'Actions',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            onView();
                            break;
                          case 'edit':
                            onEdit();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 18, color: primarySelectionColor),
                              SizedBox(width: 10),
                              Text('Lire les détails', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: primarySelectionColor),
                              SizedBox(width: 10),
                              Text('Modifier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                              SizedBox(width: 10),
                              Text(
                                'Supprimer',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Ligne inférieure : Badges épurés pour la Priorité et le Statut
                Padding(
                  padding: const EdgeInsets.only(left: 40.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Badge Priorité
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getPriorityColor(task.priority).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 12,
                              color: _getPriorityColor(task.priority),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.priority,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _getPriorityColor(task.priority),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Badge Statut (Utilisant la couleur unifiée si sélectionné/terminé)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDone
                              ? primarySelectionColor.withValues(alpha: 0.1)
                              : (isDarkTheme ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDone
                                ? primarySelectionColor.withValues(alpha: 0.3)
                                : (isDarkTheme ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(task.status),
                              size: 12,
                              color: isDone ? primarySelectionColor : (isDarkTheme ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDone ? primarySelectionColor : (isDarkTheme ? Colors.white70 : const Color(0xFF475569)),
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
        ),
      ),
    );
  }
}


