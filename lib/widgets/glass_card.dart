import 'dart:ui';
import 'package:flutter/material.dart';

/// Carte à effet "verre dépoli" (glassmorphism) : flou de l'arrière-plan
/// + fond blanc semi-transparent + léger contour blanc pour la profondeur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    // ClipRRect est nécessaire : sans lui, le flou de BackdropFilter
    // s'appliquerait sur un rectangle net, pas sur la forme arrondie
    // qu'on veut. Il "découpe" le flou selon les coins arrondis.
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        // sigmaX/sigmaY = intensité du flou. 15 est un bon compromis :
        // assez pour l'effet verre, pas au point de rendre le fond
        // méconnaissable derrière.
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}