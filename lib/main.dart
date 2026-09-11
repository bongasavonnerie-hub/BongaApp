import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/stock_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

Future<void> main() async {
  // Obligatoire avant d'utiliser tout plugin natif (dont Firebase)
  // quand on fait des appels asynchrones avant runApp().
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BongaApp());
}

class BongaApp extends StatelessWidget {
  const BongaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bonga Savonnerie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // le thème qu'on vient de créer, appliqué ici globalement
      home: const AuthGate(),
    );
  }
}

/// Écran "aiguilleur" : n'affiche rien de visuel par lui-même,
/// il regarde juste l'état de connexion et redirige.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Le tout premier instant, Firebase vérifie s'il existe une
        // session déjà sauvegardée sur l'appareil (connexion persistante).
        // Le temps de cette vérification, on affiche un simple loader,
        // sinon l'app "flasherait" l'écran de connexion une fraction de
        // seconde même pour un utilisateur déjà connecté.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // snapshot.hasData = un utilisateur Firebase Auth existe
        if (snapshot.hasData) {
          // Passe de migration (une fois par session) : remplace les UID
          // encore présents dans `effectuePar` des anciens mouvements par
          // le nom du compte, pour que l'historique affiche des noms.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            StockService().migrerAnciensEffectuePar();
          });
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
