import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikerental/service/booking_service.dart';
import 'package:bikerental/model/booking_model.dart';

class MyBookingPage extends StatefulWidget {
  const MyBookingPage({super.key});

  @override
  State<MyBookingPage> createState() =>
      _MyBookingPageState();
}

class _MyBookingPageState extends State<MyBookingPage> {
  static const primaryColor =
      Color(0xFF1B4D3E);

  final BookingService service =
      BookingService();

  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Pending',
    'Approved',
    'Active',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FB),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F9FB),

        elevation: 0,

        automaticallyImplyLeading:
            false,

        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: currentUser == null
          ? const Center(
              child: Text(
                'Please sign in to view your bookings.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            )
          : StreamBuilder<List<BookingModel>>(
              stream:
                  service.getCustomerBookings(
                currentUser.uid,
              ),

              builder:
                  (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      child: Text(
                        'Error loading bookings: ${snapshot.error}',
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                final List<BookingModel>
                    allBookings =
                    snapshot.data ?? [];

                if (allBookings.isEmpty) {
                  return _buildEmptyState();
                }

                final filteredBookings =
                    _filterBookings(
                  allBookings,
                );

                return Column(
                  children: [
                    // ==================================================
                    // FILTERS
                    // ==================================================

                    _buildFilterBar(),

                    // ==================================================
                    // BOOKINGS
                    // ==================================================

                    Expanded(
                      child:
                          filteredBookings.isEmpty
                              ? _buildNoFilteredBookings()
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(
                                    16,
                                    5,
                                    16,
                                    20,
                                  ),
                                  itemCount:
                                      filteredBookings
                                          .length,
                                  separatorBuilder:
                                      (
                                    context,
                                    index,
                                  ) =>
                                          const SizedBox(
                                    height: 12,
                                  ),
                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {
                                    final booking =
                                        filteredBookings[
                                            index];

                                    return _buildBookingCard(
                                      context,
                                      booking,
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // ============================================================
  // FILTER BOOKINGS
  // ============================================================

  List<BookingModel> _filterBookings(
    List<BookingModel> bookings,
  ) {
    if (selectedFilter == 'All') {
      return bookings;
    }

    return bookings.where(
      (booking) {
        final status =
            booking.bookingStatus
                .toLowerCase();

        switch (selectedFilter) {
          case 'Pending':
            return status == 'pending';

          case 'Approved':
            return status == 'approved';

          case 'Active':
            return status ==
                'active rental';

          case 'Completed':
            return status ==
                'completed';

          case 'Cancelled':
            return status ==
                'cancelled';

          default:
            return true;
        }
      },
    ).toList();
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),

        itemCount:
            filters.length,

        separatorBuilder:
            (context, index) =>
                const SizedBox(
          width: 8,
        ),

        itemBuilder:
            (context, index) {
          final filter =
              filters[index];

          final selected =
              selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter =
                    filter;
              });
            },

            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),

              decoration:
                  BoxDecoration(
                color: selected
                    ? primaryColor
                    : Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                border:
                    Border.all(
                  color: selected
                      ? primaryColor
                      : Colors
                          .grey
                          .shade300,
                ),
              ),

              child: Text(
                filter,

                style:
                    TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.black87,

                  fontSize: 12,

                  fontWeight:
                      selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.directions_bike,
              size: 64,
              color: Colors.grey[400],
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              'No bookings found.',
              style:
                  TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.grey[600],
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Your bicycle bookings will appear here.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 12,
                color:
                    Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO FILTERED BOOKINGS
  // ============================================================

  Widget _buildNoFilteredBookings() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 55,
              color: Colors.grey[400],
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              'No $selectedFilter bookings',
              style:
                  TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.grey[600],
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Bookings with this status will appear here.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 12,
                color:
                    Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GET ID VERIFICATION STATUS
  // ============================================================

  Future<String> _getIdVerificationStatus({
    String? verificationId,
  }) async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return 'Not Submitted';
    }

    try {
      final FirebaseFirestore firestore =
          FirebaseFirestore.instance;

      // ========================================================
      // FIRST: CHECK SPECIFIC VERIFICATION
      // ========================================================

      if (verificationId != null &&
          verificationId.isNotEmpty) {
        final DocumentSnapshot doc =
            await firestore
                .collection('id_verifications')
                .doc(verificationId)
                .get();

        if (doc.exists &&
            doc.data() != null) {
          final data =
              doc.data()
                  as Map<String, dynamic>;

          if (data['customerId'] ==
              currentUser.uid) {
            final String status =
                (data['status'] ??
                        'Pending')
                    .toString()
                    .trim();

            return status.isEmpty
                ? 'Pending'
                : status;
          }
        }
      }

      // ========================================================
      // SECOND: GET ALL VERIFICATIONS FOR CUSTOMER
      // ========================================================

      final QuerySnapshot result =
          await firestore
              .collection('id_verifications')
              .where(
                'customerId',
                isEqualTo:
                    currentUser.uid,
              )
              .get();

      if (result.docs.isEmpty) {
        return 'Not Submitted';
      }

      // ========================================================
      // FIND THE LATEST SUBMISSION
      // ========================================================

      QueryDocumentSnapshot? latestDoc;

      DateTime? latestDate;

      for (final doc in result.docs) {
        final data =
            doc.data()
                as Map<String, dynamic>;

        // First use clientSubmittedAt.
        // This timestamp is immediately available
        // when the customer submits the ID.
        dynamic timestamp =
            data['clientSubmittedAt'];

        // Fallback to submittedAt.
        if (timestamp == null) {
          timestamp =
              data['submittedAt'];
        }

        // Fallback to uploadedDate.
        if (timestamp == null) {
          timestamp =
              data['uploadedDate'];
        }

        DateTime? submittedDate;

        if (timestamp is Timestamp) {
          submittedDate =
              timestamp.toDate();
        } else if (timestamp
            is DateTime) {
          submittedDate =
              timestamp;
        }

        // First document becomes the current
        // latest document.
        if (latestDoc == null) {
          latestDoc = doc;
          latestDate =
              submittedDate;
        }

        // Compare dates when available.
        else if (submittedDate != null &&
            latestDate != null &&
            submittedDate.isAfter(
              latestDate,
            )) {
          latestDoc = doc;
          latestDate =
              submittedDate;
        }

        // If current latest has no date,
        // prefer the document that has a date.
        else if (latestDate == null &&
            submittedDate != null) {
          latestDoc = doc;
          latestDate =
              submittedDate;
        }
      }

      // ========================================================
      // FALLBACK
      // ========================================================

      latestDoc ??= result.docs.last;

      final latestData =
          latestDoc.data()
              as Map<String, dynamic>;

      final String status =
          (latestData['status'] ??
                  'Pending')
              .toString()
              .trim();

      if (status.isEmpty) {
        return 'Pending';
      }

      return status;
    } catch (e) {
      debugPrint(
        'ID verification error: $e',
      );

      return 'Not Submitted';
    }
  }

  // ============================================================
  // ID VERIFICATION STATUS BADGE
  // ============================================================

  Widget _buildIdVerificationStatus(
    String status,
  ) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
        backgroundColor =
            const Color(0xFFE8F5E9);

        textColor =
            primaryColor;

        icon =
            Icons.verified_rounded;

        break;

      case 'rejected':
        backgroundColor =
            const Color(0xFFFFEBEE);

        textColor =
            Colors.red[800]!;

        icon =
            Icons.cancel_rounded;

        break;

      case 'pending':
        backgroundColor =
            const Color(0xFFFFF3E0);

        textColor =
            Colors.orange[800]!;

        icon =
            Icons.hourglass_top_rounded;

        break;

      default:
        backgroundColor =
            const Color(0xFFF5F5F5);

        textColor =
            Colors.grey[700]!;

        icon =
            Icons.help_outline_rounded;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration:
          BoxDecoration(
        color:
            backgroundColor,

        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 15,
            color: textColor,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            status,

            style:
                TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.bold,
              color:
                  textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ID VERIFICATION MESSAGE
  // ============================================================

  Widget _buildIdVerificationMessage(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            10,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFFFF8E1),

            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),

          child:
              const Text(
            'Your ID is still being reviewed. Please wait for verification before picking up the bicycle.',

            style:
                TextStyle(
              fontSize: 11,
              color:
                  Colors.black87,
            ),
          ),
        );

      case 'verified':
      case 'approved':
        return Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            10,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFE8F5E9),

            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),

          child:
              const Text(
            'Your ID has been verified. You may proceed to the rental shop. Payment is required before the bicycle is released.',

            style:
                TextStyle(
              fontSize: 11,
              color:
                  Colors.black87,
            ),
          ),
        );

      case 'rejected':
        return Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            10,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFFFEBEE),

            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),

          child:
              const Text(
            'Your ID was rejected. Please submit a valid ID for verification.',

            style:
                TextStyle(
              fontSize: 11,
              color:
                  Colors.red,
            ),
          ),
        );

      case 'not submitted':
        return Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            10,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFF7F9FB),

            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),

          child:
              const Text(
            'Please submit a valid ID for verification before picking up the bicycle.',

            style:
                TextStyle(
              fontSize: 11,
              color:
                  Colors.black87,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // BOOKING CARD
  // ============================================================

  Widget _buildBookingCard(
    BuildContext context,
    BookingModel booking,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.03,
            ),

            blurRadius:
                8,

            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      padding:
          const EdgeInsets.all(
        16,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ==================================================
          // BOOKING ID + STATUS
          // ==================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              Expanded(
                child: Text(
                  'Booking ID: #${booking.id}',

                  style:
                      TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.grey[600],
                    fontFamily:
                        'monospace',
                  ),
                ),
              ),

              _buildStatusBadge(
                booking.bookingStatus,
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ==================================================
          // BICYCLE
          // ==================================================

          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE9EFEC,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child:
                    const Icon(
                  Icons.directions_bike,
                  color:
                      primaryColor,
                  size: 27,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  booking.bicycleName,

                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          const Divider(
            height: 1,
          ),

          const SizedBox(
            height: 14,
          ),

          // ==================================================
          // PICKUP
          // ==================================================

          _buildDetailRow(
            icon:
                Icons.login_rounded,

            title:
                'Pickup',

            date:
                booking.pickupDate,
          ),

          const SizedBox(
            height: 12,
          ),

          // ==================================================
          // RETURN
          // ==================================================

          _buildDetailRow(
            icon:
                Icons.logout_rounded,

            title:
                'Return',

            date:
                booking.returnDate,
          ),

          const SizedBox(
            height: 14,
          ),

          const Divider(
            height: 1,
          ),

          const SizedBox(
            height: 14,
          ),

          // ==================================================
          // ID VERIFICATION
          // ==================================================

          FutureBuilder<String>(
            future:
                _getIdVerificationStatus(),

            builder:
                (
              context,
              snapshot,
            ) {
              final bool loading =
                  snapshot.connectionState ==
                      ConnectionState.waiting;

              final String idStatus =
                  snapshot.data ??
                      'Pending';

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [
                      Text(
                        'ID Verification',

                        style:
                            TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey[600],
                        ),
                      ),

                      loading
                          ? const SizedBox(
                              width: 14,
                              height: 14,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,

                                color:
                                    primaryColor,
                              ),
                            )
                          : _buildIdVerificationStatus(
                              idStatus,
                            ),
                    ],
                  ),

                  if (!loading) ...[
                    const SizedBox(
                      height: 10,
                    ),

                    _buildIdVerificationMessage(
                      idStatus,
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(
            height: 14,
          ),

          const Divider(
            height: 1,
          ),

          const SizedBox(
            height: 14,
          ),

          // ==================================================
          // PAYMENT METHOD
          // ==================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              Text(
                'Payment Method',

                style:
                    TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey[600],
                ),
              ),

              Text(
                booking.paymentMethod,

                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          // ==================================================
          // PAYMENT STATUS
          // ==================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              Text(
                'Payment Status',

                style:
                    TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey[600],
                ),
              ),

              _buildPaymentBadge(
                booking.paymentStatus,
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          const Divider(
            height: 1,
          ),

          const SizedBox(
            height: 12,
          ),

          // ==================================================
          // TOTAL
          // ==================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              const Text(
                'Total Amount',

                style:
                    TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              Text(
                '₱${booking.totalAmount.toStringAsFixed(2)}',

                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ==================================================
          // STATUS MESSAGE
          // ==================================================

          _buildStatusMessage(
            booking.bookingStatus,
            booking.paymentStatus,
          ),

          // ==================================================
          // FEEDBACK
          // ==================================================

          if (booking.bookingStatus
                  .toLowerCase() ==
              'completed') ...[
            const SizedBox(
              height: 14,
            ),

            const Divider(
              height: 1,
            ),

            const SizedBox(
              height: 12,
            ),

            FutureBuilder<bool>(
              future:
                  _hasSubmittedFeedback(
                booking.id,
              ),

              builder:
                  (
                context,
                feedbackSnapshot,
              ) {
                if (feedbackSnapshot
                        .connectionState ==
                    ConnectionState.waiting) {
                  return SizedBox(
                    width:
                        double.infinity,

                    child:
                        OutlinedButton.icon(
                      onPressed:
                          null,

                      icon:
                          const SizedBox(
                        width: 16,
                        height: 16,

                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      ),

                      label:
                          const Text(
                        'Checking Feedback...',
                      ),
                    ),
                  );
                }

                final bool submitted =
                    feedbackSnapshot.data ??
                        false;

                if (submitted) {
                  return Container(
                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFE8F5E9,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),

                      border:
                          Border.all(
                        color:
                            primaryColor
                                .withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),

                    child:
                        const Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        Icon(
                          Icons
                              .check_circle_outline,

                          color:
                              primaryColor,

                          size: 18,
                        ),

                        SizedBox(
                          width: 8,
                        ),

                        Text(
                          'Feedback Submitted',

                          style:
                              TextStyle(
                            color:
                                primaryColor,

                            fontWeight:
                                FontWeight.bold,

                            fontSize:
                                13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  width:
                      double.infinity,

                  child:
                      OutlinedButton.icon(
                    onPressed: () {
                      _showFeedbackDialog(
                        context,
                        booking.id,
                      );
                    },

                    style:
                        OutlinedButton.styleFrom(
                      side:
                          const BorderSide(
                        color:
                            primaryColor,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),

                    icon:
                        const Icon(
                      Icons
                          .rate_review_outlined,

                      size: 16,

                      color:
                          primaryColor,
                    ),

                    label:
                        const Text(
                      'Leave Feedback & Rating',

                      style:
                          TextStyle(
                        color:
                            primaryColor,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CHECK IF FEEDBACK WAS ALREADY SUBMITTED
  // ============================================================

  Future<bool> _hasSubmittedFeedback(
    String bookingId,
  ) async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return false;
    }

    final QuerySnapshot result =
        await FirebaseFirestore.instance
            .collection('feedback')
            .where(
              'customerId',
              isEqualTo:
                  currentUser.uid,
            )
            .where(
              'bookingId',
              isEqualTo:
                  bookingId,
            )
            .limit(1)
            .get();

    return result.docs.isNotEmpty;
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required DateTime date,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          padding:
              const EdgeInsets.all(8),

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFF7F9FB),

            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),

          child: Icon(
            icon,
            size: 18,
            color:
                primaryColor,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style:
                    TextStyle(
                  fontSize: 11,
                  color:
                      Colors.grey[600],
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                _formatDate(date),

                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Colors.black87,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                _formatTime(date),

                style:
                    TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOOKING STATUS
  // ============================================================

  Widget _buildStatusBadge(
    String status,
  ) {
    Color backgroundColor =
        Colors.grey[200]!;

    Color textColor =
        Colors.black87;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor =
            const Color(0xFFFFF3E0);

        textColor =
            Colors.orange[800]!;

        break;

      case 'approved':
        backgroundColor =
            const Color(0xFFE3F2FD);

        textColor =
            Colors.blue[800]!;

        break;

      case 'active rental':
        backgroundColor =
            const Color(0xFFE8F5E9);

        textColor =
            primaryColor;

        break;

      case 'completed':
        backgroundColor =
            const Color(0xFFE8F5E9);

        textColor =
            primaryColor;

        break;

      case 'cancelled':
        backgroundColor =
            const Color(0xFFFFEBEE);

        textColor =
            Colors.red[800]!;

        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),

      decoration:
          BoxDecoration(
        color:
            backgroundColor,

        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),

      child: Text(
        status.toUpperCase(),

        style:
            TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
          color:
              textColor,
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT BADGE
  // ============================================================

  Widget _buildPaymentBadge(
    String status,
  ) {
    final bool isPaid =
        status.toLowerCase() ==
            'paid';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration:
          BoxDecoration(
        color: isPaid
            ? const Color(
                0xFFE8F5E9,
              )
            : const Color(
                0xFFFFF3E0,
              ),

        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),

      child: Text(
        status,

        style:
            TextStyle(
          fontSize: 11,
          fontWeight:
              FontWeight.bold,
          color: isPaid
              ? primaryColor
              : Colors.orange[800],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS MESSAGE
  // ============================================================

  Widget _buildStatusMessage(
    String bookingStatus,
    String paymentStatus,
  ) {
    String message;

    switch (
        bookingStatus.toLowerCase()) {
      case 'pending':
        message =
            'Waiting for staff approval.';
        break;

      case 'approved':
        if (paymentStatus
                .toLowerCase() ==
            'paid') {
          message =
              'Your booking is approved. You can pick up the bicycle.';
        } else {
          message =
              'Booking approved. Please pay at the rental shop.';
        }
        break;

      case 'active rental':
        message =
            'The bicycle is currently on rental.';
        break;

      case 'completed':
        message =
            'Rental completed. Thank you for using GoPedal!';
        break;

      case 'cancelled':
        message =
            'This booking has been cancelled.';
        break;

      default:
        message =
            'Booking status: $bookingStatus';
    }

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(10),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF7F9FB),

        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),

      child: Text(
        message,

        style:
            TextStyle(
          fontSize: 12,
          color:
              Colors.grey[700],
        ),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatTime(
    DateTime date,
  ) {
    final hour =
        date.hour == 0
            ? 12
            : date.hour > 12
                ? date.hour - 12
                : date.hour;

    final minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // FEEDBACK DIALOG
  // ============================================================

  void _showFeedbackDialog(
    BuildContext context,
    String bookingId,
  ) {
    double selectedRating = 5;

    final TextEditingController
        feedbackController =
        TextEditingController();

    showDialog(
      context: context,

      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setState,
          ) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),

              title:
                  const Text(
                'Leave Feedback',

                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              content:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  const Text(
                    'How was your rental experience?',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children:
                        List.generate(
                      5,
                      (index) {
                        final starRating =
                            index + 1;

                        return IconButton(
                          icon:
                              Icon(
                            starRating <=
                                    selectedRating
                                ? Icons
                                    .star_rounded
                                : Icons
                                    .star_outline_rounded,

                            color:
                                Colors.amber,

                            size:
                                32,
                          ),

                          onPressed: () {
                            setState(() {
                              selectedRating =
                                  starRating
                                      .toDouble();
                            });
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextField(
                    controller:
                        feedbackController,

                    maxLines: 3,

                    decoration:
                        InputDecoration(
                      hintText:
                          'Write a comment (optional)...',

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );

                    feedbackController
                        .dispose();
                  },

                  child:
                      const Text(
                    'Cancel',

                    style:
                        TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ),

                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryColor,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                  ),

                  onPressed: () async {
                    try {
                      final User?
                          currentUser =
                          FirebaseAuth
                              .instance
                              .currentUser;

                      if (currentUser ==
                          null) {
                        if (dialogContext
                            .mounted) {
                          Navigator.pop(
                            dialogContext,
                          );
                        }

                        if (context.mounted) {
                          ScaffoldMessenger
                              .of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content:
                                  Text(
                                'Please sign in first.',
                              ),
                            ),
                          );
                        }

                        feedbackController
                            .dispose();

                        return;
                      }

                      final QuerySnapshot
                          existingFeedback =
                          await FirebaseFirestore
                              .instance
                              .collection(
                                  'feedback')
                              .where(
                                'customerId',
                                isEqualTo:
                                    currentUser
                                        .uid,
                              )
                              .where(
                                'bookingId',
                                isEqualTo:
                                    bookingId,
                              )
                              .limit(1)
                              .get();

                      if (existingFeedback
                          .docs
                          .isNotEmpty) {
                        if (dialogContext
                            .mounted) {
                          Navigator.pop(
                            dialogContext,
                          );
                        }

                        if (context.mounted) {
                          ScaffoldMessenger
                              .of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content:
                                  Text(
                                'You have already submitted feedback for this booking.',
                              ),
                            ),
                          );
                        }

                        feedbackController
                            .dispose();

                        return;
                      }

                      final String
                          comment =
                          feedbackController
                              .text
                              .trim();

                      await FirebaseFirestore
                          .instance
                          .collection(
                              'feedback')
                          .add({
                        'customerId':
                            currentUser
                                .uid,

                        'bookingId':
                            bookingId,

                        'rating':
                            selectedRating,

                        'comment':
                            comment,

                        'date':
                            FieldValue
                                .serverTimestamp(),
                      });

                      if (dialogContext
                          .mounted) {
                        Navigator.pop(
                          dialogContext,
                        );
                      }

                      feedbackController
                          .dispose();

                      if (context.mounted) {
                        ScaffoldMessenger
                            .of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content:
                                Text(
                              'Feedback submitted successfully.',
                            ),
                          ),
                        );

                        setState(() {});
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger
                            .of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to submit feedback: $e',
                            ),
                          ),
                        );
                      }
                    }
                  },

                  child:
                      const Text(
                    'Submit',

                    style:
                        TextStyle(
                      color:
                          Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}