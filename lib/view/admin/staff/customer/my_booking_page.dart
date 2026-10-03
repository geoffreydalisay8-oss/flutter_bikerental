import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikerental/service/booking_service.dart';
import 'package:bikerental/model/booking_model.dart';

class MyBookingPage extends StatelessWidget {
  const MyBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BookingService service = BookingService();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0,

        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: currentUser == null
          ? const Center(
              child: Text(
                'Please sign in to view your bookings.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            )
          : StreamBuilder<List<BookingModel>>(
              stream: service.getCustomerBookings(currentUser.uid),

              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B4D3E),
                    ),
                  );
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading bookings: ${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                // No bookings
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bike,
                          size: 64,
                          color: Colors.grey[400],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'No bookings found.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Your bicycle bookings will appear here.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),

                  itemCount: bookings.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final booking = bookings[index];

                    return _buildBookingCard(
                      context,
                      booking,
                    );
                  },
                );
              },
            ),
    );
  }

  // ============================================================
  // BOOKING CARD
  // ============================================================

  Widget _buildBookingCard(
    BuildContext context,
    BookingModel booking,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ----------------------------------------------------
          // BOOKING ID + STATUS
          // ----------------------------------------------------

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Booking ID: #${booking.id}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              _buildStatusBadge(
                booking.bookingStatus,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ----------------------------------------------------
          // BICYCLE NAME
          // ----------------------------------------------------

          Text(
            booking.bicycleName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          const Divider(height: 1),

          const SizedBox(height: 14),

          // ----------------------------------------------------
          // PICKUP
          // ----------------------------------------------------

          _buildDetailRow(
            icon: Icons.login_rounded,
            title: 'Pickup',
            date: booking.pickupDate,
          ),

          const SizedBox(height: 12),

          // ----------------------------------------------------
          // RETURN
          // ----------------------------------------------------

          _buildDetailRow(
            icon: Icons.logout_rounded,
            title: 'Return',
            date: booking.returnDate,
          ),

          const SizedBox(height: 14),

          const Divider(height: 1),

          const SizedBox(height: 14),

          // ----------------------------------------------------
          // RENTAL FEE
          // ----------------------------------------------------

          _buildPriceRow(
            'Rental Fee',
            booking.rentalFee,
          ),

          const SizedBox(height: 8),

          // ----------------------------------------------------
          // BOOKING FEE
          // ----------------------------------------------------

          _buildPriceRow(
            'Booking Fee',
            booking.bookingFee,
          ),

          const SizedBox(height: 12),

          const Divider(height: 1),

          const SizedBox(height: 12),

          // ----------------------------------------------------
          // TOTAL + PAYMENT STATUS
          // ----------------------------------------------------

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Status',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 4),

                  _buildPaymentBadge(
                    booking.paymentStatus,
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '₱${booking.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ----------------------------------------------------
          // BOOKING STATUS MESSAGE
          // ----------------------------------------------------

          _buildStatusMessage(
            booking.bookingStatus,
            booking.paymentStatus,
          ),

          // ----------------------------------------------------
          // FEEDBACK
          // ----------------------------------------------------

          if (booking.bookingStatus.toLowerCase() == 'completed') ...[
            const SizedBox(height: 14),

            const Divider(height: 1),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () {
                  _showFeedbackDialog(
                    context,
                    booking.id,
                  );
                },

                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF1B4D3E),
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                icon: const Icon(
                  Icons.rate_review_outlined,
                  size: 16,
                  color: Color(0xFF1B4D3E),
                ),

                label: const Text(
                  'Leave Feedback & Rating',
                  style: TextStyle(
                    color: Color(0xFF1B4D3E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DATE / TIME DETAIL
  // ============================================================

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required DateTime date,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Container(
          padding: const EdgeInsets.all(8),

          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FB),
            borderRadius: BorderRadius.circular(8),
          ),

          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF1B4D3E),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 2),

              Text(
                _formatDate(date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                _formatTime(date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRICE ROW
  // ============================================================

  Widget _buildPriceRow(
    String label,
    double amount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),

        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOOKING STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(
    String status,
  ) {
    Color backgroundColor = Colors.grey[200]!;
    Color textColor = Colors.black87;

    switch (status.toLowerCase()) {

      case 'pending':
        backgroundColor = const Color(0xFFFFF3E0);
        textColor = Colors.orange[800]!;
        break;

      case 'approved':
        backgroundColor = const Color(0xFFE3F2FD);
        textColor = Colors.blue[800]!;
        break;

      case 'active rental':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF1B4D3E);
        break;

      case 'completed':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF1B4D3E);
        break;

      case 'cancelled':
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = Colors.red[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT STATUS BADGE
  // ============================================================

  Widget _buildPaymentBadge(
    String status,
  ) {
    final bool isPaid =
        status.toLowerCase() == 'paid';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: isPaid
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isPaid
              ? const Color(0xFF1B4D3E)
              : Colors.orange[800],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS MESSAGE
  // ============================================================

  Widget _buildStatusMessage(
    String bookingStatus,
    String paymentStatus,
  ) {
    String message;

    switch (bookingStatus.toLowerCase()) {

      case 'pending':
        message = 'Waiting for staff approval.';
        break;

      case 'approved':
        if (paymentStatus.toLowerCase() == 'paid') {
          message = 'Your booking is approved. You can pick up the bicycle.';
        } else {
          message = 'Booking approved. Please pay the booking fee at the shop.';
        }
        break;

      case 'active rental':
        message = 'The bicycle is currently on rental.';
        break;

      case 'completed':
        message = 'Rental completed. Thank you for using our service!';
        break;

      case 'cancelled':
        message = 'This booking has been cancelled.';
        break;

      default:
        message = 'Booking status: $bookingStatus';
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(
    DateTime date,
  ) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // FEEDBACK DIALOG
  // ============================================================

  void _showFeedbackDialog(
    BuildContext context,
    String bookingId,
  ) {
    double selectedRating = 5;

    final TextEditingController feedbackController =
        TextEditingController();

    showDialog(
      context: context,

      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setState,
          ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),

              title: const Text(
                'Leave Feedback',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,

                children: [

                  const Text(
                    'How was your rental experience?',
                  ),

                  const SizedBox(height: 12),

                  // Stars
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: List.generate(
                      5,
                      (index) {
                        final starRating =
                            index + 1;

                        return IconButton(
                          icon: Icon(
                            starRating <=
                                    selectedRating
                                ? Icons.star_rounded
                                : Icons
                                    .star_outline_rounded,

                            color: Colors.amber,
                            size: 32,
                          ),

                          onPressed: () {
                            setState(() {
                              selectedRating =
                                  starRating.toDouble();
                            });
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        feedbackController,

                    maxLines: 3,

                    decoration: InputDecoration(
                      hintText:
                          'Write a comment (optional)...',

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),

              actions: [

                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),

                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF1B4D3E),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                  ),

                  onPressed: () async {
                    // TODO:
                    // Save feedback to Firestore
                    // using your FeedbackService.

                    Navigator.pop(
                      dialogContext,
                    );

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Feedback submitted.',
                        ),
                      ),
                    );
                  },

                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}