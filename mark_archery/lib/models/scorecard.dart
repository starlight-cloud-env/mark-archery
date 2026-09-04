enum ScorecardStatus { active, completed }

class Scorecard {
  final String id;
  final String archerId;
  final String name;
  final int arrowsPerEnd;
  final int maxScore;
  final ScorecardStatus status;
  final DateTime startedAt;
  final List<List<int?>> ends;

  const Scorecard({
    required this.id,
    required this.archerId,
    required this.name,
    required this.arrowsPerEnd,
    required this.maxScore,
    required this.status,
    required this.startedAt,
    required this.ends,
  });

  int get totalEnds => ends.length;

  int endTotal(int endIndex) {
    return ends[endIndex].fold(0, (sum, score) => sum + (score ?? 0));
  }

  int get runningTotal {
    return ends.expand((end) => end).fold(0, (sum, score) => sum + (score ?? 0));
  }

  int get maxPossible => totalEnds * arrowsPerEnd * maxScore;

  ({int end, int arrow})? get nextEmptySlot {
    for (int e = 0; e < ends.length; e++) {
      for (int a = 0; a < ends[e].length; a++) {
        if (ends[e][a] == null) {
          return (end: e, arrow: a);
        }
      }
    }
    return null;
  }

  factory Scorecard.fromJson(Map<String, dynamic> json) {
    return Scorecard(
      id: json['id'] as String,
      archerId: json['archer_id'] as String,
      name: json['name'] as String,
      arrowsPerEnd: json['arrows_per_end'] as int,
      maxScore: json['max_score'] as int,
      status: ScorecardStatus.values.byName(json['status'] as String),
      startedAt: DateTime.parse(json['started_at'] as String),
      ends: (json['ends'] as List)
          .map((end) => (end as List).map((score) => score as int?).toList())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'archer_id': archerId,
      'name': name,
      'arrows_per_end': arrowsPerEnd,
      'max_score': maxScore,
      'status': status.name,
      'started_at': startedAt.toIso8601String(),
      'ends': ends,
    };
  }
}