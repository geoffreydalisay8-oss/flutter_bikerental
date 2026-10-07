import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackList extends StatelessWidget {
  const FeedbackList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        elevation: 0,

        title: const Text(
          'Customer Feedback',

          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore
            .instance
            .collection('feedback')
            .snapshots(),

        builder:
            (context, snapshot) {

          // ==================================================
          // LOADING
          // ==================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          // ==================================================
          // ERROR
          // ==================================================

          if (snapshot.hasError) {

            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Text(
                  'Error: ${snapshot.error}',

                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          // ==================================================
          // NO DATA
          // ==================================================

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {

            return const Center(
              child: Text(
                'No feedback available.',

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          // ==================================================
          // GET FEEDBACK
          // ==================================================

          final feedback =
              snapshot.data!.docs.toList();

          // ==================================================
          // SORT NEWEST FIRST
          // ==================================================

          feedback.sort(
            (a, b) {

              final dataA =
                  a.data()
                      as Map<String, dynamic>;

              final dataB =
                  b.data()
                      as Map<String, dynamic>;

              final dateA =
                  dataA['date'] is Timestamp
                      ? (dataA['date']
                              as Timestamp)
                          .toDate()
                      : DateTime(2000);

              final dateB =
                  dataB['date'] is Timestamp
                      ? (dataB['date']
                              as Timestamp)
                          .toDate()
                      : DateTime(2000);

              return dateB.compareTo(
                dateA,
              );
            },
          );

          // ==================================================
          // FEEDBACK LIST
          // ==================================================

          return ListView.builder(
            padding:
                const EdgeInsets.all(12),

            itemCount:
                feedback.length,

            itemBuilder:
                (context, index) {

              final document =
                  feedback[index];

              final data =
                  document.data()
                      as Map<String, dynamic>;

              // ==================================================
              // RATING
              // ==================================================

              final double rating =
                  data['rating'] is num
                      ? (data['rating'] as num)
                          .toDouble()
                      : 0;

              // ==================================================
              // COMMENT
              // ==================================================

              final String comment =
                  (data['comment'] ?? '')
                      .toString();

              // ==================================================
              // CUSTOMER ID
              // ==================================================

              final String customerId =
                  (data['customerId'] ??
                          'Unknown')
                      .toString();

              // ==================================================
              // BOOKING ID
              // ==================================================

              final String bookingId =
                  (data['bookingId'] ??
                          'Unknown')
                      .toString();

              // ==================================================
              // DATE
              // ==================================================

              String dateText =
                  'Processing...';

              if (data['date'] is Timestamp) {

                final date =
                    (data['date']
                            as Timestamp)
                        .toDate();

                dateText =
                    '${date.month}/${date.day}/${date.year}';
              }

              // ==================================================
              // CARD
              // ==================================================

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 10,
                ),

                elevation: 0,

                color:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child:
                    Padding(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),

                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      // ==========================================
                      // CUSTOMER
                      // ==========================================

                      Row(
                        children: [

                          const CircleAvatar(
                            child:
                                Icon(
                              Icons.person,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                                Text(
                              'Customer: $customerId',

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,

                                fontSize:
                                    16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==========================================
                      // RATING
                      // ==========================================

                      Row(
                        children: [

                          ...List.generate(
                            5,
                            (starIndex) {

                              return Icon(
                                starIndex <
                                        rating
                                    ? Icons.star
                                    : Icons
                                        .star_border,

                                color:
                                    Colors.amber,

                                size:
                                    22,
                              );
                            },
                          ),

                          const SizedBox(
                            width: 8,
                          ),

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

                      const SizedBox(
                        height: 10,
                      ),

                      // ==========================================
                      // COMMENT
                      // ==========================================

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets.all(
                          12,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey.shade50,

                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),

                        child:
                            Text(
                          comment.isEmpty
                              ? 'No comment.'
                              : comment,

                          style:
                              const TextStyle(
                            fontSize:
                                15,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ==========================================
                      // BOOKING ID
                      // ==========================================

                      Text(
                        'Booking ID: $bookingId',

                        style:
                            TextStyle(
                          color:
                              Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      // ==========================================
                      // DATE
                      // ==========================================

                      Text(
                        'Date: $dateText',

                        style:
                            TextStyle(
                          color:
                              Colors.grey.shade600,
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