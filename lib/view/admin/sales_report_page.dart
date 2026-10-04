import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  String selectedPeriod = 'Today';

  DateTime _getStartDate(DateTime now) {
    if (selectedPeriod == 'Today') {
      return DateTime(now.year, now.month, now.day);
    } else if (selectedPeriod == 'Month') {
      return DateTime(now.year, now.month, 1);
    } else {
      return DateTime(now.year, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = _getStartDate(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: const Text(
          'Sales Report',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .orderBy('paymentDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final payments = snapshot.data?.docs ?? [];
          double totalIncome = 0;

          for (final payment in payments) {
            final data = payment.data() as Map<String, dynamic>;
            totalIncome += (data['amount'] ?? 0).toDouble();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Income Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Track your rental income and system transactions.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // PERIOD SELECTOR
              Row(
                children: [
                  _periodButton('Today'),
                  _periodButton('Month'),
                  _periodButton('Year'),
                ],
              ),
              const SizedBox(height: 20),

              // TOTAL INCOME CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selectedPeriod Income',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${totalIncome.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${payments.length} payment(s) recorded',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
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
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildChart(payments),
              ),

              const SizedBox(height: 24),
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

              if (payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No payments found for this period.')),
                )
              else
                ...payments.map((payment) {
                  final data = payment.data() as Map<String, dynamic>;
                  final amount = (data['amount'] ?? 0).toDouble();
                  final method = data['paymentMethod'] ?? 'N/A';
                  final bookingId = data['bookingId'] ?? 'N/A';
                  final timestamp = data['paymentDate'] as Timestamp?;
                  final dateStr = timestamp != null
                      ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate())
                      : 'Unknown date';

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: const Icon(Icons.payment, color: Colors.blue),
                      ),
                      title: Text(
                        '₱${amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Booking: $bookingId\nMethod: $method • $dateStr'),
                      isThreeLine: true,
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _periodButton(String period) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ElevatedButton(
          onPressed: () => setState(() => selectedPeriod = period),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.white,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            elevation: 0,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(period),
        ),
      ),
    );
  }

  Widget _buildChart(List<QueryDocumentSnapshot> payments) {
    if (payments.isEmpty) {
      return const Center(child: Text('No income data available.'));
    }
    if (selectedPeriod == 'Today') return _buildTodayChart(payments);
    if (selectedPeriod == 'Month') return _buildMonthChart(payments);
    return _buildYearChart(payments);
  }

  Widget _buildTodayChart(List<QueryDocumentSnapshot> payments) {
    List<double> hourlyIncome = List.filled(24, 0);
    for (final payment in payments) {
      final data = payment.data() as Map<String, dynamic>;
      final timestamp = data['paymentDate'];
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        hourlyIncome[date.hour] += (data['amount'] ?? 0).toDouble();
      }
    }

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (val, meta) => Text('₱${val.toInt()}', style: const TextStyle(fontSize: 9)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 6,
              getTitlesWidget: (val, meta) => Text('${val.toInt()}:00', style: const TextStyle(fontSize: 9)),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(24, (i) => FlSpot(i.toDouble(), hourlyIncome[i])),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChart(List<QueryDocumentSnapshot> payments) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    List<double> dailyIncome = List.filled(daysInMonth, 0);

    for (final payment in payments) {
      final data = payment.data() as Map<String, dynamic>;
      final timestamp = data['paymentDate'];
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        if (date.month == now.month && date.year == now.year) {
          dailyIncome[date.day - 1] += (data['amount'] ?? 0).toDouble();
        }
      }
    }

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (val, meta) => Text('₱${val.toInt()}', style: const TextStyle(fontSize: 9)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 5,
              getTitlesWidget: (val, meta) => Text('${val.toInt()}', style: const TextStyle(fontSize: 9)),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(daysInMonth, (i) => FlSpot((i + 1).toDouble(), dailyIncome[i])),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildYearChart(List<QueryDocumentSnapshot> payments) {
    final now = DateTime.now();
    List<double> monthlyIncome = List.filled(12, 0);

    for (final payment in payments) {
      final data = payment.data() as Map<String, dynamic>;
      final timestamp = data['paymentDate'];
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        if (date.year == now.year) {
          monthlyIncome[date.month - 1] += (data['amount'] ?? 0).toDouble();
        }
      }
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (val, meta) => Text('₱${val.toInt()}', style: const TextStyle(fontSize: 9)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final index = val.toInt() - 1;
                if (index < 0 || index >= months.length) return const SizedBox();
                return Text(months[index], style: const TextStyle(fontSize: 9));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(12, (i) => FlSpot((i + 1).toDouble(), monthlyIncome[i])),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}