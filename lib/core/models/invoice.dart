import 'package:hive/hive.dart';

part 'invoice.g.dart';

@HiveType(typeId: 5)
enum InvoiceStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  sent,
  @HiveField(2)
  paid,
  @HiveField(3)
  overdue,
  @HiveField(4)
  cancelled
}

@HiveType(typeId: 6)
class Invoice extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String orderId;
  @HiveField(2)
  final String invoiceNumber;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  InvoiceStatus status;
  @HiveField(5)
  final double amount;

  Invoice({
    required this.id,
    required this.orderId,
    required this.invoiceNumber,
    required this.date,
    this.status = InvoiceStatus.draft,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'invoiceNumber': invoiceNumber,
    'date': date.toIso8601String(),
    'status': status.index,
    'amount': amount,
  };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'],
    orderId: json['orderId'],
    invoiceNumber: json['invoiceNumber'],
    date: DateTime.parse(json['date']),
    status: InvoiceStatus.values[json['status']],
    amount: json['amount'],
  );
}
