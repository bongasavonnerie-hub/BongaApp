import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //

import '../constants/firestore_paths.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ce "Stream" (flux continu) émet une nouvelle valeur à chaque changement
  // d'état de connexion : connexion, déconnexion, expiration de session...
  // C'est ce qui permettra à l'app de rediriger automatiquement vers
  // l'écran de connexion ou le dashboard, sans code manuel de navigation.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Raccourci pratique pour récupérer l'utilisateur Firebase Auth actuel
  // (juste son UID/email, pas encore son profil Firestore complet)
  User? get currentUser => _auth.currentUser;

  /// Connexion avec email/mot de passe.
  /// Retourne le profil COMPLET (Firestore), pas juste l'objet Auth,
  /// car c'est le profil complet dont l'app a besoin partout ailleurs.
  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) return null;

    return getUserProfile(credential.user!.uid);
  }

  Future<void> signOut() => _auth.signOut();

  /// Va chercher le document users/{uid} correspondant et le transforme
  /// en UserModel grâce à la méthode fromFirestore qu'on a écrite avant.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  /// Vérifie le VRAI statut admin, lu depuis le token d'authentification
  /// (custom claim), pas depuis un champ Firestore modifiable.
  /// `true` force le rafraîchissement du token pour être sûr d'avoir
  /// la dernière version (utile si le rôle vient d'être changé par
  /// un autre admin, par exemple).
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final idTokenResult = await user.getIdTokenResult(true);
    return idTokenResult.claims?['role'] == 'admin';
  }

  /// Version "stream" de getUserProfile : au lieu de lire une fois,
  /// écoute EN CONTINU le document users/{uid}. Utile pour l'en-tête
  /// du dashboard, qui doit refléter en temps réel un changement de
  /// rôle (ex: si un autre admin te promeut pendant que l'app est ouverte).
  Stream<UserModel?> watchUserProfile(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// Modifie le nom/prénom stocké dans Firestore. Ne touche PAS à
  /// Firebase Auth (qui ne connaît que l'email/mot de passe, pas le nom).
  Future<void> updateNomPrenom({
    required String nom,
    required String prenom,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('Aucun utilisateur connecté.');

    await _firestore.collection(FirestorePaths.users).doc(uid).update({
      'nom': nom,
      'prenom': prenom,
    });
  }

  /// Change le mot de passe, après ré-authentification obligatoire.
  Future<void> changerMotDePasse({
    required String motDePasseActuel,
    required String nouveauMotDePasse,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Aucun utilisateur connecté.');
    }

    // EmailAuthProvider.credential recrée une "preuve d'identité" à
    // partir de l'email + mot de passe ACTUEL (celui que l'utilisateur
    // vient de retaper), qu'on soumet pour prouver que c'est bien lui.
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: motDePasseActuel,
    );

    // reauthenticateWithCredential vérifie ce mot de passe actuel
    // auprès de Firebase. Si le mot de passe est faux, ça lève une
    // exception ici, AVANT même de tenter le changement.
    await user.reauthenticateWithCredential(credential);

    await user.updatePassword(nouveauMotDePasse);
  }

  /// Si le document users/{uid} n'existe pas encore pour ce compte
  /// (typiquement un compte créé dans Firebase Auth sans profil
  /// Firestore associé), on en crée un minimal automatiquement, en
  /// rôle "standard" par défaut — JAMAIS "admin" automatiquement,
  /// ce serait une faille de sécurité (n'importe qui pourrait se
  /// connecter et se retrouver admin).
  Future<void> ensureUserProfileExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection(FirestorePaths.users).doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'nom': '',
        'prenom': '',
        'email': user.email ?? '',
        'role': 'standard',
        'actif': true,
        'dateCreation': Timestamp.now(),
      });
    }
  }

  /// Renvoie "Prénom Nom" de l'utilisateur connecté, ou son email en
  /// secours si le profil Firestore n'a pas encore de nom renseigné.
  Future<String> getNomAffichage() async {
    final uid = currentUser?.uid;
    if (uid == null) return 'Utilisateur inconnu';

    final profil = await getUserProfile(uid);
    if (profil == null || (profil.nom.isEmpty && profil.prenom.isEmpty)) {
      return currentUser?.email ?? 'Utilisateur inconnu';
    }
    return '${profil.prenom} ${profil.nom}'.trim();
  }
}
