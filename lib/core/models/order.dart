import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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

@HiveType(typeId: 3)
class Milestone extends HiveObject {
  @HiveField(0)
  final String title;
  @HiveField(1)
  bool isCompleted;

  Milestone({required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'isCompleted': isCompleted,
  };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
    title: json['title'],
    isCompleted: json['isCompleted'],
  );
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
  @HiveField(9)
  List<Milestone> milestones;
  @HiveField(10)
  String shareToken;
  @HiveField(11)
  String? deliveryUrl;
  @HiveField(12)
  bool isDeliveryLocked;

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
    List<Milestone>? milestones,
    String? shareToken,
    this.deliveryUrl,
    this.isDeliveryLocked = true,
  })  : milestones = milestones ??
            [
              Milestone(title: 'Started'),
              Milestone(title: 'Working'),
              Milestone(title: 'Review'),
              Milestone(title: 'Final'),
            ],
        shareToken = shareToken ?? const Uuid().v4();

  double get progress {
    if (milestones.isEmpty) return 0.0;
    final completedCount = milestones.where((m) => m.isCompleted).length;
    return completedCount / milestones.length;
  }

  Order copyWith({
    String? title,
    String? clientName,
    Platform? platform,
    double? price,
    DateTime? deadline,
    OrderStatus? status,
    String? notes,
    List<Milestone>? milestones,
    String? shareToken,
    String? deliveryUrl,
    bool? isDeliveryLocked,
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
      milestones: milestones ?? this.milestones,
      shareToken: shareToken ?? this.shareToken,
      deliveryUrl: deliveryUrl ?? this.deliveryUrl,
      isDeliveryLocked: isDeliveryLocked ?? this.isDeliveryLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'clientName': clientName,
      'platform': platform.index,
      'price': price,
      'deadline': deadline.toIso8601String(),
      'status': status.index,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'shareToken': shareToken,
      'deliveryUrl': deliveryUrl,
      'isDeliveryLocked': isDeliveryLocked,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      title: json['title'],
      clientName: json['clientName'],
      platform: Platform.values[json['platform']],
      price: json['price'],
      deadline: DateTime.parse(json['deadline']),
      status: OrderStatus.values[json['status']],
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      milestones: (json['milestones'] as List?)
          ?.map((m) => Milestone.fromJson(m))
          .toList(),
      shareToken: json['shareToken'] ?? const Uuid().v4(),
      deliveryUrl: json['deliveryUrl'],
      isDeliveryLocked: json['isDeliveryLocked'] ?? true,
    );
  }
}
