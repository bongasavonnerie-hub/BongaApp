import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pilule compacte affichant le nom de l'auteur d'un mouvement :
/// fond coloré, texte en gras, lisible même en très petit.
class BadgeAuteur extends StatelessWidget {
  final String nom;
  final bool estEntree;

  const BadgeAuteur({
    super.key,
    required this.nom,
    this.estEntree = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: estEntree
            ? AppColors.succes.withValues(alpha: 0.15)
            : AppColors.terracotta.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        nom,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: estEntree ? AppColors.succes : AppColors.terracotta,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}