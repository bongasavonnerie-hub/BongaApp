import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/bonga_background.dart';
import '../../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscureText = true; // true = mot de passe masqué par défaut
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
      body: Stack(
  children: [
    const Positioned.fill(child: BongaBackground()),
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Transform.scale(
                      // scale > 1 = on zoome sur l'image (elle déborde du cadre, mais
                      // ClipOval découpe ce qui dépasse). On pousse ainsi la marge
                      // crème du fichier original hors de la zone visible.
                      // Ajuste cette valeur (1.15, 1.2, 1.25...) jusqu'à ce que
                      // la bande blanche disparaisse complètement sur ton téléphone.
                      scale: 1.2,
                      child: Image.asset(
                      'assets/images/logo.jpeg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                    )
                  ),
                  const SizedBox(height: 32),

                  // Sur fond translucide, on force le texte/icônes en blanc
                  // pour rester lisible malgré le fond dégradé derrière.
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.mail_outline, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText, // lié à l'état, plus figé sur "true"
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                      // suffixIcon : une icône à DROITE du champ (prefixIcon = à gauche)
                      suffixIcon: IconButton(
                        icon: Icon(
                          // On change l'icône elle-même selon l'état actuel :
                          // œil barré si le mdp est masqué, œil normal s'il est visible
                          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          // setState() redessine l'écran avec la nouvelle valeur de _obscureText
                          setState(() => _obscureText = !_obscureText);
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 12),
                    Text(_erreur!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _seConnecter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.vertSapin,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vertSapin),
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
    ),
  ],
),
    );
  }
}