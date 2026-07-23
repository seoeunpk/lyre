class UserProfile {
  final String uid;
  final String name;
  final String friendCode;

  UserProfile({
    required this.uid,
    required this.name,
    required this.friendCode,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) =>
      UserProfile(
        uid: uid,
        name: map['name'] as String? ?? '',
        friendCode: map['friendCode'] as String? ?? '',
      );
}
