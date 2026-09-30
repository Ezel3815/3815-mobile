import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/widgets/streak/streak_reward_screen.dart';
import 'package:upgrade/widgets/streak/streak_week.dart';

void main() {
  // Wednesday 30 Sep 2026 (UTC) -> Sunday-first index 3.
  final wed = DateTime.utc(2026, 9, 30, 10);

  group('completedWeekDays', () {
    test('day 1 (fresh / reset) only marks today', () {
      expect(completedWeekDays(streak: 1, nowUtc: wed),
          [false, false, false, true, false, false, false]);
    });

    test('streak of 2 marks yesterday and today', () {
      expect(completedWeekDays(streak: 2, nowUtc: wed),
          [false, false, true, true, false, false, false]);
    });

    test('long streak fills the week up to today, never future days', () {
      expect(completedWeekDays(streak: 356, nowUtc: wed),
          [true, true, true, true, false, false, false]);
    });

    test('on Sunday only Sunday can be complete', () {
      final sun = DateTime.utc(2026, 9, 27, 8);
      expect(completedWeekDays(streak: 40, nowUtc: sun),
          [true, false, false, false, false, false, false]);
    });

    test('on Saturday a 7+ streak fills the whole week', () {
      final sat = DateTime.utc(2026, 10, 3, 23);
      expect(completedWeekDays(streak: 7, nowUtc: sat), everyElement(true));
    });
  });

  test('arabicDays grammar', () {
    expect(arabicDays(1), 'يوم واحد');
    expect(arabicDays(2), 'يومان');
    expect(arabicDays(5), '5 أيام');
    expect(arabicDays(356), '356 يومًا');
  });

  testWidgets('streak window shows the real streak and the CTA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: StreakRewardScreen(streak: 356, nowUtc: wed)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 5)); // idle loop never settles
    expect(find.text('356'), findsOneWidget);
    expect(find.text('يمكنني فعلها!'), findsOneWidget);
  });

  testWidgets('a reset streak shows the real value 1, not the old number',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: StreakRewardScreen(streak: 1, nowUtc: wed)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('356'), findsNothing);
  });
}
