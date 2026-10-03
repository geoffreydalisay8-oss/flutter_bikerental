class PaymentModel {
  final String id;
  final String bookingId;
  final String customerId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String recordedBy;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.recordedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate,
      'recordedBy': recordedBy,
    };
  }

  factory PaymentModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return PaymentModel(
      id: id,
      bookingId: map['bookingId'] ?? '',
      customerId: map['customerId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      paymentDate: map['paymentDate'].toDate(),
      recordedBy: map['recordedBy'] ?? '',
    );
  }
}