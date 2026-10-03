import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagePayments extends StatefulWidget {
  const ManagePayments({super.key});

  @override
  State<ManagePayments> createState() => _ManagePaymentsState();
}

class _ManagePaymentsState extends State<ManagePayments> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'Unpaid';

  Future<void> recordPayment(
    String bookingId,
    double amount,
    String method,
  ) async {
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('payments').add({
        'bookingId': bookingId,
        'amount': amount,
        'paymentMethod': method,
        'paymentDate': FieldValue.serverTimestamp(),
        'recordedBy': 'Admin',
      });

      await firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
        'paymentStatus': 'Paid',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment recorded successfully.'),
          backgroundColor: Color(0xFF008955),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to record payment: $e',
          ),
        ),
      );
    }
  }

  void showPaymentConfirmation(
    String bookingId,
    double amount,
  ) {
    String selectedMethod = 'Cash';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Record Payment',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking ID: $bookingId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Amount: ₱${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Cash',
                        child: Text('Cash'),
                      ),
                      DropdownMenuItem(
                        value: 'GCash',
                        child: Text('GCash'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedMethod = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Are you sure you want to record this payment?',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    await recordPayment(
                      bookingId,
                      amount,
                      selectedMethod,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF008955),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Confirm Payment',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,

        title: const Text(
          'Manage Payments',
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
                  _searchQuery =
                      value.toLowerCase();
                });
              },

              decoration: InputDecoration(
                hintText:
                    'Search bicycle, customer or ID...',

                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),

                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                ),

                filled: true,
                fillColor: Colors.white,

                contentPadding:
                    const EdgeInsets.symmetric(
                  vertical: 0,
                ),

                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),

                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(
                    color: Color(0xFF008955),
                  ),
                ),
              ),
            ),
          ),

          // Main Stream Builder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF008955),
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
                  return const Center(
                    child: Text(
                      'No bookings found.',
                    ),
                  );
                }

                final docs =
                    snapshot.data!.docs;

                // Count Unpaid Payments
                final unpaidCount =
                    docs.where((d) {
                  final data =
                      d.data()
                          as Map<String, dynamic>;

                  final status =
                      (data['paymentStatus'] ??
                              'Unpaid')
                          .toString()
                          .toLowerCase();

                  return status == 'unpaid';
                }).length;

                // Count Paid Payments
                final paidCount =
                    docs.where((d) {
                  final data =
                      d.data()
                          as Map<String, dynamic>;

                  final status =
                      (data['paymentStatus'] ??
                              '')
                          .toString()
                          .toLowerCase();

                  return status == 'paid';
                }).length;

                // Filter Bookings
                final filteredDocs =
                    docs.where((doc) {
                  final data =
                      doc.data()
                          as Map<String, dynamic>;

                  final bicycleName =
                      (data['bicycleName'] ?? '')
                          .toString()
                          .toLowerCase();

                  final customerName =
                      (data['customerName'] ?? '')
                          .toString()
                          .toLowerCase();

                  final customerId =
                      (data['customerId'] ?? '')
                          .toString()
                          .toLowerCase();

                  final bookingId =
                      doc.id.toLowerCase();

                  final paymentStatus =
                      (data['paymentStatus'] ??
                              'Unpaid')
                          .toString()
                          .toLowerCase();

                  final matchesSearch =
                      bicycleName.contains(
                            _searchQuery,
                          ) ||
                      customerName.contains(
                            _searchQuery,
                          ) ||
                      customerId.contains(
                            _searchQuery,
                          ) ||
                      bookingId.contains(
                            _searchQuery,
                          );

                  bool matchesFilter = true;

                  if (_selectedFilter ==
                      'Unpaid') {
                    matchesFilter =
                        paymentStatus ==
                            'unpaid';
                  } else if (_selectedFilter ==
                      'Paid') {
                    matchesFilter =
                        paymentStatus ==
                            'paid';
                  }

                  return matchesSearch &&
                      matchesFilter;
                }).toList();

                return Column(
                  children: [
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),

                      child: Row(
                        children: [
                          _buildFilterChip(
                            'Unpaid',
                            unpaidCount,
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          _buildFilterChip(
                            'All',
                            docs.length,
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          _buildFilterChip(
                            'Paid',
                            paidCount,
                          ),
                        ],
                      ),
                    ),

                    // Payment List
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching records found.',
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),

                              itemCount:
                                  filteredDocs.length,

                              itemBuilder:
                                  (context, index) {
                                final booking =
                                    filteredDocs[index];

                                final data =
                                    booking.data()
                                        as Map<String,
                                            dynamic>;

                                return _buildPaymentCard(
                                  context,
                                  booking.id,
                                  data,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    int count,
  ) {
    final isSelected =
        _selectedFilter == label;

    return ChoiceChip(
      showCheckmark: false,
      selected: isSelected,

      label: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Text(
            label,

            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.black87,

              fontWeight:
                  FontWeight.w600,

              fontSize: 13,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),

            decoration:
                BoxDecoration(
              color: isSelected
                  ? Colors.white
                      .withOpacity(0.2)
                  : Colors.grey.shade200,

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child: Text(
              '$count',

              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.grey.shade700,

                fontSize: 11,

                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      selectedColor:
          const Color(0xFF008955),

      backgroundColor:
          Colors.white,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),

        side: BorderSide(
          color: isSelected
              ? const Color(
                  0xFF008955,
                )
              : Colors.grey.shade200,
        ),
      ),

      onSelected:
          (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter =
                label;
          });
        }
      },
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> data,
  ) {
    final paymentStatus =
        data['paymentStatus'] ??
            'Unpaid';

    final bicycleName =
        data['bicycleName'] ??
            'Unnamed Bicycle';

    final customerName =
        data['customerName'] ??
            'Unknown Customer';

    final customerId =
        data['customerId'] ??
            'N/A';

    final bookingFee =
        (data['bookingFee'] ?? 0)
            .toDouble();

    final isPaid =
        paymentStatus
            .toString()
            .toLowerCase() ==
            'paid';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(14),

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

      child: Column(
        children: [
          // Header
          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .center,

            children: [
              Container(
                width: 46,
                height: 46,

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
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Icon(
                  Icons
                      .payments_outlined,

                  color: isPaid
                      ? const Color(
                          0xFF008955,
                        )
                      : const Color(
                          0xFFE56A24,
                        ),

                  size: 24,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      'Booking ID: $bookingId',

                      style: TextStyle(
                        fontSize: 11,
                        color: Colors
                            .grey
                            .shade500,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      bicycleName,

                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              _buildStatusBadge(
                paymentStatus
                    .toString(),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // Payment Details
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),

            decoration:
                BoxDecoration(
              color: const Color(
                0xFFF8FAFC,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          'Customer',

                          style:
                              TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey
                                .shade500,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          customerName
                              .toString(),

                          style:
                              const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight
                                    .w600,
                            color: Colors
                                .black87,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .end,

                      children: [
                        Text(
                          'Booking Fee',

                          style:
                              TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey
                                .shade500,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          '₱${bookingFee.toStringAsFixed(2)}',

                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color: Color(
                              0xFF008955,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                Align(
                  alignment:
                      Alignment.centerLeft,

                  child: Text(
                    'Customer ID: $customerId',

                    style: TextStyle(
                      fontSize: 11,
                      color: Colors
                          .grey
                          .shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // Action Button
          if (!isPaid)
            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton.icon(
                onPressed: () {
                  showPaymentConfirmation(
                    bookingId,
                    bookingFee,
                  );
                },

                icon: const Icon(
                  Icons
                      .check_circle_outline,
                  size: 18,
                ),

                label:
                    const Text(
                  'Record Payment',
                  style:
                      TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF008955,
                  ),

                  foregroundColor:
                      Colors.white,

                  elevation: 0,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),

                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 12,
                  ),
                ),
              ),
            )
          else
            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.symmetric(
                vertical: 8,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade100,

                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child: const Center(
                child: Text(
                  'Payment Completed',

                  style:
                      TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    String status,
  ) {
    Color backgroundColor;
    Color textColor;

    switch (
        status.toLowerCase()) {
      case 'paid':
        backgroundColor =
            const Color(
          0xFFE8F8F0,
        );

        textColor =
            const Color(
          0xFF008955,
        );
        break;

      case 'unpaid':
      default:
        backgroundColor =
            const Color(
          0xFFFFF6E5,
        );

        textColor =
            const Color(
          0xFFE56A24,
        );
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),

      decoration:
          BoxDecoration(
        color: backgroundColor,

        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),

      child: Text(
        status,

        style: TextStyle(
          color: textColor,

          fontSize: 11,

          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}