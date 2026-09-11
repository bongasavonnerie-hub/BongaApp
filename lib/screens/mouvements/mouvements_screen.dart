import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../models/mouvement_model.dart';
import '../../services/stock_service.dart';
import '../../widgets/badge_auteur.dart';

// Enum utilisé UNIQUEMENT pour piloter l'affichage du filtre dans cet
// écran — à ne pas confondre avec TypeMouvement (qui vient du modèle
// et représente une vraie donnée Firestore). "tous" n'existe pas dans
// la base, c'est un état d'interface uniquement.
enum _FiltreMouvement { tous, entrees, sorties }

// StatefulWidget car cet écran a un état qui change sans recharger
// Firestore : le filtre sélectionné, gardé uniquement en mémoire locale.
class MouvementsScreen extends StatefulWidget {
  const MouvementsScreen({super.key});

  @override
  State<MouvementsScreen> createState() => _MouvementsScreenState();
}

class _MouvementsScreenState extends State<MouvementsScreen> {
  final _stockService = StockService();
  _FiltreMouvement _filtreActuel = _FiltreMouvement.tous;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des mouvements')),
      body: Column(
        children: [
          // ---------- BARRE DE FILTRES ----------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _chipFiltre('Tous', _FiltreMouvement.tous),
                const SizedBox(width: 8),
                _chipFiltre('Entrées', _FiltreMouvement.entrees),
                const SizedBox(width: 8),
                _chipFiltre('Sorties', _FiltreMouvement.sorties),
              ],
            ),
          ),

          // ---------- LISTE (occupe le reste de l'écran) ----------
          // Expanded est indispensable ici : sans lui, un StreamBuilder
          // placé directement dans une Column (qui n'a pas de hauteur
          // fixe) provoque une erreur "hauteur infinie".
          Expanded(
            child: StreamBuilder<List<MouvementModel>>(
              stream: _stockService.watchMouvements(limite: 100),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // On applique le filtre choisi sur la liste complète
                // reçue de Firestore. .where() garde uniquement les
                // éléments qui respectent la condition donnée.
                final mouvements = snapshot.data!.where((m) {
                  switch (_filtreActuel) {
                    case _FiltreMouvement.entrees:
                      return m.type == TypeMouvement.entree;
                    case _FiltreMouvement.sorties:
                      return m.type == TypeMouvement.sortie;
                    case _FiltreMouvement.tous:
                      return true; // aucun filtre, tout est gardé
                  }
                }).toList();

                if (mouvements.isEmpty) {
                  return const Center(
                    child: Text('Aucun mouvement pour ce filtre.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: mouvements.length,
                  itemBuilder: (context, index) =>
                      _CarteMouvement(mouvement: mouvements[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Petite fonction "fabrique" qui construit un ChoiceChip identique
  // pour chaque filtre, en ne changeant que le texte et la valeur —
  // évite de copier-coller 3 fois le même bloc de code.
  Widget _chipFiltre(String texte, _FiltreMouvement valeur) {
    final estSelectionne = _filtreActuel == valeur;

    return ChoiceChip(
      label: Text(texte),
      selected: estSelectionne,
      selectedColor: AppColors.vertSapin,
      labelStyle: TextStyle(
        color: estSelectionne ? Colors.white : AppColors.navy,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.creme,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      // onSelected est appelé au clic. On ignore le booléen "selected"
      // fourni automatiquement, et on force plutôt NOTRE valeur, car
      // on veut un choix unique (comme des boutons radio), pas une
      // sélection à bascule indépendante comme le ferait un vrai groupe
      // de checkboxes.
      onSelected: (_) => setState(() => _filtreActuel = valeur),
    );
  }
}

/// Une ligne représentant un mouvement dans l'historique complet.
/// Volontairement plus détaillée que la version "aperçu" du dashboard
/// (on y ajoute la date complète, absente de l'aperçu).
class _CarteMouvement extends StatelessWidget {
  final MouvementModel mouvement;

  const _CarteMouvement({required this.mouvement});

  // Transforme un DateTime brut en texte lisible, ex: "10/09/2026 à 14:32".
  // padLeft(2, '0') ajoute un zéro devant si le nombre n'a qu'un chiffre
  // (ex: "9" devient "09"), pour un format d'heure toujours cohérent.
  String _formaterDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year} à $heure:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final estEntree = mouvement.type == TypeMouvement.entree;
    final estLiquide = mouvement.produitType == TypeProduitMouvement.liquide;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.vertSapin.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Icône combinant DEUX informations en une seule pastille :
          // la couleur/flèche indique entrée ou sortie, et l'icône de
          // fond (eau/boîte) rappelle le type de produit.
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (estEntree ? AppColors.succes : AppColors.terracotta)
                  .withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              estEntree ? Icons.login : Icons.logout,
              color: estEntree ? AppColors.succes : AppColors.terracotta,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Expanded : force cette colonne à occuper tout l'espace
          // restant entre l'icône (taille fixe) et la quantité (taille
          // fixe) — sans lui, le texte long du motif pourrait déborder
          // hors de l'écran au lieu de passer à la ligne.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      estLiquide ? Icons.water_drop : Icons.inventory_2,
                      size: 12,
                      color: AppColors.texteSecondaire,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mouvement.produitNom,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow
                            .ellipsis, // coupe avec "..." si trop long
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mouvement.motif,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.texteSecondaire,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formaterDate(mouvement.date),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.texteSecondaire,
                  ),
                ),
                const SizedBox(height: 3),
                BadgeAuteur(
                  nom: mouvement.effectuePar,
                  estEntree: estEntree,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${estEntree ? '+' : '-'}${mouvement.quantite.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: estEntree ? AppColors.succes : AppColors.terracotta,
                ),
              ),
              // Bouton compact ouvrant le formulaire de correction. IconButton
              // seul suffirait, mais un TextButton avec icône+texte est plus
              // explicite pour une action pas encore familière à l'utilisateur.
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) =>
                      _FormulaireCorrection(mouvementOriginal: mouvement),
                ),
                icon: const Icon(Icons.undo, size: 14),
                label: const Text('Corriger', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 24),
                  foregroundColor: AppColors.texteSecondaire,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formulaire de correction : pré-rempli avec la quantité du mouvement
/// d'origine (l'utilisateur peut l'ajuster), et enregistre un mouvement
/// du type INVERSE via StockService.corrigerMouvement.
class _FormulaireCorrection extends StatefulWidget {
  final MouvementModel mouvementOriginal;

  const _FormulaireCorrection({required this.mouvementOriginal});

  @override
  State<_FormulaireCorrection> createState() => _FormulaireCorrectionState();
}

class _FormulaireCorrectionState extends State<_FormulaireCorrection> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantiteController;
  final _motifController = TextEditingController(
    text: 'Correction erreur de saisie',
  );
  TypeMouvement _type = TypeMouvement.sortie;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    // Pré-remplit avec la MÊME quantité que l'original : dans le cas
    // le plus courant (annulation complète d'une erreur), l'utilisateur
    // n'a rien à changer, juste à valider.
    _quantiteController = TextEditingController(
      text: widget.mouvementOriginal.quantite.toStringAsFixed(0),
    );
    // Pré-sélectionne le type INVERSE de l'original : c'est le cas le
    // plus fréquent (annuler un mouvement erroné). L'utilisateur peut
    // le changer s'il s'est trompé sur le type aussi.
    _type = widget.mouvementOriginal.type == TypeMouvement.entree
        ? TypeMouvement.sortie
        : TypeMouvement.entree;
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      final nomAffichage = await AuthService().getNomAffichage();

      await StockService().corrigerMouvement(
        mouvementOriginal: widget.mouvementOriginal,
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
    final original = widget.mouvementOriginal;
    final estEntreeOriginale = original.type == TypeMouvement.entree;

    return AlertDialog(
      title: const Text('Corriger ce mouvement'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mouvement d\'origine : ${estEntreeOriginale ? 'Entrée' : 'Sortie'} de '
              '${original.quantite.toStringAsFixed(0)} (${original.produitNom})',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.texteSecondaire,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choisis le type de mouvement correcteur :',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantiteController,
              decoration: const InputDecoration(
                labelText: 'Quantité à corriger',
              ),
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
              : const Text('Valider la correction'),
        ),
      ],
    );
  }
}
