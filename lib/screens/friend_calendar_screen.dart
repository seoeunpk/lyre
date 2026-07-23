import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../models/sharing_settings.dart';
import '../services/auth_service.dart';
import '../services/journal_service.dart';
import '../services/sharing_service.dart';
import '../utils/app_colors.dart';

class FriendCalendarScreen extends StatefulWidget {
  final String friendUid;
  final String friendName;

  const FriendCalendarScreen({
    super.key,
    required this.friendUid,
    required this.friendName,
  });

  @override
  State<FriendCalendarScreen> createState() => _FriendCalendarScreenState();
}

class _FriendCalendarScreenState extends State<FriendCalendarScreen> {
  final _journal = JournalService();
  final _sharing = SharingService();

  DateTime month = DateTime.now();
  final DateTime today = DateTime.now();

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
        title: Text(
          "${widget.friendName}'s Calendar",
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<SharingSettings>(
          stream: _sharing.watchSettings(widget.friendUid),
          builder: (context, settingsSnap) {
            if (settingsSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (settingsSnap.hasError) {
              return _blockedView();
            }
            final settings = settingsSnap.data ?? const SharingSettings();
            final viewerUid = AuthService().currentUser?.uid;
            final prefs = viewerUid == null
                ? const FriendSharePrefs()
                : settings.prefsFor(viewerUid);
            return StreamBuilder<List<JournalEntry>>(
              stream: _journal.getSharedEntries(widget.friendUid),
              builder: (context, entriesSnap) {
                if (entriesSnap.hasError) {
                  return _blockedView();
                }
                if (entriesSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                final entryByDay = <String, JournalEntry>{};
                for (final e in _visibleEntries(
                    entriesSnap.data ?? const <JournalEntry>[], prefs)) {
                  entryByDay[_key(e.date)] = e;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _monthHeader(),
                    _weekdayLabels(),
                    Expanded(child: _buildCalendarGrid(entryByDay, prefs)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<JournalEntry> _visibleEntries(
      List<JournalEntry> all, FriendSharePrefs prefs) {
    switch (prefs.visibility) {
      case 'tagged':
        return all.where((e) => e.tags.isNotEmpty).toList();
      case 'recent':
        final cutoff = today.subtract(const Duration(days: 30));
        return all.where((e) => e.date.isAfter(cutoff)).toList();
      default:
        return all;
    }
  }

  Widget _blockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 36, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(
              "${widget.friendName} hasn't shared their calendar with you.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.grey, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _key(DateTime d) => "${d.year}-${d.month}-${d.day}";

  void prevMonth() => setState(() => month = DateTime(month.year, month.month - 1));
  void nextMonth() => setState(() => month = DateTime(month.year, month.month + 1));

  Widget _monthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: prevMonth,
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.grey),
          ),
          Expanded(
            child: Text(
              "${monthName(month.month)} ${month.year}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          IconButton(
            onPressed: nextMonth,
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _weekdayLabels() {
    const labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    final labelWidgets = <Widget>[];
    for (final l in labels) {
      labelWidgets.add(Expanded(
        child: Center(
          child: Text(
            l,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: labelWidgets),
    );
  }

  Widget _buildCalendarGrid(
      Map<String, JournalEntry> entryByDay, FriendSharePrefs prefs) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;
    final totalCells = ((startOffset + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.75,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNum = index - startOffset + 1;
        if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();
        final date = DateTime(month.year, month.month, dayNum);
        final isToday = isSameDay(date, today);
        final entry = entryByDay[_key(date)];
        return _buildDayCell(date, dayNum, isToday, entry, prefs);
      },
    );
  }

  Widget _buildDayCell(DateTime date, int dayNum, bool isToday,
      JournalEntry? entry, FriendSharePrefs prefs) {
    final moodData =
        prefs.shareMood ? Moods.byLabel(entry?.mood) : null;
    final moodColor = moodData?.color;
    final albumArt = prefs.shareSongs ? entry?.song?.albumArtUrl : null;
    final hasArt = albumArt != null && albumArt.isNotEmpty;
    final glowColor = moodColor ?? (isToday ? AppColors.primary : null);
    final hasEntry = entry != null;

    Widget? cellContent;
    if (!hasArt && moodData != null) {
      cellContent = Text(moodData.emoji, style: const TextStyle(fontSize: 16));
    } else if (!hasArt && hasEntry) {
      cellContent = const Icon(Icons.circle, size: 8, color: AppColors.grey);
    }

    return GestureDetector(
      onTap: hasEntry ? () => _showDaySheet(entry, prefs) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: hasArt
                  ? null
                  : (moodColor?.withValues(alpha: 0.35) ??
                      (hasEntry ? AppColors.lightGrey : Colors.transparent)),
              image: hasArt
                  ? DecorationImage(
                      image: NetworkImage(albumArt), fit: BoxFit.cover)
                  : null,
              boxShadow: glowColor != null
                  ? [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: cellContent,
          ),
          const SizedBox(height: 4),
          Text(
            "$dayNum",
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              color: isToday ? Colors.black : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showDaySheet(JournalEntry entry, FriendSharePrefs prefs) {
    final mood = prefs.shareMood ? Moods.byLabel(entry.mood) : null;
    final song = prefs.shareSongs ? entry.song : null;
    final tags = prefs.shareTags ? entry.tags : const <String>[];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mood != null)
              Row(
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(mood.label,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                ],
              ),
            if (song != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                      image: song.albumArtUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(song.albumArtUrl),
                              fit: BoxFit.cover)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.trackName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text)),
                        Text(song.artistName,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.pink.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text("#$t",
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.text)),
                    ),
                ],
              ),
            ],
            if (mood == null && song == null && tags.isEmpty)
              const Text(
                "This friend logged an entry, but hasn't shared details for this day.",
                style: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String monthName(int m) => [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ][m - 1];
}
