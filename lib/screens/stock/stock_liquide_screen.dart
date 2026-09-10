import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/produit_liquide_model.dart';
import '../../services/stock_service.dart';
import '../../services/auth_service.dart';
import '../../models/mouvement_model.dart';

class StockLiquideScreen extends StatelessWidget {
  const StockLiquideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stockService = StockService();

    return Scaffold(
      appBar: AppBar(title: const Text('Stock liquide')),
      body: StreamBuilder<List<ProduitLiquideModel>>(
        stream: stockService.watchStockLiquide(),
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
            return const Center(child: Text('Aucun produit pour le moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: produits.length,
            itemBuilder: (context, index) {
              final produit = produits[index];
              return _CarteProduit(produit: produit, stockService: stockService);
            },
          );
        },
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
      builder: (_) => _FormulaireProduitLiquide(stockService: stockService),
    );
  }
}

/// Une carte affichant un produit, avec la couleur qui change selon l'alerte.
class _CarteProduit extends StatelessWidget {
  final ProduitLiquideModel produit;
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
                  color: AppColors.bleuFleur.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop, color: AppColors.bleuFleur, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(produit.nom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    // Row avec des "pilules" (petits badges arrondis) pour
                    // la contenance et l'usage, plus visuel qu'un simple texte.
                    Row(
                      children: [
                        _Pilule(texte: '${produit.contenance.toStringAsFixed(0)}${produit.uniteContenance}'),
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
                      color: produit.enAlerte ? AppColors.danger : AppColors.succes,
                    ),
                  ),
                  if (produit.enAlerte)
                    const Text('Seuil bas', style: TextStyle(fontSize: 10, color: AppColors.danger)),
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
      builder: (_) => _FormulaireMouvement(produit: produit, stockService: stockService),
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
      child: Text(texte, style: const TextStyle(fontSize: 10, color: AppColors.texteSecondaire)),
    );
  }
}

/// Formulaire d'ajout d'un NOUVEAU produit (fiche produit, pas un mouvement).
class _FormulaireProduitLiquide extends StatefulWidget {
  final StockService stockService;

  const _FormulaireProduitLiquide({required this.stockService});

  @override
  State<_FormulaireProduitLiquide> createState() => _FormulaireProduitLiquideState();
}

class _FormulaireProduitLiquideState extends State<_FormulaireProduitLiquide> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _contenanceController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _seuilController = TextEditingController();
  final _usageController = TextEditingController();
  bool _envoi = false;

  Future<void> _enregistrer() async {
    // .validate() déclenche TOUS les "validator" définis sur chaque
    // TextFormField ci-dessous, et renvoie false si un seul échoue.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _envoi = true);

    final uid = AuthService().currentUser?.uid ?? '';

    final produit = ProduitLiquideModel(
      id: '', // ignoré par Firestore lors d'un .add() — l'ID est généré côté serveur
      nom: _nomController.text.trim(),
      contenance: double.parse(_contenanceController.text),
      uniteContenance: 'L',
      usage: _usageController.text.trim(),
      quantite: double.parse(_quantiteController.text),
      seuilAlerte: double.parse(_seuilController.text),
      prixUnitaire: 0,
      prixDeGros: 0,
      dateMaj: DateTime.now(),
      majPar: uid,
    );

    await widget.stockService.ajouterProduitLiquide(produit);

    if (mounted) Navigator.of(context).pop(); // ferme la boîte de dialogue
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau produit liquide'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom (ex: Citron & Pomme)'),
                // "validator" retourne un message d'erreur (String) si invalide,
                // ou null si tout va bien. Form.validate() les collecte tous.
                validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _contenanceController,
                decoration: const InputDecoration(labelText: 'Contenance (L)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Nombre invalide' : null,
              ),
              TextFormField(
                controller: _quantiteController,
                decoration: const InputDecoration(labelText: 'Quantité initiale'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Nombre invalide' : null,
              ),
              TextFormField(
                controller: _seuilController,
                decoration: const InputDecoration(labelText: 'Seuil d\'alerte'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Nombre invalide' : null,
              ),
              TextFormField(
                controller: _usageController,
                decoration: const InputDecoration(labelText: 'Usage (ex: Ménage, Douche)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _envoi ? null : _enregistrer,
          child: _envoi
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Ajouter'),
        ),
      ],
    );
  }
}

/// Formulaire pour enregistrer une ENTRÉE ou SORTIE sur un produit existant.
class _FormulaireMouvement extends StatefulWidget {
  final ProduitLiquideModel produit;
  final StockService stockService;

  const _FormulaireMouvement({required this.produit, required this.stockService});

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

    final uid = AuthService().currentUser?.uid ?? '';

    try {
      await widget.stockService.enregistrerMouvementLiquide(
        produit: widget.produit,
        type: _type,
        quantite: double.parse(_quantiteController.text),
        motif: _motifController.text.trim(),
        effectuePar: uid,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Capture notamment l'exception "Quantité insuffisante" levée
      // dans la transaction du StockService.
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
            Text('Stock actuel : ${widget.produit.quantite.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            SegmentedButton<TypeMouvement>(
              segments: const [
                ButtonSegment(value: TypeMouvement.entree, label: Text('Entrée')),
                ButtonSegment(value: TypeMouvement.sortie, label: Text('Sortie')),
              ],
              selected: {_type},
              onSelectionChanged: (nouveauSet) => setState(() => _type = nouveauSet.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantiteController,
              decoration: const InputDecoration(labelText: 'Quantité'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || double.tryParse(v) == null) ? 'Nombre invalide' : null,
            ),
            TextFormField(
              controller: _motifController,
              decoration: const InputDecoration(labelText: 'Motif'),
              validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 8),
              Text(_erreur!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _envoi ? null : _enregistrer,
          child: _envoi
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Valider'),
        ),
      ],
    );
  }
}