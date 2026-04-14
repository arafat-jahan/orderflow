import 'package:hive/hive.dart';

part 'client_profile.g.dart';

@HiveType(typeId: 4)
class ClientProfile extends HiveObject {
  @HiveField(0)
  final String name;
  @HiveField(1)
  String notes;

  ClientProfile({required this.name, this.notes = ''});

  Map<String, dynamic> toJson() => {
    'name': name,
    'notes': notes,
  };

  factory ClientProfile.fromJson(Map<String, dynamic> json) => ClientProfile(
    name: json['name'],
    notes: json['notes'] ?? '',
  );
}
