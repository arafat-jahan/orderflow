import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'order.g.dart';

@HiveType(typeId: 1)
enum OrderStatus {
  @HiveField(0)
  newOrder('New', Color(0xFF1D4ED8), Color(0xFF93C5FD)),
  @HiveField(1)
  inProgress('In Progress', Color(0xFF78350F), Color(0xFFFCD34D)),
  @HiveField(2)
  revision('Revision', Color(0xFF431407), Color(0xFFFB923C)),
  @HiveField(3)
  delivered('Delivered', Color(0xFF064E3B), Color(0xFF5EEAD4)),
  @HiveField(4)
  completed('Completed', Color(0xFF064E3B), Color(0xFF10B981));

  final String label;
  final Color bgColor;
  final Color textColor;
  const OrderStatus(this.label, this.bgColor, this.textColor);
}

@HiveType(typeId: 2)
enum Platform {
  @HiveField(0)
  fiverr('Fiverr', Color(0xFF1DBF73), Color(0xFF064E3B)),
  @HiveField(1)
  upwork('Upwork', Color(0xFF6FDA44), Color(0xFF064E3B)),
  @HiveField(2)
  direct('Direct', Color(0xFF8B5CF6), Colors.white);

  final String label;
  final Color bgColor;
  final Color textColor;
  const Platform(this.label, this.bgColor, this.textColor);
}

@HiveType(typeId: 0)
class Order extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String clientName;
  @HiveField(3)
  final Platform platform;
  @HiveField(4)
  final double price;
  @HiveField(5)
  final DateTime deadline;
  @HiveField(6)
  OrderStatus status;
  @HiveField(7)
  final String notes;
  @HiveField(8)
  final DateTime createdAt;

  Order({
    required this.id,
    required this.title,
    required this.clientName,
    required this.platform,
    required this.price,
    required this.deadline,
    required this.status,
    this.notes = '',
    required this.createdAt,
  });

  Order copyWith({
    String? title,
    String? clientName,
    Platform? platform,
    double? price,
    DateTime? deadline,
    OrderStatus? status,
    String? notes,
  }) {
    return Order(
      id: this.id,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      platform: platform ?? this.platform,
      price: price ?? this.price,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: this.createdAt,
    );
  }
}
