import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeMouvement { entree, sortie }

enum TypeProduitMouvement { liquide, solide }

class MouvementModel {
  final String id;
  final String produitId;
  final String produitNom;
  final TypeProduitMouvement produitType;
  final TypeMouvement type;
  final double quantite;
  final String motif;
  final DateTime date;
  final String effectuePar;

  MouvementModel ({
    required this.id,
    required this.produitId,
    required this.produitNom,
    required this.produitType,
    required this.type,
    required this.quantite,
    required this.motif,
    required this.date,
    required this.effectuePar,
  });

  factory MouvementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MouvementModel(
      id: doc.id, 
      produitId: data['produitId'] ?? '', 
      produitNom: data['produitNom'], 
      produitType: (data['produitType'] == 'liquide')
      ? TypeProduitMouvement.liquide
      : TypeProduitMouvement.solide, 
      type: (data['type'] == 'entre') ? TypeMouvement.entree :TypeMouvement.sortie,
      quantite: (data['quantite'] ?? 0).toDouble(), 
      motif: data['motif'] ?? '', 
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      effectuePar: data['effectuePar'] ?? '',
    );
  }
}