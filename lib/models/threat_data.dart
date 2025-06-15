class ThreatData {
  final double threatLevel;
  final DateTime timestamp;
  final String primaryThreat;
  final Map<String, double> regionalScores;
  final List<String> keyFactors;

  ThreatData({
    required this.threatLevel,
    required this.timestamp,
    required this.primaryThreat,
    required this.regionalScores,
    required this.keyFactors,
  });

  factory ThreatData.fromMap(Map<String, dynamic> map) {
    return ThreatData(
      threatLevel: map['threatLevel']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      primaryThreat: map['primaryThreat'] ?? '',
      regionalScores: Map<String, double>.from(map['regionalScores'] ?? {}),
      keyFactors: List<String>.from(map['keyFactors'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'threatLevel': threatLevel,
      'timestamp': timestamp.toIso8601String(),
      'primaryThreat': primaryThreat,
      'regionalScores': regionalScores,
      'keyFactors': keyFactors,
    };
  }
}