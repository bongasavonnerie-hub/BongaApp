import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/produit_liquide_model.dart';
import '../models/produit_solide_model.dart';
import '../models/mouvement_model.dart';

class StockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- LECTURE (streams temps réel) ----------

  /// Stream = flux continu. Contrairement à un simple "get()" qui lit une
  /// fois, ce stream réémet automatiquement une nouvelle liste à chaque
  /// changement dans Firestore (ex: un autre membre modifie une quantité
  /// pendant que tu regardes l'écran → l'affichage se met à jour tout seul).
  Stream<List<ProduitLiquideModel>> watchStockLiquide() {
    return _firestore
        .collection(FirestorePaths.stockLiquide)
        .orderBy('nom')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProduitLiquideModel.fromFirestore(doc)).toList());
  }

  Stream<List<ProduitSolideModel>> watchStockSolide() {
    return _firestore
        .collection(FirestorePaths.stockSolide)
        .orderBy('nom')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProduitSolideModel.fromFirestore(doc)).toList());
  }

  // ---------- CRÉATION / MODIFICATION / SUPPRESSION ----------
  // Ces opérations simples (pas de transaction nécessaire) servent à la
  // FICHE produit elle-même (nom, prix, seuil...), pas aux mouvements
  // de quantité au quotidien — ça, c'est enregistrerMouvement plus bas.

  Future<void> ajouterProduitLiquide(ProduitLiquideModel produit) {
    return _firestore.collection(FirestorePaths.stockLiquide).add(produit.toFirestore());
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
    return _firestore.collection(FirestorePaths.stockSolide).add(produit.toFirestore());
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

  // ---------- MOUVEMENTS (le cœur du service) ----------

  /// Enregistre une entrée/sortie de stock LIQUIDE de façon sécurisée.
  /// Utilise une transaction : soit tout réussit, soit rien n'est appliqué.
  Future<void> enregistrerMouvementLiquide({
    required ProduitLiquideModel produit,
    required TypeMouvement type,
    required double quantite,
    required String motif,
    required String effectuePar,
  }) async {
    final produitRef =
        _firestore.collection(FirestorePaths.stockLiquide).doc(produit.id);
    // .doc() sans argument = Firestore génère un ID unique à l'avance,
    // même si le document n'est pas encore écrit. Pratique pour préparer
    // la transaction avant de savoir si elle va réussir.
    final mouvementRef = _firestore.collection(FirestorePaths.mouvements).doc();

    await _firestore.runTransaction((transaction) async {
      // On relit la quantité ACTUELLE depuis Firestore, à l'intérieur
      // même de la transaction — jamais celle qu'on avait en mémoire
      // avant. Pourquoi : si quelqu'un d'autre a modifié le stock une
      // fraction de seconde avant toi, il faut partir de la vraie valeur
      // la plus récente, sinon deux sorties simultanées pourraient
      // "s'écraser" l'une l'autre et fausser le compte.
      final snapshot = await transaction.get(produitRef);
      final quantiteActuelle = (snapshot.data()?['quantite'] ?? 0).toDouble();

      final nouvelleQuantite = (type == TypeMouvement.entree)
          ? quantiteActuelle + quantite
          : quantiteActuelle - quantite;

      // Garde-fou : on refuse une sortie qui ferait passer le stock
      // en négatif (ex: sortir 10L alors qu'il n'en reste que 3).
      if (nouvelleQuantite < 0) {
        throw Exception('Quantité insuffisante en stock.');
      }

      transaction.update(produitRef, {
        'quantite': nouvelleQuantite,
        'dateMaj': Timestamp.now(),
        'majPar': effectuePar,
      });

      transaction.set(mouvementRef, {
        'produitId': produit.id,
        'produitNom': produit.nom,
        'produitType': 'liquide',
        'type': type == TypeMouvement.entree ? 'entree' : 'sortie',
        'quantite': quantite,
        'motif': motif,
        'date': Timestamp.now(),
        'effectuePar': effectuePar,
      });
    });
  }

  /// Même logique, pour le stock SOLIDE.
  Future<void> enregistrerMouvementSolide({
    required ProduitSolideModel produit,
    required TypeMouvement type,
    required double quantite,
    required String motif,
    required String effectuePar,
  }) async {
    final produitRef =
        _firestore.collection(FirestorePaths.stockSolide).doc(produit.id);
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
        'produitId': produit.id,
        'produitNom': produit.nom,
        'produitType': 'solide',
        'type': type == TypeMouvement.entree ? 'entree' : 'sortie',
        'quantite': quantite,
        'motif': motif,
        'date': Timestamp.now(),
        'effectuePar': effectuePar,
      });
    });
  }

  /// Historique des mouvements, du plus récent au plus ancien.
  Stream<List<MouvementModel>> watchMouvements({int limite = 50}) {
    return _firestore
        .collection(FirestorePaths.mouvements)
        .orderBy('date', descending: true)
        .limit(limite)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MouvementModel.fromFirestore(doc)).toList());
  }
}