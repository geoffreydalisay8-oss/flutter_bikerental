import 'package:flutter/material.dart';
import 'package:bikerental/model/bicycle_model.dart';
import 'package:bikerental/view/admin/staff/customer/id_verification_page.dart';

class BookingSummaryPage extends StatelessWidget {
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

  String _formatDate(DateTime date) {
    final months = [
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
      'December'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Combine DateTime and TimeOfDay
  DateTime _combineDateTime(
    DateTime date,
    TimeOfDay time,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // Calculate rental duration
  Duration _getRentalDuration() {
    final pickupDateTime = _combineDateTime(
      pickupDate,
      pickupTime,
    );

    final returnDateTime = _combineDateTime(
      returnDate,
      returnTime,
    );

    return returnDateTime.difference(
      pickupDateTime,
    );
  }

  // Calculate rental days
  int _getRentalDays() {
    final duration = _getRentalDuration();

    if (duration.inMinutes <= 0) {
      return 0;
    }

    const minutesPerDay = 24 * 60;

    return (duration.inMinutes / minutesPerDay).ceil();
  }

  // Format rental duration
  String _formatDuration() {
    final duration = _getRentalDuration();

    if (duration.inMinutes <= 0) {
      return 'Invalid duration';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    String result = '';

    if (days > 0) {
      result += '$days ${days == 1 ? 'Day' : 'Days'}';
    }

    if (hours > 0) {
      if (result.isNotEmpty) {
        result += ' ';
      }

      result += '$hours ${hours == 1 ? 'Hour' : 'Hours'}';
    }

    if (minutes > 0) {
      if (result.isNotEmpty) {
        result += ' ';
      }

      result += '$minutes ${minutes == 1 ? 'Minute' : 'Minutes'}';
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    const double bookingFee = 50.0;

    final int rentalDays = _getRentalDays();

    final double totalAmount =
        rentalFee + bookingFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),

          onPressed: () =>
              Navigator.of(context).pop(),
        ),

        title: const Text(
          'Booking summary',

          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: false,

        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),

            child: CircleAvatar(
              radius: 18,

              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),

          child: Column(
            children: [
              // ==================================================
              // MAIN CARD
              // ==================================================

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(16),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.03),

                      blurRadius: 10,

                      offset:
                          const Offset(0, 2),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    // ==================================================
                    // REFERENCE HEADER
                    // ==================================================

                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        0,
                      ),

                      child: Align(
                        alignment:
                            Alignment.centerRight,

                        child: Text(
                          'Ref: #BK-0842',

                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Colors.grey[600],
                            fontFamily:
                                'monospace',
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // BICYCLE INFORMATION
                    // ==================================================

                    Padding(
                      padding:
                          const EdgeInsets.all(16),

                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),

                            child:
                                Image.network(
                              bicycle.imageUrl
                                      .isNotEmpty
                                  ? bicycle.imageUrl
                                  : 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=400',

                              width: 80,
                              height: 80,

                              fit: BoxFit.cover,

                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) =>
                                      Container(
                                width: 80,
                                height: 80,
                                color:
                                    Colors.grey[200],

                                child:
                                    const Icon(
                                  Icons
                                      .directions_bike,
                                  color:
                                      Color(
                                    0xFF1B4D3E,
                                  ),
                                  size: 36,
                                ),
                              ),
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
                                  bicycle.name,

                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        Colors.black87,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Type: ${bicycle.type}',

                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.grey[
                                            600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),

                    // ==================================================
                    // RENTAL PERIOD
                    // ==================================================

                    Padding(
                      padding:
                          const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                            children: [
                              const Text(
                                'RENTAL PERIOD',

                                style:
                                    TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      Colors.grey,
                                  letterSpacing:
                                      0.5,
                                ),
                              ),

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
                                      Colors.grey[
                                          200],

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                ),

                                child: Text(
                                  rentalDays == 1
                                      ? 'Single Day'
                                      : '$rentalDays Days',

                                  style:
                                      const TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight
                                            .bold,
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

                          // Pickup Date
                          _buildIconRow(
                            icon: Icons
                                .calendar_today_outlined,

                            title: 'Pickup Date',

                            value:
                                _formatDate(
                              pickupDate,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // Return Date
                          _buildIconRow(
                            icon: Icons
                                .event_available_outlined,

                            title: 'Return Date',

                            value:
                                _formatDate(
                              returnDate,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // Time
                          _buildIconRow(
                            icon:
                                Icons.access_time,

                            title: 'Time Slot',

                            value:
                                '${pickupTime.format(context)} – ${returnTime.format(context)}',

                            subtitle:
                                _formatDuration(),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // Location
                          _buildIconRow(
                            icon: Icons
                                .location_on_outlined,

                            title:
                                'Pickup & Return Point',

                            value:
                                'Main Campus Hub',

                            subtitle:
                                'Near Engineering Quadrangle, Bay #4',
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),

                    // ==================================================
                    // FEE CALCULATION
                    // ==================================================

                    Padding(
                      padding:
                          const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Text(
                            'FEE CALCULATION',

                            style:
                                TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Colors.grey,
                              letterSpacing:
                                  0.5,
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // Rental Fee
                          _buildPriceRow(
                            'Rental Fee ($rentalDays ${rentalDays == 1 ? 'Day' : 'Days'})',

                            '₱${rentalFee.toStringAsFixed(2)}',
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          // Booking Fee
                          _buildPriceRowWithInfo(
                            'Booking & Fleet Fee',

                            '₱${bookingFee.toStringAsFixed(2)}',
                          ),

                          const Padding(
                            padding:
                                EdgeInsets.symmetric(
                              vertical: 14,
                            ),

                            child: Divider(
                              height: 1,
                            ),
                          ),

                          // Total
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  const Text(
                                    'Total Amount',

                                    style:
                                        TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  Text(
                                    'Rental Fee + Booking Fee',

                                    style:
                                        TextStyle(
                                      fontSize: 10,
                                      color: Colors
                                          .grey[600],
                                    ),
                                  ),
                                ],
                              ),

                              Text(
                                '₱${totalAmount.toStringAsFixed(2)}',

                                style:
                                    const TextStyle(
                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      Color(
                                    0xFF1B4D3E,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // CONTINUE BUTTON
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                height: 52,

                child:
                    ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (context) =>
                            IDVerificationPage(
                          bicycle: bicycle,

                          pickupDate:
                              pickupDate,

                          pickupTime:
                              pickupTime,

                          returnDate:
                              returnDate,

                          returnTime:
                              returnTime,
                        ),
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

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: const [
                      Text(
                        'Continue to Payment',

                        style:
                            TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(
                        width: 8,
                      ),

                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // EDIT BOOKING
              // ==================================================

              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context)
                        .pop(),

                icon: const Icon(
                  Icons
                      .edit_calendar_outlined,

                  size: 18,

                  color:
                      Colors.black87,
                ),

                label: const Text(
                  'Edit Booking',

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.black87,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ICON ROW
  // ============================================================

  Widget _buildIconRow({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
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
            color: Colors.black87,
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

                style: TextStyle(
                  fontSize: 10,
                  color:
                      Colors.grey[600],
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,

                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Colors.black87,
                ),
              ),

              if (subtitle != null) ...[
                const SizedBox(
                  height: 2,
                ),

                Text(
                  subtitle,

                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRICE ROW
  // ============================================================

  Widget _buildPriceRow(
    String label,
    String amount, {
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,

      children: [
        Expanded(
          child: Text(
            label,

            style: TextStyle(
              fontSize: 13,
              color:
                  Colors.grey[700],
            ),
          ),
        ),

        Text(
          amount,

          style: TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.bold,
            color:
                textColor ??
                    Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRICE ROW WITH INFO ICON
  // ============================================================

  Widget _buildPriceRowWithInfo(
    String label,
    String amount,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,

      children: [
        Row(
          children: [
            Text(
              label,

              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.grey[700],
              ),
            ),

            const SizedBox(
              width: 4,
            ),

            Icon(
              Icons
                  .help_outline_rounded,

              size: 14,

              color:
                  Colors.grey[500],
            ),
          ],
        ),

        Text(
          amount,

          style:
              const TextStyle(
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
