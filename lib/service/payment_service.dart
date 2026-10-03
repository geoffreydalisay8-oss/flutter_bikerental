import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikerental/model/payment_model.dart';

class PaymentService {
  final CollectionReference payments =
      FirebaseFirestore.instance.collection('payments');

  Stream<List<PaymentModel>> getPayments() {
    return payments.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PaymentModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Future<void> updatePaymentStatus(
    String id,
    String status,
  ) async {
    await payments.doc(id).update({
      'status': status,
    });
  }
}