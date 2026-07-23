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
    final journal = JournalService();

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
          "Insights",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: uid == null ? null : journal.getEntries(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final entries = snapshot.data ?? const <JournalEntry>[];
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "No entries yet.\nAdd a few to start seeing patterns.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.grey, fontSize: 14, height: 1.5),
                ),
              ),
            );
          }
          return _InsightsBody(entries: entries);
        },
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  final List<JournalEntry> entries;
  const _InsightsBody({required this.entries});

  @override
  Widget build(BuildContext context) {
    final moodCounts = <String, int>{};
    final artistCounts = <String, int>{};
    final songCounts = <String, int>{};
    final tagCounts = <String, int>{};

    for (final e in entries) {
      if (e.mood.isNotEmpty) {
        moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
      }
      final s = e.song;
      if (s != null) {
        if (s.artistName.isNotEmpty) {
          artistCounts[s.artistName] = (artistCounts[s.artistName] ?? 0) + 1;
        }
        if (s.trackName.isNotEmpty) {
          final key = "${s.trackName} - ${s.artistName}";
          songCounts[key] = (songCounts[key] ?? 0) + 1;
        }
      }
      for (final t in e.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }

    final topMood = _topKey(moodCounts);
    final streak = _currentStreak(entries);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatTile(value: "${entries.length}", label: "Entries"),
              const SizedBox(width: 12),
              _StatTile(value: "$streak", label: "Day streak"),
              const SizedBox(width: 12),
              _StatTile(
                value: topMood != null
                    ? (Moods.byLabel(topMood)?.emoji ?? "-")
                    : "-",
                label: "Top mood",
              ),
            ],
          ),
          const SizedBox(height: 20),

          _Section(
            title: "Mood trends",
            child: moodCounts.isEmpty
                ? const _NoData()
                : _buildMoodBars(moodCounts, entries.length),
          ),
          const SizedBox(height: 20),

          _Section(
            title: "Top artists",
            child: _RankedList(counts: artistCounts, emptyLabel: "No songs yet"),
          ),
          const SizedBox(height: 20),

          _Section(
            title: "Top songs",
            child: _RankedList(counts: songCounts, emptyLabel: "No songs yet"),
          ),
          const SizedBox(height: 20),

          _Section(
            title: "Most-used tags",
            child: tagCounts.isEmpty
                ? const _NoData()
                : _buildTagWrap(tagCounts),
          ),
        ],
      ),
    );
  }

  static Widget _buildMoodBars(Map<String, int> moodCounts, int total) {
    final bars = <Widget>[];
    for (final m in Moods.all) {
      if ((moodCounts[m.label] ?? 0) > 0) {
        bars.add(_BarRow(
          label: "${m.emoji} ${m.label}",
          count: moodCounts[m.label]!,
          total: total,
          color: m.color,
        ));
      }
    }
    return Column(children: bars);
  }

  static Widget _buildTagWrap(Map<String, int> tagCounts) {
    final sorted = tagCounts.entries.toList();
    sorted.sort((a, b) => b.value.compareTo(a.value));
    final chips = <Widget>[];
    for (final tag in sorted) {
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.pink.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          "#${tag.key}  ${tag.value}",
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  static String? _topKey(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    String? topKey;
    int topCount = 0;
    for (final entry in counts.entries) {
      if (entry.value >= topCount) {
        topCount = entry.value;
        topKey = entry.key;
      }
    }
    return topKey;
  }

  static int _currentStreak(List<JournalEntry> entries) {
    final days = <String>{};
    for (final e in entries) {
      days.add("${e.date.year}-${e.date.month}-${e.date.day}");
    }
    int streak = 0;
    var day = DateTime.now();
    while (days.contains("${day.year}-${day.month}-${day.day}")) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _BarRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: AppColors.text),
                ),
              ),
              Text(
                "$count",
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.lightGrey,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedList extends StatelessWidget {
  final Map<String, int> counts;
  final String emptyLabel;
  const _RankedList({required this.counts, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return _NoData(label: emptyLabel);
    final sorted = counts.entries.toList();
    sorted.sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Column(
      children: List.generate(top.length, (i) {
        final e = top[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${i + 1}",
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.key,
                  style: const TextStyle(fontSize: 13, color: AppColors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "${e.value}×",
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _NoData extends StatelessWidget {
  final String label;
  const _NoData({this.label = "No data yet"});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, color: AppColors.grey),
    );
  }
}
