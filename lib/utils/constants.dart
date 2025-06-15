class AppConstants {
  // App Info
  static const String appName = 'WW3 Clock';
  static const String appVersion = '1.0.0';
  
  // Threat Levels
  static const double lowThreatThreshold = 30.0;
  static const double mediumThreatThreshold = 60.0;
  static const double highThreatThreshold = 80.0;
  
  // Update Intervals
  static const Duration newsUpdateInterval = Duration(hours: 1);
  static const Duration threatCalculationInterval = Duration(minutes: 30);
  
  // API Endpoints (we'll add these when we set up APIs)
  static const String newsApiKey = 'YOUR_NEWS_API_KEY';
  static const String newsApiUrl = 'https://newsapi.org/v2';
  
  // Firestore Collections
  static const String threatDataCollection = 'threat_data';
  static const String newsCollection = 'news_items';
  static const String settingsCollection = 'settings';
  
  // World Regions
  static const Map<String, String> worldRegions = {
    'North America': 'NA',
    'Europe': 'EU',
    'Asia': 'AS',
    'Middle East': 'ME',
    'Africa': 'AF',
    'South America': 'SA',
    'Oceania': 'OC',
  };
}