import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bikerental/service/auth_service.dart';
import 'package:bikerental/login_page.dart';

import 'package:bikerental/view/admin/bicycles_page.dart';
import 'package:bikerental/view/admin/bookings_page.dart';
import 'package:bikerental/view/admin/id_verification_page.dart';
import 'package:bikerental/view/admin/payments_page.dart';
import 'package:bikerental/view/admin/users_page.dart';
import 'package:bikerental/view/admin/feedback_page.dart';
import 'package:bikerental/view/admin/sales_report_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  final AuthService authService = AuthService();

  // Pages for the sidebar
  final List<Widget> pages = [
    const AdminHomePage(),
    const ManageBicycles(),
    const ManageBookings(),
    const IdVerificationPage(),
    const ManagePayments(),
    const ManageUsers(),
    const SalesReportPage(),
    const FeedbackList(),
  ];

  // Sidebar titles
  final List<String> titles = [
    'Dashboard',
    'Bicycles',
    'Bookings',
    'ID Verification',
    'Payments',
    'Users',
    'Reports',
    'Feedback',
  ];

  // Sidebar icons
  final List<IconData> icons = [
    Icons.dashboard,
    Icons.pedal_bike,
    Icons.book,
    Icons.badge,
    Icons.payment,
    Icons.people,
    Icons.assessment,
    Icons.feedback,
  ];

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // =============================
      // TOP APP BAR
      // =============================
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        titleSpacing: 8,

        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.black87,
                size: 20,
              ),

              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),

        title: Text(
          selectedIndex == 0
              ? 'Admin'
              : titles[selectedIndex],

          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =============================
      // SIDEBAR
      // =============================
      drawer: Drawer(
        child: Column(
          children: [
            // Sidebar Header
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),

              child: SizedBox(
                width: double.infinity,

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: const [
                    Icon(
                      Icons.pedal_bike,
                      color: Colors.white,
                      size: 45,
                    ),

                    SizedBox(height: 10),

                    Text(
                      'Bicycle Rental',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sidebar Menu
            Expanded(
              child: ListView.builder(
                itemCount: titles.length,

                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      icons[index],
                    ),

                    title: Text(
                      titles[index],
                    ),

                    selected:
                        selectedIndex == index,

                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });

                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),

            // Logout
            const Divider(),

            ListTile(
              leading: const Icon(
                Icons.logout,
              ),

              title: const Text(
                'Logout',
              ),

              onTap: logout,
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),

      // =============================
      // MAIN CONTENT
      // =============================
      body: pages[selectedIndex],
    );
  }
}


// ==================================================
// ADMIN HOME PAGE
// ==================================================

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bicycles')
          .snapshots(),

      builder: (context, bicycleSnapshot) {
        if (bicycleSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .snapshots(),

          builder: (context, bookingSnapshot) {
            if (bookingSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),

              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // =============================
                // BICYCLE DATA
                // =============================

                final bicycles =
                    bicycleSnapshot.data?.docs ?? [];

                final totalBikes =
                    bicycles.length;

                final availableBikes =
                    bicycles.where((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  return data['available'] ==
                      true;
                }).length;

                // =============================
                // BOOKING DATA
                // =============================

                final bookings =
                    bookingSnapshot.data?.docs ?? [];

                final activeRentals =
                    bookings.where((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  return data['bookingStatus'] ==
                      'Active Rental';
                }).length;

                final pendingBookings =
                    bookings.where((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  return data['bookingStatus'] ==
                      'Pending';
                }).length;

                // =============================
                // TODAY'S BOOKINGS
                // =============================

                final now = DateTime.now();

                final todayBookings =
                    bookings.where((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  final pickupDate =
                      data['pickupDate'];

                  if (pickupDate == null) {
                    return false;
                  }

                  DateTime date;

                  if (pickupDate
                      is Timestamp) {
                    date =
                        pickupDate.toDate();
                  } else {
                    return false;
                  }

                  return date.year ==
                          now.year &&
                      date.month ==
                          now.month &&
                      date.day ==
                          now.day;
                }).length;

                // =============================
                // CUSTOMER DATA
                // =============================

                final users =
                    userSnapshot.data?.docs ?? [];

                final totalCustomers =
                    users.where((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  return data['role'] ==
                      'customer';
                }).length;

                // =============================
                // REVENUE
                // =============================

                double totalRevenue = 0;

                for (final doc in bookings) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  final paymentStatus =
                      data['paymentStatus'];

                  if (paymentStatus == 'Paid') {
                    totalRevenue +=
                        (data['bookingFee'] ?? 0)
                            .toDouble();
                  }
                }

                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // =============================
                      // FLEET SNAPSHOT
                      // =============================

                      _buildSectionTitle(
                        'FLEET SNAPSHOT',
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      GridView.count(
                        shrinkWrap: true,

                        physics:
                            const NeverScrollableScrollPhysics(),

                        crossAxisCount: 2,

                        crossAxisSpacing: 10,

                        mainAxisSpacing: 10,

                        childAspectRatio: 2.1,

                        children: [
                          _FleetCard(
                            icon: Icons
                                .directions_bike_outlined,

                            iconBgColor:
                                const Color(
                              0xFFE8F5E9,
                            ),

                            iconColor:
                                const Color(
                              0xFF00BFA5,
                            ),

                            value:
                                totalBikes
                                    .toString(),

                            label:
                                'Total Bikes',
                          ),

                          _FleetCard(
                            icon: Icons
                                .check_circle_outline,

                            iconBgColor:
                                const Color(
                              0xFFE8F8F5,
                            ),

                            iconColor:
                                const Color(
                              0xFF2ECC71,
                            ),

                            value:
                                availableBikes
                                    .toString(),

                            label:
                                'Available',
                          ),

                          _FleetCard(
                            icon: Icons
                                .directions_bike,

                            iconBgColor:
                                const Color(
                              0xFFE3F2FD,
                            ),

                            iconColor:
                                const Color(
                              0xFF29B6F6,
                            ),

                            value:
                                activeRentals
                                    .toString(),

                            label:
                                'Active Rentals',
                          ),

                          _FleetCard(
                            icon: Icons
                                .calendar_today_outlined,

                            iconBgColor:
                                const Color(
                              0xFFF3E5F5,
                            ),

                            iconColor:
                                const Color(
                              0xFFAB47BC,
                            ),

                            value:
                                todayBookings
                                    .toString(),

                            label:
                                "Today's Bookings",
                          ),

                          _FleetCard(
                            icon: Icons
                                .access_time_rounded,

                            iconBgColor:
                                const Color(
                              0xFFFFF8E1,
                            ),

                            iconColor:
                                const Color(
                              0xFFFFA726,
                            ),

                            value:
                                pendingBookings
                                    .toString(),

                            label:
                                'Pending Approval',
                          ),

                          _FleetCard(
                            icon: Icons
                                .people_outline,

                            iconBgColor:
                                const Color(
                              0xFFE0F2F1,
                            ),

                            iconColor:
                                const Color(
                              0xFF26A69A,
                            ),

                            value:
                                totalCustomers
                                    .toString(),

                            label:
                                'Total Customers',
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // =============================
                      // FINANCIAL OVERVIEW
                      // =============================

                      _buildSectionTitle(
                        'FINANCIAL OVERVIEW',
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withOpacity(
                                0.02,
                              ),

                              blurRadius: 8,

                              offset:
                                  const Offset(
                                0,
                                2,
                              ),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  const Text(
                                    'TOTAL REVENUE',

                                    style:
                                        TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: Color(
                                        0xFF90A4AE,
                                      ),
                                      letterSpacing:
                                          0.5,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  Text(
                                    '₱${totalRevenue.toStringAsFixed(2)}',

                                    style:
                                        const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: Color(
                                        0xFF00897B,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              height: 32,
                              width: 1,
                              color: Colors
                                  .grey
                                  .shade200,
                            ),

                            const SizedBox(
                              width: 16,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  const Text(
                                    "TODAY'S SALES",

                                    style:
                                        TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: Color(
                                        0xFF90A4AE,
                                      ),
                                      letterSpacing:
                                          0.5,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  const Text(
                                    'View in Reports',

                                    style:
                                        TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: Color(
                                        0xFF00897B,
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
                        height: 20,
                      ),

                      // =============================
                      // RECENT BOOKINGS
                      // =============================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          _buildSectionTitle(
                            'RECENT BOOKINGS',
                          ),

                          GestureDetector(
                            onTap: () {
                              // Go to Bookings
                            },

                            child: Row(
                              children: const [
                                Text(
                                  'View All ',
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color: Color(
                                      0xFF00897B,
                                    ),
                                  ),
                                ),

                                Icon(
                                  Icons
                                      .arrow_forward_ios,
                                  size: 10,
                                  color: Color(
                                    0xFF00897B,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      if (bookings.isEmpty)
                        const Center(
                          child: Padding(
                            padding:
                                EdgeInsets.all(
                              20,
                            ),

                            child: Text(
                              'No bookings yet.',
                            ),
                          ),
                        )
                      else
                        ...bookings
                            .take(5)
                            .map((doc) {
                          final data =
                              doc.data()
                                  as Map<
                                      String,
                                      dynamic>;

                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 10,
                            ),

                            child:
                                _buildBookingCard(
                              bookingId:
                                  doc.id,

                              customerName:
                                  data[
                                          'customerName'] ??
                                      'Unknown Customer',

                              bikeModel:
                                  data[
                                          'bicycleName'] ??
                                      'Unknown Bicycle',

                              status:
                                  data[
                                          'bookingStatus'] ??
                                      'Pending',

                              statusColor:
                                  _getStatusColor(
                                data[
                                        'bookingStatus'] ??
                                    'Pending',
                              ),

                              statusBgColor:
                                  _getStatusBackgroundColor(
                                data[
                                        'bookingStatus'] ??
                                    'Pending',
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ==================================================
  // SECTION TITLE
  // ==================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,

      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF90A4AE),
        letterSpacing: 0.8,
      ),
    );
  }

  // ==================================================
  // BOOKING CARD
  // ==================================================

  Widget _buildBookingCard({
    required String bookingId,
    required String customerName,
    required String bikeModel,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.02),

            blurRadius: 8,

            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  bookingId,

                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                    color: Color(
                      0xFF0288D1,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  customerName,

                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.black87,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  bikeModel,

                  style: TextStyle(
                    fontSize: 11,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),

            decoration:
                BoxDecoration(
              color: statusBgColor,

              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),

            child: Text(
              status,

              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // BOOKING STATUS COLOR
  // ==================================================

  Color _getStatusColor(
    String status,
  ) {
    switch (status) {
      case 'Approved':
        return const Color(
          0xFF0288D1,
        );

      case 'Active Rental':
        return const Color(
          0xFF008955,
        );

      case 'Completed':
        return const Color(
          0xFF2E7D32,
        );

      case 'Cancelled':
        return const Color(
          0xFFD32F2F,
        );

      case 'Pending':
      default:
        return const Color(
          0xFFF57C00,
        );
    }
  }

  // ==================================================
  // BOOKING STATUS BACKGROUND
  // ==================================================

  Color _getStatusBackgroundColor(
    String status,
  ) {
    switch (status) {
      case 'Approved':
        return const Color(
          0xFFE1F5FE,
        );

      case 'Active Rental':
        return const Color(
          0xFFE8F8F0,
        );

      case 'Completed':
        return const Color(
          0xFFE8F5E9,
        );

      case 'Cancelled':
        return const Color(
          0xFFFFEBEE,
        );

      case 'Pending':
      default:
        return const Color(
          0xFFFFF3E0,
        );
    }
  }
}


// ==================================================
// FLEET METRIC CARD
// ==================================================

class _FleetCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String value;
  final String label;

  const _FleetCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(10),

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
                .withOpacity(0.02),

            blurRadius: 8,

            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(8),

            decoration:
                BoxDecoration(
              color: iconBgColor,

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  value,

                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.black87,
                  ),
                ),

                Text(
                  label,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 10,
                    color: Colors
                        .grey
                        .shade600,
                    fontWeight:
                        FontWeight.w500,
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