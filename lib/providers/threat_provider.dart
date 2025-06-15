import 'package:flutter/foundation.dart';
import '../models/threat_data.dart';
import '../services/threat_calculator.dart'; // Updated import
import '../services/news_api_service.dart';

class ThreatProvider extends ChangeNotifier {
  ThreatData? _currentThreatData;
  bool _isLoading = false;
  String? _error;

  ThreatData? get currentThreatData => _currentThreatData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadThreatData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch latest news
      final newsItems = await NewsApiService.fetchAllNews();
      
      // Calculate threat level using improved calculator
     _currentThreatData = await AIThreatCalculator.calculateThreatLevel(newsItems);

      
    } catch (e) {
      _error = e.toString();
      print('Error loading threat data: $e');
      
      // Fallback to default data if API fails
      _currentThreatData = ThreatData(
        threatLevel: 25.0, // Updated default level
        timestamp: DateTime.now(),
        primaryThreat: 'Monitoring (API Error)',
        regionalScores: {
          'Global': 25.0,
        },
        keyFactors: ['Check connection'],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get threat level description with updated thresholds
  String get threatLevelDescription {
    if (_currentThreatData == null) return 'Unknown';
    
    final level = _currentThreatData!.threatLevel;
    if (level < 25) return 'Low Threat';
    if (level < 40) return 'Moderate Threat';
    if (level < 60) return 'High Threat';
    if (level < 75) return 'Severe Threat';
    return 'Critical Threat';
  }
}