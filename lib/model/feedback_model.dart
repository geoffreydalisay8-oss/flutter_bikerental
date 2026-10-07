import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String customerId;
  final String bookingId;
  final double rating;
  final String comment;
  final DateTime date;

  FeedbackModel({
    required this.id,
    required this.customerId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'date': Timestamp.fromDate(date),
    };
  }

  factory FeedbackModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    DateTime feedbackDate =
        DateTime.now();

    final dynamic dateValue =
        map['date'];

    if (dateValue is Timestamp) {
      feedbackDate =
          dateValue.toDate();
    } else if (dateValue is DateTime) {
      feedbackDate = dateValue;
    }

    double ratingValue = 0;

    final dynamic rating =
        map['rating'];

    if (rating is num) {
      ratingValue =
          rating.toDouble();
    } else if (rating is String) {
      ratingValue =
          double.tryParse(rating) ??
              0;
    }

    return FeedbackModel(
      id: id,

      customerId:
          (map['customerId'] ??
                  '')
              .toString(),

      bookingId:
          (map['bookingId'] ??
                  '')
              .toString(),

      rating: ratingValue,

      comment:
          (map['comment'] ??
                  '')
              .toString(),

      date: feedbackDate,
    );
  }
}