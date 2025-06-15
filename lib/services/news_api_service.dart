import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_item.dart';
import '../config/api_keys.dart';

class NewsApiService {
  
  // Fetch news from NewsAPI
  static Future<List<NewsItem>> fetchNewsApiArticles() async {
    try {
      final url = Uri.parse(
        '${ApiKeys.newsApiUrl}/everything?q=war OR conflict OR nuclear OR tension OR military OR diplomacy OR sanctions OR treaty&language=en&sortBy=publishedAt&apiKey=${ApiKeys.newsApiKey}'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        
        return articles.map((article) => NewsItem(
          id: article['url'].hashCode.toString(),
          title: article['title'] ?? '',
          description: article['description'] ?? '',
          url: article['url'] ?? '',
          source: article['source']['name'] ?? '',
          publishedAt: DateTime.parse(article['publishedAt']),
          threatScore: _calculateThreatScore(article['title'], article['description']),
          keywords: _extractKeywords(article['title'], article['description']),
          imageUrl: article['urlToImage'],
        )).toList();
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching NewsAPI articles: $e');
      return [];
    }
  }
  
  // Fetch news from GNews
  static Future<List<NewsItem>> fetchGNewsArticles() async {
    try {
      final url = Uri.parse(
        '${ApiKeys.gNewsApiUrl}/search?q=war OR conflict OR nuclear OR tension&lang=en&country=us&max=10&apikey=${ApiKeys.gNewsApiKey}'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        
        return articles.map((article) => NewsItem(
          id: article['url'].hashCode.toString(),
          title: article['title'] ?? '',
          description: article['description'] ?? '',
          url: article['url'] ?? '',
          source: article['source']['name'] ?? '',
          publishedAt: DateTime.parse(article['publishedAt']),
          threatScore: _calculateThreatScore(article['title'], article['description']),
          keywords: _extractKeywords(article['title'], article['description']),
          imageUrl: article['image'],
        )).toList();
      } else {
        throw Exception('Failed to load GNews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching GNews articles: $e');
      return [];
    }
  }
  
  // Simple threat score calculation based on keywords
  static double _calculateThreatScore(String title, String description) {
    final text = '${title} ${description}'.toLowerCase();
    double score = 0;
    
    // High threat keywords (20 points each)
    final highThreatKeywords = [
      'nuclear', 'war', 'attack', 'invasion', 'bomb', 'missile', 'weapon',
      'crisis', 'emergency', 'threat', 'conflict', 'military action'
    ];
    
    // Medium threat keywords (10 points each)
    final mediumThreatKeywords = [
      'tension', 'dispute', 'sanctions', 'embargo', 'protest', 'unrest',
      'border', 'territorial', 'cyber attack', 'espionage'
    ];
    
    // Low threat keywords (5 points each)
    final lowThreatKeywords = [
      'concern', 'worry', 'issue', 'problem', 'challenge', 'disagreement'
    ];
    
    // Positive keywords (subtract 10 points each)
    final positiveKeywords = [
      'peace', 'treaty', 'agreement', 'cooperation', 'diplomacy', 'dialogue',
      'resolution', 'ceasefire', 'negotiate'
    ];
    
    // Count keyword occurrences
    for (String keyword in highThreatKeywords) {
      if (text.contains(keyword)) score += 20;
    }
    
    for (String keyword in mediumThreatKeywords) {
      if (text.contains(keyword)) score += 10;
    }
    
    for (String keyword in lowThreatKeywords) {
      if (text.contains(keyword)) score += 5;
    }
    
    for (String keyword in positiveKeywords) {
      if (text.contains(keyword)) score -= 10;
    }
    
    // Normalize to 0-100 scale
    return (score / 2).clamp(0.0, 100.0);
  }
  
  // Extract relevant keywords from text
  static List<String> _extractKeywords(String title, String description) {
    final text = '${title} ${description}'.toLowerCase();
    final keywords = <String>[];
    
    final relevantKeywords = [
      'nuclear', 'war', 'peace', 'conflict', 'tension', 'military',
      'diplomacy', 'sanctions', 'treaty', 'invasion', 'attack', 'crisis',
      'security', 'defense', 'alliance', 'nato', 'un', 'china', 'russia',
      'ukraine', 'israel', 'palestine', 'iran', 'north korea'
    ];
    
    for (String keyword in relevantKeywords) {
      if (text.contains(keyword)) {
        keywords.add(keyword);
      }
    }
    
    return keywords.take(5).toList(); // Limit to 5 keywords
  }
  
  // Combine news from multiple sources
  static Future<List<NewsItem>> fetchAllNews() async {
    final List<NewsItem> allNews = [];
    
    try {
      // Fetch from NewsAPI
      final newsApiArticles = await fetchNewsApiArticles();
      allNews.addAll(newsApiArticles);
      
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Fetch from GNews
      final gNewsArticles = await fetchGNewsArticles();
      allNews.addAll(gNewsArticles);
      
      // Remove duplicates and sort by threat score
      final uniqueNews = _removeDuplicates(allNews);
      uniqueNews.sort((a, b) => b.threatScore.compareTo(a.threatScore));
      
      return uniqueNews.take(20).toList(); // Return top 20 articles
      
    } catch (e) {
      print('Error fetching all news: $e');
      return [];
    }
  }
  
  // Remove duplicate articles based on similar titles
  static List<NewsItem> _removeDuplicates(List<NewsItem> articles) {
    final Map<String, NewsItem> uniqueArticles = {};
    
    for (NewsItem article in articles) {
      final key = article.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
      if (!uniqueArticles.containsKey(key)) {
        uniqueArticles[key] = article;
      }
    }
    
    return uniqueArticles.values.toList();
  }
}