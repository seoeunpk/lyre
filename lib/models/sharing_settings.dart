class FriendSharePrefs {
  final bool shareMood;
  final bool shareSongs;
  final bool shareTags;
  final String visibility;

  const FriendSharePrefs({
    this.shareMood = true,
    this.shareSongs = true,
    this.shareTags = false,
    this.visibility = 'all',
  });

  FriendSharePrefs copyWith({
    bool? shareMood,
    bool? shareSongs,
    bool? shareTags,
    String? visibility,
  }) =>
      FriendSharePrefs(
        shareMood: shareMood ?? this.shareMood,
        shareSongs: shareSongs ?? this.shareSongs,
        shareTags: shareTags ?? this.shareTags,
        visibility: visibility ?? this.visibility,
      );

  factory FriendSharePrefs.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const FriendSharePrefs();
    return FriendSharePrefs(
      shareMood: map['shareMood'] as bool? ?? true,
      shareSongs: map['shareSongs'] as bool? ?? true,
      shareTags: map['shareTags'] as bool? ?? false,
      visibility: map['visibility'] as String? ?? 'all',
    );
  }

  Map<String, dynamic> toMap() => {
        'shareMood': shareMood,
        'shareSongs': shareSongs,
        'shareTags': shareTags,
        'visibility': visibility,
      };
}

class SharingSettings {
  final Map<String, FriendSharePrefs> perFriend;
  final List<String> autoShareApplied;

  const SharingSettings({
    this.perFriend = const {},
    this.autoShareApplied = const [],
  });

  bool isSharedWith(String friendUid) => perFriend.containsKey(friendUid);

  FriendSharePrefs prefsFor(String friendUid) =>
      perFriend[friendUid] ?? const FriendSharePrefs();

  SharingSettings copyWith({
    Map<String, FriendSharePrefs>? perFriend,
    List<String>? autoShareApplied,
  }) =>
      SharingSettings(
        perFriend: perFriend ?? this.perFriend,
        autoShareApplied: autoShareApplied ?? this.autoShareApplied,
      );

  SharingSettings withFriend(String friendUid, FriendSharePrefs prefs) {
    final updated = Map<String, FriendSharePrefs>.from(perFriend);
    updated[friendUid] = prefs;
    return copyWith(perFriend: updated);
  }

  SharingSettings withoutFriend(String friendUid) {
    final updated = Map<String, FriendSharePrefs>.from(perFriend);
    updated.remove(friendUid);
    return copyWith(perFriend: updated);
  }

  factory SharingSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SharingSettings();
    final rawPerFriend = map['perFriend'] as Map<String, dynamic>? ?? {};
    return SharingSettings(
      perFriend: rawPerFriend.map(
        (uid, prefs) => MapEntry(
            uid, FriendSharePrefs.fromMap(prefs as Map<String, dynamic>?)),
      ),
      autoShareApplied: List<String>.from(map['autoShareApplied'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'perFriend': perFriend.map((uid, prefs) => MapEntry(uid, prefs.toMap())),
        'autoShareApplied': autoShareApplied,
      };
}
