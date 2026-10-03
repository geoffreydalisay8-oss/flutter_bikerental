import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingModel {
  final String id;
  final String customerId;
  final String bicycleId;
  final String bicycleName;

  final DateTime pickupDate;
  final DateTime returnDate;

  final String pickupLocation;
  final String returnLocation;

  final double rentalFee;
  final double bookingFee;
  final double totalAmount;

  final String paymentStatus;
  final String bookingStatus;

  final double? rating;
  final String? feedback;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.bicycleId,
    required this.bicycleName,
    required this.pickupDate,
    required this.returnDate,
    this.pickupLocation = 'Main Campus Hub',
    this.returnLocation = 'Main Campus Hub',
    required this.rentalFee,
    required this.bookingFee,
    required this.totalAmount,
    required this.paymentStatus,
    required this.bookingStatus,
    this.rating,
    this.feedback,
  });

  /// Getters to access formatted time strings (e.g., "10:30 AM")
  String get pickupTime => DateFormat('hh:mm a').format(pickupDate);
  String get returnTime => DateFormat('hh:mm a').format(returnDate);

  /// Getters to access formatted date strings (e.g., "Oct 03, 2026")
  String get formattedPickupDate =>
      DateFormat('MMM dd, yyyy').format(pickupDate);
  String get formattedReturnDate =>
      DateFormat('MMM dd, yyyy').format(returnDate);

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'bicycleId': bicycleId,
      'bicycleName': bicycleName,
      'pickupDate': Timestamp.fromDate(pickupDate),
      'returnDate': Timestamp.fromDate(returnDate),
      'pickupLocation': pickupLocation,
      'returnLocation': returnLocation,
      'rentalFee': rentalFee,
      'bookingFee': bookingFee,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'bookingStatus': bookingStatus,
      'rating': rating,
      'feedback': feedback,
    };
  }

  factory BookingModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return BookingModel(
      id: id,
      customerId: map['customerId'] ?? '',
      bicycleId: map['bicycleId'] ?? '',
      bicycleName: map['bicycleName'] ?? '',
      pickupDate: _parseDateTime(map['pickupDate']),
      returnDate: _parseDateTime(map['returnDate']),
      pickupLocation: map['pickupLocation'] ?? 'Main Campus Hub',
      returnLocation: map['returnLocation'] ?? 'Main Campus Hub',
      rentalFee: (map['rentalFee'] ?? 0).toDouble(),
      bookingFee: (map['bookingFee'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paymentStatus: map['paymentStatus'] ?? 'Unpaid',
      bookingStatus: map['bookingStatus'] ?? 'Pending',
      rating: (map['rating'] as num?)?.toDouble(),
      feedback: map['feedback'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}