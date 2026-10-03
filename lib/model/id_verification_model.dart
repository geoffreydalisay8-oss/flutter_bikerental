class IdVerificationModel {
  final String id;
  final String customerId;
  final String idType;
  final String idImageUrl;
  final String status;
  final String? reviewedBy;

  IdVerificationModel({
    required this.id,
    required this.customerId,
    required this.idType,
    required this.idImageUrl,
    required this.status,
    this.reviewedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'idType': idType,
      'idImageUrl': idImageUrl,
      'status': status,
      'reviewedBy': reviewedBy,
    };
  }

  factory IdVerificationModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return IdVerificationModel(
      id: id,
      customerId: map['customerId'] ?? '',
      idType: map['idType'] ?? '',
      idImageUrl: map['idImageUrl'] ?? '',
      status: map['status'] ?? 'Pending',
      reviewedBy: map['reviewedBy'],
    );
  }
}