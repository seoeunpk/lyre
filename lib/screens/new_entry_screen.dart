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

  bool saving = false;
  bool loading = true;
  bool entryExists = false;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      setState(() => loading = false);
      return;
    }

    final date = widget.date;
    final docId = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc(docId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final songData = data['song'] as Map<String, dynamic>?;
      final savedTags = List<String>.from(data['tags'] ?? []);

      setState(() {
        noteController.text = data['note'] ?? '';
        tags.addAll(savedTags);
        myTags.addAll(savedTags);
        if (songData != null) {
          song = SpotifyTrack(
            trackId: songData['trackId'] ?? '',
            trackName: songData['trackName'] ?? '',
            artistName: songData['artistName'] ?? '',
            albumArtUrl: songData['albumArtUrl'] ?? '',
          );
        }
        entryExists = true;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }


  @override
  void dispose() {
    noteController.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  void onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => results = []);
      return;
    }
    setState(() => searching = true);
    try {
      final found = await SpotifyService().searchTracks(query);
      setState(() {
        results = found;
        searching = false;
      });
    } catch (e) {
      setState(() => searching = false);
      _showSnackBar("Search failed. Check your connection.", isError: true);
    }
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
              borderSide: const BorderSide(color: AppColors.pink, width: 2),
            ),
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
        myTags.add(result);
        tags.add(result);
      });
    }
  }

  void deleteEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete entry?",
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 16)),
        content: const Text("This can't be undone.",
            style: TextStyle(color: AppColors.grey, fontSize: 14)),
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

    if (confirm != true) return;

    final uid = AuthService().currentUser?.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc("${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}")
        .delete();

    Navigator.pop(context);
  }

  void saveEntry() async {
    if (song == null) {
      _showSnackBar("Pick today's song first", isError: true);
      return;
    }
    if (noteController.text.trim().isEmpty) {
      _showSnackBar("Write something in today's note", isError: true);
      return;
    }

    setState(() => saving = true);

    try {
      final uid = AuthService().currentUser?.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('entries')
          .doc("${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}")
          .set({
        'date': Timestamp.fromDate(widget.date),
        'note': noteController.text.trim(),
        'tags': tags.toList(),
        'song': {
          'trackId': song!.trackId,
          'trackName': song!.trackName,
          'artistName': song!.artistName,
          'albumArtUrl': song!.albumArtUrl,
        },
      });

      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      setState(() => saving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.red : const Color(0xFF4A7B5A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.grey, size: 22),
              onPressed: deleteEntry,
            ),
        ],
      ),
      body: loading
          ? const SizedBox()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      children: [
                        _musicSection(),
                        const SizedBox(height: 14),
                        _noteSection(),
                        const SizedBox(height: 14),
                        _tagsSection(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        elevation: 0,
                      ),
                      child: const Text("Done",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _musicSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
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
                    onPressed: () => setState(() => song = null),
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
                        onChanged: onSearch,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14, color: AppColors.text),
                        decoration: InputDecoration(
                          hintText: "Search for a song or artist...",
                          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            borderSide: const BorderSide(color: AppColors.pink, width: 2),
                          ),
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
                if (results.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: results.map((track) => ListTile(
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
                      )).toList(),
                    ),
                  ),
                if (results.isEmpty && searchCtrl.text.isNotEmpty)
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's note",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 6,
            style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.text),
            decoration: InputDecoration(
              hintText: "Write here...",
              hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
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
                borderSide: const BorderSide(color: AppColors.pink, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tags",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...myTags.map((label) => GestureDetector(
                    onTap: () => toggleTag(label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w400)),
                    ),
                  )),
              GestureDetector(
                onTap: addCustomTag,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("+ add",
                      style: TextStyle(
                          fontSize: 13, color: AppColors.grey, fontWeight: FontWeight.w400)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
