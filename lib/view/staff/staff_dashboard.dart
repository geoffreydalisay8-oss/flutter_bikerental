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
  State<StaffDashboard> createState() =>
      _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    const StaffHomePage(),
    const ManageBookings(),
    const IdVerificationPage(),
    const StaffPaymentsPage(),
    const StaffActiveRentalsPage(),
  ];

  final List<String> titles = [
    'Dashboard',
    'Bookings',
    'ID Verification',
    'Payments',
    'Active Rentals',
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
        builder: (context) =>
            const LoginPage(),
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
    const Color primaryGreen =
        Color(0xFF1E4D40);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FB),

      appBar: AppBar(
        title: Text(
          titles[selectedIndex],
        ),
        backgroundColor:
            primaryGreen,
        foregroundColor:
            Colors.white,
      ),

      drawer: Drawer(
        child: Column(
          children: [

            // =================================================
            // STAFF HEADER
            // =================================================

            UserAccountsDrawerHeader(
              decoration:
                  const BoxDecoration(
                color:
                    primaryGreen,
              ),

              accountName:
                  const Text(
                'GoPedal Staff',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              accountEmail:
                  const Text(
                'Staff Account',
              ),

              currentAccountPicture:
                  const CircleAvatar(
                backgroundColor:
                    Colors.white,

                child: Icon(
                  Icons.support_agent,
                  size: 35,
                  color:
                      primaryGreen,
                ),
              ),
            ),

            // =================================================
            // DASHBOARD
            // =================================================

            ListTile(
              leading:
                  const Icon(
                Icons.dashboard,
              ),

              title:
                  const Text(
                'Dashboard',
              ),

              selected:
                  selectedIndex == 0,

              onTap: () {
                changePage(0);
              },
            ),

            // =================================================
            // BOOKINGS
            // =================================================

            ListTile(
              leading:
                  const Icon(
                Icons.calendar_month,
              ),

              title:
                  const Text(
                'Bookings',
              ),

              selected:
                  selectedIndex == 1,

              onTap: () {
                changePage(1);
              },
            ),

            // =================================================
            // ID VERIFICATION
            // =================================================

            ListTile(
              leading:
                  const Icon(
                Icons.verified_user,
              ),

              title:
                  const Text(
                'ID Verification',
              ),

              selected:
                  selectedIndex == 2,

              onTap: () {
                changePage(2);
              },
            ),

            // =================================================
            // PAYMENTS
            // =================================================

            ListTile(
              leading:
                  const Icon(
                Icons.payments_outlined,
              ),

              title:
                  const Text(
                'Payments',
              ),

              selected:
                  selectedIndex == 3,

              onTap: () {
                changePage(3);
              },
            ),

            // =================================================
            // ACTIVE RENTALS
            // =================================================

            ListTile(
              leading:
                  const Icon(
                Icons.pedal_bike,
              ),

              title:
                  const Text(
                'Active Rentals',
              ),

              selected:
                  selectedIndex == 4,

              onTap: () {
                changePage(4);
              },
            ),

            const Divider(),

            // =================================================
            // LOGOUT
            // =================================================

            ListTile(
              leading:
                  const Icon(
                Icons.logout,
                color: Colors.red,
              ),

              title:
                  const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),

              onTap: logout,
            ),

            const Spacer(),

            Padding(
              padding:
                  const EdgeInsets.all(16),

              child:
                  const Text(
                'GoPedal Bicycle Rental Application',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),

      body:
          pages[selectedIndex],
    );
  }
}

// =============================================================
// STAFF HOME PAGE
// =============================================================

class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  // ===========================================================
  // GET NUMBER OF DOCUMENTS
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
          (snapshot) =>
              snapshot.docs.length,
        );
  }

  Stream<int> _getPendingIdCount() {
    return FirebaseFirestore.instance
        .collection('id_verifications')
        .where(
          'status',
          isEqualTo: 'Pending',
        )
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.length,
        );
  }

  Stream<int> _getUnpaidCount() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where(
          'paymentStatus',
          isEqualTo: 'Unpaid',
        )
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.length,
        );
  }

  Stream<int> _getActiveRentalCount() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where(
          'bookingStatus',
          isEqualTo: 'Active Rental',
        )
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.length,
        );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen =
        Color(0xFF1E4D40);

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // =================================================
          // WELCOME
          // =================================================

          const Text(
            'Welcome, Staff!',
            style: TextStyle(
              fontSize: 26,
              fontWeight:
                  FontWeight.bold,
              color:
                  primaryGreen,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Assist customers and manage daily rental operations.',
            style: TextStyle(
              fontSize: 14,
              color:
                  Colors.black54,
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          // =================================================
          // TODAY'S OPERATIONS
          // =================================================

          const Text(
            'Today\'s Operations',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [

              Expanded(
                child: StreamBuilder<int>(
                  stream:
                      _getBookingCount(
                    'Pending',
                  ),
                  builder:
                      (context, snapshot) {
                    return _StatCard(
                      icon:
                          Icons.calendar_month,
                      title:
                          'Pending Bookings',
                      value:
                          '${snapshot.data ?? 0}',
                      iconColor:
                          Colors.orange,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: StreamBuilder<int>(
                  stream:
                      _getPendingIdCount(),
                  builder:
                      (context, snapshot) {
                    return _StatCard(
                      icon:
                          Icons.verified_user,
                      title:
                          'Pending IDs',
                      value:
                          '${snapshot.data ?? 0}',
                      iconColor:
                          Colors.blue,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [

              Expanded(
                child: StreamBuilder<int>(
                  stream:
                      _getUnpaidCount(),
                  builder:
                      (context, snapshot) {
                    return _StatCard(
                      icon:
                          Icons.payments_outlined,
                      title:
                          'Unpaid',
                      value:
                          '${snapshot.data ?? 0}',
                      iconColor:
                          Colors.red,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: StreamBuilder<int>(
                  stream:
                      _getActiveRentalCount(),
                  builder:
                      (context, snapshot) {
                    return _StatCard(
                      icon:
                          Icons.pedal_bike,
                      title:
                          'Active Rentals',
                      value:
                          '${snapshot.data ?? 0}',
                      iconColor:
                          primaryGreen,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 25,
          ),

          // =================================================
          // QUICK ACTIONS
          // =================================================

          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [

              Expanded(
                child:
                    _ActionCard(
                  icon:
                      Icons.calendar_month,
                  title:
                      'Bookings',
                  subtitle:
                      'Assist customers',
                  onTap: () {
                    final state =
                        context.findAncestorStateOfType<
                            _StaffDashboardState>();

                    state?.changePage(1);
                  },
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    _ActionCard(
                  icon:
                      Icons.verified_user,
                  title:
                      'ID Verification',
                  subtitle:
                      'Check customer IDs',
                  onTap: () {
                    final state =
                        context.findAncestorStateOfType<
                            _StaffDashboardState>();

                    state?.changePage(2);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [

              Expanded(
                child:
                    _ActionCard(
                  icon:
                      Icons.payments_outlined,
                  title:
                      'Payments',
                  subtitle:
                      'Record payments',
                  onTap: () {
                    final state =
                        context.findAncestorStateOfType<
                            _StaffDashboardState>();

                    state?.changePage(3);
                  },
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    _ActionCard(
                  icon:
                      Icons.pedal_bike,
                  title:
                      'Active Rentals',
                  subtitle:
                      'View current rentals',
                  onTap: () {
                    final state =
                        context.findAncestorStateOfType<
                            _StaffDashboardState>();

                    state?.changePage(4);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 25,
          ),

          // =================================================
          // STAFF RESPONSIBILITIES
          // =================================================

          const Text(
            'Staff Responsibilities',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          _ResponsibilityCard(
            icon:
                Icons.person_outline,
            title:
                'Assist Customers',
            description:
                'Help customers with bookings, bicycle rentals, and rental concerns.',
          ),

          _ResponsibilityCard(
            icon:
                Icons.calendar_month,
            title:
                'Manage Bookings',
            description:
                'Review and assist with customer booking requests.',
          ),

          _ResponsibilityCard(
            icon:
                Icons.badge_outlined,
            title:
                'Verify Customer IDs',
            description:
                'Review customer identification documents before rental approval.',
          ),

          _ResponsibilityCard(
            icon:
                Icons.payments_outlined,
            title:
                'Handle Payments',
            description:
                'Record customer payments made at the rental shop.',
          ),

          _ResponsibilityCard(
            icon:
                Icons.pedal_bike,
            title:
                'Monitor Active Rentals',
            description:
                'Monitor bicycles currently being rented and their rental status.',
          ),

          const SizedBox(
            height: 15,
          ),

          // =================================================
          // CUSTOMER SERVICE NOTICE
          // =================================================

          Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets.all(16),

            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(12),
              border:
                  Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Icon(
                  Icons.info_outline,
                  color:
                      primaryGreen,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      const Text(
                    'Staff members are the primary customer-facing personnel at the rental shop. The Admin or Owner may also assist customers when necessary.',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
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
      padding:
          const EdgeInsets.all(15),

      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border:
            Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            padding:
                const EdgeInsets.all(9),

            decoration:
                BoxDecoration(
              color:
                  iconColor.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(10),
            ),

            child:
                Icon(
              icon,
              color:
                  iconColor,
              size: 22,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            title,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 11,
              color:
                  Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ACTION CARD
// =============================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen =
        Color(0xFF1E4D40);

    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(14),

      child: Container(
        padding:
            const EdgeInsets.all(16),

        decoration:
            BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius.circular(14),
          border:
              Border.all(
            color:
                Colors.grey.shade200,
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Container(
              padding:
                  const EdgeInsets.all(10),

              decoration:
                  BoxDecoration(
                color:
                    primaryGreen
                        .withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child:
                  Icon(
                icon,
                color:
                    primaryGreen,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              title,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              subtitle,
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// RESPONSIBILITY CARD
// =============================================================

class _ResponsibilityCard
    extends StatelessWidget {

  final IconData icon;
  final String title;
  final String description;

  const _ResponsibilityCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen =
        Color(0xFF1E4D40);

    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(15),

      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border:
            Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color:
                primaryGreen,
            size: 25,
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
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  description,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// STAFF PAYMENTS PAGE
// =============================================================

class StaffPaymentsPage extends StatelessWidget {
  const StaffPaymentsPage({super.key});

  Future<String> _getCustomerName(
    String customerId,
  ) async {
    if (customerId.isEmpty) {
      return 'Unknown Customer';
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(customerId)
              .get();

      if (!doc.exists ||
          doc.data() == null) {
        return customerId;
      }

      final data = doc.data()!;

      final name =
          (data['name'] ??
                  data['fullName'] ??
                  '')
              .toString()
              .trim();

      return name.isNotEmpty
          ? name
          : customerId;
    } catch (e) {
      return customerId;
    }
  }

  Future<void> markAsPaid(
    BuildContext context,
    String bookingId,
    String paymentMethod,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Confirm Payment',
          ),
          content: Text(
            'Mark this booking as Paid?\n\n'
            'Payment Method: $paymentMethod',
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF1E4D40,
                ),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Mark as Paid',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'paymentStatus': 'Paid',
        'paymentDate':
            FieldValue.serverTimestamp(),
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text(
            'Payment marked as Paid.',
          ),
          backgroundColor:
              Color(0xFF008955),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(
            'Failed to update payment: $e',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FB),

      body:
          StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('bookings')
                .snapshots(),

        builder:
            (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF008955),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child:
                  Text(
                'Error loading payments:\n${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child:
                  Text(
                'No payment records found.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),

            itemCount:
                docs.length,

            itemBuilder:
                (context, index) {

              final doc =
                  docs[index];

              final data =
                  doc.data()
                      as Map<String, dynamic>;

              final customerId =
                  (data['customerId'] ??
                          '')
                      .toString();

              final bicycleName =
                  (data['bicycleName'] ??
                          'Unnamed Bicycle')
                      .toString();

              final paymentStatus =
                  (data['paymentStatus'] ??
                          'Unpaid')
                      .toString();

              final paymentMethod =
                  (data['paymentMethod'] ??
                          'Pay at Rental Shop')
                      .toString();

              final totalAmount =
                  _getNumber(
                data['totalAmount'],
              );

              final isPaid =
                  paymentStatus
                          .toLowerCase() ==
                      'paid';

              return FutureBuilder<String>(
                future:
                    _getCustomerName(
                  customerId,
                ),

                builder:
                    (context, customerSnapshot) {

                  final customerName =
                      customerSnapshot
                              .data ??
                          'Loading...';

                  return Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),

                    padding:
                        const EdgeInsets.all(15),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      border:
                          Border.all(
                        color:
                            Colors.grey.shade200,
                      ),
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
                                10,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFE8F8F0,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  10,
                                ),
                              ),

                              child:
                                  const Icon(
                                Icons
                                    .payments_outlined,
                                color:
                                    Color(
                                  0xFF008955,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    doc.id,
                                    style:
                                        TextStyle(
                                      fontSize:
                                          11,
                                      color:
                                          Colors
                                              .grey
                                              .shade500,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    customerName,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize:
                                          15,
                                    ),
                                  ),

                                  Text(
                                    bicycleName,
                                    style:
                                        TextStyle(
                                      fontSize:
                                          12,
                                      color:
                                          Colors
                                              .grey
                                              .shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: isPaid
                                    ? const Color(
                                        0xFFE8F8F0,
                                      )
                                    : const Color(
                                        0xFFFFF6E5,
                                      ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),

                              child:
                                  Text(
                                paymentStatus,
                                style:
                                    TextStyle(
                                  fontSize:
                                      10,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: isPaid
                                      ? const Color(
                                          0xFF008955,
                                        )
                                      : const Color(
                                          0xFFE56A24,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        Row(
                          children: [

                            Expanded(
                              child:
                                  _paymentInfo(
                                'Amount',
                                '₱${totalAmount.toStringAsFixed(2)}',
                              ),
                            ),

                            Expanded(
                              child:
                                  _paymentInfo(
                                'Method',
                                paymentMethod,
                              ),
                            ),
                          ],
                        ),

                        if (!isPaid) ...[
                          const SizedBox(
                            height: 12,
                          ),

                          SizedBox(
                            width:
                                double.infinity,

                            child:
                                ElevatedButton.icon(
                              onPressed: () {
                                markAsPaid(
                                  context,
                                  doc.id,
                                  paymentMethod,
                                );
                              },

                              icon:
                                  const Icon(
                                Icons
                                    .check_circle_outline,
                              ),

                              label:
                                  const Text(
                                'Mark as Paid',
                              ),

                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(
                                  0xFF1E4D40,
                                ),
                                foregroundColor:
                                    Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _paymentInfo(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(
          title,
          style:
              TextStyle(
            fontSize: 10,
            color:
                Colors.grey.shade500,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  double _getNumber(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }
}

// =============================================================
// STAFF ACTIVE RENTALS PAGE
// =============================================================

class StaffActiveRentalsPage
    extends StatelessWidget {
  const StaffActiveRentalsPage({
    super.key,
  });

  Future<String> _getCustomerName(
    String customerId,
  ) async {
    if (customerId.isEmpty) {
      return 'Unknown Customer';
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(customerId)
              .get();

      if (!doc.exists ||
          doc.data() == null) {
        return customerId;
      }

      final data = doc.data()!;

      final name =
          (data['name'] ??
                  data['fullName'] ??
                  '')
              .toString()
              .trim();

      return name.isNotEmpty
          ? name
          : customerId;
    } catch (e) {
      return customerId;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FB),

      body:
          StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('bookings')
                .where(
                  'bookingStatus',
                  isEqualTo:
                      'Active Rental',
                )
                .snapshots(),

        builder:
            (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF008955),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child:
                    Text(
                  'Error loading active rentals:\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child:
                  Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  Icon(
                    Icons.pedal_bike_outlined,
                    size: 55,
                    color:
                        Colors.grey.shade400,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    'No active rentals.',
                    style:
                        TextStyle(
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),

            itemCount:
                docs.length,

            itemBuilder:
                (context, index) {

              final doc =
                  docs[index];

              final data =
                  doc.data()
                      as Map<String, dynamic>;

              final customerId =
                  (data['customerId'] ??
                          '')
                      .toString();

              final bicycleName =
                  (data['bicycleName'] ??
                          'Unnamed Bicycle')
                      .toString();

              final pickupDate =
                  _getDate(
                data['pickupDate'],
              );

              final returnDate =
                  _getDate(
                data['returnDate'],
              );

              return FutureBuilder<String>(
                future:
                    _getCustomerName(
                  customerId,
                ),

                builder:
                    (context, customerSnapshot) {

                  final customerName =
                      customerSnapshot
                              .data ??
                          'Loading...';

                  return Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),

                    padding:
                        const EdgeInsets.all(
                      15,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      border:
                          Border.all(
                        color:
                            Colors.grey.shade200,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            Container(
                              width:
                                  50,
                              height:
                                  50,

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFEAF3FF,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),

                              child:
                                  const Icon(
                                Icons.pedal_bike,
                                color:
                                    Colors.blue,
                                size: 28,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    doc.id,
                                    style:
                                        TextStyle(
                                      fontSize:
                                          11,
                                      color:
                                          Colors
                                              .grey
                                              .shade500,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    bicycleName,
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          15,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    'Customer: $customerName',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          12,
                                      color:
                                          Colors
                                              .grey
                                              .shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFEAF3FF,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),

                              child:
                                  const Text(
                                'Active',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.blue,
                                  fontSize:
                                      10,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets
                                  .all(
                            12,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFF8FAFB,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),

                          child:
                              Column(
                            children: [

                              Row(
                                children: [

                                  const Icon(
                                    Icons
                                        .login,
                                    size:
                                        18,
                                    color:
                                        Color(
                                      0xFF008955,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [

                                        Text(
                                          'Pickup',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                10,
                                            color:
                                                Colors
                                                    .grey
                                                    .shade500,
                                          ),
                                        ),

                                        Text(
                                          pickupDate !=
                                                  null
                                              ? DateFormat(
                                                  'MMM dd, yyyy • hh:mm a',
                                                ).format(
                                                  pickupDate,
                                                )
                                              : 'Not available',
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                12,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              Row(
                                children: [

                                  const Icon(
                                    Icons
                                        .logout,
                                    size:
                                        18,
                                    color:
                                        Colors
                                            .orange,
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [

                                        Text(
                                          'Expected Return',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                10,
                                            color:
                                                Colors
                                                    .grey
                                                    .shade500,
                                          ),
                                        ),

                                        Text(
                                          returnDate !=
                                                  null
                                              ? DateFormat(
                                                  'MMM dd, yyyy • hh:mm a',
                                                ).format(
                                                  returnDate,
                                                )
                                              : 'Not available',
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                12,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}