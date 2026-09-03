import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final doc = await _firestore.collection(FirestorePaths.users).doc(uid).get();

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
}