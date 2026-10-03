import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() =>
      _SalesReportPageState();
}

class _SalesReportPageState
    extends State<SalesReportPage> {
  String selectedPeriod = 'Today';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
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
            .collection('payments')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          final payments =
              snapshot.data?.docs ?? [];

          final now = DateTime.now();

          List<QueryDocumentSnapshot> filteredPayments =
              [];

          for (final payment in payments) {
            final data =
                payment.data()
                    as Map<String, dynamic>;

            final timestamp =
                data['paymentDate'];

            if (timestamp is! Timestamp) {
              continue;
            }

            final paymentDate =
                timestamp.toDate();

            if (_isInSelectedPeriod(
              paymentDate,
              now,
            )) {
              filteredPayments.add(payment);
            }
          }

          double totalIncome = 0;

          for (final payment in filteredPayments) {
            final data =
                payment.data()
                    as Map<String, dynamic>;

            totalIncome +=
                (data['amount'] ?? 0).toDouble();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Income Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Track your rental income.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // PERIOD BUTTONS
              Row(
                children: [
                  _periodButton('Today'),
                  _periodButton('Month'),
                  _periodButton('Year'),
                ],
              ),

              const SizedBox(height: 20),

              // TOTAL INCOME
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selectedPeriod Income',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '₱${totalIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${filteredPayments.length} payment(s)',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'INCOME GRAPH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF90A4AE),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                height: 350,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: _buildChart(
                  filteredPayments,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'PAYMENT SUMMARY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF90A4AE),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 12),

              ...filteredPayments.map(
                (payment) {
                  final data =
                      payment.data()
                          as Map<String, dynamic>;

                  final amount =
                      (data['amount'] ?? 0)
                          .toDouble();

                  final method =
                      data['paymentMethod'] ??
                          'Unknown';

                  final bookingId =
                      data['bookingId'] ??
                          'Unknown';

                  return Card(
                    margin:
                        const EdgeInsets.only(
                      bottom: 8,
                    ),

                    child: ListTile(
                      leading:
                          const CircleAvatar(
                        child: Icon(
                          Icons.payment,
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
                        'Booking: $bookingId\n'
                        'Method: $method',
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================================================
  // PERIOD BUTTON
  // ==================================================

  Widget _periodButton(String period) {
    final isSelected =
        selectedPeriod == period;

    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.only(right: 6),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              selectedPeriod = period;
            });
          },

          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected
                    ? Colors.blue
                    : Colors.white,

            foregroundColor:
                isSelected
                    ? Colors.white
                    : Colors.black,

            elevation: 0,

            side: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),

          child: Text(period),
        ),
      ),
    );
  }

  // ==================================================
  // CHECK DATE
  // ==================================================

  bool _isInSelectedPeriod(
    DateTime paymentDate,
    DateTime now,
  ) {
    if (selectedPeriod == 'Today') {
      return paymentDate.year == now.year &&
          paymentDate.month == now.month &&
          paymentDate.day == now.day;
    }

    if (selectedPeriod == 'Month') {
      return paymentDate.year == now.year &&
          paymentDate.month == now.month;
    }

    if (selectedPeriod == 'Year') {
      return paymentDate.year == now.year;
    }

    return false;
  }

  // ==================================================
  // BUILD GRAPH
  // ==================================================

  Widget _buildChart(
    List<QueryDocumentSnapshot> payments,
  ) {
    if (payments.isEmpty) {
      return const Center(
        child: Text(
          'No income data available.',
        ),
      );
    }

    if (selectedPeriod == 'Today') {
      return _buildTodayChart(payments);
    }

    if (selectedPeriod == 'Month') {
      return _buildMonthChart(payments);
    }

    return _buildYearChart(payments);
  }

  // ==================================================
  // TODAY GRAPH
  // ==================================================

  Widget _buildTodayChart(
    List<QueryDocumentSnapshot> payments,
  ) {
    List<double> hourlyIncome =
        List.filled(24, 0);

    for (final payment in payments) {
      final data =
          payment.data()
              as Map<String, dynamic>;

      final timestamp =
          data['paymentDate'];

      if (timestamp is Timestamp) {
        final date =
            timestamp.toDate();

        final amount =
            (data['amount'] ?? 0)
                .toDouble();

        hourlyIncome[date.hour] += amount;
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),

        borderData: FlBorderData(
          show: false,
        ),

        titlesData: FlTitlesData(
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

          leftTitles: AxisTitles(
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
              reservedSize: 30,
              interval: 4,
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
            spots: List.generate(
              24,
              (index) {
                return FlSpot(
                  index.toDouble(),
                  hourlyIncome[index],
                );
              },
            ),

            isCurved: true,

            barWidth: 3,

            dotData: FlDotData(
              show: false,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // MONTH GRAPH
  // ==================================================

  Widget _buildMonthChart(
    List<QueryDocumentSnapshot> payments,
  ) {
    final now = DateTime.now();

    final daysInMonth =
        DateTime(
          now.year,
          now.month + 1,
          0,
        ).day;

    List<double> dailyIncome =
        List.filled(
      daysInMonth,
      0,
    );

    for (final payment in payments) {
      final data =
          payment.data()
              as Map<String, dynamic>;

      final timestamp =
          data['paymentDate'];

      if (timestamp is Timestamp) {
        final date =
            timestamp.toDate();

        final amount =
            (data['amount'] ?? 0)
                .toDouble();

        dailyIncome[date.day - 1] +=
            amount;
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),

        borderData: FlBorderData(
          show: false,
        ),

        titlesData: FlTitlesData(
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

          leftTitles: AxisTitles(
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
              interval: 5,
              reservedSize: 30,
              getTitlesWidget:
                  (value, meta) {
                return Text(
                  value.toInt()
                      .toString(),
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
            spots: List.generate(
              daysInMonth,
              (index) {
                return FlSpot(
                  (index + 1).toDouble(),
                  dailyIncome[index],
                );
              },
            ),

            isCurved: true,

            barWidth: 3,

            dotData: FlDotData(
              show: false,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // YEAR GRAPH
  // ==================================================

  Widget _buildYearChart(
    List<QueryDocumentSnapshot> payments,
  ) {
    final now = DateTime.now();

    List<double> monthlyIncome =
        List.filled(12, 0);

    for (final payment in payments) {
      final data =
          payment.data()
              as Map<String, dynamic>;

      final timestamp =
          data['paymentDate'];

      if (timestamp is Timestamp) {
        final date =
            timestamp.toDate();

        final amount =
            (data['amount'] ?? 0)
                .toDouble();

        if (date.year == now.year) {
          monthlyIncome[
              date.month - 1] += amount;
        }
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),

        borderData: FlBorderData(
          show: false,
        ),

        titlesData: FlTitlesData(
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

          leftTitles: AxisTitles(
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
              interval: 1,
              reservedSize: 30,
              getTitlesWidget:
                  (value, meta) {
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
            spots: List.generate(
              12,
              (index) {
                return FlSpot(
                  (index + 1).toDouble(),
                  monthlyIncome[index],
                );
              },
            ),

            isCurved: true,

            barWidth: 3,

            dotData: FlDotData(
              show: false,
            ),
          ),
        ],
      ),
    );
  }
}
