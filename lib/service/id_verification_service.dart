import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikerental/model/id_verification_model.dart';

class IDVerificationService {
  final CollectionReference verifications =
      FirebaseFirestore.instance.collection('id_verifications');

  Stream<List<IdVerificationModel>> getVerifications() {
    return verifications.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return IdVerificationModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Future<void> updateStatus(
    String id,
    String status,
  ) async {
    await verifications.doc(id).update({
      'status': status,
    });
  }
}