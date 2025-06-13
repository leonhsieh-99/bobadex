import 'package:bobadex/models/user.dart';

class Friendship {
  final String id;
  String status;
  final User requester;
  final User addressee;

  Friendship ({
    required this.id,
    required this.status,
    required this.requester,
    required this.addressee,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'],
      status: json['status'],
      requester: User.fromJson(json['requester']),
      addressee: User.fromJson(json['addressee']),
    );
  }
}