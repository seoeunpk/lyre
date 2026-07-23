import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../services/auth_service.dart';
import '../services/mood_service.dart';
import '../services/tag_service.dart';
import '../utils/app_colors.dart';
import '../utils/animated_snackbar.dart';
import '../utils/field_decoration.dart';
import '../widgets/avatar_circle.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  List<Mood> _customMoods = [];
  List<String> _customTags = [];
  bool _loading = true;
  bool _savingName = false;
  bool _profileChanged = false;

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = AuthService().currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _nameCtrl.text = user.displayName ?? '';
    final uid = user.uid;
    try {
      final moods = await MoodService().getCustomMoods(uid);
      Moods.custom = moods;
    } catch (_) {}
    try {
      final tags = await TagService().getCustomTags(uid);
      if (mounted) setState(() => _customTags = tags);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _customMoods = List.from(Moods.custom);
        _loading = false;
      });
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showAnimatedSnackBar(context, "Name can't be empty.", isError: true);
      return;
    }
    setState(() => _savingName = true);
    try {
      await AuthService().currentUser?.updateDisplayName(name);
      if (mounted) {
        showAnimatedSnackBar(context, "Name updated!");
        setState(() => _profileChanged = true);
      }
    } catch (_) {
      if (mounted) showAnimatedSnackBar(context, "Failed to update name.", isError: true);
    }
    if (mounted) setState(() => _savingName = false);
  }

  Future<Mood?> _showMoodDialog({Mood? existing}) async {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    Color pickedColor = existing?.color ?? const Color(0xFF7FA7D9);
    String selectedEmoji = existing?.emoji ?? '😊';
    final isEdit = existing != null;

    const emojis = [
      '😊', '😄', '😁', '🥰', '😍', '🤩', '😎', '🥳', '😇', '😌',
      '🙂', '😐', '😑', '🫤', '🙃', '🤔', '😕', '😟', '😔', '😢',
      '😭', '😞', '🥺', '😠', '😤', '😡', '🤬', '😰', '😨', '😧',
      '🫣', '😴', '🥱', '😪', '🤒', '🤧', '🥴', '🤯', '😵', '🥹',
      '😮', '🫠', '😬', '🤗', '😏', '😒', '🌙', '☀️', '🌸', '🎵',
      '🌊', '⚡', '🔥', '💫', '✨', '💤', '🎉', '💖', '🫶', '💪',
    ];

    const palette = [
      Color(0xFFF6C744), Color(0xFFF38B4A), Color(0xFFE57373),
      Color(0xFFB69CD8), Color(0xFF7FA7D9), Color(0xFFA8D8CE),
      Color(0xFFF4BDD0), Color(0xFF9E9E9E), Color(0xFF4A7B5A),
    ];

    return showDialog<Mood>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? "Edit mood" : "Add a mood",
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: pickedColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: pickedColor, width: 2),
                      ),
                      child: Center(
                        child: Text(selectedEmoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: labelCtrl,
                        style: const TextStyle(fontSize: 14, color: AppColors.text),
                        decoration: appFieldDecoration(hintText: "Name"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      GridView.builder(
                        padding: const EdgeInsets.all(6),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: emojis.length,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => setLocal(() => selectedEmoji = emojis[i]),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedEmoji == emojis[i]
                                  ? pickedColor.withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: selectedEmoji == emojis[i]
                                  ? Border.all(
                                      color: pickedColor.withValues(alpha: 0.6),
                                      width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(emojis[i],
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.background.withValues(alpha: 0),
                                  AppColors.background.withValues(alpha: 0.92),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Builder(builder: (_) {
                  final colorDots = <Widget>[];
                  for (final c in palette) {
                    colorDots.add(GestureDetector(
                      onTap: () => setLocal(() => pickedColor = c),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: pickedColor == c
                                ? AppColors.text
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ));
                  }
                  return Wrap(spacing: 8, runSpacing: 8, children: colorDots);
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: AppColors.grey)),
            ),
            TextButton(
              onPressed: () {
                final label = labelCtrl.text.trim();
                if (label.isEmpty) return;
                if (!isEdit) {
                  bool dupe = false;
                  for (final m in Moods.combined) {
                    if (m.label.toLowerCase() == label.toLowerCase()) {
                      dupe = true;
                      break;
                    }
                  }
                  if (dupe) return;
                } else {
                  bool dupe = false;
                  for (final m in Moods.combined) {
                    if (m.label.toLowerCase() == label.toLowerCase() &&
                        m.label != existing!.label) {
                      dupe = true;
                      break;
                    }
                  }
                  if (dupe) return;
                }
                Navigator.pop(
                    ctx, Mood(label: label, emoji: selectedEmoji, color: pickedColor));
              },
              child: Text(
                isEdit ? "Save" : "Add",
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMood(Mood original) async {
    final updated = await _showMoodDialog(existing: original);
    if (updated == null || !mounted) return;
    final uid = _uid;
    if (uid == null) return;
    try {
      await MoodService().deleteCustomMood(uid, original);
      await MoodService().addCustomMood(uid, updated);
      final idx = Moods.custom.indexWhere((m) => m.label == original.label);
      if (idx >= 0) {
        final newList = List<Mood>.from(Moods.custom);
        newList[idx] = updated;
        Moods.custom = newList;
      }
      if (mounted) setState(() => _customMoods = List.from(Moods.custom));
    } catch (_) {
      if (mounted) showAnimatedSnackBar(context, "Failed to update mood.", isError: true);
    }
  }

  Future<void> _deleteMood(Mood mood) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete mood?",
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 16)),
        content: Text('Remove "${mood.emoji} ${mood.label}"?',
            style: const TextStyle(color: AppColors.grey, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete",
                style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final uid = _uid;
    if (uid == null) return;
    try {
      await MoodService().deleteCustomMood(uid, mood);
      final remaining = <Mood>[];
      for (final m in Moods.custom) {
        if (m.label != mood.label) remaining.add(m);
      }
      Moods.custom = remaining;
      if (mounted) setState(() => _customMoods = List.from(Moods.custom));
    } catch (_) {
      if (mounted) showAnimatedSnackBar(context, "Failed to delete mood.", isError: true);
    }
  }

  Future<void> _addCustomTag() async {
    final raw = _tagCtrl.text.trim();
    final tag = raw.replaceAll(' ', '_').toLowerCase();
    if (tag.isEmpty) return;
    if (_customTags.contains(tag)) {
      showAnimatedSnackBar(context, "Tag already exists.", isError: true);
      _tagCtrl.clear();
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    try {
      await TagService().addCustomTag(uid, tag);
      setState(() {
        _customTags = List.from(_customTags)..add(tag);
        _tagCtrl.clear();
      });
    } catch (_) {
      if (mounted) showAnimatedSnackBar(context, "Failed to add tag.", isError: true);
    }
  }

  Future<void> _deleteTag(String tag) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await TagService().deleteCustomTag(uid, tag);
      final newTags = <String>[];
      for (final t in _customTags) {
        if (t != tag) newTags.add(t);
      }
      setState(() => _customTags = newTags);
    } catch (_) {
      if (mounted) showAnimatedSnackBar(context, "Failed to delete tag.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.text, size: 26),
          onPressed: () => Navigator.pop(context, _profileChanged),
        ),
        centerTitle: true,
        title: const Text(
          "My Account",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _profileSection(),
                const SizedBox(height: 28),
                _sectionLabel("Custom Moods"),
                const SizedBox(height: 10),
                _moodsSection(),
                const SizedBox(height: 28),
                _sectionLabel("My Tags"),
                const SizedBox(height: 10),
                _tagsSection(),
              ],
            ),
    );
  }

  Widget _profileSection() {
    final nameText = _nameCtrl.text.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          AvatarCircle(id: _uid ?? nameText, name: nameText, size: 80),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                  decoration: appFieldDecoration(
                    labelText: "Display name",
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _savingName ? null : _saveName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _savingName
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Save",
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

  Widget _sectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.grey,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _moodsSection() {
    if (_customMoods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "No custom moods yet.\nAdd one while logging an entry.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 13, height: 1.5),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(_customMoods.length, (i) {
          final mood = _customMoods[i];
          final isLast = i == _customMoods.length - 1;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: mood.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        mood.label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _editMood(mood),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.edit_rounded,
                            size: 17, color: AppColors.grey),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _deleteMood(mood),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 17, color: AppColors.red),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1, indent: 16, endIndent: 16, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _tagsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_customTags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildTagChips(),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagCtrl,
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                  onSubmitted: (_) => _addCustomTag(),
                  decoration: appFieldDecoration(
                    hintText: "New tag...",
                    hintFontSize: 13,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _addCustomTag,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Add",
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

  List<Widget> _buildTagChips() {
    final chips = <Widget>[];
    for (final tag in _customTags) {
      chips.add(_tagChip(tag));
    }
    return chips;
  }

  Widget _tagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pink.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "#$tag",
            style: const TextStyle(
                fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _deleteTag(tag),
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
