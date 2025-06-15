import 'package:flutter/foundation.dart';
import '../models/threat_data.dart';
import '../services/threat_calculator.dart';
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
      
      // Calculate threat level based on news
      _currentThreatData = ThreatCalculator.calculateThreatLevel(newsItems);
      
    } catch (e) {
      _error = e.toString();
      print('Error loading threat data: $e');
      
      // Fallback to default data if API fails
      _currentThreatData = ThreatData(
        threatLevel: 30.0,
        timestamp: DateTime.now(),
        primaryThreat: 'Monitoring (API Error)',
        regionalScores: {},
        keyFactors: ['Check connection'],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get threat level description
  String get threatLevelDescription {
    if (_currentThreatData == null) return 'Unknown';
    
    final level = _currentThreatData!.threatLevel;
    if (level < 30) return 'Low Threat';
    if (level < 50) return 'Moderate Threat';
    if (level < 70) return 'High Threat';
    if (level < 85) return 'Severe Threat';
    return 'Critical Threat';
  }
}