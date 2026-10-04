import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikerental/model/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference get _bookings =>
      _firestore.collection('bookings');

  // ============================================================
  // CREATE BOOKING
  // ============================================================

  Future<String> createBooking(
    BookingModel booking,
  ) async {
    final DocumentReference doc =
        await _bookings.add(
      booking.toMap(),
    );

    return doc.id;
  }

  // ============================================================
  // GET CUSTOMER BOOKINGS
  // ============================================================

  Stream<List<BookingModel>> getCustomerBookings(
    String customerId,
  ) {
    return _bookings
        .where(
          'customerId',
          isEqualTo: customerId,
        )
        .snapshots()
        .map((snapshot) {
      final List<BookingModel> bookings =
          snapshot.docs.map((doc) {
        return BookingModel.fromMap(
          doc.data()
              as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Newest booking first
      bookings.sort(
        (a, b) => b.pickupDate.compareTo(
          a.pickupDate,
        ),
      );

      return bookings;
    });
  }

  // ============================================================
  // GET ALL BOOKINGS
  // ============================================================

  Stream<List<BookingModel>> getAllBookings() {
    return _bookings
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(
          doc.data()
              as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // ============================================================
  // GET ONE BOOKING
  // ============================================================

  Future<BookingModel?> getBooking(
    String bookingId,
  ) async {
    final DocumentSnapshot doc =
        await _bookings.doc(bookingId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return BookingModel.fromMap(
      doc.data()
          as Map<String, dynamic>,
      doc.id,
    );
  }

  // ============================================================
  // UPDATE BOOKING STATUS
  // ============================================================

  Future<void> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    await _bookings.doc(bookingId).update({
      'bookingStatus': status,
    });
  }

  // ============================================================
  // UPDATE PAYMENT STATUS
  // ============================================================

  Future<void> updatePaymentStatus(
    String bookingId,
    String status,
  ) async {
    await _bookings.doc(bookingId).update({
      'paymentStatus': status,
    });
  }

  // ============================================================
  // UPDATE RATING AND FEEDBACK
  // ============================================================

  Future<void> addFeedback(
    String bookingId,
    double rating,
    String feedback,
  ) async {
    await _bookings.doc(bookingId).update({
      'rating': rating,
      'feedback': feedback,
    });
  }

  // ============================================================
  // DELETE BOOKING
  // ============================================================

  Future<void> deleteBooking(
    String bookingId,
  ) async {
    await _bookings.doc(bookingId).delete();
  }
}