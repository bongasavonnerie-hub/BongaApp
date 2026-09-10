import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/personnel_model.dart';
import '../../services/personnel_service.dart';

class PersonnelScreen extends StatelessWidget {
  const PersonnelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final personnelService = PersonnelService();

    // Scaffold = la structure de base d'un écran complet : gère à lui
    // seul la barre du haut (appBar), le contenu principal (body), et
    // les boutons flottants (floatingActionButton) au bon endroit.
    return Scaffold(
      appBar: AppBar(title: const Text('Personnel')),

      // StreamBuilder écoute watchPersonnel() en continu : dès qu'un
      // admin ajoute/modifie un employé (même depuis un autre téléphone),
      // cette liste se met à jour toute seule, sans rien recharger.
      body: StreamBuilder<List<PersonnelModel>>(
        stream: personnelService.watchPersonnel(),
        builder: (context, snapshot) {
          // Tant que Firestore n'a pas encore répondu une première fois
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final personnel = snapshot.data!;

          if (personnel.isEmpty) {
            return const Center(child: Text('Aucun membre pour le moment.'));
          }

          // ListView.builder : contrairement à ListView simple, il ne
          // construit QUE les lignes actuellement visibles à l'écran
          // (+ quelques-unes en avance). Essentiel pour rester fluide
          // même avec 100+ employés dans la liste.
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: personnel.length,
            itemBuilder: (context, index) {
              final personne = personnel[index];
              return _CartePersonnel(
                personne: personne,
                service: personnelService,
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.vertSapin,
        onPressed: () => showDialog(
          context: context,
          builder: (_) => _FormulairePersonnel(service: personnelService),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// Une ligne affichant un employé : avatar coloré + infos + badge statut.
class _CartePersonnel extends StatelessWidget {
  final PersonnelModel personne;
  final PersonnelService service;

  const _CartePersonnel({required this.personne, required this.service});

  // Calcule une couleur d'avatar stable à partir de la première lettre
  // du nom : "Diata" donnera toujours la même couleur, sans qu'on ait
  // besoin de la stocker quelque part dans Firestore.
  Color _couleurAvatar(String nom) {
    if (nom.isEmpty) return AppColors.vertSauge;
    final palette = [
      AppColors.vertSauge,
      AppColors.terracotta,
      AppColors.bleuFleur,
      AppColors.taupe,
    ];
    // codeUnitAt(0) = le code numérique de la première lettre.
    // Le "%" (modulo) ramène ce grand nombre à un index valide
    // dans notre palette de 4 couleurs (toujours entre 0 et 3).
    final index = nom.codeUnitAt(0) % palette.length;
    return palette[index];
  }

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurAvatar(personne.nom);
    // Prend la première lettre du nom et du prénom pour former les
    // initiales, ex: "Kimbembe" + "Marie" -> "KM"
    final initiales =
        '${personne.nom.isNotEmpty ? personne.nom[0] : ''}${personne.prenom.isNotEmpty ? personne.prenom[0] : ''}'
            .toUpperCase();

    // Card : une "boîte" avec ombre légère et coins arrondis, le style
    // visuel standard pour délimiter chaque ligne de la liste.
    return Card(
      // ListTile : widget prêt à l'emploi pour une ligne classique
      // (icône/avatar à gauche, titre, sous-titre, élément à droite).
      // Évite de recomposer une Row à la main à chaque fois.
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: couleur,
          child: Text(
            initiales,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(
          '${personne.prenom} ${personne.nom}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(personne.poste),
        // trailing = ce qui s'affiche tout à droite de la ligne
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            // Couleur de fond du badge selon le statut
            color: personne.statut == StatutPersonnel.actif
                ? AppColors.succesBg
                : AppColors.dangerBg,
            borderRadius: BorderRadius.circular(20), // très arrondi = forme de "pilule"
          ),
          child: Text(
            personne.statut == StatutPersonnel.actif ? 'Actif' : 'Inactif',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: personne.statut == StatutPersonnel.actif
                  ? AppColors.succes
                  : AppColors.danger,
            ),
          ),
        ),
        onTap: () => showDialog(
          context: context,
          // On repasse "personne" existante : le formulaire saura donc
          // qu'il s'agit d'une MODIFICATION, pas d'un ajout (voir plus bas).
          builder: (_) => _FormulairePersonnel(service: service, personneExistante: personne),
        ),
      ),
    );
  }
}

/// Formulaire d'ajout OU de modification d'un employé.
/// Un seul formulaire gère les deux cas, selon que personneExistante
/// est fournie ou non — évite de dupliquer tout le code du formulaire.
class _FormulairePersonnel extends StatefulWidget {
  final PersonnelService service;
  final PersonnelModel? personneExistante; // null = mode "ajout"

  const _FormulairePersonnel({required this.service, this.personneExistante});

  @override
  State<_FormulairePersonnel> createState() => _FormulairePersonnelState();
}

class _FormulairePersonnelState extends State<_FormulairePersonnel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _posteController;
  late final TextEditingController _contratController;
  late bool _actif;
  bool _envoi = false;

  // initState() s'exécute UNE SEULE FOIS, à la création du widget.
  // On l'utilise ici pour pré-remplir les champs si on modifie un
  // employé existant (sinon les champs restent vides pour un ajout).
  @override
  void initState() {
    super.initState();
    final p = widget.personneExistante;
    _nomController = TextEditingController(text: p?.nom ?? '');
    _prenomController = TextEditingController(text: p?.prenom ?? '');
    _posteController = TextEditingController(text: p?.poste ?? '');
    _contratController = TextEditingController(text: p?.contrat ?? '');
    _actif = p?.statut != StatutPersonnel.inactif;
  }

  bool get _modeModification => widget.personneExistante != null;

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _envoi = true);

    final personnel = PersonnelModel(
      // Si on modifie, on garde le même id (essentiel : sinon Firestore
      // créerait un NOUVEAU document au lieu de mettre à jour l'existant).
      // Si on ajoute, id vide — ignoré par Firestore lors du .add().
      id: widget.personneExistante?.id ?? '',
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      poste: _posteController.text.trim(),
      contrat: _contratController.text.trim(),
      dateEmbauche: widget.personneExistante?.dateEmbauche ?? DateTime.now(),
      statut: _actif ? StatutPersonnel.actif : StatutPersonnel.inactif,
    );

    if (_modeModification) {
      await widget.service.modifier(personnel);
    } else {
      await widget.service.ajouter(personnel);
    }

    // "mounted" vérifie que l'écran existe encore avant de naviguer
    // (évite une erreur si l'utilisateur a fermé l'app entre-temps).
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _supprimer() async {
    if (widget.personneExistante == null) return;
    await widget.service.supprimer(widget.personneExistante!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_modeModification ? 'Modifier' : 'Nouveau membre'),
      content: Form(
        key: _formKey,
        // SingleChildScrollView : rend le formulaire défilable si le
        // clavier prend trop de place à l'écran (petits téléphones).
        child: SingleChildScrollView(
          child: Column(
            // MainAxisSize.min = la Column ne prend que la place
            // nécessaire à son contenu, pas tout l'espace disponible
            // (sinon la boîte de dialogue s'étirerait inutilement).
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _posteController,
                decoration: const InputDecoration(labelText: 'Poste'),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _contratController,
                decoration: const InputDecoration(labelText: 'Contrat'),
                // Pas de validator ici : champ facultatif, contrairement
                // aux précédents.
              ),
              const SizedBox(height: 8),
              // SwitchListTile : combine un texte + un interrupteur sur
              // une seule ligne, pratique pour un simple oui/non.
              SwitchListTile(
                title: const Text('Actif'),
                value: _actif,
                activeColor: AppColors.vertSapin,
                contentPadding: EdgeInsets.zero,
                onChanged: (valeur) => setState(() => _actif = valeur),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // On affiche le bouton Supprimer UNIQUEMENT en mode modification
        // (pas de sens de "supprimer" quelque chose qu'on est en train
        // de créer).
        if (_modeModification)
          TextButton(
            onPressed: _supprimer,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _envoi ? null : _enregistrer,
          child: _envoi
              ? const SizedBox(
                  height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_modeModification ? 'Enregistrer' : 'Ajouter'),
        ),
      ],
    );
  }
}