import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() =>
      _SalesReportPageState();
}

class _SalesReportPageState
    extends State<SalesReportPage> {
  static const Color primaryColor =
      Color(0xFF1B4D3E);

  String selectedPeriod = 'Today';

  // ============================================================
  // START DATE
  // ============================================================

  DateTime _getStartDate(DateTime now) {
    if (selectedPeriod == 'Today') {
      return DateTime(
        now.year,
        now.month,
        now.day,
      );
    }

    if (selectedPeriod == 'Month') {
      return DateTime(
        now.year,
        now.month,
        1,
      );
    }

    return DateTime(
      now.year,
      1,
      1,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F9FA),
        elevation: 0,

        title: const Text(
          'Sales Report',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .snapshots(),

        builder: (
          context,
          snapshot,
        ) {
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
                    const EdgeInsets.all(20),
                child: Text(
                  'Error loading sales report:\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          final now = DateTime.now();

          final startDate =
              _getStartDate(now);

          final documents =
              snapshot.data?.docs ?? [];

          // ======================================================
          // GET PAID BOOKINGS
          // ======================================================

          final List<QueryDocumentSnapshot>
              paidBookings = [];

          for (final document
              in documents) {
            final data =
                document.data()
                    as Map<String, dynamic>;

            final paymentStatus =
                (data['paymentStatus'] ??
                        '')
                    .toString()
                    .toLowerCase();

            if (paymentStatus != 'paid') {
              continue;
            }

            final DateTime transactionDate =
                _getTransactionDate(data);

            if (transactionDate
                .isBefore(startDate)) {
              continue;
            }

            paidBookings.add(document);
          }

          // Sort newest first
          paidBookings.sort(
            (a, b) {
              final dataA =
                  a.data()
                      as Map<String, dynamic>;

              final dataB =
                  b.data()
                      as Map<String, dynamic>;

              final dateA =
                  _getTransactionDate(dataA);

              final dateB =
                  _getTransactionDate(dataB);

              return dateB.compareTo(dateA);
            },
          );

          // ======================================================
          // TOTAL INCOME
          // ======================================================

          double totalIncome = 0;

          for (final booking
              in paidBookings) {
            final data =
                booking.data()
                    as Map<String, dynamic>;

            totalIncome +=
                _getAmount(data);
          }

          return ListView(
            padding:
                const EdgeInsets.all(16),

            children: [
              // ==================================================
              // HEADER
              // ==================================================

              const Text(
                'Income Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Track your rental income and system transactions.',
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // PERIOD SELECTOR
              // ==================================================

              Row(
                children: [
                  _periodButton('Today'),
                  _periodButton('Month'),
                  _periodButton('Year'),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // TOTAL INCOME CARD
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(20),

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
                          .withOpacity(
                        0.03,
                      ),
                      blurRadius: 10,
                      offset:
                          const Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      '$selectedPeriod Income',
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      '₱${totalIncome.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        fontSize: 30,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      '${paidBookings.length} paid booking(s)',
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // GRAPH TITLE
              // ==================================================

              const Text(
                'INCOME GRAPH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF90A4AE),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // GRAPH
              // ==================================================

              Container(
                height: 300,

                padding:
                    const EdgeInsets.all(
                  16,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: _buildChart(
                  paidBookings,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // PAYMENT SUMMARY
              // ==================================================

              const Text(
                'PAYMENT SUMMARY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF90A4AE),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              if (paidBookings.isEmpty)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 20,
                  ),

                  child: Center(
                    child: Text(
                      'No paid bookings found for this period.',
                    ),
                  ),
                )
              else
                ...paidBookings.map(
                  (booking) {
                    return _buildPaymentCard(
                      booking,
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // PAYMENT CARD
  // ============================================================

  Widget _buildPaymentCard(
    QueryDocumentSnapshot booking,
  ) {
    final data =
        booking.data()
            as Map<String, dynamic>;

    final amount =
        _getAmount(data);

    final method =
        (data['paymentMethod'] ??
                'N/A')
            .toString();

    final bicycleName =
        (data['bicycleName'] ??
                'Bicycle')
            .toString();

    final date =
        _getTransactionDate(data);

    return Card(
      elevation: 0,

      color: Colors.white,

      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              const Color(
            0xFFE8F5E9,
          ),

          child: const Icon(
            Icons.payment,
            color: primaryColor,
          ),
        ),

        title: Text(
          '₱${amount.toStringAsFixed(2)}',

          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle: Text(
          'Booking: #${booking.id}\n'
          '$bicycleName\n'
          'Method: $method\n'
          '${DateFormat(
            'MMM dd, yyyy • hh:mm a',
          ).format(date)}',
        ),

        isThreeLine: true,
      ),
    );
  }

  // ============================================================
  // GET AMOUNT
  // ============================================================

  double _getAmount(
    Map<String, dynamic> data,
  ) {
    final value =
        data['totalAmount'];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ??
          0;
    }

    return 0;
  }

  // ============================================================
  // GET TRANSACTION DATE
  // ============================================================

  DateTime _getTransactionDate(
    Map<String, dynamic> data,
  ) {
    // First use paymentDate
    final paymentDate =
        data['paymentDate'];

    if (paymentDate is Timestamp) {
      return paymentDate.toDate();
    }

    if (paymentDate is DateTime) {
      return paymentDate;
    }

    // For old bookings without
    // paymentDate, use pickupDate.
    final pickupDate =
        data['pickupDate'];

    if (pickupDate is Timestamp) {
      return pickupDate.toDate();
    }

    if (pickupDate is DateTime) {
      return pickupDate;
    }

    if (pickupDate is String) {
      return DateTime.tryParse(
            pickupDate,
          ) ??
          DateTime.now();
    }

    return DateTime.now();
  }

  // ============================================================
  // PERIOD BUTTON
  // ============================================================

  Widget _periodButton(
    String period,
  ) {
    final bool isSelected =
        selectedPeriod == period;

    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.only(
          right: 6,
        ),

        child: ElevatedButton(
          onPressed: () {
            setState(() {
              selectedPeriod =
                  period;
            });
          },

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                isSelected
                    ? primaryColor
                    : Colors.white,

            foregroundColor:
                isSelected
                    ? Colors.white
                    : Colors.black,

            elevation: 0,

            side: BorderSide(
              color:
                  Colors.grey.shade300,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
          ),

          child: Text(period),
        ),
      ),
    );
  }

  // ============================================================
  // CHART
  // ============================================================

  Widget _buildChart(
    List<QueryDocumentSnapshot>
        bookings,
  ) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text(
          'No income data available.',
        ),
      );
    }

    if (selectedPeriod ==
        'Today') {
      return _buildTodayChart(
        bookings,
      );
    }

    if (selectedPeriod ==
        'Month') {
      return _buildMonthChart(
        bookings,
      );
    }

    return _buildYearChart(
      bookings,
    );
  }

  // ============================================================
  // TODAY CHART
  // ============================================================

  Widget _buildTodayChart(
    List<QueryDocumentSnapshot>
        bookings,
  ) {
    final List<double>
        hourlyIncome =
        List.filled(24, 0);

    for (final booking
        in bookings) {
      final data =
          booking.data()
              as Map<String, dynamic>;

      final date =
          _getTransactionDate(data);

      if (date.day ==
              DateTime.now().day &&
          date.month ==
              DateTime.now().month &&
          date.year ==
              DateTime.now().year) {
        hourlyIncome[date.hour] +=
            _getAmount(data);
      }
    }

    return LineChart(
      LineChartData(
        minY: 0,

        gridData:
            const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),

        borderData:
            FlBorderData(
          show: false,
        ),

        titlesData:
            FlTitlesData(
          topTitles:
              const AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: false,
            ),
          ),

          rightTitles:
              const AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: false,
            ),
          ),

          leftTitles:
              AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: true,
              reservedSize: 45,

              getTitlesWidget:
                  (value, meta) {
                return Text(
                  '₱${value.toInt()}',
                  style:
                      const TextStyle(
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),

          bottomTitles:
              AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 6,

              getTitlesWidget:
                  (value, meta) {
                return Text(
                  '${value.toInt()}:00',
                  style:
                      const TextStyle(
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots:
                List.generate(
              24,
              (index) {
                return FlSpot(
                  index.toDouble(),
                  hourlyIncome[index],
                );
              },
            ),

            isCurved: true,

            color: primaryColor,

            barWidth: 3,

            dotData:
                const FlDotData(
              show: false,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTH CHART
  // ============================================================

  Widget _buildMonthChart(
    List<QueryDocumentSnapshot>
        bookings,
  ) {
    final now =
        DateTime.now();

    final daysInMonth =
        DateTime(
      now.year,
      now.month + 1,
      0,
    ).day;

    final List<double>
        dailyIncome =
        List.filled(
      daysInMonth,
      0,
    );

    for (final booking
        in bookings) {
      final data =
          booking.data()
              as Map<String, dynamic>;

      final date =
          _getTransactionDate(data);

      if (date.month ==
              now.month &&
          date.year ==
              now.year) {
        dailyIncome[
            date.day - 1] +=
            _getAmount(data);
      }
    }

    return LineChart(
      LineChartData(
        minY: 0,

        gridData:
            const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),

        borderData:
            FlBorderData(
          show: false,
        ),

        titlesData:
            FlTitlesData(
          topTitles:
              const AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: false,
            ),
          ),

          rightTitles:
              const AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: false,
            ),
          ),

          leftTitles:
              AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: true,
              reservedSize: 45,

              getTitlesWidget:
                  (value, meta) {
                return Text(
                  '₱${value.toInt()}',
                  style:
                      const TextStyle(
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),

          bottomTitles:
              AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 5,

              getTitlesWidget:
                  (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style:
                      const TextStyle(
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots:
                List.generate(
              daysInMonth,
              (index) {
                return FlSpot(
                  (index + 1)
                      .toDouble(),
                  dailyIncome[index],
                );
              },
            ),

            isCurved: true,

            color: primaryColor,

            barWidth: 3,

            dotData:
                const FlDotData(
              show: false,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // YEAR CHART
  // ============================================================

  Widget _buildYearChart(
    List<QueryDocumentSnapshot>
        bookings,
  ) {
    final now =
        DateTime.now();

    final List<double>
        monthlyIncome =
        List.filled(12, 0);

    for (final booking
        in bookings) {
      final data =
          booking.data()
              as Map<String, dynamic>;

      final date =
          _getTransactionDate(data);

      if (date.year ==
          now.year) {
        monthlyIncome[
            date.month - 1] +=
            _getAmount(data);
      }
    }

    const months = [
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

    return LineChart(
      LineChartData(
        minY: 0,

        gridData:
            const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),

        borderData:
            FlBorderData(
          show: false,
        ),

        titlesData:
            FlTitlesData(
          topTitles:
              const AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: false,
            ),
          ),

          rightTitles:
              const AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: false,
            ),
          ),

          leftTitles:
              AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: true,
              reservedSize: 45,

              getTitlesWidget:
                  (value, meta) {
                return Text(
                  '₱${value.toInt()}',
                  style:
                      const TextStyle(
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),

          bottomTitles:
              AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,

              getTitlesWidget:
                  (value, meta) {
                final index =
                    value.toInt() - 1;

                if (index < 0 ||
                    index >=
                        months.length) {
                  return const SizedBox();
                }

                return Text(
                  months[index],
                  style:
                      const TextStyle(
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots:
                List.generate(
              12,
              (index) {
                return FlSpot(
                  (index + 1)
                      .toDouble(),
                  monthlyIncome[index],
                );
              },
            ),

            isCurved: true,

            color: primaryColor,

            barWidth: 3,

            dotData:
                const FlDotData(
              show: false,
            ),
          ),
        ],
      ),
    );
  }
}