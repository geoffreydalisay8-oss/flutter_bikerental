import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bikerental/service/auth_service.dart';
import 'package:bikerental/login_page.dart';

import 'package:bikerental/view/admin/bicycles_page.dart';
import 'package:bikerental/view/admin/bookings_page.dart';
import 'package:bikerental/view/admin/id_verification_page.dart';
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

  // ==================================================
  // PAGES FOR SIDEBAR
  // ==================================================

  final List<Widget> pages = [
    const AdminHomePage(),
    const ManageBicycles(),
    const ManageBookings(),
    const IdVerificationPage(),
    const ManageUsers(),
    const SalesReportPage(),
    const FeedbackList(),
  ];

  // ==================================================
  // SIDEBAR TITLES
  // ==================================================

  final List<String> titles = [
    'Dashboard',
    'Bicycles',
    'Bookings',
    'ID Verification',
    'Users',
    'Reports',
    'Feedback',
  ];

  // ==================================================
  // SIDEBAR ICONS
  // ==================================================

  final List<IconData> icons = [
    Icons.dashboard,
    Icons.pedal_bike,
    Icons.book,
    Icons.badge,
    Icons.people,
    Icons.assessment,
    Icons.feedback,
  ];

  // ==================================================
  // LOGOUT
  // ==================================================

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

  // ==================================================
  // GO TO BOOKINGS
  // ==================================================

  void goToBookings() {
    setState(() {
      selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // ==================================================
      // TOP APP BAR
      // ==================================================

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

      // ==================================================
      // SIDEBAR
      // ==================================================

      drawer: Drawer(
        child: Column(
          children: [
            // ==================================================
            // SIDEBAR HEADER
            // ==================================================

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
                      'GoPedal',
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

            // ==================================================
            // SIDEBAR MENU
            // ==================================================

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

            // ==================================================
            // LOGOUT
            // ==================================================

            const Divider(),

            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),

              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),

              onTap: logout,
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),

      // ==================================================
      // MAIN CONTENT
      // ==================================================

      body: selectedIndex == 0
          ? AdminHomePage(
              onViewAllBookings: goToBookings,
            )
          : pages[selectedIndex],
    );
  }
}

// ==================================================
// ADMIN HOME PAGE
// ==================================================

class AdminHomePage extends StatelessWidget {
  final VoidCallback? onViewAllBookings;

  const AdminHomePage({
    super.key,
    this.onViewAllBookings,
  });

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

        if (bicycleSnapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load bicycle data.',
            ),
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

            if (bookingSnapshot.hasError) {
              return const Center(
                child: Text(
                  'Failed to load booking data.',
                ),
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

                if (userSnapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Failed to load user data.',
                    ),
                  );
                }

                // ==================================================
                // BICYCLE DATA
                // ==================================================

                final bicycles =
                    bicycleSnapshot.data?.docs ?? [];

                final totalBikes =
                    bicycles.length;

                final availableBikes =
                    bicycles.where((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  return data['available'] == true;
                }).length;

                // ==================================================
                // BOOKING DATA
                // ==================================================

                final bookings =
                    bookingSnapshot.data?.docs ?? [];

                final activeRentals =
                    bookings.where((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  final status =
                      data['bookingStatus']
                          ?.toString()
                          .toLowerCase();

                  return status == 'active rental';
                }).length;

                final pendingBookings =
                    bookings.where((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  final status =
                      data['bookingStatus']
                          ?.toString()
                          .toLowerCase();

                  return status == 'pending';
                }).length;

                // ==================================================
                // TODAY'S BOOKINGS
                // ==================================================

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

                  DateTime? date;

                  if (pickupDate is Timestamp) {
                    date = pickupDate.toDate();
                  } else if (pickupDate is DateTime) {
                    date = pickupDate;
                  } else if (pickupDate is String) {
                    date = DateTime.tryParse(
                      pickupDate,
                    );
                  }

                  if (date == null) {
                    return false;
                  }

                  return date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                }).length;

                // ==================================================
                // TODAY'S SALES
                // ==================================================

                double todaySales = 0;

                for (final doc in bookings) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  final paymentStatus =
                      data['paymentStatus']
                          ?.toString()
                          .toLowerCase();

                  if (paymentStatus != 'paid') {
                    continue;
                  }

                  final paymentDate =
                      data['paymentDate'];

                  DateTime? date;

                  if (paymentDate is Timestamp) {
                    date = paymentDate.toDate();
                  } else if (paymentDate is DateTime) {
                    date = paymentDate;
                  } else if (paymentDate is String) {
                    date = DateTime.tryParse(
                      paymentDate,
                    );
                  }

                  // If there is no paymentDate,
                  // use pickupDate as fallback.
                  if (date == null) {
                    final pickupDate =
                        data['pickupDate'];

                    if (pickupDate is Timestamp) {
                      date = pickupDate.toDate();
                    } else if (pickupDate is DateTime) {
                      date = pickupDate;
                    } else if (pickupDate is String) {
                      date = DateTime.tryParse(
                        pickupDate,
                      );
                    }
                  }

                  if (date == null) {
                    continue;
                  }

                  final isToday =
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;

                  if (!isToday) {
                    continue;
                  }

                  final amount =
                      data['totalAmount'];

                  if (amount is num) {
                    todaySales +=
                        amount.toDouble();
                  } else if (amount != null) {
                    todaySales +=
                        double.tryParse(
                              amount.toString(),
                            ) ??
                            0;
                  }
                }

                // ==================================================
                // CUSTOMER DATA
                // ==================================================

                final users =
                    userSnapshot.data?.docs ?? [];

                final totalCustomers =
                    users.where((doc) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  final role =
                      data['role']
                          ?.toString()
                          .toLowerCase();

                  return role == 'customer';
                }).length;

                // ==================================================
                // REVENUE
                // ==================================================

                double totalRevenue = 0;

                for (final doc in bookings) {
                  final data = doc.data()
                      as Map<String, dynamic>;

                  final paymentStatus =
                      data['paymentStatus']
                          ?.toString()
                          .toLowerCase();

                  if (paymentStatus == 'paid') {
                    final amount =
                        data['totalAmount'];

                    if (amount is num) {
                      totalRevenue +=
                          amount.toDouble();
                    } else if (amount != null) {
                      totalRevenue +=
                          double.tryParse(
                                amount.toString(),
                              ) ??
                              0;
                    }
                  }
                }

                // ==================================================
                // RECENT BOOKINGS
                // ==================================================

                final recentBookings =
                    List<QueryDocumentSnapshot>.from(
                  bookings,
                );

                recentBookings.sort((a, b) {
                  final dataA = a.data()
                      as Map<String, dynamic>;

                  final dataB = b.data()
                      as Map<String, dynamic>;

                  final pickupA =
                      dataA['pickupDate'];

                  final pickupB =
                      dataB['pickupDate'];

                  DateTime dateA =
                      DateTime(1970);

                  DateTime dateB =
                      DateTime(1970);

                  if (pickupA is Timestamp) {
                    dateA = pickupA.toDate();
                  } else if (pickupA is DateTime) {
                    dateA = pickupA;
                  } else if (pickupA is String) {
                    dateA =
                        DateTime.tryParse(
                              pickupA,
                            ) ??
                            DateTime(1970);
                  }

                  if (pickupB is Timestamp) {
                    dateB = pickupB.toDate();
                  } else if (pickupB is DateTime) {
                    dateB = pickupB;
                  } else if (pickupB is String) {
                    dateB =
                        DateTime.tryParse(
                              pickupB,
                            ) ??
                            DateTime(1970);
                  }

                  return dateB.compareTo(dateA);
                });

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
                      // ==================================================
                      // FLEET SNAPSHOT
                      // ==================================================

                      _buildSectionTitle(
                        'FLEET SNAPSHOT',
                      ),

                      const SizedBox(height: 10),

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
                                totalBikes.toString(),

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
                                availableBikes.toString(),

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
                                activeRentals.toString(),

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
                                todayBookings.toString(),

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
                                pendingBookings.toString(),

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
                                totalCustomers.toString(),

                            label:
                                'Total Customers',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // FINANCIAL OVERVIEW
                      // ==================================================

                      _buildSectionTitle(
                        'FINANCIAL OVERVIEW',
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),

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
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  const Text(
                                    'TOTAL REVENUE',

                                    style:
                                        TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.bold,
                                      color: Color(
                                        0xFF90A4AE,
                                      ),
                                      letterSpacing: 0.5,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    '₱${totalRevenue.toStringAsFixed(2)}',

                                    style:
                                        const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
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
                              color:
                                  Colors.grey.shade200,
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  const Text(
                                    "TODAY'S SALES",

                                    style:
                                        TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.bold,
                                      color: Color(
                                        0xFF90A4AE,
                                      ),
                                      letterSpacing: 0.5,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    '₱${todaySales.toStringAsFixed(2)}',

                                    style:
                                        const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
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

                      const SizedBox(height: 20),

                      // ==================================================
                      // RECENT BOOKINGS
                      // ==================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,

                        children: [
                          _buildSectionTitle(
                            'RECENT BOOKINGS',
                          ),

                          GestureDetector(
                            onTap:
                                onViewAllBookings,

                            child: Row(
                              children: const [
                                Text(
                                  'View All ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: Color(
                                      0xFF00897B,
                                    ),
                                  ),
                                ),

                                Icon(
                                  Icons.arrow_forward_ios,
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

                      const SizedBox(height: 10),

                      if (recentBookings.isEmpty)
                        const Center(
                          child: Padding(
                            padding:
                                EdgeInsets.all(20),

                            child: Text(
                              'No bookings yet.',
                            ),
                          ),
                        )
                      else
                        ...recentBookings
                            .take(5)
                            .map((doc) {
                          final data =
                              doc.data()
                                  as Map<String, dynamic>;

                          final bookingStatus =
                              data['bookingStatus']
                                      ?.toString() ??
                                  'Pending';

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),

                            child: _buildBookingCard(
                              bookingId: doc.id,

                              customerName:
                                  data['customerName']
                                          ?.toString() ??
                                      'Unknown Customer',

                              bikeModel:
                                  data['bicycleName']
                                          ?.toString() ??
                                      'Unknown Bicycle',

                              status:
                                  bookingStatus,

                              statusColor:
                                  _getStatusColor(
                                bookingStatus,
                              ),

                              statusBgColor:
                                  _getStatusBackgroundColor(
                                bookingStatus,
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

  Widget _buildSectionTitle(String title) {
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
            color:
                Colors.black.withOpacity(0.02),

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

                const SizedBox(height: 4),

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

                const SizedBox(height: 2),

                Text(
                  bikeModel,

                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF0288D1);

      case 'active rental':
        return const Color(0xFF008955);

      case 'completed':
        return const Color(0xFF2E7D32);

      case 'cancelled':
        return const Color(0xFFD32F2F);

      case 'pending':
      default:
        return const Color(0xFFF57C00);
    }
  }

  // ==================================================
  // BOOKING STATUS BACKGROUND
  // ==================================================

  Color _getStatusBackgroundColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFE1F5FE);

      case 'active rental':
        return const Color(0xFFE8F8F0);

      case 'completed':
        return const Color(0xFFE8F5E9);

      case 'cancelled':
        return const Color(0xFFFFEBEE);

      case 'pending':
      default:
        return const Color(0xFFFFF3E0);
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
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.02),

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
                  BorderRadius.circular(10),
            ),

            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

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
                    color:
                        Colors.grey.shade600,
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