import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IdVerificationPage extends StatefulWidget {
  const IdVerificationPage({super.key});

  @override
  State<IdVerificationPage> createState() => _IdVerificationPageState();
}

class _IdVerificationPageState extends State<IdVerificationPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Pending';

  Future<void> updateStatus(String id, String status) async {
    await FirebaseFirestore.instance
        .collection('id_verifications')
        .doc(id)
        .update({
      'status': status,
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
                hintText: 'Search customer name, ID type...',
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

          // Main Stream Builder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('id_verifications')
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
                    child: Text('No ID submissions found.'),
                  );
                }

                final docs = snapshot.data!.docs;

                // Calculate filter counts dynamically
                final pendingCount = docs.where((d) {
                  final s = ((d.data() as Map<String, dynamic>)['status'] ?? 'Pending').toString().toLowerCase();
                  return s == 'pending';
                }).length;

                final verifiedCount = docs.where((d) {
                  final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString().toLowerCase();
                  return s == 'verified' || s == 'approved';
                }).length;

                final rejectedCount = docs.where((d) {
                  final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString().toLowerCase();
                  return s == 'rejected';
                }).length;

                // Filter documents by search query and category tab
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final customerName = (data['customerName'] ?? data['customerId'] ?? '').toString().toLowerCase();
                  final idType = (data['idType'] ?? '').toString().toLowerCase();
                  final status = (data['status'] ?? 'Pending').toString().toLowerCase();

                  final matchesSearch = customerName.contains(_searchQuery) || idType.contains(_searchQuery);

                  bool matchesFilter = true;
                  if (_selectedFilter == 'Pending') {
                    matchesFilter = status == 'pending';
                  } else if (_selectedFilter == 'Verified') {
                    matchesFilter = status == 'verified' || status == 'approved';
                  } else if (_selectedFilter == 'Rejected') {
                    matchesFilter = status == 'rejected';
                  }

                  return matchesSearch && matchesFilter;
                }).toList();

                return Column(
                  children: [
                    // Filter Chips Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          _buildFilterChip('Pending', pendingCount),
                          const SizedBox(width: 8),
                          _buildFilterChip('All', docs.length),
                          const SizedBox(width: 8),
                          _buildFilterChip('Verified', verifiedCount),
                          const SizedBox(width: 8),
                          _buildFilterChip('Rejected', rejectedCount),
                        ],
                      ),
                    ),

                    // Cards List
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? const Center(
                              child: Text('No matching submissions found.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
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

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      showCheckmark: false,
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      selectedColor: const Color(0xFF008955),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF008955) : Colors.grey.shade200,
        ),
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
    );
  }

  Widget _buildVerificationCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final status = (data['status'] ?? 'Pending').toString();
    final customerName = data['customerName'] ?? data['customerId'] ?? 'Unknown User';
    final idType = data['idType'] ?? 'Identification Card';
    final docNumber = data['docNumber'] ?? 'N/A';
    final uploadedDate = data['uploadedDate'] ?? 'Today, 10:24 AM';
    final associatedBooking = data['associatedBooking'] ?? 'BK-2024-0048';
    final imageUrl = data['imageUrl'] ?? '';

    final initials = customerName.isNotEmpty
        ? customerName
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'CU';

    final isPending = status.toLowerCase() == 'pending';
    final isVerified = status.toLowerCase() == 'verified' || status.toLowerCase() == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        children: [
          // Header Row: Avatar, Name/Type, Status Badge
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isVerified
                    ? const Color(0xFFDCEBFF)
                    : const Color(0xFFD7F5E8),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: isVerified
                        ? const Color(0xFF1E6FD9)
                        : const Color(0xFF008955),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF008955),
                            size: 16,
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      idType,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),

          // Details Inner Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Thumbnail Box
                Container(
                  width: 70,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.badge_outlined,
                            color: Colors.grey.shade500,
                            size: 28,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Text Information Block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Doc Number:', docNumber),
                      const SizedBox(height: 2),
                      _buildDetailRow('Uploaded:', uploadedDate),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Associated Booking: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            associatedBooking,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF008955),
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
          const SizedBox(height: 12),

          // Action Buttons
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('View ID', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => updateStatus(docId, 'Verified'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Verify', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008955),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => updateStatus(docId, 'Rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF0F0),
                      foregroundColor: const Color(0xFFE53935),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View Document Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
        backgroundColor = const Color(0xFFE8F8F0);
        textColor = const Color(0xFF008955);
        break;
      case 'pending':
        backgroundColor = const Color(0xFFFFF6E5);
        textColor = const Color(0xFFE56A24);
        break;
      case 'rejected':
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