import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/entity/leaderboard_entry.dart';
import 'package:upgrade/widgets/mossad/mossad_logic.dart';

LeaderboardEntry _e(int id, int xp, int rank, {bool me = false}) =>
    LeaderboardEntry(
      id: id,
      name: 'user$id',
      xp: xp,
      level: 1,
      isMe: me,
      rank: rank,
    );

void main() {
  group('mossadFormatXp', () {
    test('adds thousands separators', () {
      expect(mossadFormatXp(0), '0');
      expect(mossadFormatXp(999), '999');
      expect(mossadFormatXp(4820), '4,820');
      expect(mossadFormatXp(1234567), '1,234,567');
    });
  });

  group('MossadData.fromJson', () {
    test('keeps server order, rank and total', () {
      final data = MossadData.fromJson({
        'in_mossad': true,
        'total': 3,
        'entries': [
          {'id': 2, 'name': 'b', 'xp': 90, 'level': 2, 'isMe': false, 'rank': 1},
          {'id': 1, 'name': 'a', 'xp': 50, 'level': 1, 'isMe': true, 'rank': 2},
          {'id': 3, 'name': 'c', 'xp': 10, 'level': 1, 'isMe': false, 'rank': 3},
        ],
      });
      expect(data.inMossad, isTrue);
      expect(data.total, 3);
      expect(data.entries.map((e) => e.id), [2, 1, 3]);
      expect(data.entries.map((e) => e.rank), [1, 2, 3]);
      expect(data.entries.map((e) => e.xp), [90, 50, 10]);
    });
  });

  group('rank helpers', () {
    test('server rank wins, position is the fallback', () {
      expect(mossadRankOf(_e(1, 5, 812), 50), 812);
      final noRank = LeaderboardEntry(
          id: 1, name: 'x', xp: 1, level: 1, isMe: false);
      expect(mossadRankOf(noRank, 4), 5);
    });

    test('gap divider appears only for non-consecutive ranks', () {
      final list = [_e(1, 90, 1), _e(2, 80, 2), _e(9, 5, 812, me: true)];
      expect(mossadHasGapBefore(list, 0), isFalse);
      expect(mossadHasGapBefore(list, 1), isFalse);
      expect(mossadHasGapBefore(list, 2), isTrue);
    });

    test('xp gap to the student above', () {
      final list = [_e(1, 90, 1), _e(2, 80, 2, me: true), _e(3, 70, 3)];
      expect(mossadXpGapToNext(list), 10);
    });

    test('no xp gap for 1st place or when the row above is not listed', () {
      expect(mossadXpGapToNext([_e(1, 90, 1, me: true), _e(2, 80, 2)]), isNull);
      expect(
          mossadXpGapToNext([_e(1, 90, 1), _e(9, 5, 812, me: true)]), isNull);
    });

    test('neighbors are the contiguous rows around me', () {
      final list = [_e(1, 90, 1), _e(2, 80, 2, me: true), _e(3, 70, 3)];
      expect(mossadNeighbors(list).map((e) => e.id), [1, 2, 3]);

      final far = [_e(1, 90, 1), _e(9, 5, 812, me: true)];
      expect(mossadNeighbors(far).map((e) => e.id), [9]);

      expect(mossadNeighbors([_e(1, 90, 1)]), isEmpty);
      expect(mossadMyEntry([_e(1, 90, 1)]), isNull);
    });
  });
}
