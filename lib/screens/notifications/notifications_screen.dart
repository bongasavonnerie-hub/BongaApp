import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/mouvement_model.dart';
import '../../services/stock_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/badge_auteur.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _stockService = StockService();

  @override
  void initState() {
    super.initState();
    // Dès que l'utilisateur OUVRE cet écran, on marque SES notifications
    // comme lues (dans Firestore, lié à son compte — pas à l'appareil).
    // On ne bloque pas l'affichage en attendant cette écriture (pas de
    // "await" ici) : l'écran s'affiche immédiatement, l'enregistrement
    // se fait en tâche de fond.
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      NotificationService().marquerCommeLu(uid: uid);
    }
  }

  String _formaterDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year} à $heure:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<MouvementModel>>(
        stream: _stockService.watchMouvements(limite: 50),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final mouvements = snapshot.data!;

          if (mouvements.isEmpty) {
            return const Center(child: Text('Aucune notification.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mouvements.length,
            itemBuilder: (context, index) {
              final m = mouvements[index];
              final estEntree = m.type == TypeMouvement.entree;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.vertSapin.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (estEntree ? AppColors.succes : AppColors.terracotta)
                            .withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        estEntree ? Icons.login : Icons.logout,
                        color: estEntree ? AppColors.succes : AppColors.terracotta,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            estEntree
                                ? 'Entrée de stock : ${m.produitNom}'
                                : 'Sortie de stock : ${m.produitNom}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${m.quantite.toStringAsFixed(0)} unités · ${m.motif}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.texteSecondaire,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formaterDate(m.date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.texteSecondaire,
                            ),
                          ),
                          const SizedBox(height: 3),
                          BadgeAuteur(
                            nom: m.effectuePar,
                            estEntree: estEntree,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
