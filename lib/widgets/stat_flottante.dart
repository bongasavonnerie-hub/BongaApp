import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Carte translucide affichant un total en temps réel, conçue pour être
/// posée par-dessus un en-tête dégradé (fond blanc semi-transparent).
/// Générique : on lui passe le stream et une fonction qui sait calculer
/// le total à partir de N'IMPORTE QUELLE liste (liquide OU solide),
/// ce qui évite d'écrire deux fois presque le même widget.
class StatFlottante<T> extends StatelessWidget {
  final IconData icone;
  final Color couleurIcone;
  final String label;
  final Stream<List<T>> streamTotal;
  final double Function(List<T>) extraireTotal;
  final String suffixe;

  const StatFlottante({
    super.key,
    required this.icone,
    required this.couleurIcone,
    required this.label,
    required this.streamTotal,
    required this.extraireTotal,
    required this.suffixe,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: streamTotal,
      builder: (context, snapshot) {
        final total = snapshot.hasData ? extraireTotal(snapshot.data!) : 0.0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleurIcone.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: couleurIcone, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.texteSecondaire,
                      ),
                    ),
                    Text(
                      '$total${suffixe.isNotEmpty ? ' $suffixe' : ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
