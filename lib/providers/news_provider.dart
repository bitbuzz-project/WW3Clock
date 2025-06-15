import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import '../services/news_api_service.dart';

class NewsProvider extends ChangeNotifier {
  List<NewsItem> _newsItems = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  List<NewsItem> get newsItems => _newsItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> loadNews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _newsItems = await NewsApiService.fetchAllNews();
      _lastUpdated = DateTime.now();
    } catch (e) {
      _error = e.toString();
      print('Error loading news: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get high threat articles (score > 50)
  List<NewsItem> get highThreatNews {
    return _newsItems.where((item) => item.threatScore > 50).toList();
  }

  // Get recent articles (last 24 hours)
  List<NewsItem> get recentNews {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _newsItems.where((item) => item.publishedAt.isAfter(yesterday)).toList();
  }
}