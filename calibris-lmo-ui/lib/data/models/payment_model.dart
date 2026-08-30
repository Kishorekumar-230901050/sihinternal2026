enum PaymentStatus { pending, success, failed, refunded }

class PaymentModel {
  final String id;
  final String applicationId;
  final int amountInPaise;
  final PaymentStatus status;
  final String provider;
  final String orderRef;
  final String? transactionRef;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.applicationId,
    required this.amountInPaise,
    this.status = PaymentStatus.pending,
    this.provider = 'BHARATKOSH_UPI',
    required this.orderRef,
    this.transactionRef,
    required this.createdAt,
  });

  double get amountInRupees => amountInPaise / 100;

  String get formattedAmount => '₹${amountInRupees.toStringAsFixed(2)}';

  PaymentModel copyWith({
    PaymentStatus? status,
    String? transactionRef,
  }) {
    return PaymentModel(
      id: id,
      applicationId: applicationId,
      amountInPaise: amountInPaise,
      status: status ?? this.status,
      provider: provider,
      orderRef: orderRef,
      transactionRef: transactionRef ?? this.transactionRef,
      createdAt: createdAt,
    );
  }
}
