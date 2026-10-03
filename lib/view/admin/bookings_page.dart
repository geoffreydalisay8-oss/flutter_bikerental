import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBookings extends StatefulWidget {
  const ManageBookings({super.key});

  @override
  State<ManageBookings> createState() => _ManageBookingsState();
}

class _ManageBookingsState extends State<ManageBookings> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> updateStatus(String bookingId, String status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({
      'bookingStatus': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          'Manage Bookings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search bicycle, customer or ID...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF008955)),
                ),
              ),
            ),
          ),

          // Bookings List Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF008955),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No bookings found.'),
                  );
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bicycleName =
                      (data['bicycleName'] ?? '').toString().toLowerCase();
                  final customerId =
                      (data['customerId'] ?? '').toString().toLowerCase();
                  final bookingId = doc.id.toLowerCase();

                  return bicycleName.contains(_searchQuery) ||
                      customerId.contains(_searchQuery) ||
                      bookingId.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No matching bookings found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final booking = filteredDocs[index];
                    final data = booking.data() as Map<String, dynamic>;
                    return _buildBookingCard(context, booking.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> data,
  ) {
    final status = data['bookingStatus'] ?? 'Pending';
    final bicycleName = data['bicycleName'] ?? 'Unnamed Bicycle';
    final customerId = data['customerId'] ?? 'N/A';
    final paymentStatus = data['paymentStatus'] ?? 'Unpaid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              color: Color(0xFF8C9BA5),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),

          // Main Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookingId,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bicycleName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Cust: $customerId',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      paymentStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: paymentStatus.toLowerCase() == 'paid'
                            ? const Color(0xFF008955)
                            : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge + Popup Menu to change status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBadge(status),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onSelected: (newStatus) {
                  updateStatus(bookingId, newStatus);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'Pending',
                    child: Text('Pending'),
                  ),
                  PopupMenuItem(
                    value: 'Approved',
                    child: Text('Approved'),
                  ),
                  PopupMenuItem(
                    value: 'Active Rental',
                    child: Text('Active Rental'),
                  ),
                  PopupMenuItem(
                    value: 'Completed',
                    child: Text('Completed'),
                  ),
                  PopupMenuItem(
                    value: 'Cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        backgroundColor = const Color(0xFFE8F8F0);
        textColor = const Color(0xFF008955);
        break;
      case 'active rental':
      case 'pending':
        backgroundColor = const Color(0xFFFFF6E5);
        textColor = const Color(0xFFE56A24);
        break;
      case 'cancelled':
        backgroundColor = const Color(0xFFFFEBEB);
        textColor = const Color(0xFFE53935);
        break;
      default:
        backgroundColor = const Color(0xFFF4F6F8);
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}