import 'package:upgrade/entity/leaderboard_entry.dart';

/// Pure helpers for the Mossad screen (no Flutter imports, easy to unit test).
/// They never re-order the server list: the API already sorts by XP desc
/// (ties by id asc) and returns each row's real rank.

/// 4820 -> "4,820".
String mossadFormatXp(int xp) {
  final s = xp.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return xp < 0 ? '-$buf' : buf.toString();
}

/// The server rank wins; otherwise fall back to the 1-based list position.
int mossadRankOf(LeaderboardEntry entry, int index) => entry.rank ?? index + 1;

LeaderboardEntry? mossadMyEntry(List<LeaderboardEntry> entries) {
  for (final e in entries) {
    if (e.isMe) return e;
  }
  return null;
}

/// True when rows [index - 1] and [index] are not consecutive ranks, e.g. the
/// top 50 followed by the signed-in user at rank 812.
bool mossadHasGapBefore(List<LeaderboardEntry> entries, int index) {
  if (index <= 0 || index >= entries.length) return false;
  final prev = mossadRankOf(entries[index - 1], index - 1);
  final cur = mossadRankOf(entries[index], index);
  return cur - prev > 1;
}

/// XP needed to reach the student directly above the signed-in user, or null
/// when that student is not part of the returned list (or the user is 1st).
int? mossadXpGapToNext(List<LeaderboardEntry> entries) {
  final i = entries.indexWhere((e) => e.isMe);
  if (i <= 0) return null;
  if (mossadHasGapBefore(entries, i)) return null;
  final gap = entries[i - 1].xp - entries[i].xp;
  return gap < 0 ? 0 : gap;
}

/// The signed-in user's row plus the directly adjacent ranks that are present
/// in the list (used by the "ترتيبي" segment).
List<LeaderboardEntry> mossadNeighbors(List<LeaderboardEntry> entries) {
  final i = entries.indexWhere((e) => e.isMe);
  if (i < 0) return <LeaderboardEntry>[];
  final out = <LeaderboardEntry>[];
  if (i > 0 && !mossadHasGapBefore(entries, i)) out.add(entries[i - 1]);
  out.add(entries[i]);
  if (i < entries.length - 1 && !mossadHasGapBefore(entries, i + 1)) {
    out.add(entries[i + 1]);
  }
  return out;
}
