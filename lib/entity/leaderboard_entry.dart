class LeaderboardEntry {
  final int id;
  final String name;
  final String? username;
  final String? avatarHair;
  final int xp;
  final int level;
  final bool isMe;
  /// Server-side position (Mossad only; null for the friends leaderboard).
  final int? rank;

  LeaderboardEntry({
    required this.id,
    required this.name,
    this.username,
    this.avatarHair,
    required this.xp,
    required this.level,
    required this.isMe,
    this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'],
      avatarHair: json['avatar_hair'],
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      isMe: json['isMe'] ?? false,
      rank: json['rank'],
    );
  }

  String? get avatarPhotoName => avatarHair;
}

/// The "Mossad" competition: every preparatory-year student, ranked by XP.
class MossadData {
  final bool inMossad; // is the signed-in user part of the competition?
  final int total;
  final List<LeaderboardEntry> entries;
  const MossadData({required this.inMossad, required this.total, required this.entries});

  factory MossadData.fromJson(Map<String, dynamic> json) => MossadData(
        inMossad: json['in_mossad'] ?? false,
        total: json['total'] ?? 0,
        entries: ((json['entries'] ?? []) as List)
            .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
