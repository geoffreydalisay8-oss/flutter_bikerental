
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageBookings extends StatefulWidget {
  const ManageBookings({super.key});

  @override
  State<ManageBookings> createState() => _ManageBookingsState();
}

class _ManageBookingsState extends State<ManageBookings> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _selectedStatus = 'All';

  static const Color _primaryColor = Color(0xFF008955);
  static const Color _backgroundColor = Color(0xFFF7F9FC);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET CUSTOMER NAME
  // ============================================================

  Future<String> _getCustomerName(String customerId) async {
    if (customerId.isEmpty) {
      return 'Unknown Customer';
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return customerId;
      }

      final data = doc.data()!;
      final name =
          (data['name'] ?? data['fullName'] ?? '').toString().trim();

      return name.isNotEmpty ? name : customerId;
    } catch (e) {
      debugPrint('Customer name error: $e');
      return customerId;
    }
  }

  // ============================================================
  // GET LATEST ID VERIFICATION STATUS
  // ============================================================

  Future<String> _getIdVerificationStatus(String customerId) async {
    if (customerId.isEmpty) {
      return 'Not Submitted';
    }

    try {
      final result = await FirebaseFirestore.instance
          .collection('id_verifications')
          .where('customerId', isEqualTo: customerId)
          .get();

      if (result.docs.isEmpty) {
        return 'Not Submitted';
      }

      QueryDocumentSnapshot<Map<String, dynamic>>? latestDoc;
      DateTime? latestDate;

      for (final doc in result.docs) {
        final data = doc.data();

        dynamic timestamp = data['clientSubmittedAt'];
        timestamp ??= data['submittedAt'];
        timestamp ??= data['uploadedDate'];

        DateTime? submittedDate;

        if (timestamp is Timestamp) {
          submittedDate = timestamp.toDate();
        } else if (timestamp is DateTime) {
          submittedDate = timestamp;
        } else if (timestamp is String) {
          submittedDate = DateTime.tryParse(timestamp);
        }

        if (latestDoc == null ||
            (submittedDate != null &&
                (latestDate == null ||
                    submittedDate.isAfter(latestDate)))) {
          latestDoc = doc;
          latestDate = submittedDate;
        }
      }

      latestDoc ??= result.docs.last;

      final latestData = latestDoc.data();
      final status =
          (latestData['status'] ?? 'Pending').toString().trim();

      return status.isEmpty ? 'Pending' : status;
    } catch (e) {
      debugPrint('ID verification error: $e');
      return 'Not Submitted';
    }
  }

  // ============================================================
  // UPDATE BOOKING STATUS
  // ============================================================

  Future<void> updateStatus(
    String bookingId,
    String currentStatus,
    String newStatus,
    String customerId,
  ) async {
    if (currentStatus.toLowerCase() == newStatus.toLowerCase()) {
      return;
    }

    if (!_isStatusChangeAllowed(currentStatus, newStatus)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot change $currentStatus to $newStatus.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // Require a verified ID before approving a booking.
    if (newStatus.toLowerCase() == 'approved') {
      final idStatus = await _getIdVerificationStatus(customerId);

      if (!mounted) return;

      final normalizedIdStatus = idStatus.toLowerCase().trim();

      if (normalizedIdStatus != 'verified' &&
          normalizedIdStatus != 'approved') {
        String message;

        if (normalizedIdStatus == 'pending') {
          message =
              'Cannot approve this booking. The customer ID is still pending verification.';
        } else if (normalizedIdStatus == 'rejected') {
          message =
              'Cannot approve this booking. The customer ID was rejected. The customer must submit a valid ID again.';
        } else {
          message =
              'Cannot approve this booking. The customer has not submitted a verified ID.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Booking Status'),
          content: Text(
            'Change booking status from "$currentStatus" to "$newStatus"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'bookingStatus': newStatus,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to $newStatus.'),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // UPDATE PAYMENT STATUS
  // ============================================================

  Future<void> updatePaymentStatus(
    String bookingId,
    String currentPaymentStatus,
    String paymentMethod,
  ) async {
    if (currentPaymentStatus.toLowerCase() == 'paid') {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This payment is already marked as Paid.'),
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text(
            'Mark this booking payment as Paid?\n\n'
            'Payment Method: $paymentMethod',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Paid'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'paymentStatus': 'Paid',
        'paymentDate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment status updated to Paid.'),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BOOKING STATUS WORKFLOW
  // ============================================================

  bool _isStatusChangeAllowed(
    String currentStatus,
    String newStatus,
  ) {
    switch (currentStatus.toLowerCase()) {
      case 'pending':
        return newStatus == 'Approved' ||
            newStatus == 'Cancelled';

      case 'approved':
        return newStatus == 'Active Rental' ||
            newStatus == 'Cancelled';

      case 'active rental':
        return newStatus == 'Completed';

      case 'completed':
      case 'cancelled':
        return false;

      default:
        return false;
    }
  }

  List<String> _availableStatusOptions(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'pending':
        return ['Approved', 'Cancelled'];

      case 'approved':
        return ['Active Rental', 'Cancelled'];

      case 'active rental':
        return ['Completed'];

      case 'completed':
      case 'cancelled':
        return [];

      default:
        return [];
    }
  }

  // ============================================================
  // DATE HELPER
  // ============================================================

  DateTime? _getDate(dynamic value) {
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: const Text(
          'Manage Bookings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading bookings:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          return Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search bicycle, customer or ID...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade400,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
              ),

              // Status filters
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('All'),
                    _buildFilterChip('Pending'),
                    _buildFilterChip('Approved'),
                    _buildFilterChip('Active Rental'),
                    _buildFilterChip('Completed'),
                    _buildFilterChip('Cancelled'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Summary
              _buildSummaryCards(docs),

              const SizedBox(height: 8),

              // Booking list
              Expanded(
                child: _buildBookingList(docs),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _buildFilterChip(String status) {
    final selected = _selectedStatus == status;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(status),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedStatus = status;
          });
        },
        selectedColor: _primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? _primaryColor : Colors.grey.shade200,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int pending = 0;
    int approved = 0;
    int active = 0;
    int completed = 0;

    for (final doc in docs) {
      final data = doc.data();
      final status =
          (data['bookingStatus'] ?? 'Pending').toString().toLowerCase();

      if (status == 'pending') {
        pending++;
      } else if (status == 'approved') {
        approved++;
      } else if (status == 'active rental') {
        active++;
      } else if (status == 'completed') {
        completed++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 24) / 4;

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryCard(
                'Pending',
                pending,
                Icons.schedule,
                const Color(0xFFE56A24),
                cardWidth,
              ),
              _buildSummaryCard(
                'Approved',
                approved,
                Icons.check_circle_outline,
                _primaryColor,
                cardWidth,
              ),
              _buildSummaryCard(
                'Active',
                active,
                Icons.pedal_bike,
                Colors.blue,
                cardWidth,
              ),
              _buildSummaryCard(
                'Completed',
                completed,
                Icons.done_all,
                Colors.purple,
                cardWidth,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    int count,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING LIST
  // ============================================================

  Widget _buildBookingList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final filteredDocs = docs.where((doc) {
      final data = doc.data();

      final bicycleName =
          (data['bicycleName'] ?? '').toString().toLowerCase();

      final customerId =
          (data['customerId'] ?? '').toString().toLowerCase();

      final customerName =
          (data['customerName'] ?? data['fullName'] ?? '')
              .toString()
              .toLowerCase();

      final bookingId = doc.id.toLowerCase();

      final status =
          (data['bookingStatus'] ?? 'Pending').toString();

      final matchesSearch =
          bicycleName.contains(_searchQuery) ||
          customerId.contains(_searchQuery) ||
          customerName.contains(_searchQuery) ||
          bookingId.contains(_searchQuery);

      final matchesStatus = _selectedStatus == 'All' ||
          status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    // Sort newest bookings first.
    filteredDocs.sort((a, b) {
      final dateA = _getDate(a.data()['createdAt']);
      final dateB = _getDate(b.data()['createdAt']);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    if (filteredDocs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 50,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty || _selectedStatus != 'All'
                    ? 'No matching bookings found.'
                    : 'No bookings found.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final booking = filteredDocs[index];
        final data = booking.data();

        final customerId =
            (data['customerId'] ?? '').toString();

        return FutureBuilder<String>(
          future: _getCustomerName(customerId),
          builder: (context, customerSnapshot) {
            final customerName =
                customerSnapshot.data ?? 'Loading...';

            return _buildBookingCard(
              context,
              booking.id,
              data,
              customerName,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BOOKING CARD
  // ============================================================

  Widget _buildBookingCard(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> data,
    String customerName,
  ) {
    final status =
        (data['bookingStatus'] ?? 'Pending').toString();

    final bicycleName =
        (data['bicycleName'] ?? 'Unnamed Bicycle').toString();

    final customerId =
        (data['customerId'] ?? 'N/A').toString();

    final paymentMethod =
        (data['paymentMethod'] ?? 'Pay at Rental Shop').toString();

    final paymentStatus =
        (data['paymentStatus'] ?? 'Unpaid').toString();

    final totalAmount = _getNumber(data['totalAmount']);
    final pickupDate = _getDate(data['pickupDate']);
    final returnDate = _getDate(data['returnDate']);
    final createdAt = _getDate(data['createdAt']);

    final displayCustomer =
        customerName.isNotEmpty && customerName != 'Loading...'
            ? customerName
            : customerId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pedal_bike,
                  color: Color(0xFF8C9BA5),
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookingId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bicycleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Customer: $displayCustomer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(status),
              _buildStatusMenu(bookingId, status, customerId),
            ],
          ),

          const SizedBox(height: 12),

          // Rental schedule
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: _primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupDate != null
                            ? DateFormat('MMM dd, yyyy')
                                .format(pickupDate)
                            : 'No pickup date',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatRentalTime(pickupDate, returnDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Booked: ${DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ID verification
          FutureBuilder<String>(
            future: _getIdVerificationStatus(customerId),
            builder: (context, snapshot) {
              final idStatus = snapshot.data ?? 'Checking...';
              return _buildIdVerificationStatus(idStatus);
            },
          ),

          const SizedBox(height: 10),

          // Bottom information
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Total',
                  '₱${totalAmount.toStringAsFixed(2)}',
                  Icons.payments_outlined,
                ),
              ),
              Expanded(
                child: _buildPaymentStatus(
                  paymentStatus,
                  paymentMethod,
                  bookingId,
                ),
              ),
              TextButton(
                onPressed: () {
                  _showBookingDetails(
                    context,
                    bookingId,
                    data,
                    customerName,
                  );
                },
                child: const Text(
                  'View',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ID VERIFICATION STATUS DISPLAY
  // ============================================================

  Widget _buildIdVerificationStatus(String status) {
    Color color;
    Color backgroundColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
        color = _primaryColor;
        backgroundColor = const Color(0xFFE8F8F0);
        icon = Icons.verified_rounded;
        break;

      case 'pending':
        color = Colors.orange;
        backgroundColor = const Color(0xFFFFF6E5);
        icon = Icons.hourglass_top_rounded;
        break;

      case 'rejected':
        color = Colors.red;
        backgroundColor = const Color(0xFFFFEBEB);
        icon = Icons.cancel_outlined;
        break;

      case 'checking...':
        color = Colors.grey;
        backgroundColor = const Color(0xFFF4F6F8);
        icon = Icons.sync_rounded;
        break;

      default:
        color = Colors.grey;
        backgroundColor = const Color(0xFFF4F6F8);
        icon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 7),
          const Text(
            'ID Verification:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS MENU
  // ============================================================

  Widget _buildStatusMenu(
    String bookingId,
    String currentStatus,
    String customerId,
  ) {
    final options = _availableStatusOptions(currentStatus);

    if (options.isEmpty) {
      return const SizedBox(width: 8);
    }

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey.shade400,
        size: 20,
      ),
      onSelected: (newStatus) {
        updateStatus(
          bookingId,
          currentStatus,
          newStatus,
          customerId,
        );
      },
      itemBuilder: (context) {
        return options.map((status) {
          return PopupMenuItem<String>(
            value: status,
            child: Row(
              children: [
                Icon(
                  _statusIcon(status),
                  size: 18,
                  color: _statusColor(status),
                ),
                const SizedBox(width: 8),
                Text(status),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'active rental':
        return Icons.pedal_bike;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return _primaryColor;
      case 'active rental':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _buildInfoItem(
    String title,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT STATUS
  // ============================================================

  Widget _buildPaymentStatus(
    String paymentStatus,
    String paymentMethod,
    String bookingId,
  ) {
    final isPaid = paymentStatus.toLowerCase() == 'paid';

    return GestureDetector(
      onTap: !isPaid
          ? () {
              updatePaymentStatus(
                bookingId,
                paymentStatus,
                paymentMethod,
              );
            }
          : null,
      child: Row(
        children: [
          Icon(
            isPaid
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 17,
            color: isPaid ? _primaryColor : Colors.orange,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  paymentStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPaid
                        ? _primaryColor
                        : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        backgroundColor = const Color(0xFFE8F8F0);
        textColor = _primaryColor;
        break;

      case 'active rental':
        backgroundColor = const Color(0xFFEAF3FF);
        textColor = Colors.blue;
        break;

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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // BOOKING DETAILS
  // ============================================================

  void _showBookingDetails(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> data,
    String customerName,
  ) {
    final bicycleName =
        (data['bicycleName'] ?? 'Unnamed Bicycle').toString();

    final customerId =
        (data['customerId'] ?? 'N/A').toString();

    final displayCustomer =
        customerName.isNotEmpty && customerName != 'Loading...'
            ? customerName
            : customerId;

    final status =
        (data['bookingStatus'] ?? 'Pending').toString();

    final paymentMethod =
        (data['paymentMethod'] ?? 'Pay at Rental Shop').toString();

    final paymentStatus =
        (data['paymentStatus'] ?? 'Unpaid').toString();

    final pickupDate = _getDate(data['pickupDate']);
    final returnDate = _getDate(data['returnDate']);
    final createdAt = _getDate(data['createdAt']);

    final pickupLocation =
        (data['pickupLocation'] ?? 'Main Campus Hub').toString();

    final returnLocation =
        (data['returnLocation'] ?? 'Main Campus Hub').toString();

    final rentalFee = _getNumber(data['rentalFee']);
    final bookingFee = _getNumber(data['bookingFee']);
    final totalAmount = _getNumber(data['totalAmount']);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Booking Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Booking ID', bookingId),
                  _detailRow(
                    'Booking Date',
                    createdAt != null
                        ? DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(createdAt)
                        : 'Not available',
                  ),
                  _detailRow('Customer', displayCustomer),
                  _detailRow('Customer ID', customerId),
                  _detailRow('Bicycle', bicycleName),

                  const Divider(height: 24),

                  const Text(
                    'Rental Schedule',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  _detailRow(
                    'Pickup',
                    pickupDate != null
                        ? DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(pickupDate)
                        : 'Not set',
                  ),
                  _detailRow(
                    'Return',
                    returnDate != null
                        ? DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(returnDate)
                        : 'Not set',
                  ),
                  _detailRow('Pickup Location', pickupLocation),
                  _detailRow('Return Location', returnLocation),

                  const Divider(height: 24),

                  const Text(
                    'ID Verification',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  FutureBuilder<String>(
                    future: _getIdVerificationStatus(customerId),
                    builder: (context, snapshot) {
                      final idStatus =
                          snapshot.data ?? 'Checking...';
                      return _buildIdVerificationStatus(idStatus);
                    },
                  ),

                  const Divider(height: 24),

                  const Text(
                    'Payment',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  _detailRow(
                    'Rental Fee',
                    '₱${rentalFee.toStringAsFixed(2)}',
                  ),
                  _detailRow(
                    'Booking Fee',
                    '₱${bookingFee.toStringAsFixed(2)}',
                  ),
                  _detailRow(
                    'Total Amount',
                    '₱${totalAmount.toStringAsFixed(2)}',
                  ),
                  _detailRow('Payment Method', paymentMethod),
                  _detailRow('Payment Status', paymentStatus),

                  const Divider(height: 24),

                  const Text(
                    'Booking Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _detailRow('Status', status),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
            if (paymentStatus.toLowerCase() != 'paid')
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  updatePaymentStatus(
                    bookingId,
                    paymentStatus,
                    paymentMethod,
                  );
                },
                child: const Text(
                  'Mark Paid',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _showStatusOptions(
                  context,
                  bookingId,
                  status,
                  customerId,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Status'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS OPTIONS DIALOG
  // ============================================================

  void _showStatusOptions(
    BuildContext context,
    String bookingId,
    String currentStatus,
    String customerId,
  ) {
    final options = _availableStatusOptions(currentStatus);

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This booking can no longer be changed.',
          ),
        ),
      );

      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Booking Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Current status: $currentStatus',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 15),
                ...options.map((status) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _statusIcon(status),
                      color: _statusColor(status),
                    ),
                    title: Text(status),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);

                      updateStatus(
                        bookingId,
                        currentStatus,
                        status,
                        customerId,
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // NUMBER HELPER
  // ============================================================

  double _getNumber(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  // ============================================================
  // RENTAL TIME FORMAT
  // ============================================================

  String _formatRentalTime(
    DateTime? pickupDate,
    DateTime? returnDate,
  ) {
    if (pickupDate == null && returnDate == null) {
      return 'Schedule not available';
    }

    if (pickupDate != null && returnDate != null) {
      return '${DateFormat('hh:mm a').format(pickupDate)}'
          ' - '
          '${DateFormat('hh:mm a').format(returnDate)}';
    }

    if (pickupDate != null) {
      return DateFormat('hh:mm a').format(pickupDate);
    }

    return DateFormat('hh:mm a').format(returnDate!);
  }
}