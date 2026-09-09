import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/produit_liquide_model.dart';
import '../../models/produit_solide_model.dart';
import '../../services/stock_service.dart';
import '../../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stockService = StockService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            // Rappel : pas besoin de gérer la redirection ici non plus,
            // AuthGate dans main.dart la fait automatiquement dès que
            // authStateChanges détecte la déconnexion.
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _CarteStockLiquide(stream: stockService.watchStockLiquide()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CarteStockSolide(stream: stockService.watchStockSolide()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Accès rapide',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true, // permet à cette grille de vivre dans un ListView scrollable
            physics: const NeverScrollableScrollPhysics(), // le ListView parent gère le scroll
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: const [
              _RaccourciCard(icone: Icons.water_drop_outlined, titre: 'Stock liquide'),
              _RaccourciCard(icone: Icons.inventory_2_outlined, titre: 'Stock solide'),
              _RaccourciCard(icone: Icons.people_outline, titre: 'Personnel'),
              _RaccourciCard(icone: Icons.history, titre: 'Mouvements'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte "Stock liquide" : écoute le stream, calcule le total, et
/// prépare aussi la liste des produits en alerte pour ce type.
class _CarteStockLiquide extends StatelessWidget {
  final Stream<List<ProduitLiquideModel>> stream;

  const _CarteStockLiquide({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProduitLiquideModel>>(
      stream: stream,
      builder: (context, snapshot) {
        final produits = snapshot.data ?? [];

        // .fold(valeurDeDepart, (accumulateur, element) => nouvelleValeur)
        // Parcourt chaque produit et additionne sa quantité au total.
        final total = produits.fold<double>(0, (somme, p) => somme + p.quantite);

        final nbAlertes = produits.where((p) => p.enAlerte).length;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.vertClairBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Stock liquide',
                  style: TextStyle(fontSize: 12, color: AppColors.succes)),
              const SizedBox(height: 4),
              Text('${total.toStringAsFixed(0)} L',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.succes)),
              if (nbAlertes > 0) ...[
                const SizedBox(height: 6),
                Text('$nbAlertes en alerte',
                    style: const TextStyle(fontSize: 11, color: AppColors.danger)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CarteStockSolide extends StatelessWidget {
  final Stream<List<ProduitSolideModel>> stream;

  const _CarteStockSolide({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProduitSolideModel>>(
      stream: stream,
      builder: (context, snapshot) {
        final produits = snapshot.data ?? [];
        final total = produits.fold<double>(0, (somme, p) => somme + p.quantite);
        final nbAlertes = produits.where((p) => p.enAlerte).length;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.alerteBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Stock solide',
                  style: TextStyle(fontSize: 12, color: AppColors.alerte)),
              const SizedBox(height: 4),
              Text('${total.toStringAsFixed(0)} pcs',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.alerte)),
              if (nbAlertes > 0) ...[
                const SizedBox(height: 6),
                Text('$nbAlertes en alerte',
                    style: const TextStyle(fontSize: 11, color: AppColors.danger)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RaccourciCard extends StatelessWidget {
  final IconData icone;
  final String titre;

  const _RaccourciCard({required this.icone, required this.titre});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: on branchera la navigation vers chaque écran
          // dès qu'on les aura créés (stock, personnel, mouvements).
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: AppColors.vertSapin, size: 26),
              const Spacer(),
              Text(titre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}