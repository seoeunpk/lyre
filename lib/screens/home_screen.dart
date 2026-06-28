import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../services/auth_service.dart';
import '../services/journal_service.dart';
import '../utils/app_colors.dart';
import '../utils/animated_snackbar.dart';
import 'history_screen.dart';
import 'insights_screen.dart';
import 'new_entry_screen.dart';
import 'profile_screen.dart';
import '../services/mood_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _journal = JournalService();
  DateTime month = DateTime.now();
  final DateTime today = DateTime.now();

  bool _yearView = false;
  int _collageYear = DateTime.now().year;
  bool _collageMoodMode = true;

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadCustomMoods();
  }

  Future<void> _loadCustomMoods() async {
    final uid = _uid;
    if (uid == null) return;
    final moods = await MoodService().getCustomMoods(uid);
    Moods.custom = moods;
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void openEntry(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewEntryScreen(date: date)),
    );
  }

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  void openInsights() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InsightsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _bottomBar(),
      body: SafeArea(
        child: StreamBuilder<List<JournalEntry>>(
          stream: _uid == null ? null : _journal.getEntries(_uid!),
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <JournalEntry>[];
            final entryByDay = <String, JournalEntry>{};
            for (final e in all) {
              entryByDay[_key(e.date)] = e;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                if (_yearView)
                  _yearModeRow()
                else
                  _weekdayLabels(),
                Expanded(
                  child: _yearView
                      ? _buildYearCollage(all)
                      : buildCalendarGrid(entryByDay),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _key(DateTime d) => "${d.year}-${d.month}-${d.day}";

  void prevMonth() => setState(() => month = DateTime(month.year, month.month - 1));
  void nextMonth() => setState(() => month = DateTime(month.year, month.month + 1));
  void _prevYear() => setState(() {
        _collageYear--;
        month = DateTime(_collageYear, month.month);
      });
  void _nextYear() {
    if (_collageYear >= today.year) return;
    setState(() {
      _collageYear++;
      month = DateTime(_collageYear, month.month);
    });
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Title — always perfectly centered
          Text(
            _yearView
                ? '$_collageYear'
                : '${monthName(month.month)} ${month.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          // Controls pinned to the edges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _yearView ? _prevYear : prevMonth,
                icon: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.grey),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _yearView = !_yearView),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _yearView
                            ? Icons.calendar_month_rounded
                            : Icons.grid_view_rounded,
                        color: AppColors.grey,
                        size: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _yearView ? _nextYear : nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // tiny mood · albums text row, right-aligned above the year grid
  Widget _yearModeRow() {
    textBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.text : AppColors.grey,
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          textBtn('mood', _collageMoodMode,
              () => setState(() => _collageMoodMode = true)),
          const Text('  ·  ',
              style: TextStyle(fontSize: 11, color: AppColors.grey)),
          textBtn('albums', !_collageMoodMode,
              () => setState(() => _collageMoodMode = false)),
        ],
      ),
    );
  }

  // ── Month calendar ──────────────────────────────────────────────────────────

  Widget _weekdayLabels() {
    const labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: labels
            .map((l) => Expanded(
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
                ))
            .toList(),
      ),
    );
  }

  Widget buildCalendarGrid(Map<String, JournalEntry> entryByDay) {
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
        return buildDayCell(date, dayNum, isToday, entry);
      },
    );
  }

  Widget buildDayCell(DateTime date, int dayNum, bool isToday, JournalEntry? entry) {
    final isFuture = date.isAfter(today);
    final moodData = Moods.byLabel(entry?.mood);
    final moodColor = moodData?.color;
    final albumArt = entry?.song?.albumArtUrl;
    final hasArt = albumArt != null && albumArt.isNotEmpty;
    final glowColor = moodColor ?? (isToday ? AppColors.primary : null);

    return GestureDetector(
      onTap: isFuture
          ? () => showAnimatedSnackBar(context, "Can't add an entry for a future date.", isError: true)
          : () => openEntry(date),
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
                  : (moodColor?.withValues(alpha: 0.35) ?? AppColors.lightGrey),
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
            child: (!hasArt && moodData != null)
                ? Text(moodData.emoji, style: const TextStyle(fontSize: 16))
                : null,
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

  // ── Year collage ────────────────────────────────────────────────────────────

  Widget _buildYearCollage(List<JournalEntry> all) {
    final entryMap = <String, JournalEntry>{};
    for (final e in all) {
      if (e.date.year == _collageYear) {
        entryMap['${e.date.month}-${e.date.day}'] = e;
      }
    }
    final totalDays = DateTime(_collageYear + 1, 1, 1)
        .difference(DateTime(_collageYear, 1, 1))
        .inDays;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: LayoutBuilder(builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const gap = 1.0;

        int nCols = 20;
        for (int n = 5; n <= 60; n++) {
          final cs = (w - gap * (n + 1)) / n;
          final rows = (totalDays / n).ceil();
          if (rows * cs + gap * (rows + 1) <= h) {
            nCols = n;
            break;
          }
        }
        final cellSize = (w - gap * (nCols + 1)) / nCols;
        final nRows = (totalDays / nCols).ceil();
        final gridH = nRows * cellSize + gap * (nRows + 1);

        return ClipRect(
          child: SizedBox(
            width: w,
            height: h,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: w,
                height: gridH,
                color: AppColors.border,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(nRows, (ri) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(gap, gap, 0, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(nCols, (ci) {
                          final dayIndex = ri * nCols + ci;
                          if (dayIndex >= totalDays) {
                            return Padding(
                              padding: EdgeInsets.only(right: gap),
                              child: SizedBox(width: cellSize, height: cellSize),
                            );
                          }
                          final date = DateTime(_collageYear, 1, dayIndex + 1);
                          final isFuture = date.isAfter(today);
                          final isToday = isSameDay(date, today);
                          final key = '${date.month}-${date.day}';
                          final entry = entryMap[key];
                          final albumArt = entry?.song?.albumArtUrl ?? '';
                          final hasArt = albumArt.isNotEmpty;
                          final mood = Moods.byLabel(entry?.mood);
                          final showArt = hasArt && !_collageMoodMode;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _yearView = false;
                                month = DateTime(_collageYear, date.month, 1);
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.only(right: gap),
                              child: SizedBox(
                                width: cellSize,
                                height: cellSize,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isFuture
                                            ? AppColors.background.withValues(alpha: 0.4)
                                            : showArt
                                                ? null
                                                : (mood != null
                                                    ? mood.color.withValues(alpha: 0.5)
                                                    : AppColors.background),
                                        image: showArt
                                            ? DecorationImage(
                                                image: NetworkImage(albumArt),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _bottomBar() {
    return BottomAppBar(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary),
            ),
            IconButton(
              onPressed: openHistory,
              icon: const Icon(Icons.history_rounded, color: AppColors.grey),
            ),
            GestureDetector(
              onTap: () => openEntry(today),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.text.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text("+",
                      style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w400)),
                ),
              ),
            ),
            IconButton(
              onPressed: openInsights,
              icon: const Icon(Icons.bar_chart_rounded, color: AppColors.grey),
            ),
            IconButton(
              onPressed: openProfile,
              icon: const Icon(Icons.person_outline_rounded, color: AppColors.grey),
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
