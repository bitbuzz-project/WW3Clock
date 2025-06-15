import 'historical_threat_data.dart';

class ThreatTrend {
  final double currentLevel;
  final double previousLevel;
  final double changePercent;
  final String changeDirection;
  final DateTime comparisonPeriod;
  final List<HistoricalThreatData> historicalData;

  ThreatTrend({
    required this.currentLevel,
    required this.previousLevel,
    required this.changePercent,
    required this.changeDirection,
    required this.comparisonPeriod,
    required this.historicalData,
  });

  String get formattedChangePercent {
    String sign = changePercent >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(1)}%';
  }
}