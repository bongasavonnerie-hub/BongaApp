import 'package:cloud_firestore/cloud_firestore.dart';

class ProduitLiquideModel {
  final String id;
  final String nom; // ex: "Citron & Pomme" — le parfum EST le nom, ici
  final double contenance; // taille d'UNE bouteille, ex: 5
  final String uniteContenance; // "L"
  final String usage; // "Ménage", "Douche"...
  final double quantite; // NOMBRE de bouteilles en stock
  final double seuilAlerte;
  final double prixUnitaire;
  final double prixDeGros;
  final DateTime dateMaj;
  final String majPar;

  ProduitLiquideModel ({
    required this.id,
    required this.nom,
    required this.contenance,
    required this.uniteContenance,
    required this.usage,
    required this.quantite,
    required this.seuilAlerte,
    required this.prixUnitaire,
    required this.prixDeGros,
    required this.dateMaj,
    required this.majPar,
  });

   // Utile pour l'écran dashboard : true si on est sous le seuil défini
   bool get enAlerte => quantite <=seuilAlerte;

  factory  ProduitLiquideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProduitLiquideModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      // .toDouble() : Firestore peut stocker un nombre comme "int" ou "double"
      // selon comment tu l'as tapé dans la console. On force toujours en
      // double pour ne jamais avoir de surprise de type dans le code.
      contenance: (data['contenance'] ?? 0).toDouble(),
      uniteContenance: data['uniteContenance'] ?? 'L',
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
      'contenance': contenance,
      'uniteContenance': uniteContenance,
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