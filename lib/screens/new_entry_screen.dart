import 'dart:async';
import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../services/auth_service.dart';
import '../services/journal_service.dart';
import '../services/mood_service.dart';
import '../services/tag_service.dart';
import '../services/spotify_service.dart';
import '../utils/app_colors.dart';
import '../utils/animated_snackbar.dart';
import '../utils/field_decoration.dart';

class NewEntryScreen extends StatefulWidget {
  final DateTime date;
  const NewEntryScreen({super.key, required this.date});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final noteController = TextEditingController();
  final searchCtrl = TextEditingController();
  final _journal = JournalService();

  SpotifyTrack? song;
  List<SpotifyTrack> results = [];
  bool searching = false;
  bool showSearch = false;

  String? selectedMood;

  final List<String> myTags = [];
  final Set<String> tags = {};
  bool showTags = true;

  List<Mood> _customMoods = List.from(Moods.custom);

  bool _moodExpanded = true;
  bool _noteExpanded = true;
  bool saving = false;
  bool loading = true;
  bool entryExists = false;

  Timer? debounce;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final uid = AuthService().currentUser?.uid;
      if (uid == null) {
        setState(() => loading = false);
        return;
      }
      final existing = await _journal.getEntryForDate(uid, widget.date);
      if (!mounted) return;
      if (existing != null) {
        noteController.text = existing.note;
        selectedMood = existing.mood.isEmpty ? null : existing.mood;
        tags.addAll(existing.tags);
        for (final t in existing.tags) {
          if (!myTags.contains(t)) myTags.add(t);
        }
        if (existing.song != null) {
          song = SpotifyTrack(
            trackId: existing.song!.trackId,
            trackName: existing.song!.trackName,
            artistName: existing.song!.artistName,
            albumArtUrl: existing.song!.albumArtUrl,
          );
        }
        entryExists = true;
      }
      if (Moods.custom.isEmpty) {
        try {
          final loaded = await MoodService().getCustomMoods(uid);
          Moods.custom = loaded;
          if (mounted) setState(() => _customMoods = List.from(loaded));
        } catch (_) {}
      }
      try {
        final savedTags = await TagService().getCustomTags(uid);
        for (final t in savedTags) {
          if (!myTags.contains(t)) myTags.add(t);
        }
      } catch (_) {}
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    noteController.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  void onSpotifySearchChanged(String query) {
    if (debounce != null && debounce!.isActive) {
      debounce!.cancel();
    }
    debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() {
          results = [];
          searching = false;
        });
        return;
      }
      setState(() => searching = true);
      try {
        final found = await SpotifyService().searchTracks(query);
        if (mounted) {
          setState(() {
            results = found;
            searching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => searching = false);
      }
    });
  }

  void selectSong(SpotifyTrack track) {
    setState(() {
      song = track;
      results = [];
      showSearch = false;
      searchCtrl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void removeSong() => setState(() => song = null);

  void selectMood(String label) {
    setState(() => selectedMood = selectedMood == label ? null : label);
  }

  void addCustomMood() async {
    final labelCtrl = TextEditingController();
    Color pickedColor = const Color(0xFF7FA7D9);
    String selectedEmoji = '😊';

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

    final mood = await showDialog<Mood>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add a mood",
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 16)),
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
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  ? Border.all(color: pickedColor.withValues(alpha: 0.6), width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(emojis[i], style: const TextStyle(fontSize: 20)),
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
                            color: pickedColor == c ? AppColors.text : Colors.transparent,
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
                bool dupe = false;
                for (final m in Moods.combined) {
                  if (m.label.toLowerCase() == label.toLowerCase()) {
                    dupe = true;
                    break;
                  }
                }
                if (dupe) return;
                Navigator.pop(ctx, Mood(label: label, emoji: selectedEmoji, color: pickedColor));
              },
              child: const Text("Add",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (mood == null || !mounted) return;
    final uid = AuthService().currentUser?.uid;
    if (uid != null) await MoodService().addCustomMood(uid, mood);
    Moods.custom = List.from(Moods.custom)..add(mood);
    setState(() => _customMoods = List.from(Moods.custom));
  }

  void deleteCustomMood(Mood mood) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete mood",
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 16)),
        content: Text("Remove \"${mood.label}\"?",
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
    final uid = AuthService().currentUser?.uid;
    if (uid != null) await MoodService().deleteCustomMood(uid, mood);
    if (selectedMood == mood.label) setState(() => selectedMood = null);
    final remaining = <Mood>[];
    for (final m in Moods.custom) {
      if (m.label != mood.label) remaining.add(m);
    }
    Moods.custom = remaining;
    setState(() => _customMoods = List.from(Moods.custom));
  }

  void toggleTag(String label) {
    setState(() {
      if (tags.contains(label)) {
        tags.remove(label);
      } else {
        tags.add(label);
      }
    });
  }

  void addCustomTag() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Add a tag",
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: const TextStyle(color: AppColors.text, fontSize: 14),
          decoration: appFieldDecoration(
            hintText: "e.g. school, travel, late_night...",
            hintFontSize: 13,
            counterText: '',
            focusColor: AppColors.pink,
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Add",
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        if (!myTags.contains(result)) myTags.add(result);
        tags.add(result);
      });
      final uid = AuthService().currentUser?.uid;
      if (uid != null) {
        try {
          await TagService().addCustomTag(uid, result);
        } catch (_) {}
      }
    }
  }

  void confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete entry?",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                fontSize: 16)),
        content: const Text(
          "This can't be undone.",
          style: TextStyle(color: AppColors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    setState(() => saving = true);
    try {
      final docId =
          "${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}";
      await _journal.deleteEntry(uid, docId);
      if (!mounted) return;
      _showSnackBar("Entry deleted");
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Failed to delete. Try again.", isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void saveEntry() async {
    if (song == null) {
      _showSnackBar("Pick today's song first", isError: true);
      return;
    }
    if (selectedMood == null) {
      _showSnackBar("How are you feeling? Pick a mood", isError: true);
      return;
    }
    if (noteController.text.trim().isEmpty) {
      _showSnackBar("Write something in today's note", isError: true);
      return;
    }

    setState(() => saving = true);

    try {
      final uid = AuthService().currentUser?.uid;
      if (uid == null) throw Exception('not signed in');

      final entry = JournalEntry(
        date: widget.date,
        mood: selectedMood!,
        note: noteController.text.trim(),
        tags: tags.toList(),
        song: EntrySong.fromTrack(song!),
      );
      await _journal.saveEntry(uid, entry);

      if (!mounted) return;
      _showSnackBar(entryExists ? "Entry updated!" : "Entry saved!");
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Failed to save. Try again.", isError: true);
      setState(() => saving = false);
    }
  }

  List<Widget> _buildTrackTiles() {
    final tiles = <Widget>[];
    for (final track in results) {
      tiles.add(ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(8),
            image: track.albumArtUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(track.albumArtUrl),
                    fit: BoxFit.cover)
                : null,
          ),
        ),
        title: Text(track.trackName,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(track.artistName,
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        onTap: () => selectSong(track),
      ));
    }
    return tiles;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    showAnimatedSnackBar(context, message, isError: isError);
  }

  String get dateLabel {
    final d = widget.date;
    final weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    final months = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"];
    return "${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.text, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          dateLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        actions: [
          if (entryExists)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
              onPressed: saving ? null : confirmDelete,
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      children: [
                        _musicSection(),
                        const SizedBox(height: 14),
                        MoodCard(
                          selected: selectedMood,
                          onSelect: selectMood,
                          customMoods: _customMoods,
                          onAddMood: addCustomMood,
                          onDeleteMood: deleteCustomMood,
                          expanded: _moodExpanded,
                          onExpand: () => setState(() => _moodExpanded = !_moodExpanded),
                        ),
                        const SizedBox(height: 14),
                        TagsCard(
                          myTags: myTags,
                          tags: tags,
                          expanded: showTags,
                          onExpand: () => setState(() => showTags = !showTags),
                          onTag: toggleTag,
                          onAdd: addCustomTag,
                        ),
                        const SizedBox(height: 14),
                        _noteSection(),
                      ],
                    ),
                  ),
                ),
                DoneButton(
                  saving: saving,
                  isEdit: entryExists,
                  onPressed: saveEntry,
                ),
              ],
            ),
    );
  }

  Widget _musicSection() {
    return EntryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Music",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 12),
          if (song != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      image: song!.albumArtUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(song!.albumArtUrl), fit: BoxFit.cover)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song!.trackName,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(song!.artistName,
                            style: const TextStyle(fontSize: 12, color: AppColors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.grey, size: 18),
                    onPressed: removeSong,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )
          else if (showSearch)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: onSpotifySearchChanged,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14, color: AppColors.text),
                        decoration: appFieldDecoration(
                          hintText: "Search for a song or artist...",
                          hintFontSize: 13,
                          radius: 14,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          focusColor: AppColors.pink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() {
                        showSearch = false;
                        results = [];
                        searchCtrl.clear();
                      }),
                      child: const Text("Cancel",
                          style: TextStyle(
                              color: AppColors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                if (searching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  )
                else if (results.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: _buildTrackTiles(),
                    ),
                  )
                else if (searchCtrl.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No songs found for "${searchCtrl.text}"',
                        style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                  ),
              ],
            )
          else
            GestureDetector(
              onTap: () => setState(() => showSearch = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text("Add a song",
                      style: TextStyle(
                          color: AppColors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _noteSection() {
    return EntryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _noteExpanded = !_noteExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Text("Today's note",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                const Spacer(),
                Icon(
                  _noteExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
          if (_noteExpanded) ...[
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 6,
              style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.text),
              decoration: appFieldDecoration(
                hintText: "Write here...",
                hintFontSize: 14,
                radius: 14,
                contentPadding: const EdgeInsets.all(14),
                focusColor: AppColors.pink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MoodCard extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final List<Mood> customMoods;
  final VoidCallback onAddMood;
  final ValueChanged<Mood> onDeleteMood;
  final bool expanded;
  final VoidCallback onExpand;

  const MoodCard({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.customMoods,
    required this.onAddMood,
    required this.onDeleteMood,
    required this.expanded,
    required this.onExpand,
  });

  Widget _chip(Mood m, bool isSelected, {bool deletable = false}) {
    return GestureDetector(
      onTap: () => onSelect(m.label),
      onLongPress: deletable ? () => onDeleteMood(m) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? m.color.withValues(alpha: 0.28)
              : AppColors.text.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              m.label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EntryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onExpand,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Text(
                  "How are you feeling?",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildMoodChips(selected, customMoods, onAddMood),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMoodChips(
    String? selected,
    List<Mood> customMoods,
    VoidCallback onAddMood,
  ) {
    final chips = <Widget>[];
    for (final m in Moods.all) {
      chips.add(_chip(m, selected == m.label));
    }
    for (final m in customMoods) {
      chips.add(_chip(m, selected == m.label, deletable: true));
    }
    chips.add(GestureDetector(
      onTap: onAddMood,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "+ add",
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ));
    return chips;
  }
}

class TagsCard extends StatelessWidget {
  final List<String> myTags;
  final Set<String> tags;
  final bool expanded;
  final VoidCallback onExpand;
  final ValueChanged<String> onTag;
  final VoidCallback onAdd;

  const TagsCard({
    super.key,
    required this.myTags,
    required this.tags,
    required this.expanded,
    required this.onExpand,
    required this.onTag,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return EntryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onExpand,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Text(
                  "Tags",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildTagChips(),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTagChips() {
    final chips = <Widget>[];
    for (final label in myTags) {
      chips.add(TagChip(
        label: label,
        selected: tags.contains(label),
        onTap: () => onTag(label),
      ));
    }
    chips.add(AddTagChip(onTap: onAdd));
    return chips;
  }
}

class TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TagChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.pink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.text,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class AddTagChip extends StatelessWidget {
  final VoidCallback onTap;
  const AddTagChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "+ add",
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class EntryCard extends StatelessWidget {
  final Widget child;
  const EntryCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DoneButton extends StatelessWidget {
  final bool saving;
  final bool isEdit;
  final VoidCallback onPressed;
  const DoneButton({
    super.key,
    required this.saving,
    required this.isEdit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: saving ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 17),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
            elevation: 0,
          ),
          child: saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  isEdit ? "Update" : "Done",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
