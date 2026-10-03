import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bikerental/model/bicycle_model.dart';

class BicycleService {
  final CollectionReference bicycles =
      FirebaseFirestore.instance.collection('bicycles');

  Stream<List<BicycleModel>> getBicycles() {
    return bicycles.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BicycleModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Future<void> addBicycle(
    BicycleModel bicycle,
  ) async {
    await bicycles.add(
      bicycle.toMap(),
    );
  }

  Future<void> updateBicycle(
    BicycleModel bicycle,
  ) async {
    await bicycles.doc(bicycle.id).update(
      bicycle.toMap(),
    );
  }

  Future<void> deleteBicycle(
    String id,
  ) async {
    await bicycles.doc(id).delete();
  }
}