import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/task_storage_service.dart';
import 'login_screen.dart';

/// ============================================================================
/// FICHIER : lib/screens/settings_screen.dart
/// ROLE    : Écran Paramètres de l'application (Préférences, Données, Déconnexion)
/// ============================================================================

class SettingsScreen extends StatefulWidget {
  final VoidCallback onTasksCleared;

  const SettingsScreen({
    super.key,
    required this.onTasksCleared,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primaryColor = Color(0xFF4F46E5);

  bool _enableNotifications = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _enableNotifications = prefs.getBool('enable_notifications') ?? true;
        _isDarkMode = themeNotifier.value == ThemeMode.dark;
      });
    }
  }

  Future<void> _toggleDarkMode(bool val) async {
    setState(() {
      _isDarkMode = val;
    });
    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', val);
  }

  Future<void> _toggleNotifications(bool val) async {
    setState(() {
      _enableNotifications = val;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', val);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val ? 'Notifications de rappel activées.' : 'Notifications désactivées.'),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 26),
              SizedBox(width: 10),
              Text('Déconnexion'),
            ],
          ),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
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
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await AuthService.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 26),
              SizedBox(width: 10),
              Text('Effacer les tâches'),
            ],
          ),
          content: const Text('Cette action supprimera toutes les tâches enregistrées.'),
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
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final currentUser = await AuthService.getCurrentUser();
                await TaskStorageService.saveUserTasks(currentUser?.id, []);
                widget.onTasksCleared();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Toutes les tâches ont été réinitialisées.'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Supprimer tout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Préférences Générales',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          // Options Toggles
          Container(
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
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: primaryColor),
                  title: const Text('Notifications de Rappel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Rappels pour vos tâches à faire', style: TextStyle(fontSize: 12)),
                  value: _enableNotifications,
                  activeTrackColor: primaryColor,
                  onChanged: _toggleNotifications,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: primaryColor),
                  title: const Text('Mode Sombre', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Activer le thème sombre sur toute l\'application', style: TextStyle(fontSize: 12)),
                  value: _isDarkMode,
                  activeTrackColor: primaryColor,
                  onChanged: _toggleDarkMode,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Gestion des Données',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          Container(
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
            child: ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              title: const Text('Réinitialiser les tâches', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
              subtitle: const Text('Effacer toute la liste actuelle', style: TextStyle(fontSize: 12)),
              onTap: _confirmClearData,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'À propos & Déconnexion',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          Container(
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
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: primaryColor),
                  title: Text('Application To-Do Liste Mobile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text('Version 1.0.0 - Mode Professionnel Evalué', style: TextStyle(fontSize: 12)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                  title: const Text('Se déconnecter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  subtitle: const Text('Fermer la session actuelle', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
