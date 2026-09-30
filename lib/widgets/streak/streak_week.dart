/// Pure helpers for the standalone Streak Reward window. No Flutter imports so
/// they are trivially unit-testable.

/// Which days of the current Sunday-first week are part of the streak.
///
/// The backend defines a streak as consecutive UTC calendar days ending on the
/// day it was last saved (see updateStreak in decks-cards.service.ts). When the
/// window opens the streak has just been saved for *today*, so the completed
/// days are today and the (streak - 1) days before it, clipped to this week.
/// Nothing here is guessed: it is derived only from the authoritative streak.
List<bool> completedWeekDays({required int streak, required DateTime nowUtc}) {
  final u = nowUtc.toUtc();
  final todayIndex = DateTime.utc(u.year, u.month, u.day).weekday % 7; // Sun = 0
  return List<bool>.generate(7, (i) {
    final daysAgo = todayIndex - i;
    if (daysAgo < 0) return false; // future day this week
    return daysAgo < streak;
  });
}

/// Index (Sunday = 0) of today in the Sunday-first week, in UTC.
int todayWeekIndex(DateTime nowUtc) {
  final u = nowUtc.toUtc();
  return DateTime.utc(u.year, u.month, u.day).weekday % 7;
}

/// Arabic day count with correct grammatical number.
String arabicDays(int n) {
  if (n == 1) return 'يوم واحد';
  if (n == 2) return 'يومان';
  if (n >= 3 && n <= 10) return '$n أيام';
  return '$n يومًا';
}

const List<String> weekDayLabelsAr = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];
