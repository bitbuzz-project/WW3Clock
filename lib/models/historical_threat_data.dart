class HistoricalThreatData {
  final double threatLevel;
  final DateTime timestamp;
  final String primaryThreat;
  final Map<String, double> categoryScores;
  final Map<String, double> regionalScores;

  HistoricalThreatData({
    required this.threatLevel,
    required this.timestamp,
    required this.primaryThreat,
    required this.categoryScores,
    required this.regionalScores,
  });

  factory HistoricalThreatData.fromMap(Map<String, dynamic> map) {
    return HistoricalThreatData(
      threatLevel: map['threatLevel']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      primaryThreat: map['primaryThreat'] ?? '',
      categoryScores: Map<String, double>.from(map['categoryScores'] ?? {}),
      regionalScores: Map<String, double>.from(map['regionalScores'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'threatLevel': threatLevel,
      'timestamp': timestamp.toIso8601String(),
      'primaryThreat': primaryThreat,
      'categoryScores': categoryScores,
      'regionalScores': regionalScores,
    };
  }
}