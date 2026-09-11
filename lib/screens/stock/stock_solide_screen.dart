import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/produit_solide_model.dart';
import '../../models/mouvement_model.dart';
import '../../services/stock_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/bonga_background.dart';
import '../../widgets/stat_flottante.dart';

class StockSolideScreen extends StatelessWidget {
  const StockSolideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stockService = StockService();

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- EN-TÊTE DÉGRADÉ ----------
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Stack(
                children: [
                  const SizedBox(
                    height: 200,
                    child: BongaBackground(),
                  ),
                  Positioned(
                    top: 50,
                    left: 4,
                    right: 20,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Stock solide',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------- CARTES STATS FLOTTANTES ----------
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: StatFlottante(
                        icone: Icons.inventory_2,
                        couleurIcone: AppColors.terracotta,
                        label: 'Total en stock',
                        streamTotal: stockService.watchStockSolide(),
                        extraireTotal: (produits) =>
                            produits.fold<double>(0, (s, p) => s + p.quantite),
                        suffixe: 'pcs',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatFlottante(
                        icone: Icons.warning_amber_rounded,
                        couleurIcone: AppColors.danger,
                        label: 'En alerte',
                        streamTotal: stockService.watchStockSolide(),
                        extraireTotal: (produits) => produits
                            .where((p) => p.enAlerte)
                            .length
                            .toDouble(),
                        suffixe: '',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ---------- LISTE DES PRODUITS ----------
            StreamBuilder<List<ProduitSolideModel>>(
              stream: stockService.watchStockSolide(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Erreur de chargement : ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final produits = snapshot.data!;

                if (produits.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Aucun produit pour le moment.')),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final produit in produits)
                        _CarteProduit(
                          produit: produit,
                          stockService: stockService,
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.vertSapin,
        onPressed: () => _ouvrirFormulaireAjout(context, stockService),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _ouvrirFormulaireAjout(BuildContext context, StockService stockService) {
    showDialog(
      context: context,
      builder: (_) => _FormulaireProduitSolide(stockService: stockService),
    );
  }
}

class _CarteProduit extends StatelessWidget {
  final ProduitSolideModel produit;
  final StockService stockService;

  const _CarteProduit({required this.produit, required this.stockService});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _ouvrirFormulaireMouvement(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icône dans un cercle bleu (couleur associée au liquide),
              // même motif que sur le dashboard pour rester cohérent.
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bleuFleur.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: AppColors.bleuFleur,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Row avec des "pilules" (petits badges arrondis) pour
                    // la contenance et l'usage, plus visuel qu'un simple texte.
                    Row(
                      children: [
                        _Pilule(
                          texte: '${produit.grammage.toStringAsFixed(0)} g',
                        ),
                        const SizedBox(width: 6),
                        _Pilule(texte: produit.usage),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    produit.quantite.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: produit.enAlerte
                          ? AppColors.danger
                          : AppColors.succes,
                    ),
                  ),
                  if (produit.enAlerte)
                    const Text(
                      'Seuil bas',
                      style: TextStyle(fontSize: 10, color: AppColors.danger),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ouvrirFormulaireMouvement(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          _FormulaireMouvement(produit: produit, stockService: stockService),
    );
  }
}

/// Petit badge arrondi ("pilule") pour afficher une info courte de
/// façon compacte et visuellement distincte du texte normal.
class _Pilule extends StatelessWidget {
  final String texte;

  const _Pilule({required this.texte});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.creme,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texte,
        style: const TextStyle(fontSize: 10, color: AppColors.texteSecondaire),
      ),
    );
  }
}

/// Formulaire d'ajout d'un NOUVEAU produit solide.
class _FormulaireProduitSolide extends StatefulWidget {
  final StockService stockService;

  const _FormulaireProduitSolide({required this.stockService});

  @override
  State<_FormulaireProduitSolide> createState() =>
      _FormulaireProduitSolideState();
}

class _FormulaireProduitSolideState extends State<_FormulaireProduitSolide> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _grammageController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _seuilController = TextEditingController();
  final _usageController = TextEditingController();
  bool _parfume = false; // état de l'interrupteur, pas un TextEditingController
  bool _envoi = false;

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _envoi = true);

    final uid = AuthService().currentUser?.uid ?? '';

    final produit = ProduitSolideModel(
      id: '',
      nom: _nomController.text.trim(),
      grammage: double.parse(_grammageController.text),
      parfume: _parfume,
      usage: _usageController.text.trim(),
      quantite: double.parse(_quantiteController.text),
      seuilAlerte: double.parse(_seuilController.text),
      prixUnitaire: 0,
      prixDeGros: 0,
      dateMaj: DateTime.now(),
      majPar: uid,
    );

    await widget.stockService.ajouterProduitSolide(produit);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau produit solide'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom (ex: Curcuma 144)',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _grammageController,
                decoration: const InputDecoration(labelText: 'Grammage (g)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? 'Nombre invalide'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantiteController,
                decoration: const InputDecoration(
                  labelText: 'Quantité initiale',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? 'Nombre invalide'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _seuilController,
                decoration: const InputDecoration(labelText: 'Seuil d\'alerte'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? 'Nombre invalide'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usageController,
                decoration: const InputDecoration(
                  labelText: 'Usage (ex: Corps)',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              // SwitchListTile combine un texte + un interrupteur sur une
              // même ligne, pratique pour un simple booléen dans un formulaire.
              SwitchListTile(
                title: const Text('Parfumé'),
                value: _parfume,
                activeThumbColor: AppColors.vertSapin,
                contentPadding: EdgeInsets.zero,
                onChanged: (valeur) => setState(() => _parfume = valeur),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _envoi ? null : _enregistrer,
          child: _envoi
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajouter'),
        ),
      ],
    );
  }
}

/// Formulaire pour enregistrer une ENTRÉE ou SORTIE sur un produit existant.
class _FormulaireMouvement extends StatefulWidget {
  final ProduitSolideModel produit;
  final StockService stockService;

  const _FormulaireMouvement({
    required this.produit,
    required this.stockService,
  });

  @override
  State<_FormulaireMouvement> createState() => _FormulaireMouvementState();
}

class _FormulaireMouvementState extends State<_FormulaireMouvement> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteController = TextEditingController();
  final _motifController = TextEditingController();
  TypeMouvement _type = TypeMouvement.sortie;
  bool _envoi = false;
  String? _erreur;

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    final nomAffichage = await AuthService().getNomAffichage();

    try {
      await widget.stockService.enregistrerMouvementSolide(
        produit: widget.produit,
        type: _type,
        quantite: double.parse(_quantiteController.text),
        motif: _motifController.text.trim(),
        effectuePar: nomAffichage,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.produit.nom),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stock actuel : ${widget.produit.quantite.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 12),
            SegmentedButton<TypeMouvement>(
              segments: const [
                ButtonSegment(
                  value: TypeMouvement.entree,
                  label: Text('Entrée'),
                ),
                ButtonSegment(
                  value: TypeMouvement.sortie,
                  label: Text('Sortie'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (nouveauSet) =>
                  setState(() => _type = nouveauSet.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantiteController,
              decoration: const InputDecoration(labelText: 'Quantité'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || double.tryParse(v) == null)
                  ? 'Nombre invalide'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motifController,
              decoration: const InputDecoration(labelText: 'Motif'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Champ requis' : null,
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 8),
              Text(
                _erreur!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _envoi ? null : _enregistrer,
          child: _envoi
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Valider'),
        ),
      ],
    );
  }
}
