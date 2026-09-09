import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String? _erreur;

  // Important : libérer les controllers quand l'écran est détruit,
  // sinon ils restent en mémoire inutilement (fuite mémoire).
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      await _authService.signIn(
        _emailController.text.trim(), // .trim() enlève les espaces oubliés en début/fin
        _passwordController.text,
      );
      // Pas de navigation ici volontairement — voir explication ci-dessus,
      // AuthGate s'en charge automatiquement via authStateChanges.
    } catch (e) {
      // On affiche un message générique plutôt que l'erreur technique brute,
      // par sécurité (ne jamais révéler si c'est l'email OU le mot de passe
      // qui est faux — ça faciliterait les tentatives de piratage).
      setState(() => _erreur = 'Connexion impossible. Vérifiez vos identifiants.');
    } finally {
      // "finally" s'exécute que ça ait réussi ou échoué — on arrête
      // toujours le chargement, pour ne pas laisser le bouton bloqué.
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bloc visuel façon logo
                  ClipOval(
  child: Image.asset(
    'assets/images/logo.jpeg',
    width: 160,
    height: 160,
    // BoxFit.cover : l'image remplit tout le cercle sans se déformer,
    // quitte à rogner légèrement les bords si le ratio ne correspond
    // pas exactement à un cercle parfait.
    fit: BoxFit.cover,
  ),
),
                  const SizedBox(height: 40),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passwordController,
                    obscureText: true, // masque le mot de passe à l'écran
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),

                  if (_erreur != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _erreur!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // On désactive le bouton pendant le chargement
                      // (onPressed: null = bouton grisé, non cliquable)
                      onPressed: _loading ? null : _seConnecter,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Se connecter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}