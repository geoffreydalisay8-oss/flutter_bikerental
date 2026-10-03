import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikerental/model/booking_model.dart'; // Adjust path if needed

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BookingModel>> getCustomerBookings(String customerId) {
    return _firestore
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> submitFeedback({
    required String bookingId,
    required double rating,
    required String feedback,
  }) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'rating': rating,
      'feedback': feedback,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}