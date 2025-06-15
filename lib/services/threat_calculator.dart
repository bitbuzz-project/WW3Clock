import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_item.dart';
import '../models/threat_data.dart';

class AIThreatCalculator {
  // Free API endpoints
  static const String huggingFaceApiUrl = 'https://api-inference.huggingface.co/models';
  
  // Free Hugging Face models (no API key required for inference API)
  static const String sentimentModel = 'cardiffnlp/twitter-roberta-base-sentiment-latest';
  static const String classificationModel = 'facebook/bart-large-mnli';
  
  // Alternative: Use Ollama local models (completely free)
  static const String ollamaUrl = 'http://localhost:11434/api/generate';
  
  static Future<ThreatData> calculateThreatLevel(List<NewsItem> newsItems) async {
    if (newsItems.isEmpty) {
      return _createDefaultThreatData();
    }

    try {
      // Method 1: Try enhanced keyword analysis first (most reliable)
      List<Map<String, dynamic>> analysis = _enhancedKeywordAnalysis(newsItems);
      
      // Method 2: Try to enhance with Hugging Face if available
      try {
        List<Map<String, dynamic>> aiAnalysis = await _analyzeWithHuggingFace(newsItems.take(3).toList());
        if (aiAnalysis.isNotEmpty) {
          // Merge AI analysis with keyword analysis
          analysis = _mergeAnalysis(analysis, aiAnalysis);
        }
      } catch (e) {
        print('Hugging Face analysis failed, using keyword analysis: $e');
      }

      // Calculate threat level from analysis
      return _calculateThreatFromAI(analysis, newsItems);
      
    } catch (e) {
      print('AI analysis failed completely, using simple fallback: $e');
      // Simple fallback
      return _createSimpleFallback(newsItems);
    }
  }

  // Method 1: Enhanced keyword analysis (always works)
  static List<Map<String, dynamic>> _enhancedKeywordAnalysis(List<NewsItem> newsItems) {
    List<Map<String, dynamic>> results = [];
    
    for (NewsItem item in newsItems.take(15)) {
      Map<String, dynamic> analysis = _advancedTextAnalysis(item);
      results.add({
        'newsItem': item,
        'enhancedAnalysis': analysis,
        'aiConfidence': 0.7,
      });
    }
    
    return results;
  }

  static Map<String, dynamic> _advancedTextAnalysis(NewsItem item) {
    String text = '${item.title} ${item.description}'.toLowerCase();
    
    // Advanced threat indicators with context
    Map<String, Map<String, dynamic>> threatIndicators = {
      'nuclear_weapons': {
        'keywords': ['nuclear weapon', 'atomic bomb', 'warhead', 'nuclear strike', 'nuclear threat', 'nuclear test'],
        'base_score': 70,
        'negative_context': ['disarmament', 'treaty', 'reduction', 'peaceful', 'civilian']
      },
      'nuclear_civilian': {
        'keywords': ['nuclear power', 'nuclear reactor', 'nuclear energy', 'nuclear plant', 'nuclear facility'],
        'base_score': 15,
        'negative_context': []
      },
      'active_conflict': {
        'keywords': ['invasion', 'attack', 'bombing', 'war', 'combat', 'fighting', 'assault', 'offensive'],
        'base_score': 65,
        'negative_context': ['ended', 'ceasefire', 'peace', 'stopped']
      },
      'military_buildup': {
        'keywords': ['troops deployed', 'military buildup', 'forces mobilized', 'military exercises', 'deployment'],
        'base_score': 40,
        'negative_context': ['training', 'routine', 'humanitarian', 'peacekeeping']
      },
      'diplomatic_crisis': {
        'keywords': ['sanctions', 'diplomatic crisis', 'expelled', 'recall ambassador', 'tension'],
        'base_score': 30,
        'negative_context': ['lifted', 'dialogue', 'negotiations', 'resolved']
      },
      'cyber_threats': {
        'keywords': ['cyber attack', 'hacking', 'cyberwar', 'data breach', 'ransomware'],
        'base_score': 35,
        'negative_context': ['prevented', 'defended', 'secured']
      },
      'positive_developments': {
        'keywords': ['peace agreement', 'treaty signed', 'cooperation', 'dialogue', 'resolution', 'ceasefire'],
        'base_score': -15,
        'negative_context': []
      }
    };
    
    double totalScore = 25.0; // Base score
    List<String> detectedCategories = [];
    List<String> reasonings = [];
    
    threatIndicators.forEach((category, indicators) {
      List<String> keywords = List<String>.from(indicators['keywords']);
      double baseScore = (indicators['base_score'] as num).toDouble();
      List<String> negativeContext = List<String>.from(indicators['negative_context']);
      
      for (String keyword in keywords) {
        if (text.contains(keyword)) {
          double score = baseScore;
          
          // Check for negative context
          bool hasNegativeContext = false;
          for (String negKeyword in negativeContext) {
            if (text.contains(negKeyword)) {
              hasNegativeContext = true;
              break;
            }
          }
          
          if (hasNegativeContext) {
            score *= 0.4; // Significantly reduce score
            reasonings.add('$keyword (mitigated by context)');
          } else {
            reasonings.add('$keyword detected');
          }
          
          // Apply urgency multipliers
          if (text.contains('urgent') || text.contains('immediate') || text.contains('emergency')) {
            score *= 1.15;
          }
          if (text.contains('breaking') || text.contains('just in')) {
            score *= 1.1;
          }
          
          totalScore += score * 0.15; // Scale down the impact
          detectedCategories.add(category);
          break; // Only count once per category
        }
      }
    });
    
    return {
      'threat_score': totalScore.clamp(15.0, 85.0),
      'categories': detectedCategories,
      'reasoning': reasonings.take(3).join(', '),
      'confidence': detectedCategories.isNotEmpty ? 0.75 : 0.5,
    };
  }

  // Method 2: Hugging Face analysis (with proper error handling)
  static Future<List<Map<String, dynamic>>> _analyzeWithHuggingFace(List<NewsItem> newsItems) async {
    List<Map<String, dynamic>> results = [];
    
    try {
      for (int i = 0; i < newsItems.length && i < 3; i++) {
        NewsItem item = newsItems[i];
        String text = '${item.title}. ${item.description}';
        if (text.length > 400) {
          text = text.substring(0, 400); // Limit text length
        }
        
        // Analyze sentiment with timeout
        Map<String, dynamic> sentiment = await _getHuggingFaceSentiment(text);
        
        results.add({
          'newsItem': item,
          'sentiment': sentiment,
          'aiConfidence': sentiment['confidence'] ?? 0.5,
        });
        
        // Rate limiting - free tier has limits
        await Future.delayed(Duration(milliseconds: 1000));
      }
    } catch (e) {
      print('Hugging Face analysis error: $e');
    }
    
    return results;
  }

  static Future<Map<String, dynamic>> _getHuggingFaceSentiment(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$huggingFaceApiUrl/$sentimentModel'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'inputs': text}),
      ).timeout(Duration(seconds: 8));

      if (response.statusCode == 200) {
        dynamic result = json.decode(response.body);
        
        if (result is List && result.isNotEmpty) {
          var sentiments = result[0];
          if (sentiments is List && sentiments.isNotEmpty) {
            var topSentiment = sentiments.reduce((a, b) => 
              (a['score'] ?? 0) > (b['score'] ?? 0) ? a : b);
            
            return {
              'label': topSentiment['label'] ?? 'NEUTRAL',
              'confidence': (topSentiment['score'] ?? 0.5).toDouble(),
              'threat_score': _sentimentToThreatScore(
                topSentiment['label'] ?? 'NEUTRAL', 
                (topSentiment['score'] ?? 0.5).toDouble()
              )
            };
          }
        }
      }
    } catch (e) {
      print('Sentiment analysis failed: $e');
    }
    
    return {
      'label': 'NEUTRAL', 
      'confidence': 0.5, 
      'threat_score': 25.0
    };
  }

  static double _sentimentToThreatScore(String sentiment, double confidence) {
    switch (sentiment.toLowerCase()) {
      case 'negative':
      case 'label_2':
        return 25 + (confidence * 35); // 25-60 range
      case 'positive':
      case 'label_0':
        return 15 + (confidence * 15); // 15-30 range
      default:
        return 25; // Neutral
    }
  }

  static List<Map<String, dynamic>> _mergeAnalysis(
      List<Map<String, dynamic>> keywordAnalysis, 
      List<Map<String, dynamic>> aiAnalysis) {
    
    // For now, just combine them - you can make this more sophisticated
    List<Map<String, dynamic>> merged = List.from(keywordAnalysis);
    
    // Enhance keyword analysis with AI sentiment where available
    for (var aiResult in aiAnalysis) {
      NewsItem aiItem = aiResult['newsItem'];
      
      // Find corresponding keyword analysis
      for (var keywordResult in merged) {
        NewsItem keywordItem = keywordResult['newsItem'];
        
        if (keywordItem.id == aiItem.id) {
          // Merge AI sentiment into keyword analysis
          if (keywordResult['enhancedAnalysis'] != null) {
            Map<String, dynamic> enhanced = Map.from(keywordResult['enhancedAnalysis']);
            
            double aiThreatScore = aiResult['sentiment']['threat_score'] ?? 25.0;
            double keywordScore = enhanced['threat_score'] ?? 25.0;
            double aiConfidence = aiResult['sentiment']['confidence'] ?? 0.5;
            
            // Weight the scores based on AI confidence
            double finalScore = (keywordScore * 0.7) + (aiThreatScore * 0.3 * aiConfidence);
            
            enhanced['threat_score'] = finalScore.clamp(15.0, 85.0);
            enhanced['ai_enhanced'] = true;
            enhanced['ai_sentiment'] = aiResult['sentiment']['label'];
            
            keywordResult['enhancedAnalysis'] = enhanced;
            keywordResult['aiConfidence'] = (keywordResult['aiConfidence'] + aiConfidence) / 2;
          }
          break;
        }
      }
    }
    
    return merged;
  }

  static ThreatData _calculateThreatFromAI(List<Map<String, dynamic>> analyses, List<NewsItem> newsItems) {
    if (analyses.isEmpty) {
      return _createDefaultThreatData();
    }
    
    double totalScore = 0.0;
    double totalConfidence = 0.0;
    Map<String, int> categoryCount = {};
    List<String> allReasonings = [];
    
    for (var analysis in analyses) {
      double threatScore = 25.0;
      double confidence = 0.5;
      
      // Extract threat score from analysis
      if (analysis['enhancedAnalysis'] != null) {
        Map<String, dynamic> enhanced = analysis['enhancedAnalysis'];
        threatScore = (enhanced['threat_score'] ?? 25.0).toDouble();
        confidence = (enhanced['confidence'] ?? 0.5).toDouble();
        
        if (enhanced['reasoning'] != null) {
          allReasonings.add(enhanced['reasoning'].toString());
        }
        
        if (enhanced['categories'] != null) {
          List<dynamic> categories = enhanced['categories'];
          for (var category in categories) {
            String categoryStr = category.toString();
            categoryCount[categoryStr] = (categoryCount[categoryStr] ?? 0) + 1;
          }
        }
      }
      
      // Weight by confidence and recency
      double weight = confidence;
      if (analysis['newsItem'] != null) {
        NewsItem item = analysis['newsItem'];
        int hoursAgo = DateTime.now().difference(item.publishedAt).inHours;
        if (hoursAgo <= 6) weight *= 1.2;
        else if (hoursAgo <= 24) weight *= 1.0;
        else if (hoursAgo <= 72) weight *= 0.8;
        else weight *= 0.6;
      }
      
      totalScore += threatScore * weight;
      totalConfidence += weight;
    }
    
    double averageScore = totalConfidence > 0 ? totalScore / totalConfidence : 25.0;
    
    // Apply global modifiers
    averageScore = _applyGlobalModifiers(averageScore, categoryCount, newsItems);
    
    return ThreatData(
      threatLevel: averageScore.clamp(15.0, 85.0),
      timestamp: DateTime.now(),
      primaryThreat: _identifyPrimaryThreat(categoryCount),
      regionalScores: _calculateRegionalScores(newsItems),
      keyFactors: _extractKeyFactors(allReasonings, categoryCount),
    );
  }

  static double _applyGlobalModifiers(double score, Map<String, int> categories, List<NewsItem> newsItems) {
    // Multiple threat types increase overall risk
    int activeCategories = categories.values.where((count) => count > 0).length;
    
    double categoryMultiplier = 1.0;
    if (activeCategories >= 4) {
      categoryMultiplier = 1.15;
    } else if (activeCategories >= 2) {
      categoryMultiplier = 1.08;
    }
    
    // Recent news gets higher weight
    double recentNewsWeight = 1.0;
    if (newsItems.isNotEmpty) {
      int recentNews = newsItems.where((item) {
        int hoursAgo = DateTime.now().difference(item.publishedAt).inHours;
        return hoursAgo <= 24;
      }).length;
      
      if (recentNews >= 5) {
        recentNewsWeight = 1.1;
      }
    }
    
    return score * categoryMultiplier * recentNewsWeight;
  }

  static ThreatData _createDefaultThreatData() {
    return ThreatData(
      threatLevel: 20.0,
      timestamp: DateTime.now(),
      primaryThreat: 'Global Monitoring Active',
      regionalScores: {'Global': 20.0},
      keyFactors: ['System initializing'],
    );
  }

  static ThreatData _createSimpleFallback(List<NewsItem> newsItems) {
    // Very simple analysis if everything fails
    double avgThreatScore = 25.0;
    
    if (newsItems.isNotEmpty) {
      double total = 0.0;
      for (NewsItem item in newsItems.take(10)) {
        total += item.threatScore;
      }
      avgThreatScore = (total / newsItems.take(10).length).clamp(15.0, 85.0);
    }
    
    return ThreatData(
      threatLevel: avgThreatScore,
      timestamp: DateTime.now(),
      primaryThreat: 'Basic Analysis Active',
      regionalScores: {'Global': avgThreatScore},
      keyFactors: ['Using fallback analysis'],
    );
  }

  static String _identifyPrimaryThreat(Map<String, int> categoryCount) {
    if (categoryCount.isEmpty) return 'Global Monitoring';
    
    String primaryCategory = categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
        
    Map<String, String> categoryNames = {
      'nuclear_weapons': 'Nuclear Threats',
      'nuclear_civilian': 'Nuclear Energy Issues',
      'active_conflict': 'Active Conflicts',
      'military_buildup': 'Military Tensions',
      'diplomatic_crisis': 'Diplomatic Crisis',
      'cyber_threats': 'Cyber Security',
      'positive_developments': 'Positive Developments',
    };
    
    return categoryNames[primaryCategory] ?? 'Security Monitoring';
  }

  static Map<String, double> _calculateRegionalScores(List<NewsItem> newsItems) {
    Map<String, List<double>> regionScores = {
      'Global': [],
      'Europe': [],
      'Asia': [],
      'Middle East': [],
      'North America': [],
      'Africa': [],
    };
    
    for (NewsItem item in newsItems.take(15)) {
      String region = _identifyRegion(item);
      double score = item.threatScore;
      
      if (regionScores.containsKey(region)) {
        regionScores[region]!.add(score);
      } else {
        regionScores['Global']!.add(score);
      }
    }
    
    Map<String, double> averages = {};
    regionScores.forEach((region, scores) {
      if (scores.isNotEmpty) {
        averages[region] = scores.reduce((a, b) => a + b) / scores.length;
      } else {
        averages[region] = 25.0;
      }
    });
    
    return averages;
  }

  static String _identifyRegion(NewsItem item) {
    String text = '${item.title} ${item.description}'.toLowerCase();
    
    if (text.contains('ukraine') || text.contains('russia') || text.contains('europe') || 
        text.contains('nato') || text.contains('eu ')) {
      return 'Europe';
    } else if (text.contains('china') || text.contains('taiwan') || text.contains('japan') || 
               text.contains('korea') || text.contains('asia')) {
      return 'Asia';
    } else if (text.contains('israel') || text.contains('palestine') || text.contains('iran') || 
               text.contains('syria') || text.contains('middle east') || text.contains('iraq')) {
      return 'Middle East';
    } else if (text.contains('usa') || text.contains('america') || text.contains('canada') || 
               text.contains('mexico')) {
      return 'North America';
    } else if (text.contains('africa') || text.contains('sudan') || text.contains('congo')) {
      return 'Africa';
    }
    
    return 'Global';
  }

  static List<String> _extractKeyFactors(List<String> reasonings, Map<String, int> categories) {
    List<String> factors = [];
    
    // Add top categories
    var sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var entry in sortedCategories.take(2)) {
      String displayName = entry.key.replaceAll('_', ' ').replaceAll('nuclear weapons', 'nuclear concerns');
      factors.add(displayName);
    }
    
    // Add key reasonings
    for (String reasoning in reasonings.take(2)) {
      if (reasoning.isNotEmpty && !factors.any((f) => reasoning.toLowerCase().contains(f.toLowerCase()))) {
        factors.add(reasoning);
      }
    }
    
    return factors.isEmpty ? ['Analysis complete'] : factors.take(4).toList();
  }
}