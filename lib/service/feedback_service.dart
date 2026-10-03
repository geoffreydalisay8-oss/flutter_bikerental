import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikerental/model/feedback_model.dart';

class FeedbackService {
  final CollectionReference feedback =
      FirebaseFirestore.instance.collection('feedback');

  Stream<List<FeedbackModel>> getFeedback() {
    return feedback.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FeedbackModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }
}