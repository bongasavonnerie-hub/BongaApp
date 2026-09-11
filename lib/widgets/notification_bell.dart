import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/mouvement_model.dart';
import '../services/stock_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../screens/notifications/notifications_screen.dart';

/// Icône cloche avec badge de compteur, à placer dans l'en-tête d'un
/// écran. StatefulWidget car il doit charger UNE FOIS la date de
/// dernière lecture (opération asynchrone), puis rester à l'écoute
/// EN CONTINU des nouveaux mouvements.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _notificationService = NotificationService();
  final _stockService = StockService();
  DateTime? _derniereLecture; // null tant que non chargée

  @override
  void initState() {
    super.initState();
    _chargerDerniereLecture();
  }

  Future<void> _chargerDerniereLecture() async {
    // Le curseur est PAR UTILISATEUR : chaque fois que l'état de
    // connexion change (nouveau compte), initState est rejoué (le
    // dashboard est reconstruit) et on relit le curseur du nouveau
    // connecté — il verra donc ses propres notifications non lues.
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    final date = await _notificationService.getDerniereLecture(uid: uid);
    // "mounted" vérifie que le widget existe encore avant de mettre à
    // jour son état (évite une erreur si l'écran a été fermé entre-temps).
    if (mounted) setState(() => _derniereLecture = date);
  }

  @override
  Widget build(BuildContext context) {
    // Tant qu'on ne sait pas encore quelle est la date de référence,
    // on affiche la cloche sans badge plutôt que de deviner un chiffre faux.
    if (_derniereLecture == null) {
      return const Icon(Icons.notifications_outlined, color: Colors.white);
    }

    return StreamBuilder<List<MouvementModel>>(
      stream: _stockService.watchMouvements(limite: 50),
      builder: (context, snapshot) {
        final mouvements = snapshot.data ?? [];

        // On compte combien de mouvements sont plus récents que la
        // dernière consultation enregistrée.
        final nonLus = mouvements
            .where((m) => m.date.isAfter(_derniereLecture!))
            .length;

        return GestureDetector(
          onTap: () async {
            // On navigue vers l'écran complet, ET on attend son retour
            // (await) pour ensuite recharger la date de dernière lecture
            // (mise à jour par cet écran) — le badge redescend donc à 0
            // dès qu'on revient sur le dashboard.
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
            _chargerDerniereLecture();
          },
          // Badge : widget natif Flutter, superpose un petit indicateur
          // sur le coin de son enfant. isLabelVisible masque le badge
          // entier (pas juste le vide) quand le compteur est à 0.
          child: Badge(
            isLabelVisible: nonLus > 0,
            label: Text('$nonLus'),
            backgroundColor: AppColors.danger,
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
