import 'package:cloud_firestore/cloud_firestore.dart';

class ProduitSolideModel {
  final String id;
  final String nom; // ex: "Curcuma 144"
  final double grammage; // ex: 144
  final bool parfume; // true/false, sans distinction du type de parfum
  final String usage;
  final double quantite;
  final double seuilAlerte;
  final double prixUnitaire;
  final double prixDeGros;
  final DateTime dateMaj;
  final String majPar;

  ProduitSolideModel({
    required this.id,
    required this.nom,
    required this.grammage,
    required this.parfume,
    required this.usage,
    required this.quantite,
    required this.seuilAlerte,
    required this.prixUnitaire,
    required this.prixDeGros,
    required this.dateMaj,
    required this.majPar,
  });

  bool get enAlerte => quantite <= seuilAlerte;

  factory ProduitSolideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProduitSolideModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      grammage: (data['grammage'] ?? 0).toDouble(),
      parfume: data['parfume'] ?? false,
      usage: data['usage'] ?? '',
      quantite: (data['quantite'] ?? 0).toDouble(),
      seuilAlerte: (data['seuilAlerte'] ?? 0).toDouble(),
      prixUnitaire: (data['prixUnitaire'] ?? 0).toDouble(),
      prixDeGros: (data['prixDeGros'] ?? 0).toDouble(),
      dateMaj: (data['dateMaj'] as Timestamp?)?.toDate() ?? DateTime.now(),
      majPar: data['majPar'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'grammage': grammage,
      'parfume': parfume,
      'usage': usage,
      'quantite': quantite,
      'seuilAlerte': seuilAlerte,
      'prixUnitaire': prixUnitaire,
      'prixDeGros': prixDeGros,
      'dateMaj': Timestamp.fromDate(dateMaj),
      'majPar': majPar,
    };
  }
}