import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bikerental/model/bicycle_model.dart';
import 'package:bikerental/model/booking_model.dart';
import 'package:bikerental/service/booking_service.dart';

import 'package:bikerental/view/admin/staff/customer/my_booking_page.dart';

class BookingSummaryPage extends StatefulWidget {
  final BicycleModel bicycle;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final double rentalFee;

  const BookingSummaryPage({
    super.key,
    required this.bicycle,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.rentalFee,
  });

  @override
  State<BookingSummaryPage> createState() =>
      _BookingSummaryPageState();
}

class _BookingSummaryPageState
    extends State<BookingSummaryPage> {
  final BookingService bookingService =
      BookingService();

  final double bookingFee = 50.00;

  bool isConfirming = false;

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // GET PICKUP DATETIME
  // ============================================================

  DateTime _getPickupDateTime() {
    return DateTime(
      widget.pickupDate.year,
      widget.pickupDate.month,
      widget.pickupDate.day,
      widget.pickupTime.hour,
      widget.pickupTime.minute,
    );
  }

  // ============================================================
  // GET RETURN DATETIME
  // ============================================================

  DateTime _getReturnDateTime() {
    return DateTime(
      widget.returnDate.year,
      widget.returnDate.month,
      widget.returnDate.day,
      widget.returnTime.hour,
      widget.returnTime.minute,
    );
  }

  // ============================================================
  // GET RENTAL DAYS
  // ============================================================

  int _getRentalDays() {
    final pickup =
        _getPickupDateTime();

    final returnDate =
        _getReturnDateTime();

    final duration =
        returnDate.difference(pickup);

    final hours =
        duration.inMinutes / 60;

    if (hours <= 24) {
      return 1;
    }

    return (hours / 24).ceil();
  }

  // ============================================================
  // GET TOTAL
  // ============================================================

  double _getTotalAmount() {
    return widget.rentalFee +
        bookingFee;
  }

  // ============================================================
  // CONFIRM BOOKING
  // ============================================================

  Future<void> _confirmBooking() async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in before booking.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isConfirming = true;
    });

    try {
      final BookingModel booking =
          BookingModel(
        id: '',

        customerId:
            currentUser.uid,

        bicycleId:
            widget.bicycle.id,

        bicycleName:
            widget.bicycle.name,

        pickupDate:
            _getPickupDateTime(),

        returnDate:
            _getReturnDateTime(),

        rentalFee:
            widget.rentalFee,

        bookingFee:
            bookingFee,

        totalAmount:
            _getTotalAmount(),

        paymentStatus:
            'Unpaid',

        bookingStatus:
            'Pending',
      );

      // SAVE TO FIRESTORE
      final String bookingId =
          await bookingService.createBooking(
        booking,
      );

      if (!mounted) return;

      setState(() {
        isConfirming = false;
      });

      _showBookingSuccess(
        bookingId,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isConfirming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create booking: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showBookingSuccess(
    String bookingId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                width: 70,
                height: 70,

                decoration: const BoxDecoration(
                  color:
                      Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.check_rounded,
                  size: 45,
                  color:
                      Color(0xFF1B4D3E),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your booking has been submitted successfully.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color:
                      const Color(
                    0xFFF7F9FB,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child: Column(
                  children: [
                    const Text(
                      'Booking ID',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '#$bookingId',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF1B4D3E),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Booking Status',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Pending',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MyBookingPage(),
                      ),
                    );
                  },

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF1B4D3E,
                    ),

                    foregroundColor:
                        Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),

                  child: const Text(
                    'View My Bookings',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final int rentalDays =
        _getRentalDays();

    final double totalAmount =
        _getTotalAmount();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FB),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F9FB),

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Booking Summary',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'REVIEW YOUR BOOKING',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF1B4D3E),
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Check your booking details before confirming.',
              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.grey[600],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // BICYCLE
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.03),
                    blurRadius: 8,
                    offset:
                        const Offset(0, 2),
                  ),
                ],
              ),

              child: Row(
                children: [
                  Container(
                    width: 90,
                    height: 75,

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF1F4F2,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),

                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),

                      child: widget
                              .bicycle
                              .imageUrl
                              .isNotEmpty
                          ? Image.network(
                              widget
                                  .bicycle
                                  .imageUrl,
                              fit: BoxFit.cover,

                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const Icon(
                                  Icons
                                      .directions_bike,
                                  size: 40,
                                  color:
                                      Color(
                                    0xFF1B4D3E,
                                  ),
                                );
                              },
                            )
                          : const Icon(
                              Icons
                                  .directions_bike,
                              size: 40,
                              color:
                                  Color(
                                0xFF1B4D3E,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFE8F5E9,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              6,
                            ),
                          ),

                          child:
                              const Text(
                            'BICYCLE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Color(
                                0xFF1B4D3E,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          widget
                              .bicycle
                              .name,

                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          widget
                              .bicycle
                              .type,

                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // RENTAL SCHEDULE
            // ==================================================

            _buildSectionCard(
              title: 'Rental Schedule',
              icon:
                  Icons.calendar_month,

              child: Column(
                children: [
                  _buildScheduleRow(
                    icon:
                        Icons.login_rounded,

                    label: 'Pickup',

                    date:
                        _formatDate(
                      widget.pickupDate,
                    ),

                    time:
                        _formatTime(
                      widget.pickupTime,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildScheduleRow(
                    icon:
                        Icons.logout_rounded,

                    label: 'Return',

                    date:
                        _formatDate(
                      widget.returnDate,
                    ),

                    time:
                        _formatTime(
                      widget.returnTime,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // RENTAL DETAILS
            // ==================================================

            _buildSectionCard(
              title: 'Rental Details',
              icon:
                  Icons.receipt_long,

              child: Column(
                children: [
                  _buildAmountRow(
                    'Rental Rate',
                    '₱${widget.bicycle.rentalRate.toStringAsFixed(2)} / day',
                  ),

                  const SizedBox(height: 12),

                  _buildAmountRow(
                    'Rental Duration',
                    '$rentalDays ${rentalDays == 1 ? 'day' : 'days'}',
                  ),

                  const SizedBox(height: 12),

                  _buildAmountRow(
                    'Rental Fee',
                    '₱${widget.rentalFee.toStringAsFixed(2)}',
                  ),

                  const SizedBox(height: 12),

                  _buildAmountRow(
                    'Booking Fee',
                    '₱${bookingFee.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TOTAL
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),

              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFF1B4D3E),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.white70,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Rental + Booking Fee',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Colors.white60,
                        ),
                      ),
                    ],
                  ),

                  Text(
                    '₱${totalAmount.toStringAsFixed(2)}',

                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // PAYMENT
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),

              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(
                      8,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFFF3E0,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),

                    child: const Icon(
                      Icons
                          .payments_outlined,
                      size: 20,
                      color:
                          Colors.orange,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        const Text(
                          'Payment Status',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'Unpaid',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                Colors.orange,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Payment will be made at the rental shop.',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // ID VERIFICATION
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),

              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(
                      8,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFE3F2FD,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),

                    child: const Icon(
                      Icons
                          .badge_outlined,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        const Text(
                          'ID Verification',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Your valid ID must be verified before the rental can be released.',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // CONFIRM BOOKING
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                onPressed:
                    widget.bicycle.available &&
                            !isConfirming
                        ? _confirmBooking
                        : null,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF1B4D3E,
                  ),

                  foregroundColor:
                      Colors.white,

                  disabledBackgroundColor:
                      Colors.grey[300],

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),

                child: isConfirming
                    ? const SizedBox(
                        width: 24,
                        height: 24,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,

              child: OutlinedButton(
                onPressed: isConfirming
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                        );
                      },

                style:
                    OutlinedButton.styleFrom(
                  side:
                      const BorderSide(
                    color:
                        Color(0xFF1B4D3E),
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),

                child: const Text(
                  'Back to Schedule',
                  style: TextStyle(
                    color:
                        Color(0xFF1B4D3E),
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.03),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(
                  8,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF7F9FB,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),

                child: Icon(
                  icon,
                  size: 18,
                  color:
                      const Color(
                    0xFF1B4D3E,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // SCHEDULE ROW
  // ============================================================

  Widget _buildScheduleRow({
    required IconData icon,
    required String label,
    required String date,
    required String time,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          padding:
              const EdgeInsets.all(8),

          decoration: BoxDecoration(
            color:
                const Color(0xFFF7F9FB),
            borderRadius:
                BorderRadius.circular(8),
          ),

          child: Icon(
            icon,
            size: 18,
            color:
                const Color(0xFF1B4D3E),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      Colors.grey[600],
                ),
              ),

              const SizedBox(height: 3),

              Text(
                date,
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                time,
                style: TextStyle(
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
  // AMOUNT ROW
  // ============================================================

  Widget _buildAmountRow(
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,

      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color:
                Colors.grey[700],
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.bold,
            color:
                Colors.black87,
          ),
        ),
      ],
    );
  }
}