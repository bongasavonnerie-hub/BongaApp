import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fond dégradé avec éléments décoratifs flottants (bulles, goutte, feuille).
/// À utiliser en arrière-plan de n'importe quel écran, via un Stack :
/// Stack(children: [BongaBackground(), ...contenu de l'écran...])
class BongaBackground extends StatelessWidget {
  const BongaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.vertSapin, AppColors.vertSauge],
        ),
      ),
      child: Stack(
        children: [
          // Grosse bulle discrète en haut à droite, à moitié hors écran
          Positioned(
            top: -60,
            right: -40,
            child: _Bulle(diametre: 180, opacite: 0.08),
          ),
          // Petite bulle en bas à gauche
          Positioned(
            bottom: 100,
            left: -30,
            child: _Bulle(diametre: 120, opacite: 0.10),
          ),
          // Bulle moyenne, milieu droite
          Positioned(
            top: 240,
            right: 20,
            child: _Bulle(diametre: 60, opacite: 0.12),
          ),
          // Goutte d'eau stylisée, discrète, en bas à droite
          Positioned(
            bottom: -20,
            right: 40,
            child: CustomPaint(
              size: const Size(90, 120),
              painter: _GouttePainter(opacite: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un simple cercle translucide = une bulle de mousse/savon.
class _Bulle extends StatelessWidget {
  final double diametre;
  final double opacite;

  const _Bulle({required this.diametre, required this.opacite});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametre,
      height: diametre,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacite),
      ),
    );
  }
}

/// Dessine une forme de goutte d'eau avec CustomPainter, car Flutter
/// n'a pas d'icône "goutte" native qui rende bien à cette échelle.
class _GouttePainter extends CustomPainter {
  final double opacite;

  _GouttePainter({required this.opacite});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacite);
    final path = Path();

    // Point de départ : la pointe de la goutte, en haut
    path.moveTo(size.width / 2, 0);
    // Courbe vers le côté droit, s'élargissant vers le bas
    path.quadraticBezierTo(
      size.width,
      size.height * 0.6,
      size.width / 2,
      size.height,
    );
    // Courbe symétrique vers le côté gauche, remontant vers la pointe
    path.quadraticBezierTo(0, size.height * 0.6, size.width / 2, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  // Comme cette forme ne change jamais, pas besoin de redessiner :
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
