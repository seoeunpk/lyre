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
  final _searchFocus = FocusNode();

  String _keyword = '';
  Set<String> _moodFilter = {};
  String? _tagFilter;

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<JournalEntry> _applyFilters(List<JournalEntry> all) {
    final result = <JournalEntry>[];
    for (final e in all) {
      if (_moodFilter.isNotEmpty && !_moodFilter.contains(e.mood)) continue;
      if (_tagFilter != null && !e.tags.contains(_tagFilter)) continue;
      if (_keyword.isNotEmpty) {
        final k = _keyword.toLowerCase();
        final hit = e.note.toLowerCase().contains(k) ||
            (e.song?.trackName ?? '').toLowerCase().contains(k) ||
            (e.song?.artistName ?? '').toLowerCase().contains(k) ||
            e.tags.join(' ').toLowerCase().contains(k);
        if (!hit) continue;
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
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: AppColors.text, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "History",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        actions: const [SizedBox(width: 4)],
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: _uid == null ? null : _journal.getEntries(_uid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final all = snapshot.data ?? const <JournalEntry>[];
          final allTags = all.expand((e) => e.tags).toSet();
          final filtered = _applyFilters(all);

          return Column(
            children: [
              _buildSearchRow(allTags),
              const SizedBox(height: 4),
              Expanded(
                child: all.isEmpty
                    ? buildEmpty("No entries yet.")
                    : filtered.isEmpty
                        ? buildEmpty("No entries match your filters.")
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) => EntryHistoryCard(
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

  Widget _buildSearchRow(Set<String> allTags) {
    final hasFilter = _moodFilter.isNotEmpty || _tagFilter != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('history-search'),
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: (v) => setState(() => _keyword = v.trim()),
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                hintText: "Search notes, songs, tags...",
                hintStyle:
                    const TextStyle(color: AppColors.grey, fontSize: 13),
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
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showFilterSheet(allTags),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: hasFilter ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasFilter ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: hasFilter ? Colors.white : AppColors.text,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final base = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? base.withValues(alpha: 0.28)
              : AppColors.text.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(Set<String> allTags) {
    final localMoods = Set<String>.from(_moodFilter);
    String? localTag = _tagFilter;
    final tags = allTags.toList()..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      "Filter",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setLocal(() {
                        localMoods.clear();
                        localTag = null;
                      }),
                      child: const Text("Clear all",
                          style: TextStyle(
                              color: AppColors.grey, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("MOOD",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey,
                        letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: Moods.combined
                      .map((m) => _filterChip(
                            label: "${m.emoji} ${m.label}",
                            selected: localMoods.contains(m.label),
                            color: m.color,
                            onTap: () => setLocal(() {
                              if (localMoods.contains(m.label)) {
                                localMoods.remove(m.label);
                              } else {
                                localMoods.add(m.label);
                              }
                            }),
                          ))
                      .toList(),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text("TAGS",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags
                        .map((t) => _filterChip(
                              label: "#$t",
                              selected: localTag == t,
                              color: AppColors.pink,
                              onTap: () => setLocal(() =>
                                  localTag = localTag == t ? null : t),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _moodFilter = Set.from(localMoods);
                        _tagFilter = localTag;
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Apply",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
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
                      color: mood.color.withValues(alpha: 0.28),
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
