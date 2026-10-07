import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IdVerificationPage extends StatefulWidget {
  const IdVerificationPage({super.key});

  @override
  State<IdVerificationPage> createState() => _IdVerificationPageState();
}

class _IdVerificationPageState extends State<IdVerificationPage> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'Pending';

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus(
    String id,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('id_verifications')
          .doc(id)
          .update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'Admin',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'Verified'
                ? 'ID verified successfully.'
                : 'ID rejected.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update ID status: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // VIEW ID PHOTO
  // ============================================================

  void _viewIdPhoto(
    BuildContext context,
    String imageUrl,
    String customerName,
  ) {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No ID photo was uploaded.',
          ),
        ),
      );

      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF008955),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$customerName - ID',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Full ID Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      loadingBuilder:
                          (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const SizedBox(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF008955),
                            ),
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Unable to load ID image.',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'You can zoom in to inspect the ID.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // VIEW DOCUMENT DETAILS
  // ============================================================

  void _viewDocumentDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final customerName =
        (data['customerName'] ??
                data['customerId'] ??
                'Unknown User')
            .toString();

    final customerEmail =
        (data['customerEmail'] ?? 'N/A').toString();

    final idType =
        (data['idType'] ?? 'Identification Card').toString();

    final docNumber =
        (data['docNumber'] ?? 'N/A').toString();

    final status =
        (data['status'] ?? 'Pending').toString();

    final booking =
        (data['associatedBooking'] ??
                data['bookingId'] ??
                'N/A')
            .toString();

    final submittedAt =
        _formatTimestamp(data['submittedAt']);

    final reviewedAt =
        _formatTimestamp(data['reviewedAt']);

    final reviewedBy =
        (data['reviewedBy'] ?? 'N/A').toString();

    // Support BOTH field names.
    final imageUrl =
        (data['imageUrl'] ??
                data['idImageUrl'] ??
                '')
            .toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Document Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ID IMAGE
                if (imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(dialogContext);

                      _viewIdPhoto(
                        context,
                        imageUrl,
                        customerName,
                      );
                    },
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 45,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 45,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No ID photo available',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Tap the image to view full size',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                _buildInfoRow(
                  'Customer',
                  customerName,
                ),

                _buildInfoRow(
                  'Email',
                  customerEmail,
                ),

                _buildInfoRow(
                  'ID Type',
                  idType,
                ),

                _buildInfoRow(
                  'Document Number',
                  docNumber,
                ),

                _buildInfoRow(
                  'Booking',
                  booking,
                ),

                _buildInfoRow(
                  'Status',
                  status,
                ),

                _buildInfoRow(
                  'Submitted',
                  submittedAt,
                ),

                _buildInfoRow(
                  'Reviewed',
                  reviewedAt,
                ),

                _buildInfoRow(
                  'Reviewed By',
                  reviewedBy,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FORMAT TIMESTAMP
  // ============================================================

  String _formatTimestamp(dynamic value) {
    if (value == null) {
      return 'N/A';
    }

    if (value is Timestamp) {
      final date = value.toDate();

      return '${_monthName(date.month)} '
          '${date.day}, '
          '${date.year} '
          '${_twoDigits(date.hour)}:'
          '${_twoDigits(date.minute)}';
    }

    return value.toString();
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month];
  }

  String _twoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F9FC),
       

        title: const Text(
          'ID Verification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: Column(
        children: [
          // ======================================================
          // SEARCH BAR
          // ======================================================

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
                    'Search customer name, ID type...',
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

          // ======================================================
          // FIRESTORE STREAM
          // ======================================================

          Expanded(
            child:
                StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('id_verifications')
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
                    child: Text(
                      'Error loading ID submissions:\n${snapshot.error}',
                      textAlign:
                          TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No ID submissions found.',
                    ),
                  );
                }

                final docs =
                    snapshot.data!.docs;

                // ==================================================
                // COUNTS
                // ==================================================

                final pendingCount =
                    docs.where((d) {
                  final data = d.data()
                      as Map<String, dynamic>;

                  final status =
                      (data['status'] ??
                              'Pending')
                          .toString()
                          .toLowerCase();

                  return status ==
                      'pending';
                }).length;

                final verifiedCount =
                    docs.where((d) {
                  final data = d.data()
                      as Map<String, dynamic>;

                  final status =
                      (data['status'] ??
                              '')
                          .toString()
                          .toLowerCase();

                  return status ==
                          'verified' ||
                      status ==
                          'approved';
                }).length;

                final rejectedCount =
                    docs.where((d) {
                  final data = d.data()
                      as Map<String, dynamic>;

                  final status =
                      (data['status'] ??
                              '')
                          .toString()
                          .toLowerCase();

                  return status ==
                      'rejected';
                }).length;

                // ==================================================
                // FILTER
                // ==================================================

                final filteredDocs =
                    docs.where((doc) {
                  final data =
                      doc.data()
                          as Map<String, dynamic>;

                  final customerName =
                      (data['customerName'] ??
                              data['customerId'] ??
                              '')
                          .toString()
                          .toLowerCase();

                  final idType =
                      (data['idType'] ?? '')
                          .toString()
                          .toLowerCase();

                  final status =
                      (data['status'] ??
                              'Pending')
                          .toString()
                          .toLowerCase();

                  final matchesSearch =
                      customerName.contains(
                            _searchQuery,
                          ) ||
                          idType.contains(
                            _searchQuery,
                          );

                  bool matchesFilter = true;

                  if (_selectedFilter ==
                      'Pending') {
                    matchesFilter =
                        status == 'pending';
                  } else if (_selectedFilter ==
                      'Verified') {
                    matchesFilter =
                        status == 'verified' ||
                            status == 'approved';
                  } else if (_selectedFilter ==
                      'Rejected') {
                    matchesFilter =
                        status == 'rejected';
                  }

                  return matchesSearch &&
                      matchesFilter;
                }).toList();

                return Column(
                  children: [
                    // ==================================================
                    // FILTER CHIPS
                    // ==================================================

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
                            'Pending',
                            pendingCount,
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
                            'Verified',
                            verifiedCount,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          _buildFilterChip(
                            'Rejected',
                            rejectedCount,
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // CARDS
                    // ==================================================

                    Expanded(
                      child:
                          filteredDocs.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No matching submissions found.',
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
                                      filteredDocs
                                          .length,
                                  itemBuilder:
                                      (context,
                                          index) {
                                    final doc =
                                        filteredDocs[
                                            index];

                                    final data =
                                        doc.data()
                                            as Map<
                                                String,
                                                dynamic>;

                                    return _buildVerificationCard(
                                      context,
                                      doc.id,
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

  // ============================================================
  // FILTER CHIP
  // ============================================================

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

          const SizedBox(width: 6),

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

      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter =
                label;
          });
        }
      },
    );
  }

  // ============================================================
  // VERIFICATION CARD
  // ============================================================

  Widget _buildVerificationCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final status =
        (data['status'] ?? 'Pending')
            .toString();

    final customerName =
        (data['customerName'] ??
                data['customerId'] ??
                'Unknown User')
            .toString();

    final idType =
        (data['idType'] ??
                'Identification Card')
            .toString();

    final docNumber =
        (data['docNumber'] ??
                'N/A')
            .toString();

    // Support submittedAt
    // and uploadedDate.
    final uploadedDate =
        _formatTimestamp(
      data['uploadedDate'] ??
          data['submittedAt'],
    );

    final associatedBooking =
        (data['associatedBooking'] ??
                data['bookingId'] ??
                'N/A')
            .toString();

    // IMPORTANT:
    // Supports both imageUrl and idImageUrl.
    final imageUrl =
        (data['imageUrl'] ??
                data['idImageUrl'] ??
                '')
            .toString();

    final initials =
        customerName.isNotEmpty
            ? customerName
                .trim()
                .split(' ')
                .map(
                  (e) =>
                      e.isNotEmpty
                          ? e[0]
                          : '',
                )
                .take(2)
                .join()
                .toUpperCase()
            : 'CU';

    final isPending =
        status.toLowerCase() ==
            'pending';

    final isVerified =
        status.toLowerCase() ==
                'verified' ||
            status.toLowerCase() ==
                'approved';

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
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [
              CircleAvatar(
                radius: 20,

                backgroundColor:
                    isVerified
                        ? const Color(
                            0xFFDCEBFF,
                          )
                        : const Color(
                            0xFFD7F5E8,
                          ),

                child: Text(
                  initials,
                  style: TextStyle(
                    color: isVerified
                        ? const Color(
                            0xFF1E6FD9,
                          )
                        : const Color(
                            0xFF008955,
                          ),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 13,
                  ),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customerName,
                            style:
                                const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Colors.black87,
                            ),
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ),

                        if (isVerified)
                          const Icon(
                            Icons
                                .check_circle,
                            color:
                                Color(
                              0xFF008955,
                            ),
                            size: 16,
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      idType,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                  ],
                ),
              ),

              _buildStatusBadge(
                status,
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // DETAILS BOX
          // ======================================================

          Container(
            padding:
                const EdgeInsets.all(
              10,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF8FAFC,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: Row(
              children: [
                // ==================================================
                // THUMBNAIL
                // ==================================================

                GestureDetector(
                  onTap: imageUrl
                          .isNotEmpty
                      ? () {
                          _viewIdPhoto(
                            context,
                            imageUrl,
                            customerName,
                          );
                        }
                      : null,

                  child: Container(
                    width: 70,
                    height: 48,

                    decoration:
                        BoxDecoration(
                      color: Colors
                          .grey
                          .shade200,

                      borderRadius:
                          BorderRadius
                              .circular(
                        8,
                      ),
                    ),

                    child: imageUrl
                            .isNotEmpty
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                            child:
                                Image.network(
                              imageUrl,
                              fit: BoxFit
                                  .cover,
                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return Icon(
                                  Icons
                                      .broken_image_outlined,
                                  color: Colors
                                      .grey
                                      .shade500,
                                  size: 28,
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons
                                  .badge_outlined,
                              color: Colors
                                  .grey
                                  .shade500,
                              size: 28,
                            ),
                          ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // ==================================================
                // INFORMATION
                // ==================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      _buildDetailRow(
                        'Doc Number:',
                        docNumber,
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      _buildDetailRow(
                        'Uploaded:',
                        uploadedDate,
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      Row(
                        children: [
                          Text(
                            'Associated Booking: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                          ),

                          Expanded(
                            child: Text(
                              associatedBooking,
                              style:
                                  const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    Color(
                                  0xFF008955,
                                ),
                              ),
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // ACTION BUTTONS
          // ======================================================

          if (isPending)
            Row(
              children: [
                // VIEW ID
                Expanded(
                  child:
                      OutlinedButton(
                    onPressed:
                        imageUrl
                                .isNotEmpty
                            ? () {
                                _viewIdPhoto(
                                  context,
                                  imageUrl,
                                  customerName,
                                );
                              }
                            : () {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text(
                                      'No ID photo available.',
                                    ),
                                  ),
                                );
                              },

                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          Colors.black87,
                      side: BorderSide(
                        color: Colors
                            .grey
                            .shade200,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 10,
                      ),
                    ),

                    child:
                        const Text(
                      'View ID',
                      style:
                          TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                // VERIFY
                Expanded(
                  child:
                      ElevatedButton
                          .icon(
                    onPressed: () =>
                        updateStatus(
                      docId,
                      'Verified',
                    ),

                    icon:
                        const Icon(
                      Icons.check,
                      size: 16,
                    ),

                    label:
                        const Text(
                      'Verify',
                      style:
                          TextStyle(
                        fontSize: 12,
                      ),
                    ),

                    style:
                        ElevatedButton
                            .styleFrom(
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
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                // REJECT
                Expanded(
                  child:
                      ElevatedButton(
                    onPressed: () =>
                        updateStatus(
                      docId,
                      'Rejected',
                    ),

                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFFFF0F0,
                      ),
                      foregroundColor:
                          const Color(
                        0xFFE53935,
                      ),
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 10,
                      ),
                    ),

                    child:
                        const Text(
                      'Reject',
                      style:
                          TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // VIEW DOCUMENT DETAILS
            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed: () {
                  _viewDocumentDetails(
                    context,
                    data,
                  );
                },

                icon:
                    const Icon(
                  Icons
                      .visibility_outlined,
                  size: 16,
                ),

                label: const Text(
                  'View Document Details',
                ),

                style:
                    OutlinedButton
                        .styleFrom(
                  foregroundColor:
                      Colors.black87,
                  side: BorderSide(
                    color: Colors
                        .grey
                        .shade200,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow(
    String label,
    String value,
  ) {
    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 11,
            color: Colors
                .grey
                .shade600,
          ),
        ),

        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
              color:
                  Colors.black87,
            ),
            overflow:
                TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(
    String status,
  ) {
    Color backgroundColor;
    Color textColor;

    switch (
        status.toLowerCase()) {
      case 'verified':
      case 'approved':
        backgroundColor =
            const Color(
          0xFFE8F8F0,
        );
        textColor =
            const Color(
          0xFF008955,
        );
        break;

      case 'pending':
        backgroundColor =
            const Color(
          0xFFFFF6E5,
        );
        textColor =
            const Color(
          0xFFE56A24,
        );
        break;

      case 'rejected':
        backgroundColor =
            const Color(
          0xFFFFEBEB,
        );
        textColor =
            const Color(
          0xFFE53935,
        );
        break;

      default:
        backgroundColor =
            const Color(
          0xFFF4F6F8,
        );
        textColor =
            Colors.grey.shade700;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),

      decoration:
          BoxDecoration(
        color:
            backgroundColor,
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