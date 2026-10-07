import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bikerental/service/booking_service.dart';

class RentalHistoryPage
    extends StatelessWidget {
  const RentalHistoryPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final BookingService service =
        BookingService();

    final String customerId =
        FirebaseAuth.instance
            .currentUser!
            .uid;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Rental History'),
      ),

      body: StreamBuilder(
        stream:
            service.getCustomerBookings(
          customerId,
        ),

        builder:
            (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final bookings =
              snapshot.data!
                  .where(
                    (booking) =>
                        booking
                            .bookingStatus ==
                        'Completed',
                  )
                  .toList();

          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                'No rental history.',
              ),
            );
          }

          return ListView.builder(
            itemCount:
                bookings.length,

            itemBuilder:
                (context, index) {
              final booking =
                  bookings[index];

              return Card(
                child: ListTile(
                  title: Text(
                    booking.bicycleName,
                  ),

                  subtitle: Text(
                    '${booking.pickupDate} - '
                    '${booking.returnDate}\n'
                    '₱${booking.rentalFee}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}