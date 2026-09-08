import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/personnel_model.dart';

class PersonnelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection =>
      _firestore.collection(FirestorePaths.personnels);

  /// Stream temps réel de la liste du personnel, triée par nom.
  Stream<List<PersonnelModel>> watchPersonnel() {
    return _collection.orderBy('nom').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PersonnelModel.fromFirestore(doc)).toList());
  }

  Future<void> ajouter(PersonnelModel personnel) {
    return _collection.add(personnel.toFirestore());
  }

  Future<void> modifier(PersonnelModel personnel) {
    return _collection.doc(personnel.id).update(personnel.toFirestore());
  }

  Future<void> supprimer(String id) {
    return _collection.doc(id).delete();
  }
}