import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'history_screen.dart';
import 'insights_screen.dart';
import 'new_entry_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime month = DateTime.now();
  final DateTime today = DateTime.now();

  void openEntry(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewEntryScreen(date: date)),
    );
  }

  Stream<Map<String, String>> _entriesStream() {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return Stream.value({});
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .snapshots()
        .map((snapshot) {
      final map = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final songData = data['song'] as Map<String, dynamic>?;
        map[doc.id] = songData?['albumArtUrl'] as String? ?? '';
      }
      return map;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _bottomBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _monthHeader(),
            _weekdayLabels(),
            Expanded(
              child: StreamBuilder<Map<String, String>>(
                stream: _entriesStream(),
                builder: (context, snapshot) {
                  return _calendarGrid(snapshot.data ?? {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void prevMonth() {
    setState(() {
      month = DateTime(month.year, month.month - 1);
    });
  }

  void nextMonth() {
    setState(() {
      month = DateTime(month.year, month.month + 1);
    });
  }

  Widget _monthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
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

  Widget _calendarGrid(Map<String, String> entries) {
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
        final docId =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final albumArtUrl = entries[docId];
        return _dayCell(date, dayNum, isToday, albumArtUrl);
      },
    );
  }

  Widget _dayCell(DateTime date, int dayNum, bool isToday, String? albumArtUrl) {
    final isFuture = date.isAfter(today);
    return GestureDetector(
      onTap: isFuture
          ? () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("You can't write a journal for a future date.",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.all(16),
                ),
              )
          : () => openEntry(date),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppColors.lightGrey,
              image: albumArtUrl != null && albumArtUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(albumArtUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
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

  Widget _bottomBar() {
    return BottomAppBar(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.calendar_month_rounded,
                color: AppColors.primary),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InsightsScreen()),
            ),
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.grey),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            icon: const Icon(Icons.history_rounded, color: AppColors.grey),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.grey),
          ),
        ],
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