import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../services/auth_service.dart';
import '../services/journal_service.dart';
import '../utils/app_colors.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Insights',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: uid == null ? null : JournalService().getEntries(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) return const _EmptyState();
          return _InsightsContent(entries: entries);
        },
      ),
    );
  }
}

class _InsightsContent extends StatefulWidget {
  final List<JournalEntry> entries;
  const _InsightsContent({required this.entries});

  @override
  State<_InsightsContent> createState() => _InsightsContentState();
}

class _InsightsContentState extends State<_InsightsContent> {
  int selectedDays = 30;
  bool showMoodTrend = false;

  @override
  Widget build(BuildContext context) {
    final shownEntries = getEntriesForPeriod(widget.entries);
    final moods = countMoods(shownEntries);
    final tags = countTags(shownEntries);
    final artists = countArtists(shownEntries);
    final songs = countSongs(shownEntries);
    final topMood = getTopItem(moods);
    final topArtist = getTopItem(artists);
    final activeDays = shownEntries.map((e) => dateKey(e.date)).toSet().length;
    final daysLabel = selectedDays == 0 ? 'all time' : 'last $selectedDays days';
    final connections = getConnections(shownEntries);
    final comparison = compareWithPreviousPeriod(widget.entries, selectedDays);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your reflection, at a glance',
            style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.text)),
        const SizedBox(height: 4),
        const Text('These patterns are based on your saved entries.',
            style: TextStyle(fontSize: 12, color: AppColors.grey)),
        const SizedBox(height: 16),
        buildPeriodPicker(),
        const SizedBox(height: 18),
        Row(children: [
          _StatBox(value: '${shownEntries.length}', label: 'Entries'),
          const SizedBox(width: 10),
          _StatBox(
              value: selectedDays == 0 ? '$activeDays' : '$activeDays/$selectedDays',
              label: 'Days journaled'),
          const SizedBox(width: 10),
          _StatBox(
              value: topMood == null ? '—' : (Moods.byLabel(topMood)?.emoji ?? '•'),
              label: topMood ?? 'Top mood'),
        ]),
        const SizedBox(height: 20),
        _Section(
          title: 'Journaling rhythm',
          subtitle: 'Your activity over the last 7 days',
          child: Column(children: [
            _WeeklyChart(counts: weeklyCounts(widget.entries)),
            const SizedBox(height: 14),
            Row(children: [
              _SmallStat(
                  icon: Icons.local_fire_department_rounded,
                  value: '${currentStreak(widget.entries)} days',
                  label: 'Current streak'),
              _SmallStat(
                  icon: Icons.emoji_events_rounded,
                  value: '${longestStreak(widget.entries)} days',
                  label: 'Best streak'),
              _SmallStat(
                  icon: Icons.edit_note_rounded,
                  value: '${averageWords(shownEntries)}',
                  label: 'Avg. words'),
            ]),
          ]),
        ),
        if (comparison != null) ...[
          const SizedBox(height: 12),
          _ComparisonCard(text: comparison),
        ],
        const SizedBox(height: 20),
        _Section(
          title: 'Mood balance',
          subtitle: moods.isEmpty
              ? 'No moods recorded in this period'
              : 'How often each mood appears in the $daysLabel',
          child: moods.isEmpty
              ? const _NoData('Add a mood to an entry to see this pattern.')
              : Column(
                  children: sortedMoods(moods)
                      .map((mood) => _MoodRow(
                            mood: mood,
                            count: moods[mood.label]!,
                            total: moods.values.fold(0, (a, b) => a + b),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Mood over time',
          subtitle:
              showMoodTrend
                  ? 'How your most common moods appear across the last 4 weeks.'
                  : 'Your last ${selectedDays == 7 ? 7 : 30} days. Each coloured day has a saved mood.',
          child: Column(children: [
            Row(children: [
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => showMoodTrend = !showMoodTrend),
                icon: Icon(showMoodTrend
                    ? Icons.view_week_rounded
                    : Icons.show_chart_rounded),
                label: Text(showMoodTrend ? 'Timeline' : 'Trend chart'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
            _MoodTimeline(
              entries: widget.entries,
              days: selectedDays == 7 ? 7 : 30,
              showTrend: showMoodTrend,
            ),
          ]),
        ),
        if (topMood != null && shownEntries.length > 1) ...[
          const SizedBox(height: 20),
          _PatternCard(
            text: '${Moods.byLabel(topMood)?.emoji ?? '•'} $topMood appears in '
                '${((moods[topMood]! / moods.values.fold(0, (a, b) => a + b)) * 100).round()}% '
                'of your mood-tagged entries in this period.',
          ),
        ],
        const SizedBox(height: 20),
        _Section(
          title: 'More to notice',
          subtitle: 'Small details from your reflections',
          child: _ExtraInsights(entries: shownEntries, songs: songs),
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Connections you may notice',
          subtitle: 'Shown after at least 3 matching entries',
          child: connections.isEmpty
              ? const _NoData(
                  'Keep adding moods, music, and tags to reveal connections.')
              : Column(
                  children: connections
                      .map((connection) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.link_rounded,
                                    color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(connection,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.text,
                                          height: 1.35)),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Music in your journal',
          subtitle: musicSubtitle(shownEntries),
          child: topArtist == null
              ? const _NoData('Attach a song to an entry to see your music habits.')
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Most returned-to artist',
                      style: TextStyle(fontSize: 12, color: AppColors.grey)),
                  const SizedBox(height: 4),
                  Text(topArtist,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  Text('${artists[topArtist]} entries',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                ]),
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Your recurring contexts',
          subtitle: 'Tags you return to most often',
          child: tags.isEmpty
              ? const _NoData('Add tags to reveal the contexts in your entries.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sortedItems(tags).take(8).map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.pink.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('#${item.key}  ${item.value}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text,
                              fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
        ),
      ]),
    );
  }

  Widget buildPeriodPicker() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        buildPeriodButton(7, '7 days'),
        buildPeriodButton(30, '30 days'),
        buildPeriodButton(0, 'All time'),
      ]),
    );
  }

  Widget buildPeriodButton(int days, String label) {
    final selected = selectedDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedDays = days),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.text : AppColors.grey)),
        ),
      ),
    );
  }

  List<JournalEntry> getEntriesForPeriod(List<JournalEntry> entries) {
    if (selectedDays == 0) return entries;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: selectedDays - 1));
    return entries.where((entry) => !entry.date.isBefore(start)).toList();
  }
}

Map<String, int> countMoods(List<JournalEntry> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    if (entry.mood.isNotEmpty) counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
  }
  return counts;
}

Map<String, int> countTags(List<JournalEntry> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    for (final tag in entry.tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return counts;
}

Map<String, int> countArtists(List<JournalEntry> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    final artist = entry.song?.artistName ?? '';
    if (artist.isNotEmpty) counts[artist] = (counts[artist] ?? 0) + 1;
  }
  return counts;
}

Map<String, int> countSongs(List<JournalEntry> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    final song = entry.song;
    if (song != null && song.trackName.isNotEmpty) {
      final title = '${song.trackName} — ${song.artistName}';
      counts[title] = (counts[title] ?? 0) + 1;
    }
  }
  return counts;
}

String musicSubtitle(List<JournalEntry> entries) {
  if (entries.isEmpty) return 'No entries in this period';
  final withMusic = entries.where((entry) => entry.song != null).length;
  final percentage = (withMusic / entries.length * 100).round();
  return '$withMusic entries include a song ($percentage%)';
}

List<String> getConnections(List<JournalEntry> entries) {
  final connections = <String>[];
  final artistConnection = artistMoodConnection(entries);
  final tagConnection = tagMoodConnection(entries);
  final weekdayConnection = weekdayMoodConnection(entries);

  if (artistConnection != null) connections.add(artistConnection);
  if (tagConnection != null) connections.add(tagConnection);
  if (weekdayConnection != null) connections.add(weekdayConnection);
  return connections;
}

String? artistMoodConnection(List<JournalEntry> entries) {
  final entriesByArtist = <String, List<JournalEntry>>{};
  for (final entry in entries) {
    final artist = entry.song?.artistName ?? '';
    if (artist.isNotEmpty && entry.mood.isNotEmpty) {
      entriesByArtist.putIfAbsent(artist, () => []).add(entry);
    }
  }
  if (entriesByArtist.isEmpty) return null;

  final artists = entriesByArtist.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  final artist = artists.first;
  if (artist.value.length < 3) return null;

  final mood = getTopItem(countMoods(artist.value));
  if (mood == null) return null;
  final emoji = Moods.byLabel(mood)?.emoji ?? '•';
  return '$artist is often paired with $emoji $mood '
      '(${artist.value.length} entries).';
}

String? tagMoodConnection(List<JournalEntry> entries) {
  final entriesByTag = <String, List<JournalEntry>>{};
  for (final entry in entries) {
    if (entry.mood.isEmpty) continue;
    for (final tag in entry.tags) {
      entriesByTag.putIfAbsent(tag, () => []).add(entry);
    }
  }
  if (entriesByTag.isEmpty) return null;

  final tags = entriesByTag.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  final tag = tags.first;
  if (tag.value.length < 3) return null;

  final mood = getTopItem(countMoods(tag.value));
  if (mood == null) return null;
  final emoji = Moods.byLabel(mood)?.emoji ?? '•';
  return 'When you use #${tag.key}, you most often record $emoji $mood.';
}

String? weekdayMoodConnection(List<JournalEntry> entries) {
  final entriesByWeekday = <int, List<JournalEntry>>{};
  for (final entry in entries) {
    if (entry.mood.isNotEmpty) {
      entriesByWeekday.putIfAbsent(entry.date.weekday, () => []).add(entry);
    }
  }
  if (entriesByWeekday.isEmpty) return null;

  final weekdays = entriesByWeekday.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  final weekday = weekdays.first;
  if (weekday.value.length < 3) return null;

  final mood = getTopItem(countMoods(weekday.value));
  if (mood == null) return null;
  final emoji = Moods.byLabel(mood)?.emoji ?? '•';
  return 'On ${weekdayName(weekday.key)}s, you most often record $emoji $mood.';
}

String weekdayName(int weekday) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[weekday - 1];
}

String? compareWithPreviousPeriod(List<JournalEntry> entries, int days) {
  if (days == 0) return null;
  final now = DateTime.now();
  final currentStart = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: days - 1));
  final previousStart = currentStart.subtract(Duration(days: days));
  final currentCount = entries
      .where((entry) => !entry.date.isBefore(currentStart))
      .length;
  final previousCount = entries
      .where((entry) =>
          !entry.date.isBefore(previousStart) && entry.date.isBefore(currentStart))
      .length;
  if (currentCount + previousCount < 3) return null;

  if (currentCount == previousCount) {
    return 'You journaled the same number of times as the previous $days days.';
  }
  final difference = (currentCount - previousCount).abs();
  final direction = currentCount > previousCount ? 'more' : 'fewer';
  return 'You journaled $difference $direction time${difference == 1 ? '' : 's'} '
      'than in the previous $days days.';
}

String? longestReflectionTag(List<JournalEntry> entries) {
  final wordsByTag = <String, List<int>>{};
  for (final entry in entries) {
    final words = entry.note.trim().isEmpty
        ? 0
        : entry.note.trim().split(RegExp(r'\s+')).length;
    for (final tag in entry.tags) {
      wordsByTag.putIfAbsent(tag, () => []).add(words);
    }
  }
  if (wordsByTag.isEmpty) return null;

  final tags = wordsByTag.entries.where((entry) => entry.value.length >= 2).toList();
  if (tags.isEmpty) return null;
  tags.sort((a, b) {
    final averageA = a.value.reduce((x, y) => x + y) / a.value.length;
    final averageB = b.value.reduce((x, y) => x + y) / b.value.length;
    return averageB.compareTo(averageA);
  });
  return tags.first.key;
}

String? musicMood(List<JournalEntry> entries) {
  final musicEntries = entries
      .where((entry) => entry.song != null && entry.mood.isNotEmpty)
      .toList();
  if (musicEntries.length < 3) return null;
  return getTopItem(countMoods(musicEntries));
}

String? getTopItem(Map<String, int> counts) {
  if (counts.isEmpty) return null;
  return sortedItems(counts).first.key;
}

List<MapEntry<String, int>> sortedItems(Map<String, int> counts) {
  final items = counts.entries.toList();
  items.sort((a, b) => b.value.compareTo(a.value));
  return items;
}

List<Mood> sortedMoods(Map<String, int> counts) {
  final moods = Moods.combined.where((mood) => counts.containsKey(mood.label)).toList();
  moods.sort((a, b) => counts[b.label]!.compareTo(counts[a.label]!));
  return moods;
}

String dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

List<int> weeklyCounts(List<JournalEntry> entries) {
  final today = DateTime.now();
  return List.generate(7, (index) {
    final day = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: 6 - index));
    return entries.where((entry) => dateKey(entry.date) == dateKey(day)).length;
  });
}

int currentStreak(List<JournalEntry> entries) {
  final days = entries.map((entry) => dateKey(entry.date)).toSet();
  var day = DateTime.now();
  day = DateTime(day.year, day.month, day.day);
  if (!days.contains(dateKey(day))) day = day.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(dateKey(day))) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

int longestStreak(List<JournalEntry> entries) {
  final days = entries.map((entry) => DateTime(entry.date.year, entry.date.month, entry.date.day)).toSet().toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final day in days) {
    run = previous != null && day.difference(previous).inDays == 1 ? run + 1 : 1;
    if (run > best) best = run;
    previous = day;
  }
  return best;
}

int averageWords(List<JournalEntry> entries) {
  final notes = entries.where((entry) => entry.note.trim().isNotEmpty).toList();
  if (notes.isEmpty) return 0;
  final words = notes.fold(0, (sum, entry) => sum + entry.note.trim().split(RegExp(r'\s+')).length);
  return (words / notes.length).round();
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 3),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
      const SizedBox(height: 4),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
    ]),
  ));
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Section({required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _WeeklyChart extends StatelessWidget {
  final List<int> counts;
  const _WeeklyChart({required this.counts});
  @override
  Widget build(BuildContext context) {
    final max = counts.fold(1, (biggest, count) => count > biggest ? count : biggest);
    final today = DateTime.now();
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SizedBox(height: 104, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(7, (index) {
      final weekday = today.subtract(Duration(days: 6 - index)).weekday;
      return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text(counts[index] == 0 ? '' : '${counts[index]}', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
        const SizedBox(height: 4),
        Container(height: counts[index] == 0 ? 2 : 54 * counts[index] / max, margin: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5))),
        const SizedBox(height: 7),
        Text(names[weekday - 1].substring(0, 1), style: const TextStyle(fontSize: 11, color: AppColors.grey)),
      ]));
    })));
  }
}

class _MoodTimeline extends StatelessWidget {
  final List<JournalEntry> entries;
  final int days;
  final bool showTrend;
  const _MoodTimeline({
    required this.entries,
    required this.days,
    required this.showTrend,
  });

  @override
  Widget build(BuildContext context) {
    if (showTrend) return _MoodTrendChart(entries: entries);

    final today = DateTime.now();
    final dates = List.generate(days, (index) {
      final date = today.subtract(Duration(days: days - 1 - index));
      return DateTime(date.year, date.month, date.day);
    });
    final entriesByDay = <String, JournalEntry>{};
    for (final entry in entries) {
      entriesByDay[dateKey(entry.date)] = entry;
    }

    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: dates
            .map((date) => buildDay(date, entriesByDay[dateKey(date)]))
            .toList(),
      ),
    );
  }

  Widget buildDay(DateTime date, JournalEntry? entry) {
    final mood = Moods.byLabel(entry?.mood);
    final isToday = dateKey(date) == dateKey(DateTime.now());
    return Container(
      width: 48,
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: mood?.color.withValues(alpha: 0.35) ?? AppColors.lightGrey,
        borderRadius: BorderRadius.circular(9),
        border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          shortWeekday(date.weekday),
          style: const TextStyle(fontSize: 10, color: AppColors.grey),
        ),
        const SizedBox(height: 3),
        Text(mood?.emoji ?? '·', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text('${date.day}',
            style: const TextStyle(fontSize: 10, color: AppColors.grey)),
      ]),
    );
  }

  String shortWeekday(int weekday) {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return names[weekday - 1];
  }
}

class _MoodTrendChart extends StatelessWidget {
  final List<JournalEntry> entries;
  const _MoodTrendChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 27));
    final countsByMood = <String, List<int>>{};

    for (final entry in entries) {
      if (entry.mood.isEmpty || entry.date.isBefore(start)) continue;
      final daysFromStart = entry.date.difference(start).inDays;
      final week = daysFromStart ~/ 7;
      if (week < 0 || week > 3) continue;
      countsByMood.putIfAbsent(entry.mood, () => [0, 0, 0, 0]);
      countsByMood[entry.mood]![week]++;
    }

    if (countsByMood.isEmpty) {
      return const _NoData('Add moods to entries to see a weekly trend.');
    }

    final moods = sortedItems({
      for (final item in countsByMood.entries)
        item.key: item.value.fold(0, (sum, count) => sum + count),
    }).take(3).map((item) => item.key).toList();
    var biggestCount = 1;
    for (final mood in moods) {
      for (final count in countsByMood[mood]!) {
        if (count > biggestCount) biggestCount = count;
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 125,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (week) {
            return Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: moods.map((mood) {
                      final count = countsByMood[mood]![week];
                      final color = Moods.byLabel(mood)?.color ?? AppColors.primary;
                      return Container(
                        width: 10,
                        height: count == 0 ? 2 : 74 * count / biggestCount,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Week ${week + 1}',
                    style: const TextStyle(fontSize: 10, color: AppColors.grey)),
              ]),
            );
          }),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 6,
        children: moods.map((mood) {
          final moodData = Moods.byLabel(mood);
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: moodData?.color ?? AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text('${moodData?.emoji ?? '•'} $mood',
                style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          ]);
        }).toList(),
      ),
    ]);
  }
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _SmallStat({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Icon(icon, color: AppColors.primary, size: 19),
    const SizedBox(height: 5),
    Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
    const SizedBox(height: 2),
    Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
  ]));
}

class _MoodRow extends StatelessWidget {
  final Mood mood;
  final int count;
  final int total;
  const _MoodRow({required this.mood, required this.count, required this.total});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('${mood.emoji} ${mood.label}', style: const TextStyle(fontSize: 13, color: AppColors.text))),
        Text('${(count / total * 100).round()}%  ·  $count', style: const TextStyle(fontSize: 12, color: AppColors.grey, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: count / total, minHeight: 8, backgroundColor: AppColors.lightGrey, valueColor: AlwaysStoppedAnimation<Color>(mood.color))),
    ]),
  );
}

class _ExtraInsights extends StatelessWidget {
  final List<JournalEntry> entries;
  final Map<String, int> songs;
  const _ExtraInsights({required this.entries, required this.songs});

  @override
  Widget build(BuildContext context) {
    final moodCount = countMoods(entries).length;
    final reflectiveTag = longestReflectionTag(entries);
    final repeatedSong = getTopItem(songs);
    final musicMoodLabel = musicMood(entries);
    final musicMoodEmoji = Moods.byLabel(musicMoodLabel)?.emoji ?? '•';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        moodCount == 0
            ? 'No moods were recorded in this period yet.'
            : moodCount == 1
                ? 'You recorded 1 mood in this period.'
                : 'You recorded $moodCount different moods in this period.',
        style: const TextStyle(fontSize: 13, color: AppColors.text),
      ),
      if (reflectiveTag != null) ...[
        const SizedBox(height: 10),
        Text('Your longer reflections are often tagged #$reflectiveTag.',
            style: const TextStyle(fontSize: 13, color: AppColors.text)),
      ],
      if (repeatedSong != null && songs[repeatedSong]! >= 2) ...[
        const SizedBox(height: 10),
        Text('You saved $repeatedSong ${songs[repeatedSong]} times.',
            style: const TextStyle(fontSize: 13, color: AppColors.text)),
      ],
      if (musicMoodLabel != null) ...[
        const SizedBox(height: 10),
        Text('When you attach music, you most often record '
            '$musicMoodEmoji $musicMoodLabel.',
            style: const TextStyle(fontSize: 13, color: AppColors.text)),
      ],
    ]);
  }
}

class _PatternCard extends StatelessWidget {
  final String text;
  const _PatternCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(18)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('A small pattern', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.35)),
      ])),
    ]),
  );
}

class _ComparisonCard extends StatelessWidget {
  final String text;
  const _ComparisonCard({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.text, height: 1.35)),
            ),
          ],
        ),
      );
}

class _NoData extends StatelessWidget {
  final String text;
  const _NoData(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 13, color: AppColors.grey, height: 1.4));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(
    padding: EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.insights_rounded, size: 42, color: AppColors.primary),
      SizedBox(height: 14),
      Text('Your patterns will grow here.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
      SizedBox(height: 6),
      Text('Add a few entries to see your moods, journaling rhythm, and music habits.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey, fontSize: 14, height: 1.45)),
    ]),
  ));
}
