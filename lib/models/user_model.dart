import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, standard }

class UserModel {
  final String uid;
  final String nom;
  final String prenom;
  final String email;
  final UserRole role;
  final bool actif;
  final DateTime dateCreation;
  // null = l'utilisateur n'a jamais consulté ses notifications.
  // Chaque utilisateur a SON propre curseur (contrairement à avant où
  // c'était celui de l'appareil) : voir NotificationService.
  final DateTime? derniereLectureNotifications;

  UserModel ({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.actif = true,
    required this.dateCreation,
    this.derniereLectureNotifications,
  });

   // Raccourci pratique : partout où on aura besoin de vérifier
  // "est-ce que cet utilisateur est admin ?", on écrira juste user.isAdmin
  bool get isAdmin => role == UserRole.admin;
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      // doc.id = l'uid du document, qu'on a créé égal à l'UID Auth(rappel)
      uid: doc.id, 
      nom: data['nom'], 
      prenom: data['prenom'], 
      email: data['email'], 
      // Si le champ role est absent ou différent de "admin" l'utilisateur est considéré comme standard
      // Par sécurité vaux mieux sous-estimer les droits que de les sur-estimer
      role: (data['role'] == 'admin') ? UserRole.admin : UserRole.standard, 
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      derniereLectureNotifications:
          (data['derniereLectureNotifications'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom' : nom,
      'prenom': prenom,
      'email' : email,
      'role': role == UserRole.admin ? 'admin' : 'standard',
      'actif' : actif,
      'dateCreation' : Timestamp.fromDate(dateCreation),
    };
  }

}