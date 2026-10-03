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
      'date': date,
    };
  }

  factory FeedbackModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return FeedbackModel(
      id: id,
      customerId: map['customerId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      date: map['date'].toDate(),
    );
  }
}