import 'package:flutter/material.dart';

enum OrderStatus {
  newOrder('New', Color(0xFF1D4ED8), Color(0xFF93C5FD)),
  inProgress('In Progress', Color(0xFF78350F), Color(0xFFFCD34D)),
  revision('Revision', Color(0xFF431407), Color(0xFFFB923C)),
  delivered('Delivered', Color(0xFF064E3B), Color(0xFF5EEAD4)),
  completed('Completed', Color(0xFF064E3B), Color(0xFF10B981));

  final String label;
  final Color bgColor;
  final Color textColor;
  const OrderStatus(this.label, this.bgColor, this.textColor);
}

enum Platform {
  fiverr('Fiverr', Color(0xFF1DBF73), Color(0xFF064E3B)),
  upwork('Upwork', Color(0xFF6FDA44), Color(0xFF064E3B)),
  direct('Direct', Color(0xFF8B5CF6), Colors.white);

  final String label;
  final Color bgColor;
  final Color textColor;
  const Platform(this.label, this.bgColor, this.textColor);
}

class Order {
  final String id;
  final String title;
  final String clientName;
  final Platform platform;
  final double price;
  final DateTime deadline;
  final OrderStatus status;
  final String notes;
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
