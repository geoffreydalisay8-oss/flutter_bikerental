import 'package:flutter/material.dart';

import 'package:bikerental/model/bicycle_model.dart';
import 'package:bikerental/view/customer/id_verification_page.dart';

class BookingPage extends StatefulWidget {
  final BicycleModel bicycle;

  const BookingPage({
    super.key,
    required this.bicycle,
  });

  @override
  State<BookingPage> createState() =>
      _BookingPageState();
}

class _BookingPageState
    extends State<BookingPage> {

  DateTime? pickupDate;
  TimeOfDay? pickupTime;

  DateTime? returnDate;
  TimeOfDay? returnTime;

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();

    pickupDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    pickupTime = TimeOfDay(
      hour: now.hour,
      minute: now.minute,
    );

    final DateTime defaultReturn =
        now.add(
      const Duration(hours: 8),
    );

    returnDate = DateTime(
      defaultReturn.year,
      defaultReturn.month,
      defaultReturn.day,
    );

    returnTime = TimeOfDay(
      hour: defaultReturn.hour,
      minute: defaultReturn.minute,
    );
  }

  // ============================================================
  // PICKUP DATE
  // ============================================================

  Future<void> selectPickupDate() async {
    final DateTime? selected =
        await showDatePicker(
      context: context,
      initialDate:
          pickupDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      pickupDate = selected;

      if (returnDate != null &&
          returnDate!.isBefore(
            selected,
          )) {
        returnDate = selected;
      }
    });
  }

  // ============================================================
  // PICKUP TIME
  // ============================================================

  Future<void> selectPickupTime() async {
    final TimeOfDay? selected =
        await showTimePicker(
      context: context,
      initialTime:
          pickupTime ?? TimeOfDay.now(),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      pickupTime = selected;
    });
  }

  // ============================================================
  // RETURN DATE
  // ============================================================

  Future<void> selectReturnDate() async {
    final DateTime? selected =
        await showDatePicker(
      context: context,
      initialDate:
          returnDate ??
              pickupDate ??
              DateTime.now(),
      firstDate:
          pickupDate ??
              DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      returnDate = selected;
    });
  }

  // ============================================================
  // RETURN TIME
  // ============================================================

  Future<void> selectReturnTime() async {
    final TimeOfDay? selected =
        await showTimePicker(
      context: context,
      initialTime:
          returnTime ?? TimeOfDay.now(),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      returnTime = selected;
    });
  }

  // ============================================================
  // GET PICKUP DATETIME
  // ============================================================

  DateTime get pickupDateTime {
    return DateTime(
      pickupDate!.year,
      pickupDate!.month,
      pickupDate!.day,
      pickupTime!.hour,
      pickupTime!.minute,
    );
  }

  // ============================================================
  // GET RETURN DATETIME
  // ============================================================

  DateTime get returnDateTime {
    return DateTime(
      returnDate!.year,
      returnDate!.month,
      returnDate!.day,
      returnTime!.hour,
      returnTime!.minute,
    );
  }

  // ============================================================
  // DURATION
  // ============================================================

  Duration get rentalDuration {
    if (pickupDate == null ||
        pickupTime == null ||
        returnDate == null ||
        returnTime == null) {
      return Duration.zero;
    }

    return returnDateTime
        .difference(pickupDateTime);
  }

  // ============================================================
  // RENTAL DAYS
  // ============================================================

  int get rentalDays {
    final Duration duration =
        rentalDuration;

    if (duration.inMinutes <= 0) {
      return 0;
    }

    return (duration.inHours / 24)
        .ceil();
  }

  // ============================================================
  // RENTAL FEE
  // ============================================================

  double get rentalFee {
    final int days = rentalDays;

    if (days <= 0) {
      return 0;
    }

    return widget.bicycle.rentalRate *
        days;
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool get isFormValid {
    if (pickupDate == null ||
        pickupTime == null ||
        returnDate == null ||
        returnTime == null) {
      return false;
    }

    return returnDateTime
        .isAfter(pickupDateTime);
  }

  // ============================================================
  // INVALID MESSAGE
  // ============================================================

  void _showInvalidScheduleMessage() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Please select a valid rental schedule.',
        ),
      ),
    );
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
          'Schedule Rental',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ==================================================
              // BICYCLE
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(16),

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
                      width: 70,
                      height: 70,

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFF7F9FB,
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),

                      child: widget.bicycle
                                  .imageUrl
                                  .isNotEmpty
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                              child:
                                  Image.network(
                                widget.bicycle
                                    .imageUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.pedal_bike,
                              color:
                                  Color(
                                0xFF1B4D3E,
                              ),
                              size: 35,
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

                            style:
                                TextStyle(
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
                                  Color(
                                0xFF1B4D3E,
                              ),
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
                'PICKUP SCHEDULE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      Color(0xFF1B4D3E),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // PICKUP
              // ==================================================

              Row(
                children: [

                  Expanded(
                    child: _scheduleBox(
                      icon:
                          Icons.calendar_today,
                      label: 'Pickup Date',
                      value:
                          pickupDate == null
                              ? 'Select date'
                              : formatDate(
                                  pickupDate!,
                                ),
                      onTap:
                          selectPickupDate,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: _scheduleBox(
                      icon:
                          Icons.access_time,
                      label: 'Pickup Time',
                      value:
                          pickupTime == null
                              ? 'Select time'
                              : formatTime(
                                  pickupTime!,
                                ),
                      onTap:
                          selectPickupTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'RETURN SCHEDULE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      Color(0xFF1B4D3E),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // RETURN
              // ==================================================

              Row(
                children: [

                  Expanded(
                    child: _scheduleBox(
                      icon:
                          Icons.calendar_today,
                      label: 'Return Date',
                      value:
                          returnDate == null
                              ? 'Select date'
                              : formatDate(
                                  returnDate!,
                                ),
                      onTap:
                          selectReturnDate,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: _scheduleBox(
                      icon:
                          Icons.access_time,
                      label: 'Return Time',
                      value:
                          returnTime == null
                              ? 'Select time'
                              : formatTime(
                                  returnTime!,
                                ),
                      onTap:
                          selectReturnTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // RENTAL INFORMATION
              // ==================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: Column(
                  children: [

                    _infoRow(
                      'Rental Duration',
                      rentalDays > 0
                          ? '$rentalDays day(s)'
                          : '--',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _infoRow(
                      'Rental Rate',
                      '₱${widget.bicycle.rentalRate.toStringAsFixed(2)} / day',
                    ),

                    const Divider(
                      height: 24,
                    ),

                    _infoRow(
                      'Estimated Rental Fee',
                      '₱${rentalFee.toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ==================================================
              // CONTINUE
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed: isFormValid
                      ? () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      IDVerificationPage(
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

                                rentalFee:
                                    rentalFee,
                              ),
                            ),
                          );

                        }
                      : _showInvalidScheduleMessage,

                  style:
                      ElevatedButton
                          .styleFrom(
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

                  child: const Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [

                      Text(
                        'Continue to ID Verification',

                        style:
                            TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
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

  // ============================================================
  // SCHEDULE BOX
  // ============================================================

  Widget _scheduleBox({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {

    return GestureDetector(
      onTap: onTap,

      child: Container(
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

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Icon(
              icon,
              size: 18,
              color:
                  const Color(
                0xFF1B4D3E,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              label,

              style: TextStyle(
                fontSize: 10,
                color:
                    Colors.grey[500],
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              value,

              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    String label,
    String value, {
    bool bold = false,
  }) {

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
                Colors.grey[600],
          ),
        ),

        Text(
          value,

          style: TextStyle(
            fontSize: 13,
            fontWeight:
                bold
                    ? FontWeight.bold
                    : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}