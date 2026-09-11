import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';
import '../models/produit_liquide_model.dart';
import '../models/produit_solide_model.dart';
import '../models/mouvement_model.dart';

class StockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- LECTURE ----------

  Stream<List<ProduitLiquideModel>> watchStockLiquide() {
    return _firestore
        .collection(FirestorePaths.stockLiquide)
        .orderBy('nom')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProduitLiquideModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ProduitSolideModel>> watchStockSolide() {
    return _firestore
        .collection(FirestorePaths.stockSolide)
        .orderBy('nom')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProduitSolideModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ---------- CRÉATION / MODIFICATION / SUPPRESSION DE FICHES ----------

  Future<void> ajouterProduitLiquide(ProduitLiquideModel produit) {
    return _firestore
        .collection(FirestorePaths.stockLiquide)
        .add(produit.toFirestore());
  }

  Future<void> modifierProduitLiquide(ProduitLiquideModel produit) {
    return _firestore
        .collection(FirestorePaths.stockLiquide)
        .doc(produit.id)
        .update(produit.toFirestore());
  }

  Future<void> supprimerProduitLiquide(String id) {
    return _firestore.collection(FirestorePaths.stockLiquide).doc(id).delete();
  }

  Future<void> ajouterProduitSolide(ProduitSolideModel produit) {
    return _firestore
        .collection(FirestorePaths.stockSolide)
        .add(produit.toFirestore());
  }

  Future<void> modifierProduitSolide(ProduitSolideModel produit) {
    return _firestore
        .collection(FirestorePaths.stockSolide)
        .doc(produit.id)
        .update(produit.toFirestore());
  }

  Future<void> supprimerProduitSolide(String id) {
    return _firestore.collection(FirestorePaths.stockSolide).doc(id).delete();
  }

  // ---------- MOUVEMENTS ----------

  /// Cœur commun à tout enregistrement de mouvement (nouvelle saisie OU
  /// correction) : une seule fonction, réutilisée partout, pour éviter
  /// de dupliquer la logique de transaction à plusieurs endroits — un
  /// bug corrigé ici est corrigé PARTOUT.
  Future<void> _appliquerMouvement({
    required String produitId,
    required String produitNom,
    required TypeProduitMouvement produitType,
    required TypeMouvement type,
    required double quantite,
    required String motif,
    required String effectuePar,
  }) async {
    final collection = produitType == TypeProduitMouvement.liquide
        ? FirestorePaths.stockLiquide
        : FirestorePaths.stockSolide;

    final produitRef = _firestore.collection(collection).doc(produitId);
    final mouvementRef = _firestore.collection(FirestorePaths.mouvements).doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(produitRef);
      final quantiteActuelle = (snapshot.data()?['quantite'] ?? 0).toDouble();

      final nouvelleQuantite = (type == TypeMouvement.entree)
          ? quantiteActuelle + quantite
          : quantiteActuelle - quantite;

      if (nouvelleQuantite < 0) {
        throw Exception('Quantité insuffisante en stock.');
      }

      transaction.update(produitRef, {
        'quantite': nouvelleQuantite,
        'dateMaj': Timestamp.now(),
        'majPar': effectuePar,
      });

      transaction.set(mouvementRef, {
        'produitId': produitId,
        'produitNom': produitNom,
        'produitType': produitType == TypeProduitMouvement.liquide
            ? 'liquide'
            : 'solide',
        'type': type == TypeMouvement.entree ? 'entree' : 'sortie',
        'quantite': quantite,
        'motif': motif,
        'date': Timestamp.now(),
        'effectuePar': effectuePar,
      });
    });
  }

  Future<void> enregistrerMouvementLiquide({
    required ProduitLiquideModel produit,
    required TypeMouvement type,
    required double quantite,
    required String motif,
    required String effectuePar,
  }) {
    return _appliquerMouvement(
      produitId: produit.id,
      produitNom: produit.nom,
      produitType: TypeProduitMouvement.liquide,
      type: type,
      quantite: quantite,
      motif: motif,
      effectuePar: effectuePar,
    );
  }

  Future<void> enregistrerMouvementSolide({
    required ProduitSolideModel produit,
    required TypeMouvement type,
    required double quantite,
    required String motif,
    required String effectuePar,
  }) {
    return _appliquerMouvement(
      produitId: produit.id,
      produitNom: produit.nom,
      produitType: TypeProduitMouvement.solide,
      type: type,
      quantite: quantite,
      motif: motif,
      effectuePar: effectuePar,
    );
  }

  /// NOUVEAU : enregistre une CORRECTION d'un mouvement existant.
  /// Le type (entrée OU sortie) est choisi par l'utilisateur — il peut
  /// aussi se tromper sur le type, pas seulement sur la quantité.
  Future<void> corrigerMouvement({
    required MouvementModel mouvementOriginal,
    required TypeMouvement type,
    required double quantite,
    required String motif,
    required String effectuePar,
  }) {
    return _appliquerMouvement(
      produitId: mouvementOriginal.produitId,
      produitNom: mouvementOriginal.produitNom,
      produitType: mouvementOriginal.produitType,
      type: type,
      quantite: quantite,
      motif: motif,
      effectuePar: effectuePar,
    );
  }

  Stream<List<MouvementModel>> watchMouvements({int limite = 50}) {
    return _firestore
        .collection(FirestorePaths.mouvements)
        .orderBy('date', descending: true)
        .limit(limite)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MouvementModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ---------- MIGRATION DES ANCIENS MOUVEMENTS ----------
  // Avant, `effectuePar` contenait l'UID du compte (illisible). Depuis,
  // il contient le nom affichable ("Prénom Nom"). Cette passe ponctuelle
  // remplace les UID encore présents dans les mouvements existants par
  // leur nom, pour que l'historique affiche toujours un nom humain.
  // Le flag statique évite de relancer la migration à chaque rebuild
  // du dashboard au cours d'une même session d'appli.
  static bool _migrationAnciensLancee = false;

  final _regExpNomOuMail = RegExp(r'[\s@.]');

  Future<void> migrerAnciensEffectuePar() async {
    if (_migrationAnciensLancee) return;
    _migrationAnciensLancee = true;

    final snapshot = await _firestore
        .collection(FirestorePaths.mouvements)
        .orderBy('date', descending: true)
        .limit(500)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final valeur = (data['effectuePar'] as String?) ?? '';

      // Un nom affichable contient un espace, un accent, un '@' (email)
      // ou un point. Un UID Firebase est un jeton alphanumérique pur :
      // si la valeur contient un de ces séparateurs, c'est déjà lisible.
      if (valeur.isEmpty ||
          valeur == 'Utilisateur inconnu' ||
          _regExpNomOuMail.hasMatch(valeur)) {
        continue;
      }

      final profilDoc = await _firestore
          .collection(FirestorePaths.users)
          .doc(valeur)
          .get();
      if (!profilDoc.exists) continue;

      final profil = profilDoc.data() ?? {};
      final nom = ('${profil['prenom'] ?? ''} ${profil['nom'] ?? ''}').trim();
      if (nom.isEmpty) continue;

      await doc.reference.update({'effectuePar': nom});
    }
  }
}
