
import 'package:flutter/material.dart';
import 'package:bikerental/model/bicycle_model.dart';
import 'package:bikerental/view/admin/staff/customer/booking_summary_page.dart';

class BookingPage extends StatefulWidget {
  final BicycleModel bicycle;

  const BookingPage({
    super.key,
    required this.bicycle,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? pickupDate;
  TimeOfDay? pickupTime;

  DateTime? returnDate;
  TimeOfDay? returnTime;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    pickupDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    pickupTime = TimeOfDay(
      hour: now.hour,
      minute: now.minute,
    );

    // Default return date is the same day.
    returnDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // Default return time is 8 hours after pickup.
    final futureTime = now.add(
      const Duration(hours: 8),
    );

    returnTime = TimeOfDay(
      hour: futureTime.hour,
      minute: futureTime.minute,
    );
  }

  // ============================================================
  // SELECT PICKUP DATE
  // ============================================================

  Future<void> selectPickupDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate:
          pickupDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() {
        pickupDate = date;

        // If the current return date is before
        // the new pickup date, move the return
        // date to the pickup date.
        if (returnDate == null ||
            returnDate!.isBefore(date)) {
          returnDate = date;
        }
      });
    }
  }

  // ============================================================
  // SELECT RETURN DATE
  // ============================================================

  Future<void> selectReturnDate() async {
    final minimumDate =
        pickupDate ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: minimumDate,
      lastDate: DateTime(2030),
      initialDate:
          returnDate != null &&
                  !returnDate!.isBefore(
                    minimumDate,
                  )
              ? returnDate!
              : minimumDate,
    );

    if (date != null) {
      setState(() {
        returnDate = date;
      });
    }
  }

  // ============================================================
  // SELECT PICKUP TIME
  // ============================================================

  Future<void> selectPickupTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime:
          pickupTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        pickupTime = time;
      });
    }
  }

  // ============================================================
  // SELECT RETURN TIME
  // ============================================================

  Future<void> selectReturnTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime:
          returnTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        returnTime = time;
      });
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select Date';
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  // ============================================================
  // GET WEEKDAY
  // ============================================================

  String _getWeekday(DateTime? date) {
    if (date == null) {
      return '';
    }

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return weekdays[date.weekday - 1];
  }

  // ============================================================
  // COMBINE DATE AND TIME
  // ============================================================

  DateTime? _combineDateTime(
    DateTime? date,
    TimeOfDay? time,
  ) {
    if (date == null || time == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // ============================================================
  // GET RENTAL DURATION
  // ============================================================

  Duration? _getRentalDuration() {
    final pickupDateTime =
        _combineDateTime(
      pickupDate,
      pickupTime,
    );

    final returnDateTime =
        _combineDateTime(
      returnDate,
      returnTime,
    );

    if (pickupDateTime == null ||
        returnDateTime == null) {
      return null;
    }

    return returnDateTime
        .difference(pickupDateTime);
  }

  // ============================================================
  // GET RENTAL DAYS
  //
  // The application uses a daily rate.
  //
  // Example:
  // 8 hours  = 1 day
  // 1 day    = 1 day
  // 1 day + 5 hours = 2 days
  // ============================================================

  int _getRentalDays() {
    final duration =
        _getRentalDuration();

    if (duration == null) {
      return 0;
    }

    if (duration.inMinutes <= 0) {
      return 0;
    }

    final minutesPerDay =
        const Duration(days: 1)
            .inMinutes;

    return (duration.inMinutes /
            minutesPerDay)
        .ceil();
  }

  // ============================================================
  // GET RENTAL FEE
  // ============================================================

  double _getRentalFee() {
    final rentalDays =
        _getRentalDays();

    return widget.bicycle.rentalRate *
        rentalDays;
  }

  // ============================================================
  // FORMAT DURATION
  // ============================================================

  String _formatDuration() {
    final duration =
        _getRentalDuration();

    if (duration == null) {
      return 'Select schedule';
    }

    if (duration.inMinutes <= 0) {
      return 'Invalid duration';
    }

    final days = duration.inDays;

    final hours =
        duration.inHours % 24;

    final minutes =
        duration.inMinutes % 60;

    String result = '';

    if (days > 0) {
      result +=
          '$days ${days == 1 ? 'day' : 'days'}';
    }

    if (hours > 0) {
      if (result.isNotEmpty) {
        result += ' ';
      }

      result +=
          '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    if (minutes > 0) {
      if (result.isNotEmpty) {
        result += ' ';
      }

      result +=
          '$minutes ${minutes == 1 ? 'min' : 'mins'}';
    }

    return result;
  }

  // ============================================================
  // CHECK IF SCHEDULE IS VALID
  // ============================================================

  bool _isScheduleValid() {
    final pickupDateTime =
        _combineDateTime(
      pickupDate,
      pickupTime,
    );

    final returnDateTime =
        _combineDateTime(
      returnDate,
      returnTime,
    );

    if (pickupDateTime == null ||
        returnDateTime == null) {
      return false;
    }

    return returnDateTime
        .isAfter(pickupDateTime);
  }

  // ============================================================
  // SHOW INVALID SCHEDULE MESSAGE
  // ============================================================

  void _showInvalidScheduleMessage() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Return date and time must be after pickup date and time.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFormValid =
        pickupDate != null &&
            pickupTime != null &&
            returnDate != null &&
            returnTime != null &&
            _isScheduleValid();

    final rentalDays =
        _getRentalDays();

    final rentalFee =
        _getRentalFee();

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

          onPressed: () =>
              Navigator.of(context).pop(),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'SCHEDULE RENTAL',

                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF1B4D3E),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // BICYCLE INFORMATION
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(12),

                decoration:
                    BoxDecoration(
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
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),

                          child:
                              Image.network(
                            widget.bicycle.imageUrl
                                    .isNotEmpty
                                ? widget.bicycle
                                    .imageUrl
                                : 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=800',

                            width: 90,
                            height: 80,

                            fit: BoxFit.cover,

                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Container(
                                width: 90,
                                height: 80,
                                color:
                                    Colors.grey[200],

                                child:
                                    const Icon(
                                  Icons
                                      .directions_bike,
                                  color:
                                      Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),

                        Positioned(
                          bottom: 6,
                          left: 6,

                          child:
                              Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFF1B4D3E,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                4,
                              ),
                            ),

                            child:
                                const Text(
                              'BIKE',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 8,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                            children: [
                              Expanded(
                                child:
                                    Text(
                                  widget
                                      .bicycle
                                      .name,

                                  style:
                                      const TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),

                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color:
                                      widget.bicycle
                                              .available
                                          ? const Color(
                                              0xFFE8F5E9,
                                            )
                                          : Colors
                                              .red
                                              .withOpacity(
                                              0.1,
                                            ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                ),

                                child:
                                    Text(
                                  widget
                                          .bicycle
                                          .available
                                      ? 'Active'
                                      : 'Unavailable',

                                  style:
                                      TextStyle(
                                    color: widget
                                            .bicycle
                                            .available
                                        ? const Color(
                                            0xFF2E7D32,
                                          )
                                        : Colors.red,

                                    fontSize:
                                        10,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 2,
                          ),

                          Text(
                            'Type: ${widget.bicycle.type}',

                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Colors.grey[600],
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          RichText(
                            text:
                                TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '₱${widget.bicycle.rentalRate.toStringAsFixed(2)}',

                                  style:
                                      const TextStyle(
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        Color(
                                      0xFF1B4D3E,
                                    ),
                                  ),
                                ),

                                TextSpan(
                                  text:
                                      ' / day',

                                  style:
                                      TextStyle(
                                    fontSize:
                                        12,
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
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // BOOKING WINDOW
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  const Text(
                    'Booking Window',

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    'Daily Rate Applied',

                    style: TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // PICKUP DATE
              // ==================================================

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .all(10),

                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xFFE8F5E9),
                        shape:
                            BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons
                            .calendar_today_outlined,

                        color:
                            Color(0xFF1B4D3E),

                        size: 20,
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
                          Text(
                            'PICKUP DATE',

                            style:
                                TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Colors.grey[
                                      500],
                              letterSpacing:
                                  0.5,
                            ),
                          ),

                          const SizedBox(
                            height: 2,
                          ),

                          Row(
                            children: [
                              Text(
                                pickupDate !=
                                        null
                                    ? _formatDate(
                                        pickupDate)
                                    : 'Select Date',

                                style:
                                    const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              if (pickupDate !=
                                  null) ...[
                                const SizedBox(
                                  width: 6,
                                ),

                                Text(
                                  _getWeekday(
                                    pickupDate,
                                  ),

                                  style:
                                      TextStyle(
                                    fontSize:
                                        12,
                                    color: Colors
                                        .grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    TextButton(
                      onPressed:
                          selectPickupDate,

                      style:
                          TextButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFFF0F4F2,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),

                      child:
                          const Text(
                        'Change',

                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFF1B4D3E,
                          ),
                          fontWeight:
                              FontWeight
                                  .bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // RETURN DATE
              // ==================================================

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .all(10),

                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xFFE8F5E9),
                        shape:
                            BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons
                            .event_available_outlined,

                        color:
                            Color(0xFF1B4D3E),

                        size: 20,
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
                          Text(
                            'RETURN DATE',

                            style:
                                TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Colors.grey[
                                      500],
                              letterSpacing:
                                  0.5,
                            ),
                          ),

                          const SizedBox(
                            height: 2,
                          ),

                          Row(
                            children: [
                              Text(
                                returnDate !=
                                        null
                                    ? _formatDate(
                                        returnDate)
                                    : 'Select Date',

                                style:
                                    const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              if (returnDate !=
                                  null) ...[
                                const SizedBox(
                                  width: 6,
                                ),

                                Text(
                                  _getWeekday(
                                    returnDate,
                                  ),

                                  style:
                                      TextStyle(
                                    fontSize:
                                        12,
                                    color: Colors
                                        .grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    TextButton(
                      onPressed:
                          selectReturnDate,

                      style:
                          TextButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFFF0F4F2,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),

                      child:
                          const Text(
                        'Change',

                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFF1B4D3E,
                          ),
                          fontWeight:
                              FontWeight
                                  .bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // PICKUP TIME + RETURN TIME
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets
                              .all(14),

                      decoration:
                          BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .access_time,

                                size: 16,

                                color:
                                    Color(
                                  0xFF1B4D3E,
                                ),
                              ),

                              const SizedBox(
                                width: 6,
                              ),

                              Text(
                                'PICKUP TIME',

                                style:
                                    TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      Colors.grey[
                                          500],
                                  letterSpacing:
                                      0.5,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          GestureDetector(
                            onTap:
                                selectPickupTime,

                            child:
                                Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF7F9FB,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,

                                children: [
                                  Text(
                                    pickupTime !=
                                            null
                                        ? pickupTime!
                                            .format(
                                            context,
                                          )
                                        : 'Select Time',

                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      fontSize:
                                          14,
                                    ),
                                  ),

                                  const Icon(
                                    Icons
                                        .unfold_more,
                                    size: 16,
                                    color:
                                        Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            'Hub opens 7:30 AM',

                            style:
                                TextStyle(
                              fontSize: 10,
                              color:
                                  Colors.grey[
                                      500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets
                              .all(14),

                      decoration:
                          BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .history_toggle_off,

                                size: 16,

                                color:
                                    Color(
                                  0xFF1B4D3E,
                                ),
                              ),

                              const SizedBox(
                                width: 6,
                              ),

                              Expanded(
                                child: Text(
                                  'RETURN TIME',

                                  style:
                                      TextStyle(
                                    fontSize:
                                        9,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        Colors.grey[
                                            500],
                                    letterSpacing:
                                        0.5,
                                  ),

                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          GestureDetector(
                            onTap:
                                selectReturnTime,

                            child:
                                Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF7F9FB,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,

                                children: [
                                  Text(
                                    returnTime !=
                                            null
                                        ? returnTime!
                                            .format(
                                            context,
                                          )
                                        : 'Select Time',

                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      fontSize:
                                          14,
                                    ),
                                  ),

                                  const Icon(
                                    Icons
                                        .unfold_more,
                                    size: 16,
                                    color:
                                        Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Row(
                            children: [
                              const Icon(
                                Icons.timelapse,

                                size: 12,

                                color:
                                    Color(
                                  0xFF1B4D3E,
                                ),
                              ),

                              const SizedBox(
                                width: 4,
                              ),

                              Expanded(
                                child:
                                    Text(
                                  _formatDuration(),

                                  style:
                                      TextStyle(
                                    fontSize:
                                        10,
                                    color:
                                        Colors.grey[
                                            700],
                                    fontWeight:
                                        FontWeight
                                            .w500,
                                  ),

                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // ESTIMATED TOTAL
              // ==================================================

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons
                              .receipt_long_outlined,

                          size: 18,

                          color:
                              Colors.grey[700],
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              rentalDays > 0
                                  ? 'Estimated Total ($rentalDays ${rentalDays == 1 ? 'day' : 'days'})'
                                  : 'Estimated Total',

                              style:
                                  TextStyle(
                                fontSize:
                                    13,
                                color:
                                    Colors.grey[
                                        700],
                                fontWeight:
                                    FontWeight
                                        .w500,
                              ),
                            ),

                            const SizedBox(
                              height: 2,
                            ),

                            Text(
                              _formatDuration(),

                              style:
                                  TextStyle(
                                fontSize:
                                    10,
                                color:
                                    Colors.grey[
                                        500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Text(
                      '₱${rentalFee.toStringAsFixed(2)}',

                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF1B4D3E),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ==================================================
              // REVIEW BOOKING BUTTON
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                height: 52,

                child:
                    ElevatedButton(
                  onPressed:
                      isFormValid
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          BookingSummaryPage(
                                    bicycle:
                                        widget.bicycle,

                                    pickupDate:
                                        pickupDate!,

                                    pickupTime:
                                        pickupTime!,

                                    returnDate:
                                        returnDate!,

                                    returnTime:
                                        returnTime!,

                                    // If your current
                                    // BookingSummaryPage
                                    // does not have this
                                    // parameter yet,
                                    // remove this line
                                    // or add the parameter
                                    // there.
                                    rentalFee:
                                        rentalFee,
                                  ),
                                ),
                              );
                            }
                          : () {
                              _showInvalidScheduleMessage();
                            },

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF1B4D3E,
                    ),

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

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: const [
                      Text(
                        'Review Booking Summary',

                        style:
                            TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      SizedBox(
                        width: 8,
                      ),

                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

