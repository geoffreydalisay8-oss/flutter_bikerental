import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikerental/model/feedback_model.dart';

class FeedbackService {
  final CollectionReference feedback =
      FirebaseFirestore.instance.collection('feedback');

  // ============================================================
  // GET ALL FEEDBACK
  // ============================================================

  Stream<List<FeedbackModel>> getFeedback() {
    return feedback.snapshots().map((snapshot) {
      final List<FeedbackModel> feedbackList =
          snapshot.docs.map((doc) {
        return FeedbackModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      // Newest first
      feedbackList.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      return feedbackList;
    });
  }

  // ============================================================
  // ADD FEEDBACK
  // ============================================================

  Future<String> addFeedback({
    required String customerId,
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    final DocumentReference doc =
        await feedback.add({
      'customerId': customerId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'date': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // ============================================================
  // CHECK IF FEEDBACK ALREADY EXISTS
  // ============================================================

  Future<bool> hasFeedback(
    String bookingId,
  ) async {
    final QuerySnapshot snapshot =
        await feedback
            .where(
              'bookingId',
              isEqualTo: bookingId,
            )
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }
}