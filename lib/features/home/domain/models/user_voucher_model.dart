class UserVoucherModel {
  final String id;
  final String packageId;
  final String userId;
  final String paymentReference;
  final String? redeemedAt;
  final DateTime createdAt;
  final String voucherCode;
  
  // We can include package details if the backend sends it in the future,
  // but for now we'll match the basic fields.
  
  UserVoucherModel({
    required this.id,
    required this.packageId,
    required this.userId,
    required this.paymentReference,
    this.redeemedAt,
    required this.createdAt,
    required this.voucherCode,
  });

  factory UserVoucherModel.fromJson(Map<String, dynamic> json) {
    return UserVoucherModel(
      id: json['id'],
      packageId: json['package_id'],
      userId: json['user_id'],
      paymentReference: json['payment_reference'],
      redeemedAt: json['redeemed_at'],
      createdAt: DateTime.parse(json['created_at']),
      voucherCode: json['voucher_code'] ?? json['id'], // Fallback if voucher_code isn't explicitly returned
    );
  }
}
