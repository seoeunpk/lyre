import 'package:cloud_firestore/cloud_firestore.dart';

class Friendship {
  final String id;
  final List<String> users;
  final String requestedBy;
  final String status;
  final DateTime? createdAt;

  Friendship({
    required this.id,
    required this.users,
    required this.requestedBy,
    required this.status,
    this.createdAt,
  });

  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';

  String otherUid(String selfUid) =>
      users.firstWhere((u) => u != selfUid, orElse: () => '');

  factory Friendship.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return Friendship(
      id: id,
      users: List<String>.from(map['users'] ?? []),
      requestedBy: map['requestedBy'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
