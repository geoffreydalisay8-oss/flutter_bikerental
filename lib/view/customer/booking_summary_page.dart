
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bikerental/model/bicycle_model.dart';
import 'package:bikerental/model/booking_model.dart';
import 'package:bikerental/service/booking_service.dart';
import 'package:bikerental/view/customer/home_page.dart';

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
  // PAYMENT
  // ============================================================

  String selectedPaymentMethod =
      'Pay at Rental Shop';

  final TextEditingController cardNameController =
      TextEditingController();

  final TextEditingController cardNumberController =
      TextEditingController();

  final TextEditingController expiryController =
      TextEditingController();

  final TextEditingController cvvController =
      TextEditingController();

  // ============================================================
  // PICKUP DATETIME
  // ============================================================

  DateTime get pickupDateTime {
    return DateTime(
      widget.pickupDate.year,
      widget.pickupDate.month,
      widget.pickupDate.day,
      widget.pickupTime.hour,
      widget.pickupTime.minute,
    );
  }

  // ============================================================
  // RETURN DATETIME
  // ============================================================

  DateTime get returnDateTime {
    return DateTime(
      widget.returnDate.year,
      widget.returnDate.month,
      widget.returnDate.day,
      widget.returnTime.hour,
      widget.returnTime.minute,
    );
  }

  // ============================================================
  // TOTAL
  // ============================================================

  double get totalAmount {
    return widget.rentalFee + bookingFee;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(DateTime date) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String formatTime(TimeOfDay time) {
    return time.format(context);
  }

  // ============================================================
  // VALIDATE CARD
  // ============================================================

  bool _validateCard() {
    if (cardNameController.text.trim().isEmpty) {
      _showError(
        'Please enter the cardholder name.',
      );
      return false;
    }

    final String cardNumber =
        cardNumberController.text
            .replaceAll(' ', '')
            .trim();

    if (cardNumber.length < 12) {
      _showError(
        'Please enter a valid card number.',
      );
      return false;
    }

    if (expiryController.text.trim().isEmpty) {
      _showError(
        'Please enter the card expiry date.',
      );
      return false;
    }

    if (cvvController.text.trim().length < 3) {
      _showError(
        'Please enter a valid CVV.',
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ============================================================
  // CONFIRM BOOKING
  // ============================================================

  Future<void> _confirmBooking() async {
    if (isConfirming) {
      return;
    }

    if (selectedPaymentMethod == 'Card') {
      if (!_validateCard()) {
        return;
      }
    }

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be logged in.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isConfirming = true;
    });

    try {
      // ----------------------------------------------------------
      // PAYMENT STATUS
      // ----------------------------------------------------------

      String paymentStatus;

      if (selectedPaymentMethod == 'Card') {
        paymentStatus = 'Paid';
      } else {
        paymentStatus = 'Unpaid';
      }

      // ----------------------------------------------------------
      // CREATE BOOKING
      // ----------------------------------------------------------

      final BookingModel booking =
          BookingModel(
        id: '',
        customerId: currentUser.uid,
        bicycleId: widget.bicycle.id,
        bicycleName: widget.bicycle.name,
        pickupDate: pickupDateTime,
        returnDate: returnDateTime,
        rentalFee: widget.rentalFee,
        bookingFee: bookingFee,
        totalAmount: totalAmount,
        paymentMethod: selectedPaymentMethod,
        paymentStatus: paymentStatus,
        bookingStatus: 'Pending',
      );

      final String bookingId =
          await bookingService.createBooking(
        booking,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isConfirming = false;
      });

      _showBookingSuccess(
        bookingId,
        paymentStatus,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isConfirming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create booking: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  void _showBookingSuccess(
    String bookingId,
    String paymentStatus,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Column(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),

              SizedBox(
                height: 12,
              ),

              Text(
                'Booking Submitted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your booking has been submitted and is waiting for staff approval.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF7F9FB),
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: Column(
                  children: [
                    const Text(
                      'BOOKING ID',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      bookingId,
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF1B4D3E),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'Payment: $paymentStatus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            paymentStatus ==
                                    'Paid'
                                ? Colors.green
                                : Colors.orange
                                    .shade800,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      'Status: Pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          actionsPadding:
              const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20,
          ),

          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,

              child: ElevatedButton(
                onPressed: () {
                  // ------------------------------------------------
                  // CLOSE SUCCESS DIALOG
                  // ------------------------------------------------

                  Navigator.of(
                    dialogContext,
                  ).pop();

                  // ------------------------------------------------
                  // GO DIRECTLY TO CUSTOMER HOME
                  // WITH MY BOOKINGS SELECTED
                  // ------------------------------------------------

                  Navigator.of(
                    context,
                  ).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          const CustomerHomePage(
                        initialIndex: 2,
                      ),
                    ),
                    (route) => false,
                  );
                },

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF1B4D3E),

                  foregroundColor:
                      Colors.white,

                  elevation: 0,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),

                child: const Text(
                  'View My Bookings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PAYMENT OPTION
  // ============================================================

  Widget _paymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final bool selected =
        selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = value;
        });
      },

      child: Container(
        width: double.infinity,
        margin:
            const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEFF7F3)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color: selected
                ? const Color(0xFF1B4D3E)
                : Colors.grey.shade200,

            width: selected ? 1.5 : 1,
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,

              decoration:
                  BoxDecoration(
                color: selected
                    ? const Color(0xFFDDEFE7)
                    : const Color(0xFFF7F9FB),

                borderRadius:
                    BorderRadius.circular(10),
              ),

              child: Icon(
                icon,
                color:
                    const Color(0xFF1B4D3E),
                size: 22,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,

              color: selected
                  ? const Color(0xFF1B4D3E)
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD PAYMENT FORM
  // ============================================================

  Widget _buildCardPaymentForm() {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(top: 4),

      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF7F9FB),

        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.credit_card,
                color:
                    Color(0xFF1B4D3E),
                size: 20,
              ),

              SizedBox(
                width: 8,
              ),

              Text(
                'Card Payment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          TextField(
            controller:
                cardNameController,

            decoration:
                _inputDecoration(
              'Cardholder Name',
              Icons.person_outline,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          TextField(
            controller:
                cardNumberController,

            keyboardType:
                TextInputType.number,

            maxLength: 19,

            decoration:
                _inputDecoration(
              'Card Number',
              Icons.credit_card,
            ).copyWith(
              counterText: '',
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                      expiryController,

                  keyboardType:
                      TextInputType.datetime,

                  maxLength: 5,

                  decoration:
                      _inputDecoration(
                    'MM/YY',
                    Icons.calendar_today_outlined,
                  ).copyWith(
                    counterText: '',
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: TextField(
                  controller:
                      cvvController,

                  keyboardType:
                      TextInputType.number,

                  obscureText: true,

                  maxLength: 4,

                  decoration:
                      _inputDecoration(
                    'CVV',
                    Icons.lock_outline,
                  ).copyWith(
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Icon(
                Icons.info_outline,
                size: 15,
                color: Colors.grey,
              ),

              SizedBox(
                width: 6,
              ),

              Expanded(
                child: Text(
                  'This is a simulated card payment for the application prototype. Card details are not stored.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,

      prefixIcon: Icon(
        icon,
        size: 19,
        color:
            Colors.grey.shade500,
      ),

      filled: true,

      fillColor: Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),

        borderSide:
            BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),

        borderSide:
            BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),

      focusedBorder:
          const OutlineInputBorder(
        borderRadius:
            BorderRadius.all(
          Radius.circular(10),
        ),

        borderSide:
            BorderSide(
          color:
              Color(0xFF1B4D3E),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context) {
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
            color: Colors.black,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Booking Summary',

          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'BICYCLE',

                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF1B4D3E),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Container(
                padding:
                    const EdgeInsets.all(16),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 75,
                      height: 75,

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFF7F9FB,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),

                      child: widget
                              .bicycle
                              .imageUrl
                              .isNotEmpty
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(12),

                              child:
                                  Image.network(
                                widget.bicycle
                                    .imageUrl,

                                fit:
                                    BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.pedal_bike,
                              size: 36,
                              color:
                                  Color(0xFF1B4D3E),
                            ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            widget.bicycle.name,

                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            widget.bicycle.type,

                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Colors.grey[600],
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            '₱${widget.bicycle.rentalRate.toStringAsFixed(2)} / day',

                            style:
                                const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF1B4D3E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'RENTAL SCHEDULE',

                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF1B4D3E),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: Column(
                  children: [
                    _scheduleRow(
                      icon: Icons.login,
                      title: 'Pickup',
                      date:
                          formatDate(
                        widget.pickupDate,
                      ),
                      time:
                          formatTime(
                        widget.pickupTime,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _scheduleRow(
                      icon: Icons.logout,
                      title: 'Return',
                      date:
                          formatDate(
                        widget.returnDate,
                      ),
                      time:
                          formatTime(
                        widget.returnTime,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'RENTAL DETAILS',

                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF1B4D3E),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: Column(
                  children: [
                    _priceRow(
                      'Rental Fee',
                      widget.rentalFee,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _priceRow(
                      'Booking Fee',
                      bookingFee,
                    ),

                    const Divider(
                      height: 24,
                    ),

                    _priceRow(
                      'Total Amount',
                      totalAmount,
                      bold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'PAYMENT METHOD',

                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF1B4D3E),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              _paymentOption(
                title: 'Card',
                subtitle:
                    'Pay securely using a card',
                icon:
                    Icons.credit_card_outlined,
                value: 'Card',
              ),

              _paymentOption(
                title:
                    'Pay at Rental Shop',
                subtitle:
                    'Pay when you pick up the bicycle',
                icon:
                    Icons.storefront_outlined,
                value:
                    'Pay at Rental Shop',
              ),

              if (selectedPaymentMethod ==
                  'Card')
                _buildCardPaymentForm(),

              const SizedBox(
                height: 18,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(10),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFF7F9FB,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),

                      child: const Icon(
                        Icons.payments_outlined,
                        color:
                            Color(0xFF1B4D3E),
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Text(
                            'Payment Status',

                            style:
                                TextStyle(
                              fontSize: 11,
                              color:
                                  Colors.grey,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            selectedPaymentMethod ==
                                    'Card'
                                ? 'Paid'
                                : 'Unpaid',

                            style:
                                TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.bold,

                              color:
                                  selectedPaymentMethod ==
                                          'Card'
                                      ? const Color(
                                          0xFF008955,
                                        )
                                      : Colors.orange
                                          .shade800,
                            ),
                          ),

                          const SizedBox(
                            height: 2,
                          ),

                          Text(
                            selectedPaymentMethod ==
                                    'Card'
                                ? 'Payment will be processed before booking confirmation.'
                                : 'Payment can be made at the rental shop.',

                            style:
                                const TextStyle(
                              fontSize: 11,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFEFF7F3),

                  borderRadius:
                      BorderRadius.circular(16),

                  border:
                      Border.all(
                    color:
                        const Color(0xFFD5E9DF),
                  ),
                ),

                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Icon(
                      Icons
                          .verified_user_outlined,

                      color:
                          Color(0xFF1B4D3E),

                      size: 24,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            'ID Verification Submitted',

                            style:
                                TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          SizedBox(
                            height: 5,
                          ),

                          Text(
                            'Your valid ID must be verified before the rental can be released.',

                            style:
                                TextStyle(
                              fontSize: 11,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width:
                    double.infinity,

                height: 52,

                child:
                    ElevatedButton(
                  onPressed:
                      isConfirming
                          ? null
                          : _confirmBooking,

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(0xFF1B4D3E),

                    disabledBackgroundColor:
                        Colors.grey[300],

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  child:
                      isConfirming
                          ? const SizedBox(
                              width: 22,
                              height: 22,

                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2.5,
                              ),
                            )
                          : const Text(
                              'Confirm Booking',

                              style:
                                  TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              SizedBox(
                width:
                    double.infinity,

                height: 48,

                child:
                    OutlinedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        const Color(
                      0xFF1B4D3E,
                    ),

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

                  child:
                      const Text(
                    'Back to ID Verification',

                    style:
                        TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SCHEDULE ROW
  // ============================================================

  Widget _scheduleRow({
    required IconData icon,
    required String title,
    required String date,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.all(10),

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFF7F9FB),

            borderRadius:
                BorderRadius.circular(10),
          ),

          child: Icon(
            icon,

            color:
                const Color(0xFF1B4D3E),

            size: 20,
          ),
        ),

        const SizedBox(
          width: 12,
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
                      Colors.grey[500],
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                date,

                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Text(
          time,

          style:
              const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.bold,
            color:
                Color(0xFF1B4D3E),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRICE ROW
  // ============================================================

  Widget _priceRow(
    String label,
    double amount, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [
        Text(
          label,

          style: TextStyle(
            fontSize:
                bold ? 14 : 13,

            fontWeight:
                bold
                    ? FontWeight.bold
                    : FontWeight.normal,

            color:
                Colors.grey[700],
          ),
        ),

        Text(
          '₱${amount.toStringAsFixed(2)}',

          style: TextStyle(
            fontSize:
                bold ? 16 : 13,

            fontWeight:
                FontWeight.bold,

            color: bold
                ? const Color(
                    0xFF1B4D3E,
                  )
                : Colors.black,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    cardNameController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();

    super.dispose();
  }
}