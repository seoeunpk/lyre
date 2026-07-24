import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../models/friendship.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../utils/app_colors.dart';
import '../utils/animated_snackbar.dart';
import '../utils/field_decoration.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/section_label.dart';
import 'friend_calendar_screen.dart';
import 'sharing_settings_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _friends = FriendService();
  final _codeCtrl = TextEditingController();

  String? myCode;
  bool loadingCode = true;
  String? codeError;
  bool sendingRequest = false;
  final Map<String, Future<UserProfile?>> _userCache = {};

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadMyCode();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyCode([StateSetter? setLocal]) async {
    final uid = _uid;
    if (uid == null) return;
    final apply = setLocal ?? setState;
    apply(() {
      loadingCode = true;
      codeError = null;
    });
    try {
      var user = await _friends.getUser(uid);
      if (user?.friendCode.isEmpty ?? true) {
        final displayName = AuthService().currentUser?.displayName?.trim();
        await _friends.ensureProfile(
          uid,
          (displayName?.isNotEmpty ?? false) ? displayName! : 'LYRE user',
        );
        user = await _friends.getUser(uid);
      }
      if (!mounted) return;
      apply(() {
        myCode = user?.friendCode.isNotEmpty == true ? user!.friendCode : null;
        codeError = myCode == null ? "Couldn't generate a code." : null;
        loadingCode = false;
      });
    } catch (_) {
      if (!mounted) return;
      apply(() {
        codeError = "Couldn't generate a code. Check your connection.";
        loadingCode = false;
      });
    }
  }

  Future<UserProfile?> _userFor(String uid) {
    return _userCache.putIfAbsent(uid, () => _friends.getUser(uid));
  }

  Future<void> _sendRequest([StateSetter? setLocal]) async {
    final uid = _uid;
    if (uid == null) return;
    final apply = setLocal ?? setState;
    apply(() => sendingRequest = true);
    try {
      final error = await _friends.sendRequestByCode(uid, _codeCtrl.text);
      if (!mounted) return;
      if (error != null) {
        showAnimatedSnackBar(context, error, isError: true);
      } else {
        _codeCtrl.clear();
        FocusScope.of(context).unfocus();
        showAnimatedSnackBar(context, "Friend request sent!");
      }
    } catch (_) {
      if (!mounted) return;
      showAnimatedSnackBar(context, "Couldn't send request. Check your connection.",
          isError: true);
    } finally {
      if (mounted) apply(() => sendingRequest = false);
    }
  }

  void _copyCode() {
    if (myCode == null) return;
    Clipboard.setData(ClipboardData(text: myCode!));
    showAnimatedSnackBar(context, "Code copied!");
  }

  void _openSharingSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SharingSettingsScreen()),
    );
  }

  void _openFriendCalendar(String friendUid, String friendName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FriendCalendarScreen(friendUid: friendUid, friendName: friendName),
      ),
    );
  }

  void _openInviteSheet() {
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
          builder: (ctx, setSheetState) => _inviteCard(setSheetState),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
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
          "My Friends",
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.text),
            tooltip: "Sharing settings",
            onPressed: _openSharingSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openInviteSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        tooltip: "Invite friends",
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: uid == null
          ? const SizedBox()
          : StreamBuilder<List<Friendship>>(
              stream: _friends.friendshipsFor(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                final all = snapshot.data ?? const <Friendship>[];
                final accepted = all.where((f) => f.isAccepted).toList();
                final incoming = all
                    .where((f) => f.isPending && f.requestedBy != uid)
                    .toList();
                final outgoing = all
                    .where((f) => f.isPending && f.requestedBy == uid)
                    .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    const SectionLabel("Friends"),
                    const SizedBox(height: 10),
                    if (accepted.isEmpty)
                      const EmptyStateCard(
                          "No friends yet. Tap the button below to invite someone.")
                    else
                      ...accepted.map((f) => _friendTile(uid, f)),
                    if (incoming.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const SectionLabel("Pending requests"),
                      const SizedBox(height: 10),
                      ...incoming.map((f) => _requestTile(uid, f)),
                    ],
                    if (outgoing.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const SectionLabel("Sent requests"),
                      const SizedBox(height: 10),
                      ...outgoing.map((f) => _outgoingTile(uid, f)),
                    ],
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
    );
  }

  Widget _personTile(
    String uid,
    Friendship f, {
    required String fallbackName,
    required Widget Function(String otherUid, String name) trailing,
  }) {
    final otherUid = f.otherUid(uid);
    return FutureBuilder<UserProfile?>(
      future: _userFor(otherUid),
      builder: (context, snap) {
        final name = snap.data?.name.isNotEmpty == true
            ? snap.data!.name
            : fallbackName;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              AvatarCircle(id: otherUid, name: name),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text),
                ),
              ),
              trailing(otherUid, name),
            ],
          ),
        );
      },
    );
  }

  Widget _friendTile(String uid, Friendship f) {
    return _personTile(
      uid,
      f,
      fallbackName: "Friend",
      trailing: (otherUid, name) => OutlinedButton(
        onPressed: () => _openFriendCalendar(otherUid, name),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("View Calendar",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _requestTile(String uid, Friendship f) {
    return _personTile(
      uid,
      f,
      fallbackName: "Someone",
      trailing: (otherUid, name) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _friends.respondToRequest(f.id, false),
            child: const Text("Decline",
                style: TextStyle(color: AppColors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () => _friends.respondToRequest(f.id, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Accept",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _outgoingTile(String uid, Friendship f) {
    return _personTile(
      uid,
      f,
      fallbackName: "Someone",
      trailing: (otherUid, name) => const Text("Requested",
          style: TextStyle(color: AppColors.grey, fontSize: 12)),
    );
  }

  Widget _inviteCard(StateSetter setLocal) {
    return Container(
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
          const SectionLabel("Invite friends"),
          const SizedBox(height: 14),
          const Text("Share your LYRE code",
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    myCode ??
                        (loadingCode ? "Generating..." : "Not available"),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: loadingCode
                    ? null
                    : (myCode != null ? _copyCode : () => _loadMyCode(setLocal)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(myCode != null ? "Copy" : "Retry",
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (codeError != null) ...[
            const SizedBox(height: 8),
            Text(codeError!,
                style: const TextStyle(color: AppColors.red, fontSize: 12)),
          ],
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 18),
          const Text("Add a friend by code",
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                  decoration: appFieldDecoration(
                    hintText: "e.g. foxmatchablue",
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: sendingRequest ? null : () => _sendRequest(setLocal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: sendingRequest
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Add",
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
