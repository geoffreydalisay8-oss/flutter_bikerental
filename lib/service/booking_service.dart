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
      BookingModel booking) async {
    // Find customer's ID verification
    final QuerySnapshot verificationSnapshot =
        await _firestore
            .collection('id_verifications')
            .where(
              'customerId',
              isEqualTo: booking.customerId,
            )
            .get();

    String? verificationId;
    String verificationStatus =
        'Not Submitted';

    // ------------------------------------------------------------
    // GET LATEST ID VERIFICATION
    // ------------------------------------------------------------

    if (verificationSnapshot.docs.isNotEmpty) {
      final List<QueryDocumentSnapshot> docs =
          verificationSnapshot.docs.toList();

      docs.sort((a, b) {
        final Map<String, dynamic> aData =
            a.data() as Map<String, dynamic>;

        final Map<String, dynamic> bData =
            b.data() as Map<String, dynamic>;

        final dynamic aTime =
            aData['submittedAt'];

        final dynamic bTime =
            bData['submittedAt'];

        if (aTime is Timestamp &&
            bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }

        return 0;
      });

      final QueryDocumentSnapshot
          verificationDoc = docs.first;

      final Map<String, dynamic>
          verificationData =
          verificationDoc.data()
              as Map<String, dynamic>;

      verificationId =
          verificationDoc.id;

      verificationStatus =
          verificationData['status'] ??
              'Pending';
    }

    // ------------------------------------------------------------
    // CREATE BOOKING DATA
    // ------------------------------------------------------------

    final Map<String, dynamic> bookingData =
        booking.toMap();

    // Connect ID verification to booking
    bookingData['idVerificationId'] =
        verificationId ?? '';

    bookingData['idVerificationStatus'] =
        verificationStatus;

    // ------------------------------------------------------------
    // CREATE BOOKING
    // ------------------------------------------------------------

    final DocumentReference doc =
        await _bookings.add(bookingData);

    // ------------------------------------------------------------
    // CONNECT ID VERIFICATION BACK TO BOOKING
    // ------------------------------------------------------------

    if (verificationId != null) {
      await _firestore
          .collection('id_verifications')
          .doc(verificationId)
          .update({
        'bookingId': doc.id,
        'associatedBooking': doc.id,
      });
    }

    return doc.id;
  }

  // ============================================================
  // GET CUSTOMER BOOKINGS
  // ============================================================

  Stream<List<BookingModel>>
      getCustomerBookings(
          String customerId) {
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

      bookings.sort(
        (a, b) => b.pickupDate
            .compareTo(a.pickupDate),
      );

      return bookings;
    });
  }

  // ============================================================
  // GET ALL BOOKINGS
  // ============================================================

  Stream<List<BookingModel>>
      getAllBookings() {
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
      String bookingId) async {
    final DocumentSnapshot doc =
        await _bookings.doc(bookingId).get();

    if (!doc.exists ||
        doc.data() == null) {
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
      String status) async {
    await _bookings.doc(bookingId).update({
      'bookingStatus': status,
    });
  }

  // ============================================================
  // UPDATE PAYMENT STATUS
  // ============================================================

  Future<void> updatePaymentStatus(
      String bookingId,
      String status) async {
    final Map<String, dynamic> data = {
      'paymentStatus': status,
    };

    if (status.toLowerCase() == 'paid') {
      data['paymentDate'] =
          FieldValue.serverTimestamp();
    } else {
      data['paymentDate'] = null;
    }

    await _bookings.doc(bookingId).update(data);
  }

  // ============================================================
  // ADD FEEDBACK
  // ============================================================

  Future<void> addFeedback(
      String bookingId,
      String customerId,
      double rating,
      String feedbackText) async {
    await _bookings.doc(bookingId).update({
      'rating': rating,
      'feedback': feedbackText,
    });

    await _firestore
        .collection('feedback')
        .add({
      'customerId': customerId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': feedbackText,
      'date':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // DELETE BOOKING
  // ============================================================

  Future<void> deleteBooking(
      String bookingId) async {
    await _bookings
        .doc(bookingId)
        .delete();
  }
}