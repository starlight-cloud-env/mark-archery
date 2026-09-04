class ScorecardTemplate {
  final String id;
  final String name;
  final int ends;
  final int arrowsPerEnd;
  final int maxScore;

  const ScorecardTemplate({
    required this.id,
    required this.name,
    required this.ends,
    required this.arrowsPerEnd,
    required this.maxScore,
  });

  factory ScorecardTemplate.fromJson(Map<String, dynamic> json) {
    return ScorecardTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      ends: json['ends'] as int,
      arrowsPerEnd: json['arrows_per_end'] as int,
      maxScore: json['max_score'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ends': ends,
      'arrows_per_end': arrowsPerEnd,
      'max_score': maxScore,
    };
  }
}