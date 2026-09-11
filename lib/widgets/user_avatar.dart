import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/user_model.dart';

/// Avatar rond avec initiales, réutilisable pour n'importe quel
/// UserModel (admin connecté, membre du personnel...).
class UserAvatar extends StatelessWidget {
  final UserModel? user; // null = pas encore chargé, affiche un placeholder
  final double taille;

  const UserAvatar({super.key, required this.user, this.taille = 40});

  // Même logique que dans personnel_screen.dart : une couleur stable
  // calculée à partir de la première lettre du nom.
  Color _couleurAvatar(String nom) {
    if (nom.isEmpty) return AppColors.vertSauge;
    final palette = [
      AppColors.vertSauge,
      AppColors.terracotta,
      AppColors.bleuFleur,
      AppColors.taupe,
    ];
    return palette[nom.codeUnitAt(0) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    // Tant que le profil n'est pas encore chargé (ex: juste après
    // connexion), on affiche une icône neutre plutôt qu'un écran vide.
    if (user == null) {
      return CircleAvatar(
        radius: taille / 2,
        backgroundColor: AppColors.vertSauge,
        child: Icon(Icons.person, color: Colors.white, size: taille * 0.5),
      );
    }

    final initiales =
        '${user!.nom.isNotEmpty ? user!.nom[0] : ''}${user!.prenom.isNotEmpty ? user!.prenom[0] : ''}'
            .toUpperCase();

    return CircleAvatar(
      radius: taille / 2,
      backgroundColor: _couleurAvatar(user!.nom),
      child: Text(
        initiales,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: taille * 0.35, // proportionnel à la taille du cercle
        ),
      ),
    );
  }
}
