import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/friendship.dart';
import '../models/sharing_settings.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../services/sharing_service.dart';
import '../utils/app_colors.dart';
import '../utils/animated_snackbar.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/section_label.dart';

class SharingSettingsScreen extends StatefulWidget {
  const SharingSettingsScreen({super.key});

  @override
  State<SharingSettingsScreen> createState() => _SharingSettingsScreenState();
}

class _SharingSettingsScreenState extends State<SharingSettingsScreen> {
  final _friends = FriendService();
  final _sharing = SharingService();

  bool loading = true;
  bool saving = false;
  List<Friendship> _friendships = [];
  final Map<String, UserProfile?> _userCache = {};
  SharingSettings _settings = const SharingSettings();

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => loading = false);
      return;
    }
    final settings = await _sharing.getSettings(uid);
    final friendshipsSnap =
        await _friends.friendshipsFor(uid).first.timeout(
              const Duration(seconds: 10),
              onTimeout: () => [],
            );
    final accepted = friendshipsSnap.where((f) => f.isAccepted).toList();
    await Future.wait(accepted.map((f) async {
      final otherUid = f.otherUid(uid);
      _userCache[otherUid] = await _friends.getUser(otherUid);
    }));
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _friendships = accepted;
      loading = false;
    });
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => saving = true);
    try {
      await _sharing.updateSettings(uid, _settings);
      if (mounted) showAnimatedSnackBar(context, "Sharing settings saved!");
    } catch (_) {
      if (mounted) {
        showAnimatedSnackBar(context, "Failed to save. Try again.",
            isError: true);
      }
    }
    if (mounted) setState(() => saving = false);
  }

  void _toggleFriend(String friendUid, bool enabled) {
    setState(() {
      _settings = enabled
          ? _settings.withFriend(friendUid, _settings.prefsFor(friendUid))
          : _settings.withoutFriend(friendUid);
    });
  }

  void _editFriendPrefs(String friendUid, String name) {
    var draft = _settings.prefsFor(friendUid);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SectionLabel(name),
                const SizedBox(height: 14),
                const Text("What they can see",
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500)),
                for (final field in _shareToggleFields)
                  CheckboxListTile(
                    value: field.value(draft),
                    onChanged: (v) =>
                        setLocal(() => draft = field.apply(draft, v ?? false)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    activeColor: AppColors.primary,
                    title: Text(field.label,
                        style:
                            const TextStyle(fontSize: 14, color: AppColors.text)),
                  ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10, top: 2),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 14, color: AppColors.grey),
                      SizedBox(width: 34),
                      Expanded(
                        child: Text(
                          "Journal notes are always private and never shared.",
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                const Text("Activity visibility",
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500)),
                for (final option in _visibilityOptions)
                  RadioListTile<String>(
                    value: option.$1,
                    groupValue: draft.visibility,
                    onChanged: (v) =>
                        setLocal(() => draft = draft.copyWith(visibility: v)),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(option.$2,
                        style:
                            const TextStyle(fontSize: 14, color: AppColors.text)),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(
                          () => _settings = _settings.withFriend(friendUid, draft));
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text("Done",
                        style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: AppColors.text, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Sharing Settings",
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const SectionLabel("Share calendar with"),
                const SizedBox(height: 8),
                _friendships.isEmpty
                    ? const EmptyStateCard(
                        "Add friends first, then choose who can see your calendar.")
                    : _friendsCard(),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Save Changes",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _friendsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(_friendships.length, (i) {
          final f = _friendships[i];
          final uid = _uid!;
          final otherUid = f.otherUid(uid);
          final name = _userCache[otherUid]?.name.isNotEmpty == true
              ? _userCache[otherUid]!.name
              : "Friend";
          final isLast = i == _friendships.length - 1;
          final shared = _settings.isSharedWith(otherUid);
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      color: shared ? AppColors.text : AppColors.lightGrey,
                      tooltip: "$name's sharing settings",
                      onPressed:
                          shared ? () => _editFriendPrefs(otherUid, name) : null,
                    ),
                    Switch(
                      value: shared,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => _toggleFriend(otherUid, v),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1, indent: 16, endIndent: 16, color: AppColors.border),
            ],
          );
        }),
      ),
    );
  }
}

class _ShareToggleField {
  final String label;
  final bool Function(FriendSharePrefs) value;
  final FriendSharePrefs Function(FriendSharePrefs, bool) apply;
  const _ShareToggleField(this.label, this.value, this.apply);
}

final _shareToggleFields = [
  _ShareToggleField("Mood entries", (p) => p.shareMood,
      (p, v) => p.copyWith(shareMood: v)),
  _ShareToggleField("Songs and artists", (p) => p.shareSongs,
      (p, v) => p.copyWith(shareSongs: v)),
  _ShareToggleField("Tags", (p) => p.shareTags, (p, v) => p.copyWith(shareTags: v)),
];

const _visibilityOptions = [
  ('all', "Show all entries"),
  ('tagged', "Show only tagged entries"),
  ('recent', "Show only recent entries (last 30 days)"),
];
