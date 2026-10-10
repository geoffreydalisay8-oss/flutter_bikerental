import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:bikerental/service/auth_service.dart';
import 'package:bikerental/login_page.dart';

import 'package:bikerental/view/admin/bookings_page.dart';
import 'package:bikerental/view/admin/id_verification_page.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int selectedIndex = 0;

  // =========================================================
  // STAFF PAGES
  // =========================================================

  final List<Widget> pages = [
    const StaffHomePage(),
    const ManageBookings(),
    const IdVerificationPage(),
  ];

  // =========================================================
  // PAGE TITLES
  // =========================================================

  final List<String> titles = [
    'Dashboard',
    'Bookings',
    'ID Verification',
  ];

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    await AuthService().logout();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // CHANGE PAGE
  // =========================================================

  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });

    Navigator.pop(context);
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1E4D40);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        title: Text(
          titles[selectedIndex],
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),

      // =====================================================
      // DRAWER
      // =====================================================

      drawer: Drawer(
        child: Column(
          children: [
            // =================================================
            // STAFF HEADER
            // =================================================

            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: primaryGreen,
              ),
              accountName: const Text(
                'GoPedal Staff',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: const Text(
                'Staff Account',
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.support_agent,
                  size: 35,
                  color: primaryGreen,
                ),
              ),
            ),

            // =================================================
            // DASHBOARD
            // =================================================

            ListTile(
              leading: const Icon(
                Icons.dashboard,
              ),
              title: const Text(
                'Dashboard',
              ),
              selected: selectedIndex == 0,
              onTap: () {
                changePage(0);
              },
            ),

            // =================================================
            // BOOKINGS
            // =================================================

            ListTile(
              leading: const Icon(
                Icons.calendar_month,
              ),
              title: const Text(
                'Bookings',
              ),
              selected: selectedIndex == 1,
              onTap: () {
                changePage(1);
              },
            ),

            // =================================================
            // ID VERIFICATION
            // =================================================

            ListTile(
              leading: const Icon(
                Icons.verified_user,
              ),
              title: const Text(
                'ID Verification',
              ),
              selected: selectedIndex == 2,
              onTap: () {
                changePage(2);
              },
            ),

            const Divider(),

            // =================================================
            // LOGOUT
            // =================================================

            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onTap: logout,
            ),

            const Spacer(),

            // =================================================
            // FOOTER
            // =================================================

            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'GoPedal Bicycle Rental Application',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),

      // =====================================================
      // CURRENT PAGE
      // =====================================================

      body: pages[selectedIndex],
    );
  }
}

// =============================================================
// STAFF HOME PAGE
// =============================================================

class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  // ===========================================================
  // GET BOOKING COUNT
  // ===========================================================

  Stream<int> _getBookingCount(
    String status,
  ) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where(
          'bookingStatus',
          isEqualTo: status,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.length,
        );
  }

  // ===========================================================
  // GET PENDING ID COUNT
  // ===========================================================

  Stream<int> _getPendingIdCount() {
    return FirebaseFirestore.instance
        .collection('id_verifications')
        .where(
          'status',
          isEqualTo: 'Pending',
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.length,
        );
  }

  // ===========================================================
  // GET UNPAID COUNT
  // ===========================================================

  Stream<int> _getUnpaidCount() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where(
          'paymentStatus',
          isEqualTo: 'Unpaid',
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.length,
        );
  }

  // ===========================================================
  // GET ACTIVE RENTAL COUNT
  // ===========================================================

  Stream<int> _getActiveRentalCount() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where(
          'bookingStatus',
          isEqualTo: 'Active Rental',
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.length,
        );
  }

  // ===========================================================
  // GET CUSTOMER NAME
  // ===========================================================

  Future<String> _getCustomerName(
    String customerId,
  ) async {
    if (customerId.isEmpty) {
      return 'Unknown Customer';
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return 'Unknown Customer';
      }

      final data = doc.data()!;

      final fullName = data['fullName']
          ?.toString()
          .trim();

      if (fullName != null && fullName.isNotEmpty) {
        return fullName;
      }

      final name = data['name']
          ?.toString()
          .trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }

      return 'Unknown Customer';
    } catch (e) {
      return 'Unknown Customer';
    }
  }

  // ===========================================================
  // GET DATE
  // ===========================================================

  DateTime? _getDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1E4D40);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===================================================
          // WELCOME
          // ===================================================

          const Text(
            'Welcome, Staff!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Monitor today\'s rental operations.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          // ===================================================
          // TODAY'S OPERATIONS
          // ===================================================

          const Text(
            'Today\'s Operations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ===================================================
          // STAT ROW 1
          // ===================================================

          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _getBookingCount(
                    'Pending',
                  ),
                  builder: (context, snapshot) {
                    return _StatCard(
                      icon: Icons.calendar_month,
                      title: 'Pending Bookings',
                      value: '${snapshot.data ?? 0}',
                      iconColor: Colors.orange,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: StreamBuilder<int>(
                  stream: _getPendingIdCount(),
                  builder: (context, snapshot) {
                    return _StatCard(
                      icon: Icons.verified_user,
                      title: 'Pending IDs',
                      value: '${snapshot.data ?? 0}',
                      iconColor: Colors.blue,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ===================================================
          // STAT ROW 2
          // ===================================================

          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _getUnpaidCount(),
                  builder: (context, snapshot) {
                    return _StatCard(
                      icon: Icons.payments_outlined,
                      title: 'Unpaid Payments',
                      value: '${snapshot.data ?? 0}',
                      iconColor: Colors.red,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: StreamBuilder<int>(
                  stream: _getActiveRentalCount(),
                  builder: (context, snapshot) {
                    return _StatCard(
                      icon: Icons.pedal_bike,
                      title: 'Active Rentals',
                      value: '${snapshot.data ?? 0}',
                      iconColor: primaryGreen,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 30,
          ),

          // ===================================================
          // RECENT BOOKINGS
          // ===================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bookings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              TextButton(
                onPressed: () {
                  final state = context
                      .findAncestorStateOfType<
                          _StaffDashboardState>();

                  state?.changePage(1);
                },
                child: const Text(
                  'View All',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primaryGreen,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const _EmptySection(
                  icon: Icons.error_outline,
                  message:
                      'Unable to load recent bookings.',
                );
              }

              final docs =
                  snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const _EmptySection(
                  icon: Icons.calendar_month_outlined,
                  message: 'No bookings yet.',
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  final customerId =
                      (data['customerId'] ?? '')
                          .toString();

                  final savedCustomerName =
                      (data['customerName'] ?? '')
                          .toString()
                          .trim();

                  final bicycleName =
                      (data['bicycleName'] ??
                              'Unnamed Bicycle')
                          .toString();

                  final status =
                      (data['bookingStatus'] ??
                              'Pending')
                          .toString();

                  final pickupDate =
                      _getDate(
                    data['pickupDate'],
                  );

                  return FutureBuilder<String>(
                    future: savedCustomerName.isNotEmpty
                        ? Future.value(
                            savedCustomerName,
                          )
                        : _getCustomerName(
                            customerId,
                          ),
                    builder:
                        (context, customerSnapshot) {
                      final customerName =
                          customerSnapshot.data ??
                              'Loading...';

                      return _RecentBookingCard(
                        bookingId: doc.id,
                        customerName:
                            customerName,
                        bicycleName:
                            bicycleName,
                        status: status,
                        pickupDate:
                            pickupDate,
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(
            height: 30,
          ),

          // ===================================================
          // ACTIVE RENTALS
          // ===================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Rentals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              TextButton(
                onPressed: () {
                  final state = context
                      .findAncestorStateOfType<
                          _StaffDashboardState>();

                  state?.changePage(1);
                },
                child: const Text(
                  'View Bookings',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where(
                  'bookingStatus',
                  isEqualTo: 'Active Rental',
                )
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primaryGreen,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const _EmptySection(
                  icon: Icons.error_outline,
                  message:
                      'Unable to load active rentals.',
                );
              }

              final docs =
                  snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const _EmptySection(
                  icon: Icons.pedal_bike_outlined,
                  message: 'No active rentals.',
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  final customerId =
                      (data['customerId'] ?? '')
                          .toString();

                  final savedCustomerName =
                      (data['customerName'] ?? '')
                          .toString()
                          .trim();

                  final bicycleName =
                      (data['bicycleName'] ??
                              'Unnamed Bicycle')
                          .toString();

                  final returnDate =
                      _getDate(
                    data['returnDate'],
                  );

                  return FutureBuilder<String>(
                    future: savedCustomerName.isNotEmpty
                        ? Future.value(
                            savedCustomerName,
                          )
                        : _getCustomerName(
                            customerId,
                          ),
                    builder:
                        (context, customerSnapshot) {
                      final customerName =
                          customerSnapshot.data ??
                              'Loading...';

                      return _ActiveRentalSummaryCard(
                        customerName:
                            customerName,
                        bicycleName:
                            bicycleName,
                        returnDate:
                            returnDate,
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// STAT CARD
// =============================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// RECENT BOOKING CARD
// =============================================================

class _RecentBookingCard
    extends StatelessWidget {
  final String bookingId;
  final String customerName;
  final String bicycleName;
  final String status;
  final DateTime? pickupDate;

  const _RecentBookingCard({
    required this.bookingId,
    required this.customerName,
    required this.bicycleName,
    required this.status,
    required this.pickupDate,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;

      case 'active rental':
        return Colors.green;

      case 'completed':
        return Colors.grey;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.blue,
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
                  customerName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  bicycleName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),

                if (pickupDate != null) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(pickupDate!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ACTIVE RENTAL SUMMARY CARD
// =============================================================

class _ActiveRentalSummaryCard
    extends StatelessWidget {
  final String customerName;
  final String bicycleName;
  final DateTime? returnDate;

  const _ActiveRentalSummaryCard({
    required this.customerName,
    required this.bicycleName,
    required this.returnDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.pedal_bike,
              color: Colors.blue,
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
                  customerName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  bicycleName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),

                if (returnDate != null) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    'Return: ${DateFormat('MMM dd, yyyy • hh:mm a').format(returnDate!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFFE8F8F0,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: Color(0xFF008955),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// EMPTY SECTION
// =============================================================

class _EmptySection
    extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptySection({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: Colors.grey.shade400,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}