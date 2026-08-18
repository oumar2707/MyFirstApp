import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// ============================================================================
// FICHIER : lib/services/auth_service.dart
// ROLE    : Service d'authentification 100% local avec SharedPreferences.
// ============================================================================

class AuthService {
  static const String _usersKey = 'registered_users_list';
  static const String _currentSessionKey = 'active_user_session';

  /// Récupérer tous les utilisateurs enregistrés depuis SharedPreferences
  static Future<List<UserModel>> _getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force le rafraîchissement depuis le stockage physique
    final List<String>? usersJson = prefs.getStringList(_usersKey);
    if (usersJson == null || usersJson.isEmpty) return [];

    return usersJson.map((str) {
      return UserModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();
  }

  /// Sauvegarder la liste des utilisateurs enregistrés
  static Future<void> _saveRegisteredUsers(List<UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> usersJson = users.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList(_usersKey, usersJson);
  }

  /// Inscription d'un nouvel utilisateur
  static Future<({bool success, String message, UserModel? user})> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return (success: false, message: 'Tous les champs sont obligatoires.', user: null);
    }

    final users = await _getRegisteredUsers();

    // Vérification de l'unicité de l'email
    final exists = users.any((u) => u.email.trim().toLowerCase() == cleanEmail);
    if (exists) {
      return (success: false, message: 'Un compte existe déjà avec cet e-mail.', user: null);
    }

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanName,
      email: cleanEmail,
      password: cleanPassword,
      createdAt: DateTime.now(),
    );

    users.add(newUser);
    await _saveRegisteredUsers(users);

    // Définir comme session active
    await _setActiveUserSession(newUser);

    return (success: true, message: 'Compte créé avec succès !', user: newUser);
  }

  /// Connexion d'un utilisateur existant avec diagnostic d'erreur précis
  static Future<({bool success, String message, UserModel? user})> loginUser({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return (success: false, message: 'Veuillez remplir tous les champs.', user: null);
    }

    final users = await _getRegisteredUsers();

    // 1. Vérifier si l'adresse e-mail existe
    final usersWithEmail = users.where((u) => u.email.trim().toLowerCase() == cleanEmail).toList();

    if (usersWithEmail.isEmpty) {
      return (
        success: false,
        message: 'Aucun compte trouvé avec cet e-mail ($cleanEmail). Veuillez vous inscrire.',
        user: null
      );
    }

    // 2. Vérifier si le mot de passe correspond
    final matchedUser = usersWithEmail.firstWhere(
      (u) => u.password.trim() == cleanPassword,
      orElse: () => UserModel(
        id: '',
        name: '',
        email: '',
        password: '',
        createdAt: DateTime.now(),
      ),
    );

    if (matchedUser.id.isEmpty) {
      return (
        success: false,
        message: 'Mot de passe incorrect pour cet e-mail.',
        user: null
      );
    }

    // Définir la session active
    await _setActiveUserSession(matchedUser);

    return (success: true, message: 'Connexion réussie !', user: matchedUser);
  }

  /// Obtenir l'utilisateur actuellement connecté
  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final String? userJson = prefs.getString(_currentSessionKey);
    if (userJson == null || userJson.isEmpty) return null;

    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Mettre à jour la session active
  static Future<void> _setActiveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSessionKey, jsonEncode(user.toJson()));
  }

  /// Mettre à jour le profil utilisateur (Nom, Email, Avatar)
  static Future<({bool success, String message})> updateUserProfile({
    required String name,
    required String email,
    String? avatar,
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      return (success: false, message: 'Aucun utilisateur connecté.');
    }

    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty || cleanEmail.isEmpty) {
      return (success: false, message: 'Le nom et l\'e-mail ne peuvent être vides.');
    }

    final users = await _getRegisteredUsers();

    // Vérifier si le nouvel email n'est pas utilisé par un autre utilisateur
    final emailTaken = users.any((u) => u.id != currentUser.id && u.email.trim().toLowerCase() == cleanEmail);
    if (emailTaken) {
      return (success: false, message: 'Cet e-mail est déjà utilisé par un autre compte.');
    }

    currentUser.name = cleanName;
    currentUser.email = cleanEmail;
    if (avatar != null) {
      currentUser.avatar = avatar;
    }

    // Mise à jour dans la liste globale
    final index = users.indexWhere((u) => u.id == currentUser.id);
    if (index != -1) {
      users[index] = currentUser;
      await _saveRegisteredUsers(users);
    }

    // Mise à jour de la session active
    await _setActiveUserSession(currentUser);

    return (success: true, message: 'Profil mis à jour avec succès !');
  }

  /// Changer le mot de passe de l'utilisateur
  static Future<({bool success, String message})> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      return (success: false, message: 'Aucun utilisateur connecté.');
    }

    final cleanCurrent = currentPassword.trim();
    final cleanNew = newPassword.trim();
    final cleanConfirm = confirmPassword.trim();

    if (cleanCurrent.isEmpty || cleanNew.isEmpty || cleanConfirm.isEmpty) {
      return (success: false, message: 'Veuillez remplir tous les champs de mot de passe.');
    }

    if (currentUser.password.trim() != cleanCurrent) {
      return (success: false, message: 'Le mot de passe actuel est incorrect.');
    }

    if (cleanNew.length < 4) {
      return (success: false, message: 'Le nouveau mot de passe doit contenir au moins 4 caractères.');
    }

    if (cleanNew != cleanConfirm) {
      return (success: false, message: 'Les nouveaux mots de passe ne correspondent pas.');
    }

    currentUser.password = cleanNew;

    final users = await _getRegisteredUsers();
    final index = users.indexWhere((u) => u.id == currentUser.id);
    if (index != -1) {
      users[index] = currentUser;
      await _saveRegisteredUsers(users);
    }

    await _setActiveUserSession(currentUser);

    return (success: true, message: 'Mot de passe modifié avec succès !');
  }

  /// Déconnexion (suppression de la session)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSessionKey);
  }
}
