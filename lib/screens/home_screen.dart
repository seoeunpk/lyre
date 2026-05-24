import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';
import 'new_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime month = DateTime.now();
  final DateTime today = DateTime.now();

  void showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                title: const Text("Change Account",
                    style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService().signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              ListTile(
                title: const Text("Log Out",
                    style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService().signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openEntry(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewEntryScreen(date: date)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: buildBottomBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildMonthHeader(),
            buildWeekdayLabels(),
            Expanded(child: buildCalendarGrid()),
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

  Widget buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: prevMonth,
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.grey),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
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
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget buildWeekdayLabels() {
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

  Widget buildCalendarGrid() {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;
    final totalCells = ((startOffset + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.82,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNum = index - startOffset + 1;
        if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();
        final date =
            DateTime(month.year, month.month, dayNum);
        final isToday = isSameDay(date, today);
        return buildDayCell(date, dayNum, isToday);
      },
    );
  }

  Widget buildDayCell(DateTime date, int dayNum, bool isToday) {
    return GestureDetector(
      onTap: () => openEntry(date),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppColors.lightGrey,
              border: isToday
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),

          ),
          const SizedBox(height: 4),
          Text(
            "$dayNum",
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              color: isToday ? AppColors.text : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomBar() {
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
            onPressed: () {},
            icon: const Icon(Icons.bar_chart_rounded,
                color: AppColors.grey),
          ),
          GestureDetector(
            onTap: () => openEntry(today),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text("+",
                    style: TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.w300)),
              ),
            ),
          ),
          IconButton(
            onPressed: showProfileMenu,
            icon: const Icon(Icons.person_outline_rounded,
                color: AppColors.grey),
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
