import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../services/auth_service.dart';
import '../services/journal_service.dart';
import '../utils/app_colors.dart';
import 'new_entry_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _journal = JournalService();
  final _searchCtrl = TextEditingController();

  String _keyword = '';
  String? _moodFilter; // null = all moods
  String? _tagFilter; // null = all tags

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // filter the entries by the mood, tag and search box
  List<JournalEntry> _applyFilters(List<JournalEntry> all) {
    final result = <JournalEntry>[];
    for (final e in all) {
      // mood filter
      if (_moodFilter != null && e.mood != _moodFilter) continue;
      // tag filter
      if (_tagFilter != null && !e.tags.contains(_tagFilter)) continue;
      // search box - check the note, song and tags
      if (_keyword.isNotEmpty) {
        final k = _keyword.toLowerCase();
        final inNote = e.note.toLowerCase().contains(k);
        final inSong = (e.song?.trackName ?? '').toLowerCase().contains(k) ||
            (e.song?.artistName ?? '').toLowerCase().contains(k);
        final inTags = e.tags.join(' ').toLowerCase().contains(k);
        if (!inNote && !inSong && !inTags) continue;
      }
      result.add(e);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: AppColors.text, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Journal History",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: _uid == null ? null : _journal.getEntries(_uid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final all = snapshot.data ?? const <JournalEntry>[];
          // get all the tags that have been used
          final allTags = <String>{};
          for (final e in all) {
            allTags.addAll(e.tags);
          }
          final filtered = _applyFilters(all);

          return Column(
            children: [
              buildSearchField(),
              buildMoodFilters(),
              if (allTags.isNotEmpty) buildTagFilters(allTags.toList()),
              const SizedBox(height: 4),
              Expanded(
                child: all.isEmpty
                    ? buildEmpty("No entries yet.\nStart journaling to see them here.")
                    : filtered.isEmpty
                        ? buildEmpty("No entries match your filters.")
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) =>
                                EntryHistoryCard(
                              entry: filtered[i],
                              onTap: () => _openEntry(filtered[i].date),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openEntry(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewEntryScreen(date: date)),
    );
  }

  Widget buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _keyword = v.trim()),
        style: const TextStyle(fontSize: 14, color: AppColors.text),
        decoration: InputDecoration(
          hintText: "Search notes, songs, tags...",
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.grey, size: 20),
          suffixIcon: _keyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.grey, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _keyword = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget buildMoodFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChipPill(
            label: "All moods",
            selected: _moodFilter == null,
            onTap: () => setState(() => _moodFilter = null),
          ),
          ...Moods.all.map((m) => FilterChipPill(
                label: "${m.emoji} ${m.label}",
                selected: _moodFilter == m.label,
                color: m.color,
                onTap: () => setState(() => _moodFilter =
                    _moodFilter == m.label ? null : m.label),
              )),
        ],
      ),
    );
  }

  Widget buildTagFilters(List<String> tags) {
    tags.sort();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            FilterChipPill(
              label: "All tags",
              selected: _tagFilter == null,
              onTap: () => setState(() => _tagFilter = null),
              small: true,
            ),
            ...tags.map((t) => FilterChipPill(
                  label: "#$t",
                  selected: _tagFilter == t,
                  color: AppColors.pink,
                  small: true,
                  onTap: () => setState(
                      () => _tagFilter = _tagFilter == t ? null : t),
                )),
          ],
        ),
      ),
    );
  }

  Widget buildEmpty(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.grey, fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}

class FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final bool small;

  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
              horizontal: small ? 12 : 14, vertical: small ? 6 : 8),
          decoration: BoxDecoration(
            color: selected
                ? base.withValues(alpha: color == null ? 1 : 0.35)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? base : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: small ? 12 : 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected && color == null
                  ? Colors.white
                  : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class EntryHistoryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  const EntryHistoryCard({super.key, required this.entry, required this.onTap});

  static const _months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  String get _dateLabel =>
      "${_months[entry.date.month - 1]} ${entry.date.day}, ${entry.date.year}";

  @override
  Widget build(BuildContext context) {
    final mood = Moods.byLabel(entry.mood);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _dateLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                if (mood != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: mood.color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${mood.emoji} ${mood.label}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
              ],
            ),
            if (entry.song != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                      image: entry.song!.albumArtUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(entry.song!.albumArtUrl),
                              fit: BoxFit.cover)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.song!.trackName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          entry.song!.artistName,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                entry.note,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.text, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.pink.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "#$t",
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.text,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
