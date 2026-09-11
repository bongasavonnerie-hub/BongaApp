import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/user_avatar.dart';
import '../admin/gestion_admins_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  @override
  void initState() {
    super.initState();
    // Si le doc users/{uid} n'existe pas encore (ex: compte créé avant
    // qu'on gère automatiquement les profils), on le crée au chargement.
    // Le stream ci-dessous re-émettra alors le profil créé.
    AuthService().ensureUserProfileExists();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<UserModel?>(
        stream: AuthService().watchUserProfile(uid),
        builder: (context, snapshot) {
          // ConnectionState.waiting = le tout premier chargement, avant la
          // moindre réponse de Firestore (que ce soit un succès ou une erreur).
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erreur de chargement du profil : ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Profil introuvable.'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: UserAvatar(user: user, taille: 88)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${user.prenom} ${user.nom}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user.email,
                  style: const TextStyle(color: AppColors.texteSecondaire),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.isAdmin
                        ? AppColors.vertClairBg
                        : AppColors.creme,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.isAdmin ? 'Administrateur' : 'Membre standard',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: user.isAdmin
                          ? AppColors.succes
                          : AppColors.texteSecondaire,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ---------- NOUVEAU : modifier mes informations ----------
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.vertSapin,
                  ),
                  title: const Text('Modifier mon nom / prénom'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => _FormulaireModifierNom(user: user),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                    color: AppColors.vertSapin,
                  ),
                  title: const Text('Changer mon mot de passe'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const _FormulaireChangerMotDePasse(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (user.isAdmin)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.vertSapin,
                    ),
                    title: const Text('Gestion des admins'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GestionAdminsScreen(),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: const Text(
                    'Se déconnecter',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () async {
                    await AuthService().signOut();
                    // "mounted" ici est celui du BuildContext, pas d'un
                    // State — vérifie que ce contexte est toujours valide
                    // avant de naviguer, par sécurité.
                    if (context.mounted) {
                      // popUntil((route) => route.isFirst) retire TOUTES
                      // les pages empilées (ici : ProfilScreen) jusqu'à
                      // revenir à la toute première page de la pile —
                      // celle contrôlée par AuthGate, qui affichera alors
                      // correctement LoginScreen puisque l'utilisateur
                      // n'est plus connecté.
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Formulaire de modification du nom/prénom, pré-rempli avec les
/// valeurs actuelles (même pattern que le formulaire personnel).
class _FormulaireModifierNom extends StatefulWidget {
  final UserModel user;

  const _FormulaireModifierNom({required this.user});

  @override
  State<_FormulaireModifierNom> createState() => _FormulaireModifierNomState();
}

class _FormulaireModifierNomState extends State<_FormulaireModifierNom> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user.nom);
    _prenomController = TextEditingController(text: widget.user.prenom);
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      await AuthService().updateNomPrenom(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = 'Une erreur est survenue. Réessaie.');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier mon nom / prénom'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(labelText: 'Prénom'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Champ requis' : null,
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 8),
              Text(
                _erreur!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _envoi ? null : _enregistrer,
          child: _envoi
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}

/// Formulaire de changement de mot de passe : demande l'ACTUEL (pour
/// ré-authentification) et le NOUVEAU (deux fois, pour éviter une
/// faute de frappe qui bloquerait l'utilisateur hors de son compte).
class _FormulaireChangerMotDePasse extends StatefulWidget {
  const _FormulaireChangerMotDePasse();

  @override
  State<_FormulaireChangerMotDePasse> createState() =>
      _FormulaireChangerMotDePasseState();
}

class _FormulaireChangerMotDePasseState
    extends State<_FormulaireChangerMotDePasse> {
  final _formKey = GlobalKey<FormState>();
  final _actuelController = TextEditingController();
  final _nouveauController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérification supplémentaire, en dehors des "validator" classiques
    // car elle compare DEUX champs entre eux (pas juste un champ seul).
    if (_nouveauController.text != _confirmationController.text) {
      setState(() => _erreur = 'Les deux mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      await AuthService().changerMotDePasse(
        motDePasseActuel: _actuelController.text,
        nouveauMotDePasse: _nouveauController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // "wrong-password" si le mot de passe actuel est faux,
      // "weak-password" si le nouveau est trop simple (Firebase l'exige).
      setState(
        () => _erreur = 'Mot de passe actuel incorrect, ou nouveau mot de passe trop faible.',
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer mon mot de passe'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _actuelController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nouveauController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? '6 caractères minimum' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmationController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Champ requis' : null,
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 8),
              Text(
                _erreur!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _envoi ? null : _enregistrer,
          child: _envoi
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Valider'),
        ),
      ],
    );
  }
}
