import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/produit_liquide_model.dart';
import '../../models/produit_solide_model.dart';
import '../../models/mouvement_model.dart';
import '../../models/personnel_model.dart';
import '../../services/stock_service.dart';
import '../../services/personnel_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/bonga_background.dart';
import '../stock/stock_liquide_screen.dart';
import '../stock/stock_solide_screen.dart';
import '../personnel/personnel_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stockService = StockService();
    final personnelService = PersonnelService();

    // Scaffold sans AppBar cette fois : notre en-tête personnalisé
    // (dégradé) remplace la barre du haut classique.
    return Scaffold(
      backgroundColor: AppColors.creme,
      // SingleChildScrollView : tout l'écran défile d'un bloc (en-tête
      // compris), contrairement à avant où seul le contenu sous l'AppBar
      // défilait.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- EN-TÊTE DÉGRADÉ ----------
            // ClipRRect + coins arrondis en bas seulement : donne l'effet
            // "bannière" qui se termine en douceur sur le fond crème.
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Stack(
                children: [
                  // Notre widget de fond dégradé + bulles, réutilisé tel quel
                  const SizedBox(
                    height: 240,
                    child: BongaBackground(),
                  ),
                  // Contenu par-dessus le dégradé : titre + bouton déconnexion
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonga Savonnerie',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Vue d\'ensemble du stock',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () => AuthService().signOut(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------- CARTES STATS "FLOTTANTES" ----------
            // Transform.translate remonte ce bloc pour qu'il chevauche
            // le bas de l'en-tête dégradé (offset négatif en Y = vers le haut).
            // dy: -40 veut dire "40 pixels plus haut que sa position normale".
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatFlottante(
                        icone: Icons.water_drop,
                        couleurIcone: AppColors.bleuFleur,
                        label: 'Stock liquide',
                        streamTotal: stockService.watchStockLiquide(),
                        extraireTotal: (produits) => (produits as List<ProduitLiquideModel>)
                            .fold<double>(0, (s, p) => s + p.quantite),
                        suffixe: 'unités',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatFlottante(
                        icone: Icons.inventory_2,
                        couleurIcone: AppColors.terracotta,
                        label: 'Stock solide',
                        streamTotal: stockService.watchStockSolide(),
                        extraireTotal: (produits) => (produits as List<ProduitSolideModel>)
                            .fold<double>(0, (s, p) => s + p.quantite),
                        suffixe: 'unités',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------- ACCÈS RAPIDE ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Accès rapide',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 17),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _RaccourciCardRiche(
                    icone: Icons.water_drop_outlined,
                    titre: 'Stock liquide',
                    couleur: AppColors.bleuFleur,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StockLiquideScreen())),
                  ),
                  _RaccourciCardRiche(
                    icone: Icons.inventory_2_outlined,
                    titre: 'Stock solide',
                    couleur: AppColors.terracotta,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StockSolideScreen())),
                  ),
                  // StreamBuilder ici aussi, pour afficher le NOMBRE de
                  // membres du personnel directement sur la carte, comme
                  // un vrai compteur, pas juste un raccourci muet.
                  StreamBuilder<List<PersonnelModel>>(
                    stream: personnelService.watchPersonnel(),
                    builder: (context, snapshot) {
                      final nb = snapshot.data?.length ?? 0;
                      return _RaccourciCardRiche(
                        icone: Icons.people_outline,
                        titre: 'Personnel',
                        sousTitre: '$nb membre${nb > 1 ? 's' : ''}',
                        couleur: AppColors.vertSapin,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PersonnelScreen())),
                      );
                    },
                  ),
                  const _RaccourciCardRiche(
                    icone: Icons.history,
                    titre: 'Mouvements',
                    couleur: AppColors.taupe,
                    // onTap absent pour l'instant : écran pas encore créé
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------- DERNIERS MOUVEMENTS ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Derniers mouvements',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 17),
              ),
            ),
            StreamBuilder<List<MouvementModel>>(
              // On ne demande que les 4 plus récents ici : un simple
              // aperçu, pas l'historique complet (ce sera l'écran dédié).
              stream: stockService.watchMouvements(limite: 4),
              builder: (context, snapshot) {
                final mouvements = snapshot.data ?? [];

                if (mouvements.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Aucun mouvement enregistré.',
                        style: TextStyle(color: AppColors.texteSecondaire)),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: mouvements.map((m) => _LigneMouvement(mouvement: m)).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Carte translucide affichant un total en temps réel, conçue pour être
/// posée par-dessus le dégradé (fond blanc semi-transparent).
/// Générique : on lui passe le stream et une fonction qui sait calculer
/// le total à partir de N'IMPORTE QUELLE liste (liquide OU solide),
/// ce qui évite d'écrire deux fois presque le même widget.
class _StatFlottante<T> extends StatelessWidget {
  final IconData icone;
  final Color couleurIcone;
  final String label;
  final Stream<List<T>> streamTotal;
  final double Function(List<T>) extraireTotal;
  final String suffixe;

  const _StatFlottante({
    required this.icone,
    required this.couleurIcone,
    required this.label,
    required this.streamTotal,
    required this.extraireTotal,
    required this.suffixe,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: streamTotal,
      builder: (context, snapshot) {
        final total = snapshot.hasData ? extraireTotal(snapshot.data!) : 0.0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // Une ombre légère (pas dans notre charte habituelle, mais
            // nécessaire ici pour que la carte blanche se détache
            // clairement du fond crème juste en dessous).
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icône dans un cercle de couleur : motif qu'on va
              // réutiliser partout pour un rendu plus riche.
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleurIcone.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: couleurIcone, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(fontSize: 11, color: AppColors.texteSecondaire)),
                    Text(
                      total.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Carte d'accès rapide enrichie : icône dans un cercle coloré,
/// titre, et sous-titre optionnel (ex: nombre d'éléments).
class _RaccourciCardRiche extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? sousTitre;
  final Color couleur;
  final VoidCallback? onTap;

  const _RaccourciCardRiche({
    required this.icone,
    required this.titre,
    required this.couleur,
    this.sousTitre,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: couleur, size: 20),
              ),
              const Spacer(),
              Text(titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (sousTitre != null) ...[
                const SizedBox(height: 2),
                Text(sousTitre!,
                    style: const TextStyle(fontSize: 11, color: AppColors.texteSecondaire)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Une ligne compacte représentant un mouvement de stock (entrée/sortie),
/// utilisée dans l'aperçu "Derniers mouvements" du dashboard.
class _LigneMouvement extends StatelessWidget {
  final MouvementModel mouvement;

  const _LigneMouvement({required this.mouvement});

  @override
  Widget build(BuildContext context) {
    final estEntree = mouvement.type == TypeMouvement.entree;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vertSapin.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(
            estEntree ? Icons.arrow_downward : Icons.arrow_upward,
            size: 16,
            color: estEntree ? AppColors.succes : AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mouvement.produitNom,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text(mouvement.motif,
                    style: const TextStyle(fontSize: 11, color: AppColors.texteSecondaire)),
              ],
            ),
          ),
          Text(
            '${estEntree ? '+' : '-'}${mouvement.quantite.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: estEntree ? AppColors.succes : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}