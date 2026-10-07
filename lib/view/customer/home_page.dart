import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'bicycles_page.dart';
import 'my_booking_page.dart';

class CustomerHomePage extends StatefulWidget {
  // ============================================================
  // INITIAL TAB
  // 0 = Home
  // 1 = Bicycles
  // 2 = Bookings
  // 3 = Profile
  // ============================================================

  final int initialIndex;

  const CustomerHomePage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  late int _selectedIndex;

  final List<Widget> _pages = const [
    HomeContentView(),
    BicyclesPage(),
    MyBookingPage(),
    ProfileContentView(),
  ];

  // ============================================================
  // INITIALIZE SELECTED TAB
  // ============================================================

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.initialIndex;
  }

  // ============================================================
  // CHANGE TAB
  // ============================================================

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xFF1B4D3E),

        unselectedItemColor: Colors.grey,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ),
            activeIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.directions_bike_outlined,
            ),
            activeIcon: Icon(
              Icons.directions_bike,
            ),
            label: 'Bicycles',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_month_outlined,
            ),
            activeIcon: Icon(
              Icons.calendar_month,
            ),
            label: 'Bookings',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            activeIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME CONTENT
// ============================================================

class HomeContentView extends StatefulWidget {
  const HomeContentView({super.key});

  @override
  State<HomeContentView> createState() => _HomeContentViewState();
}

class _HomeContentViewState extends State<HomeContentView> {
  static const primaryColor = Color(0xFF1B4D3E);

  String _selectedType = 'All';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,

        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bike,
                color: primaryColor,
              ),
            ),

            const SizedBox(width: 12),

            const Text(
              'Home',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          
          const SizedBox(width: 5),

          Padding(
            padding: const EdgeInsets.only(
              right: 15,
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          30,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ======================================================
            // WELCOME
            // ======================================================

            StreamBuilder<DocumentSnapshot>(
              stream: user == null
                  ? null
                  : FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),

              builder: (context, snapshot) {
                String name = 'Customer';

                if (snapshot.hasData &&
                    snapshot.data!.exists) {
                  final data =
                      snapshot.data!.data()
                          as Map<String, dynamic>?;

                  if (data != null &&
                      data['name'] != null &&
                      data['name']
                          .toString()
                          .trim()
                          .isNotEmpty) {
                    name = data['name'].toString();
                  }
                }

                final hour = DateTime.now().hour;

                String greeting;

                if (hour < 12) {
                  greeting = 'Good morning';
                } else if (hour < 18) {
                  greeting = 'Good afternoon';
                } else {
                  greeting = 'Good evening';
                }

                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      '$greeting, $name!',

                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'Ready for your next ride?',

                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(
              height: 25,
            ),

            // ======================================================
            // BROWSE BY TYPE
            // ======================================================

            const Text(
              'Browse by Type',

              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: Row(
                children: [
                  _buildTypeChip('All'),
                  _buildTypeChip('Mountain'),
                  _buildTypeChip('Road'),
                  _buildTypeChip('City'),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ======================================================
            // YOUR BOOKING
            // ======================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Your Booking',

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    final parent =
                        context.findAncestorStateOfType<
                            _CustomerHomePageState>();

                    parent?.changeTab(2);
                  },

                  child: const Text(
                    'See All',

                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            _buildYourBooking(),

            const SizedBox(
              height: 25,
            ),

            // ======================================================
            // AVAILABLE BICYCLES
            // ======================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Available Bicycles',

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    final parent =
                        context.findAncestorStateOfType<
                            _CustomerHomePageState>();

                    parent?.changeTab(1);
                  },

                  child: const Text(
                    'See All',

                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bicycles')
                  .where(
                    'available',
                    isEqualTo: true,
                  )
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),

                      child:
                          CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildEmptyBicycleResult(
                    message:
                        'Unable to load bicycles.',
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return _buildEmptyBicycleResult(
                    message:
                        'No bicycles available.',
                  );
                }

                final bicycles =
                    snapshot.data!.docs;

                return Column(
                  children: bicycles
                      .take(3)
                      .map(
                        (doc) =>
                            _buildBicycleCard(doc),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TYPE CHIP
  // ============================================================

  Widget _buildTypeChip(String label) {
    final bool selected =
        _selectedType == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = label;
        });
      },

      child: Container(
        margin: const EdgeInsets.only(
          right: 10,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? primaryColor
              : Colors.white,

          borderRadius:
              BorderRadius.circular(25),

          border: Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade300,
          ),
        ),

        child: Text(
          label,

          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.black87,

            fontWeight: selected
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // YOUR BOOKING
  // ============================================================

  Widget _buildYourBooking() {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildNoBooking();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where(
            'customerId',
            isEqualTo: user.uid,
          )
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(25),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(15),
            ),

            child: const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return _buildNoBooking();
        }

        final activeBookings =
            snapshot.data!.docs.where(
          (doc) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            final status =
                data['bookingStatus'] ??
                    'Pending';

            return status == 'Pending' ||
                status == 'Approved' ||
                status == 'Active Rental';
          },
        ).toList();

        if (activeBookings.isEmpty) {
          return _buildNoBooking();
        }

        activeBookings.sort(
          (a, b) {
            final aData =
                a.data()
                    as Map<String, dynamic>;

            final bData =
                b.data()
                    as Map<String, dynamic>;

            final aDate =
                _parseTimestamp(
              aData['pickupDate'],
            );

            final bDate =
                _parseTimestamp(
              bData['pickupDate'],
            );

            return aDate.compareTo(bDate);
          },
        );

        final doc =
            activeBookings.first;

        final data =
            doc.data()
                as Map<String, dynamic>;

        return _buildBookingCard(
          doc.id,
          data,
        );
      },
    );
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.now();
    }

    return DateTime.now();
  }

  // ============================================================
  // NO BOOKING
  // ============================================================

  Widget _buildNoBooking() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(15),
      ),

      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,

            size: 40,

            color: Colors.grey[400],
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            'No active booking',

            style: TextStyle(
              fontWeight:
                  FontWeight.w600,

              color:
                  Colors.grey[700],
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Book a bicycle to start your ride.',

            textAlign:
                TextAlign.center,

            style: TextStyle(
              color:
                  Colors.grey[500],

              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING CARD
  // ============================================================

  Widget _buildBookingCard(
    String bookingId,
    Map<String, dynamic> data,
  ) {
    final bicycleName =
        data['bicycleName'] ??
            'Bicycle';

    final pickupDate =
        _parseTimestamp(
      data['pickupDate'],
    );

    final returnDate =
        _parseTimestamp(
      data['returnDate'],
    );

    final rentalFee =
        (data['rentalFee'] ?? 0)
            .toDouble();

    final bookingFee =
        (data['bookingFee'] ?? 0)
            .toDouble();

    final totalAmount =
        (data['totalAmount'] ??
                rentalFee + bookingFee)
            .toDouble();

    final bookingStatus =
        data['bookingStatus'] ??
            'Pending';

    final paymentStatus =
        data['paymentStatus'] ??
            'Unpaid';

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.04,
            ),

            blurRadius: 10,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [
              Expanded(
                child: Text(
                  bicycleName,

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              _buildStatusBadge(
                bookingStatus,
                _getBookingStatusColor(
                  bookingStatus,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,

                size: 17,

                color:
                    Colors.grey[600],
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  '${DateFormat('MMM dd, yyyy').format(pickupDate)} - '
                  '${DateFormat('MMM dd, yyyy').format(returnDate)}',

                  style: TextStyle(
                    color:
                        Colors.grey[700],

                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              Icon(
                Icons.access_time,

                size: 17,

                color:
                    Colors.grey[600],
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                '${DateFormat('hh:mm a').format(pickupDate)} - '
                '${DateFormat('hh:mm a').format(returnDate)}',

                style: TextStyle(
                  color:
                      Colors.grey[700],

                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Total: ₱${totalAmount.toStringAsFixed(2)}',

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              _buildStatusBadge(
                paymentStatus,

                paymentStatus == 'Paid'
                    ? Colors.green
                    : Colors.orange,
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          SizedBox(
            width: double.infinity,

            child: OutlinedButton(
              onPressed: () {
                final parent =
                    context.findAncestorStateOfType<
                        _CustomerHomePageState>();

                parent?.changeTab(2);
              },

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    primaryColor,

                side:
                    const BorderSide(
                  color:
                      primaryColor,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 12,
                ),
              ),

              child: const Text(
                'View Booking',

                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BICYCLE CARD
  // ============================================================

  Widget _buildBicycleCard(
    QueryDocumentSnapshot doc,
  ) {
    final data =
        doc.data()
            as Map<String, dynamic>;

    final name =
        data['name'] ??
            'Bicycle';

    final type =
        data['type'] ??
            'Bicycle';

    final rentalRate =
        (data['rentalRate'] ?? 0)
            .toDouble();

    final description =
        data['description'] ??
            '';

    final imageUrl =
        data['imageUrl'] ??
            '';

    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.04,
            ),

            blurRadius: 10,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          if (imageUrl
              .toString()
              .isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(
                top:
                    Radius.circular(18),
              ),

              child:
                  Image.network(
                imageUrl,

                width:
                    double.infinity,

                height: 170,

                fit:
                    BoxFit.cover,

                errorBuilder:
                    (context, error, stackTrace) {
                  return _buildBikePlaceholder();
                },
              ),
            )
          else
            _buildBikePlaceholder(),

          Padding(
            padding:
                const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,

                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            primaryColor
                                .withOpacity(
                          0.1,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),

                      child: Text(
                        type,

                        style:
                            const TextStyle(
                          color:
                              primaryColor,

                          fontSize: 11,

                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                if (description
                    .toString()
                    .trim()
                    .isNotEmpty)
                  Text(
                    description,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        TextStyle(
                      color:
                          Colors.grey[600],

                      fontSize: 13,
                    ),
                  ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .payments_outlined,

                      size: 18,

                      color:
                          primaryColor,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      '₱${rentalRate.toStringAsFixed(2)} / hour',

                      style:
                          const TextStyle(
                        color:
                            primaryColor,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 14,
                ),

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      ElevatedButton(
                    onPressed: () {
                      final parent =
                          context.findAncestorStateOfType<
                              _CustomerHomePageState>();

                      parent?.changeTab(1);
                    },

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryColor,

                      foregroundColor:
                          Colors.white,

                      elevation: 0,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),

                    child:
                        const Text(
                      'Rent Now',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
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

  Widget _buildBikePlaceholder() {
    return Container(
      width: double.infinity,

      height: 170,

      decoration:
          const BoxDecoration(
        color:
            Color(0xFFE9EFEC),

        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(18),
        ),
      ),

      child:
          const Center(
        child: Icon(
          Icons.directions_bike,

          size: 65,

          color:
              primaryColor,
        ),
      ),
    );
  }

  Widget _buildEmptyBicycleResult({
    required String message,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(25),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(15),
      ),

      child: Column(
        children: [
          Icon(
            Icons
                .directions_bike_outlined,

            size: 40,

            color:
                Colors.grey[400],
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            message,

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withOpacity(0.1),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        text,

        style:
            TextStyle(
          color: color,

          fontSize: 11,

          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBookingStatusColor(
    String status,
  ) {
    switch (status) {
      case 'Approved':
        return Colors.blue;

      case 'Active Rental':
        return Colors.green;

      case 'Completed':
        return Colors.grey;

      case 'Cancelled':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfileContentView extends StatelessWidget {
  const ProfileContentView({
    super.key,
  });

  static const primaryColor =
      Color(0xFF1B4D3E);

  @override
  Widget build(
    BuildContext context,
  ) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7F7),

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        elevation: 0,

        automaticallyImplyLeading:
            false,

        title: const Text(
          'Profile',

          style: TextStyle(
            color:
                Colors.black87,

            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(25),

              decoration:
                  BoxDecoration(
                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),

              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 42,

                    backgroundColor:
                        primaryColor,

                    child: Icon(
                      Icons.person,

                      color:
                          Colors.white,

                      size: 45,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  Text(
                    user?.email ??
                        'Customer',

                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Container(
              width:
                  double.infinity,

              decoration:
                  BoxDecoration(
                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),

              child: Column(
                children: [
                  ListTile(
                    leading:
                        const Icon(
                      Icons
                          .person_outline,

                      color:
                          primaryColor,
                    ),

                    title:
                        const Text(
                      'Account',
                    ),

                    trailing:
                        const Icon(
                      Icons
                          .chevron_right,
                    ),

                    onTap: () {},
                  ),

                  const Divider(
                    height: 1,
                  ),

                  ListTile(
                    leading:
                        const Icon(
                      Icons
                          .settings_outlined,

                      color:
                          primaryColor,
                    ),

                    title:
                        const Text(
                      'Settings',
                    ),

                    trailing:
                        const Icon(
                      Icons
                          .chevron_right,
                    ),

                    onTap: () {},
                  ),

                  const Divider(
                    height: 1,
                  ),

                  ListTile(
                    leading:
                        const Icon(
                      Icons
                          .help_outline,

                      color:
                          primaryColor,
                    ),

                    title:
                        const Text(
                      'Help & Support',
                    ),

                    trailing:
                        const Icon(
                      Icons
                          .chevron_right,
                    ),

                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width:
                  double.infinity,

              child:
                  OutlinedButton.icon(
                onPressed:
                    () async {
                  await FirebaseAuth
                      .instance
                      .signOut();

                  if (context.mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(
                      '/',
                      (route) => false,
                    );
                  }
                },

                icon:
                    const Icon(
                  Icons.logout,
                ),

                label:
                    const Text(
                  'Logout',
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.red,

                  side:
                      const BorderSide(
                    color:
                        Colors.red,
                  ),

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 13,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}