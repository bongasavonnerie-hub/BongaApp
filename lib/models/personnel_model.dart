import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutPersonnel { actif, inactif }

class PersonnelModel {
  final String id;
  final String nom;
  final String prenom;
  final String poste;
  final String contrat;
  final DateTime dateEmbauche;
  final StatutPersonnel statut;

  PersonnelModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.poste,
    required this.contrat,
    required this.dateEmbauche,
    this.statut = StatutPersonnel.actif,
  });

  factory PersonnelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonnelModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      poste: data['poste'] ?? '',
      contrat: data['contrat'] ?? 'Pas disponible',
      dateEmbauche: (data['dateEmbauche'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: (data['statut'] == 'inactif') ? StatutPersonnel.inactif : StatutPersonnel.actif,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'prenom': prenom,
      'poste': poste,
      'contrat': contrat,
      'dateEmbauche': Timestamp.fromDate(dateEmbauche),
      'statut': statut == StatutPersonnel.inactif ? 'inactif' : 'actif',
    };
  }
}