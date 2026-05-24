import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/spotify_service.dart';
import '../utils/app_colors.dart';

class NewEntryScreen extends StatefulWidget {
  final DateTime date;
  const NewEntryScreen({super.key, required this.date});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final noteController = TextEditingController();
  final searchCtrl = TextEditingController();

  SpotifyTrack? song;
  List<SpotifyTrack> results = [];
  bool searching = false;
  bool showSearch = false;

  final Set<String> tags = {};
  final List<String> myTags = [];
  bool showTags = true;

  Timer? debounce;
  bool saving = false;

  @override
  void dispose() {
    noteController.dispose();
    searchCtrl.dispose();
    debounce?.cancel();
    super.dispose();
  }

  void onSpotifySearchChanged(String query) {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() {
          results = [];
          searching = false;
        });
        return;
      }
      setState(() => searching = true);
      final found = await SpotifyService().searchTracks(query);
      if (mounted) {
        setState(() {
          results = found;
          searching = false;
        });
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
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: "e.g. motivated, cozy...",
            hintStyle: const TextStyle(color: AppColors.grey),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Add",
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        myTags.add(result);
        tags.add(result);
      });
    }
  }

  void saveEntry() async {
    if (song == null) {
      showSnackBar("Pick today's song first", isError: true);
      return;
    }
    if (noteController.text.trim().isEmpty) {
      showSnackBar("Write something in today's note", isError: true);
      return;
    }

    setState(() => saving = true);

    try {
      final uid = AuthService().currentUser?.uid;
      final date = widget.date;
      final docId =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('entries')
          .doc(docId)
          .set({
        'date': Timestamp.fromDate(date),
        'note': noteController.text.trim(),
        'tags': tags.toList(),
        'song': {
          'trackId': song!.trackId,
          'trackName': song!.trackName,
          'artistName': song!.artistName,
          'albumArtUrl': song!.albumArtUrl,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      noteController.clear();
      setState(() {
        song = null;
        tags.clear();
      });
      showSnackBar("Entry saved!");
    } catch (e) {
      if (!mounted) return;
      showSnackBar("Failed to save. Try again.", isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.red : const Color(0xFF4A7B5A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String get dateLabel {
    final d = widget.date;
    final weekdays = [
      "Monday", "Tuesday", "Wednesday", "Thursday",
      "Friday", "Saturday", "Sunday"
    ];
    final months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return "${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: AppColors.text, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          dateLabel,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  MusicCard(
                    song: song,
                    showSearch: showSearch,
                    searchController: searchCtrl,
                    results: results,
                    isSearching: searching,
                    onAddSong: () => setState(() => showSearch = true),
                    onSearch: onSpotifySearchChanged,
                    onSelect: selectSong,
                    onRemove: removeSong,
                    onCancel: () {
                      setState(() {
                        showSearch = false;
                        results = [];
                        searchCtrl.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  NoteCard(controller: noteController),
                  const SizedBox(height: 14),
                  TagsCard(
                    myTags: myTags,
                    tags: tags,
                    expanded: showTags,
                    onExpand: () =>
                        setState(() => showTags = !showTags),
                    onTag: toggleTag,
                    onAdd: addCustomTag,
                  ),
                ],
              ),
            ),
          ),
          DoneButton(saving: saving, onPressed: saveEntry),
        ],
      ),
    );
  }
}

class MusicCard extends StatelessWidget {
  final SpotifyTrack? song;
  final bool showSearch;
  final TextEditingController searchController;
  final List<SpotifyTrack> results;
  final bool isSearching;
  final VoidCallback onAddSong;
  final ValueChanged<String> onSearch;
  final ValueChanged<SpotifyTrack> onSelect;
  final VoidCallback onRemove;
  final VoidCallback onCancel;

  const MusicCard({
    required this.song,
    required this.showSearch,
    required this.searchController,
    required this.results,
    required this.isSearching,
    required this.onAddSong,
    required this.onSearch,
    required this.onSelect,
    required this.onRemove,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return EntryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Music",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          if (song != null)
            AttachedSongTile(track: song!, onRemove: onRemove)
          else if (showSearch)
            SearchPanel(
              controller: searchController,
              results: results,
              isSearching: isSearching,
              onChanged: onSearch,
              onSelect: onSelect,
              onCancel: onCancel,
            )
          else
            AddSongButton(onTap: onAddSong),
        ],
      ),
    );
  }
}

class AddSongButton extends StatelessWidget {
  final VoidCallback onTap;
  const AddSongButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            "Add a song",
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class AttachedSongTile extends StatelessWidget {
  final SpotifyTrack track;
  final VoidCallback onRemove;
  const AttachedSongTile({required this.track, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              image: track.albumArtUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(track.albumArtUrl),
                      fit: BoxFit.cover)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.trackName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  track.artistName,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.grey, size: 18),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class SearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final List<SpotifyTrack> results;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final ValueChanged<SpotifyTrack> onSelect;
  final VoidCallback onCancel;

  const SearchPanel({
    required this.controller,
    required this.results,
    required this.isSearching,
    required this.onChanged,
    required this.onSelect,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: true,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.text),
                decoration: InputDecoration(
                  hintText: "Search for a song or artist...",
                  hintStyle: const TextStyle(
                      color: AppColors.grey, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onCancel,
              child: const Text(
                "Cancel",
                style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (isSearching)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        if (!isSearching && results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: results.map((track) {
                final isFirst = track == results.first;
                final isLast = track == results.last;
                return Column(
                  children: [
                    if (!isFirst)
                      const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
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
                      title: Text(
                        track.trackName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artistName,
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => onSelect(track),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: isFirst ? const Radius.circular(14) : Radius.zero,
                          bottom: isLast ? const Radius.circular(14) : Radius.zero,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        if (!isSearching && results.isEmpty && controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "No songs found for \"${controller.text}\"",
              style: const TextStyle(
                  color: AppColors.grey, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class NoteCard extends StatelessWidget {
  final TextEditingController controller;
  const NoteCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return EntryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's note",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 6,
            style: const TextStyle(
                fontSize: 14, height: 1.6, color: AppColors.text),
            decoration: InputDecoration(
              hintText: "Write here...",
              hintStyle:
                  const TextStyle(color: AppColors.grey, fontSize: 14),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
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
              children: [
                ...myTags.map((label) => TagChip(
                      label: label,
                      selected: tags.contains(label),
                      onTap: () => onTag(label),
                    )),
                AddTagChip(onTap: onAdd),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TagChip({
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
          style: TextStyle(
            fontSize: 13,
            color: AppColors.text,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class AddTagChip extends StatelessWidget {
  final VoidCallback onTap;
  const AddTagChip({required this.onTap});

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
  const EntryCard({required this.child});

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
  final VoidCallback onPressed;
  const DoneButton({required this.saving, required this.onPressed});

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
              : const Text(
                  "Done",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
