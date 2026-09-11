import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../constants/firestore_paths.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';

class GestionAdminsScreen extends StatelessWidget {
  const GestionAdminsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des admins')),
      // On lit directement Firestore ici (pas via AuthService) car cet
      // écran a besoin de la liste ENTIÈRE des utilisateurs, pas d'un
      // profil précis — un cas d'usage propre à cet écran seulement.
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final utilisateurs = snapshot.data!.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: utilisateurs.length,
            itemBuilder: (context, index) {
              final user = utilisateurs[index];
              return Card(
                child: ListTile(
                  leading: UserAvatar(user: user),
                  title: Text('${user.prenom} ${user.nom}'),
                  subtitle: Text(user.email),
                  trailing: Chip(
                    label: Text(user.isAdmin ? 'Admin' : 'Standard'),
                    backgroundColor: user.isAdmin
                        ? AppColors.vertClairBg
                        : AppColors.creme,
                  ),
                  onTap: () => _confirmerChangementRole(context, user),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmerChangementRole(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          user.isAdmin ? 'Retirer les droits admin ?' : 'Promouvoir en admin ?',
        ),
        content: const Text(
          'Cette action nécessite une Cloud Function côté serveur, pas encore déployée. '
          'Une fois en place, ce bouton appellera cette fonction directement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
