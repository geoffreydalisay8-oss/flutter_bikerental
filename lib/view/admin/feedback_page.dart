import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackList extends StatelessWidget {
  const FeedbackList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Feedback',
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedback')
            .orderBy(
              'date',
              descending: true,
            )
            .snapshots(),

        builder: (context, snapshot) {

          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          // No feedback
          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No feedback available.',
              ),
            );
          }

          final feedback =
              snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),

            itemCount: feedback.length,

            itemBuilder: (context, index) {

              final document =
                  feedback[index];

              final data =
                  document.data()
                      as Map<String, dynamic>;

              final rating =
                  (data['rating'] ?? 0).toDouble();

              final comment =
                  data['comment'] ?? '';

              final customerId =
                  data['customerId'] ?? '';

              final bookingId =
                  data['bookingId'] ?? '';

              // Convert Firestore Timestamp
              String dateText = '';

              if (data['date'] != null &&
                  data['date'] is Timestamp) {

                final timestamp =
                    data['date'] as Timestamp;

                final date =
                    timestamp.toDate();

                dateText =
                    '${date.month}/${date.day}/${date.year}';
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),

                child: Padding(
                  padding: const EdgeInsets.all(15),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      // Customer
                      Row(
                        children: [

                          const CircleAvatar(
                            child: Icon(
                              Icons.person,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              'Customer: $customerId',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Rating
                      Row(
                        children: [

                          // Show 5 stars
                          ...List.generate(
                            5,
                            (starIndex) {
                              return Icon(
                                starIndex < rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 22,
                              );
                            },
                          ),

                          const SizedBox(width: 8),

                          Text(
                            '${rating.toInt()} / 5',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Comment
                      Text(
                        comment.isEmpty
                            ? 'No comment.'
                            : comment,
                        style:
                            const TextStyle(
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Booking ID
                      Text(
                        'Booking ID: $bookingId',
                        style:
                            const TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Date
                      Text(
                        'Date: $dateText',
                        style:
                            const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
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