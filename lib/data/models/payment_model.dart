class PaymentModel {
  final int id;
  final int orderId;
  final String paymentMethod; // 'cash', 'tempo', 'transfer'
  final String paymentStatus; // 'pending', 'paid', 'overdue'
  final DateTime? dueDate;
  final String? bankAccountDestination;
  final String? proofOfTransferUrl;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.paymentStatus,
    this.dueDate,
    this.bankAccountDestination,
    this.proofOfTransferUrl,
  });

  bool get isOverdue {
    if (paymentStatus.toLowerCase() == 'overdue') return true;
    if (paymentMethod.toLowerCase() == 'tempo' && dueDate != null) {
      return DateTime.now().isAfter(dueDate!) && paymentStatus.toLowerCase() != 'paid';
    }
    return false;
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      orderId: json['order_id'] is int ? json['order_id'] : int.parse(json['order_id'].toString()),
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentStatus: json['payment_status'] ?? 'pending',
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      bankAccountDestination: json['bank_account_destination'],
      proofOfTransferUrl: json['proof_of_transfer_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'due_date': dueDate?.toIso8601String(),
      'bank_account_destination': bankAccountDestination,
      'proof_of_transfer_url': proofOfTransferUrl,
    };
  }
}
