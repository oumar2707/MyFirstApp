import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/task.dart';
import '../services/auth_service.dart';

/// ============================================================================
/// FICHIER : lib/screens/profile_screen.dart
/// ROLE    : Écran Profil de l'utilisateur (Infos, Statisiques, Édition)
/// ============================================================================

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  final List<Task> tasks;
  final VoidCallback onProfileUpdated;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.tasks,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryColor = Color(0xFF4F46E5);

  // Liste des avatars disponibles localement
  static const List<({String id, IconData icon, Color color, String name})> _availableAvatars = [
    (id: 'initials', icon: Icons.person_rounded, color: primaryColor, name: 'Initiales'),
    (id: 'face_1', icon: Icons.face_rounded, color: Color(0xFFEC4899), name: 'Élégant'),
    (id: 'face_2', icon: Icons.sentiment_very_satisfied_rounded, color: Color(0xFF10B981), name: 'Souriant'),
    (id: 'developer', icon: Icons.code_rounded, color: Color(0xFF3B82F6), name: 'Développeur'),
    (id: 'star', icon: Icons.star_rounded, color: Color(0xFFF59E0B), name: 'Étoile'),
    (id: 'robot', icon: Icons.smart_toy_rounded, color: Color(0xFF8B5CF6), name: 'Robot'),
  ];

  /// Méthode d'importation d'une photo depuis la galerie locale
  Future<void> _pickAvatarFromGallery() async {
    final currentUser = widget.user;
    if (currentUser == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        final avatarString = 'custom_base64:$base64Image';

        final updateResult = await AuthService.updateUserProfile(
          name: currentUser.name,
          email: currentUser.email,
          avatar: avatarString,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(updateResult.message),
              backgroundColor: updateResult.success ? primaryColor : const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          if (updateResult.success) {
            widget.onProfileUpdated();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du choix de l\'image : $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showChangeAvatarDialog() {
    final currentUser = widget.user;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.photo_camera_rounded, color: primaryColor, size: 26),
              SizedBox(width: 10),
              Text('Photo de Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton principal d'import depuis la galerie
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _pickAvatarFromGallery();
                    },
                    icon: const Icon(Icons.photo_library_rounded, size: 20),
                    label: const Text(
                      'Choisir depuis la galerie',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'ou choisir un icône',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: _availableAvatars.map((avatarItem) {
                    final bool isSelected = (currentUser.avatar ?? 'initials') == avatarItem.id;
                    return InkWell(
                      onTap: () async {
                        Navigator.of(dialogContext).pop();
                        final result = await AuthService.updateUserProfile(
                          name: currentUser.name,
                          email: currentUser.email,
                          avatar: avatarItem.id,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor: result.success ? primaryColor : const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          if (result.success) {
                            widget.onProfileUpdated();
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: avatarItem.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? avatarItem.color : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: Icon(avatarItem.icon, color: avatarItem.color, size: 32),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer', style: TextStyle(color: Color(0xFF64748B))),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setPassState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: primaryColor, size: 26),
                  SizedBox(width: 10),
                  Text('Changer de mot de passe', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPassController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe actuel',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setPassState(() => obscureCurrent = !obscureCurrent),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPassController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setPassState(() => obscureNew = !obscureNew),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmer nouveau mot de passe',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setPassState(() => obscureConfirm = !obscureConfirm),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
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
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final result = await AuthService.changePassword(
                      currentPassword: currentPassController.text,
                      newPassword: newPassController.text,
                      confirmPassword: confirmPassController.text,
                    );
                    if (context.mounted) {
                      if (result.success) {
                        Navigator.of(dialogContext).pop();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: result.success ? primaryColor : const Color(0xFFEF4444),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final currentUser = widget.user;
    if (currentUser == null) return;

    final TextEditingController nameController = TextEditingController(text: currentUser.name);
    final TextEditingController emailController = TextEditingController(text: currentUser.email);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: primaryColor, size: 26),
              SizedBox(width: 10),
              Text('Modifier le profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Adresse e-mail',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showChangePasswordDialog();
                  },
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: const Text('Changer de mot de passe'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final result = await AuthService.updateUserProfile(
                  name: nameController.text,
                  email: emailController.text,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.success ? primaryColor : const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  if (result.success) {
                    widget.onProfileUpdated();
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildAvatarWidget(UserModel? user) {
    final avatarId = user?.avatar ?? 'initials';

    if (avatarId.startsWith('custom_base64:')) {
      try {
        final base64Data = avatarId.replaceFirst('custom_base64:', '');
        final bytes = base64Decode(base64Data);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 76,
            height: 76,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_rounded, size: 40, color: primaryColor),
          ),
        );
      } catch (_) {
        return const Icon(Icons.person_rounded, size: 40, color: primaryColor);
      }
    }

    final matchedAvatar = _availableAvatars.firstWhere(
      (a) => a.id == avatarId,
      orElse: () => _availableAvatars.first,
    );

    if (avatarId != 'initials') {
      return Icon(matchedAvatar.icon, size: 40, color: matchedAvatar.color);
    }

    return Text(
      _getInitials(user?.name ?? 'Utilisateur'),
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final int totalTasks = widget.tasks.length;
    final int completedTasks = widget.tasks.where((t) => t.isCompleted || t.status == 'Terminée').length;
    final int inProgressTasks = widget.tasks.where((t) => t.status == 'En cours' && !t.isCompleted).length;
    final double completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Carte En-tête Profil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3730A3), primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar cliquable avec icône d'édition photo
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _showChangeAvatarDialog,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _buildAvatarWidget(user),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showChangeAvatarDialog,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'Nom Utilisateur',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'email@domaine.com',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Modifier le profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showChangePasswordDialog,
                      icon: const Icon(Icons.lock_reset_rounded, size: 16),
                      label: const Text('Mot de passe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section Statistiques
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Statistiques d\'Activité',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildStatCard(
                title: 'Total Tâches',
                value: '$totalTasks',
                icon: Icons.format_list_bulleted_rounded,
                color: const Color(0xFF3B82F6),
                isDarkTheme: isDarkTheme,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'Terminées',
                value: '$completedTasks',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
                isDarkTheme: isDarkTheme,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'En cours',
                value: '$inProgressTasks',
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFFF59E0B),
                isDarkTheme: isDarkTheme,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barre de Progression globale
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Taux d\'accomplissement',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkTheme ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      '${(completionRate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    minHeight: 10,
                    backgroundColor: isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkTheme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: isDarkTheme ? Colors.white60 : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

