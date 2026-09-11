import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';

/// Gère, pour CHAQUE UTILISATEUR, la date de dernière consultation des
/// notifications. Curseur stocké dans Firestore (champ
/// `derniereLectureNotifications` sur `users/{uid}`), donc lié au
/// COMPTE : si un autre utilisateur se connecte sur le même appareil,
/// il repart de zéro et voit toutes les notifications comme non lues.
class NotificationService {
  static const _champDerniereLecture = 'derniereLectureNotifications';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Renvoie la date à laquelle CET utilisateur a ouvert les
  /// notifications pour la dernière fois.
  ///
  /// Si jamais lu (champ absent), renvoie 1970 : TOUS les mouvements
  /// existants comptent comme "non lus" — exactement ce qu'on veut
  /// pour quelqu'un qui vient de se connecter pour la première fois.
  Future<DateTime> getDerniereLecture({required String uid}) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .get();
      final ts = (doc.data()?[_champDerniereLecture] as Timestamp?)?.toDate();
      return ts ?? DateTime.fromMillisecondsSinceEpoch(0);
    } on Exception {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  /// Enregistre "maintenant" comme date de dernière lecture pour CET
  /// utilisateur. `set` avec merge : crée le champ s'il n'existe pas,
  /// sans écraser le reste du profil.
  Future<void> marquerCommeLu({required String uid}) async {
    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .set(
          {_champDerniereLecture: Timestamp.now()},
          SetOptions(merge: true),
        );
  }
}