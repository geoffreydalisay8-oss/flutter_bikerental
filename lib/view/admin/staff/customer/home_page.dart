import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String staffId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
        title: const Text(
          'Staff Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Welcome
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Dashboard Cards
            Row(
              children: [
                Expanded(
                  child: _dashboardCard(
                    title: 'Total Bicycles',
                    icon: Icons.directions_bike,
                    collection: 'bicycles',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dashboardCard(
                    title: 'Total Bookings',
                    icon: Icons.book_online,
                    collection: 'bookings',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _dashboardCard(
                    title: 'Pending Bookings',
                    icon: Icons.pending_actions,
                    collection: 'bookings',
                    queryField: 'bookingStatus',
                    queryValue: 'Pending',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dashboardCard(
                    title: 'Payments',
                    icon: Icons.payment,
                    collection: 'payments',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Your Bookings
            const Text(
              'Your Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where(
                    'assignedTo',
                    isEqualTo: staffId,
                  )
                  .snapshots(),

              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B4D3E),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No bookings assigned to you.',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {

                    final data =
                        bookings[index].data()
                            as Map<String, dynamic>;

                    final bookingId =
                        bookings[index].id;

                    final bicycleName =
                        data['bicycleName'] ?? 'Unknown Bicycle';

                    final customerId =
                        data['customerId'] ?? 'Unknown Customer';

                    final bookingStatus =
                        data['bookingStatus'] ?? 'Pending';

                    final paymentStatus =
                        data['paymentStatus'] ?? 'Unpaid';

                    DateTime? pickupDate;
                    DateTime? returnDate;

                    if (data['pickupDate'] is Timestamp) {
                      pickupDate =
                          (data['pickupDate'] as Timestamp)
                              .toDate();
                    }

                    if (data['returnDate'] is Timestamp) {
                      returnDate =
                          (data['returnDate'] as Timestamp)
                              .toDate();
                    }

                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          // Booking ID
                          Row(
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                color:
                                    Color(0xFF1B4D3E),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Booking ID: $bookingId',
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Bicycle
                          Text(
                            bicycleName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Customer
                          Text(
                            'Customer ID: $customerId',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Pickup
                          if (pickupDate != null)
                            Text(
                              'Pickup: '
                              '${pickupDate.month}/'
                              '${pickupDate.day}/'
                              '${pickupDate.year}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),

                          const SizedBox(height: 5),

                          // Return
                          if (returnDate != null)
                            Text(
                              'Return: '
                              '${returnDate.month}/'
                              '${returnDate.day}/'
                              '${returnDate.year}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Status
                          Row(
                            children: [

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFE8F1ED,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(20),
                                ),
                                child: Text(
                                  bookingStatus,
                                  style:
                                      const TextStyle(
                                    color:
                                        Color(
                                      0xFF1B4D3E,
                                    ),
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius:
                                      BorderRadius
                                          .circular(20),
                                ),
                                child: Text(
                                  paymentStatus,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dashboard Card
  Widget _dashboardCard({
    required String title,
    required IconData icon,
    required String collection,
    String? queryField,
    String? queryValue,
  }) {
    Query query =
        FirebaseFirestore.instance.collection(collection);

    if (queryField != null && queryValue != null) {
      query = query.where(
        queryField,
        isEqualTo: queryValue,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {

        final int count =
            snapshot.data?.docs.length ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Icon(
                icon,
                size: 30,
                color: const Color(0xFF1B4D3E),
              ),

              const SizedBox(height: 12),

              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}