import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_item.dart';
import '../models/threat_data.dart';

class AIThreatCalculator {
  // Free API endpoints
  static const String huggingFaceApiUrl = 'https://api-inference.huggingface.co/models';
  static const String googleTranslateApiUrl = 'https://translate.googleapis.com/translate_a/single';
  
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
      // Method 1: Try Hugging Face free inference API
      List<Map<String, dynamic>> aiAnalysis = await _analyzeWithHuggingFace(newsItems);
      
      if (aiAnalysis.isEmpty) {
        // Method 2: Fallback to local Ollama if available
        aiAnalysis = await _analyzeWithOllama(newsItems);
      }
      
      if (aiAnalysis.isEmpty) {
        // Method 3: Fallback to enhanced keyword analysis
        aiAnalysis = _enhancedKeywordAnalysis(newsItems);
      }

      // Calculate threat level from AI analysis
      return _calculateThreatFromAI(aiAnalysis, newsItems);
      
    } catch (e) {
      print('AI analysis failed, using enhanced fallback: $e');
      // Fallback to enhanced keyword analysis
      List<Map<String, dynamic>> analysis = _enhancedKeywordAnalysis(newsItems);
      return _calculateThreatFromAI(analysis, newsItems);
    }
  }

  // Method 1: Hugging Face Free Inference API
  static Future<List<Map<String, dynamic>>> _analyzeWithHuggingFace(List<NewsItem> newsItems) async {
    List<Map<String, dynamic>> results = [];
    
    try {
      for (int i = 0; i < newsItems.length && i < 10; i++) {
        NewsItem item = newsItems[i];
        String text = '${item.title}. ${item.description}'.substring(0, 500); // Limit text length
        
        // Analyze sentiment
        Map<String, dynamic> sentiment = await _getHuggingFaceSentiment(text);
        
        // Analyze threat classification
        Map<String, dynamic> classification = await _getHuggingFaceClassification(text);
        
        results.add({
          'newsItem': item,
          'sentiment': sentiment,
          'classification': classification,
          'aiConfidence': (sentiment['confidence'] + classification['confidence']) / 2,
        });
        
        // Rate limiting - free tier has limits
        await Future.delayed(Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Hugging Face analysis failed: $e');
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
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> result = json.decode(response.body);
        if (result.isNotEmpty && result[0] is List) {
          var sentiments = result[0] as List;
          var topSentiment = sentiments.reduce((a, b) => a['score'] > b['score'] ? a : b);
          
          return {
            'label': topSentiment['label'],
            'confidence': topSentiment['score'],
            'threat_score': _sentimentToThreatScore(topSentiment['label'], topSentiment['score'])
          };
        }
      }
    } catch (e) {
      print('Sentiment analysis failed: $e');
    }
    
    return {'label': 'NEUTRAL', 'confidence': 0.5, 'threat_score': 25.0};
  }

  static Future<Map<String, dynamic>> _getHuggingFaceClassification(String text) async {
    // Use zero-shot classification to categorize threat types
    List<String> threatLabels = [
      'military conflict',
      'nuclear threat',
      'terrorism',
      'cyber attack',
      'economic crisis',
      'political instability',
      'peaceful resolution',
      'diplomatic success'
    ];
    
    try {
      final response = await http.post(
        Uri.parse('$huggingFaceApiUrl/$classificationModel'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'inputs': text,
          'parameters': {
            'candidate_labels': threatLabels,
          }
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        Map<String, dynamic> result = json.decode(response.body);
        
        return {
          'labels': result['labels'] ?? [],
          'scores': result['scores'] ?? [],
          'confidence': (result['scores'] as List).isNotEmpty ? result['scores'][0] : 0.5,
          'threat_score': _classificationToThreatScore(result)
        };
      }
    } catch (e) {
      print('Classification failed: $e');
    }
    
    return {'labels': [], 'scores': [], 'confidence': 0.5, 'threat_score': 25.0};
  }

  // Method 2: Local Ollama (completely free, runs locally)
  static Future<List<Map<String, dynamic>>> _analyzeWithOllama(List<NewsItem> newsItems) async {
    List<Map<String, dynamic>> results = [];
    
    try {
      for (int i = 0; i < newsItems.length && i < 5; i++) {
        NewsItem item = newsItems[i];
        String prompt = _createThreatAnalysisPrompt(item);
        
        Map<String, dynamic> analysis = await _queryOllama(prompt);
        
        if (analysis.isNotEmpty) {
          results.add({
            'newsItem': item,
            'aiAnalysis': analysis,
            'aiConfidence': 0.8,
          });
        }
      }
    } catch (e) {
      print('Ollama analysis failed (probably not installed): $e');
    }
    
    return results;
  }

  static Future<Map<String, dynamic>> _queryOllama(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(ollamaUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': 'llama2', // Free model
          'prompt': prompt,
          'stream': false,
        }),
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        Map<String, dynamic> result = json.decode(response.body);
        String responseText = result['response'] ?? '';
        
        return _parseOllamaResponse(responseText);
      }
    } catch (e) {
      print('Ollama query failed: $e');
    }
    
    return {};
  }

  static String _createThreatAnalysisPrompt(NewsItem item) {
    return '''
Analyze this news headline and description for global security threat level:

Title: ${item.title}
Description: ${item.description}

Rate the threat level from 1-10 and provide reasoning:
1-2: No threat (positive news, cooperation)
3-4: Low threat (minor tensions, routine events)
5-6: Moderate threat (diplomatic issues, protests)
7-8: High threat (military tensions, sanctions)
9-10: Critical threat (active conflicts, nuclear concerns)

Respond in this exact format:
THREAT_LEVEL: [number]
CATEGORY: [military/nuclear/cyber/economic/diplomatic/social]
REASONING: [brief explanation]
CONFIDENCE: [0.1-1.0]
''';
  }

  static Map<String, dynamic> _parseOllamaResponse(String response) {
    try {
      RegExp threatLevelRegex = RegExp(r'THREAT_LEVEL:\s*(\d+)');
      RegExp categoryRegex = RegExp(r'CATEGORY:\s*(\w+)');
      RegExp reasoningRegex = RegExp(r'REASONING:\s*(.+?)(?=\n|$)');
      RegExp confidenceRegex = RegExp(r'CONFIDENCE:\s*([\d.]+)');
      
      double threatLevel = 5.0;
      String category = 'unknown';
      String reasoning = '';
      double confidence = 0.5;
      
      var threatMatch = threatLevelRegex.firstMatch(response);
      if (threatMatch != null) {
        threatLevel = double.parse(threatMatch.group(1)!) * 10; // Convert 1-10 to 10-100
      }
      
      var categoryMatch = categoryRegex.firstMatch(response);
      if (categoryMatch != null) {
        category = categoryMatch.group(1)!;
      }
      
      var reasoningMatch = reasoningRegex.firstMatch(response);
      if (reasoningMatch != null) {
        reasoning = reasoningMatch.group(1)!.trim();
      }
      
      var confidenceMatch = confidenceRegex.firstMatch(response);
      if (confidenceMatch != null) {
        confidence = double.parse(confidenceMatch.group(1)!);
      }
      
      return {
        'threat_score': threatLevel.clamp(15.0, 85.0),
        'category': category,
        'reasoning': reasoning,
        'confidence': confidence,
      };
    } catch (e) {
      print('Failed to parse Ollama response: $e');
      return {'threat_score': 25.0, 'category': 'unknown', 'confidence': 0.3};
    }
  }

  // Method 3: Enhanced keyword analysis with context scoring
  static List<Map<String, dynamic>> _enhancedKeywordAnalysis(List<NewsItem> newsItems) {
    List<Map<String, dynamic>> results = [];
    
    for (NewsItem item in newsItems.take(15)) {
      Map<String, dynamic> analysis = _advancedTextAnalysis(item);
      results.add({
        'newsItem': item,
        'enhancedAnalysis': analysis,
        'aiConfidence': 0.6,
      });
    }
    
    return results;
  }

  static Map<String, dynamic> _advancedTextAnalysis(NewsItem item) {
    String text = '${item.title} ${item.description}'.toLowerCase();
    
    // Advanced threat indicators with context
    Map<String, Map<String, dynamic>> threatIndicators = {
      'nuclear_weapons': {
        'keywords': ['nuclear weapon', 'atomic bomb', 'warhead', 'nuclear strike', 'nuclear threat'],
        'base_score': 80,
        'negative_context': ['disarmament', 'treaty', 'reduction', 'peaceful']
      },
      'nuclear_civilian': {
        'keywords': ['nuclear power', 'reactor', 'nuclear energy', 'nuclear plant'],
        'base_score': 15,
        'negative_context': []
      },
      'active_conflict': {
        'keywords': ['invasion', 'attack', 'bombing', 'war', 'combat', 'fighting'],
        'base_score': 70,
        'negative_context': ['ended', 'ceasefire', 'peace']
      },
      'military_buildup': {
        'keywords': ['troops deployed', 'military buildup', 'forces mobilized', 'exercises'],
        'base_score': 45,
        'negative_context': ['training', 'routine', 'humanitarian']
      },
      'diplomatic_crisis': {
        'keywords': ['sanctions', 'diplomatic crisis', 'expelled', 'recall ambassador'],
        'base_score': 35,
        'negative_context': ['lifted', 'dialogue', 'negotiations']
      },
      'positive_developments': {
        'keywords': ['peace agreement', 'treaty signed', 'cooperation', 'dialogue', 'resolution'],
        'base_score': -20,
        'negative_context': []
      }
    };
    
    double totalScore = 25.0; // Base score
    List<String> detectedCategories = [];
    List<String> reasonings = [];
    
    threatIndicators.forEach((category, indicators) {
      List<String> keywords = indicators['keywords'];
      double baseScore = indicators['base_score'].toDouble();
      List<String> negativeContext = indicators['negative_context'];
      
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
            score *= 0.3; // Significantly reduce score
          }
          
          // Apply urgency multipliers
          if (text.contains('urgent') || text.contains('immediate') || text.contains('emergency')) {
            score *= 1.2;
          }
          if (text.contains('breaking') || text.contains('just in')) {
            score *= 1.1;
          }
          
          totalScore += score * 0.1; // Scale down the impact
          detectedCategories.add(category);
          reasonings.add('Detected: $keyword (${hasNegativeContext ? 'mitigated' : 'concerning'})');
          break; // Only count once per category
        }
      }
    });
    
    return {
      'threat_score': totalScore.clamp(15.0, 85.0),
      'categories': detectedCategories,
      'reasoning': reasonings.join('; '),
      'confidence': detectedCategories.isNotEmpty ? 0.7 : 0.4,
    };
  }

  static double _sentimentToThreatScore(String sentiment, double confidence) {
    switch (sentiment.toLowerCase()) {
      case 'negative':
        return 30 + (confidence * 40); // 30-70 range
      case 'positive':
        return 15 + (confidence * 10); // 15-25 range
      default:
        return 25; // Neutral
    }
  }

  static double _classificationToThreatScore(Map<String, dynamic> classification) {
    List<String> labels = List<String>.from(classification['labels'] ?? []);
    List<double> scores = List<double>.from(classification['scores'] ?? []);
    
    if (labels.isEmpty || scores.isEmpty) return 25.0;
    
    double totalScore = 25.0;
    
    for (int i = 0; i < labels.length && i < 3; i++) {
      String label = labels[i].toLowerCase();
      double score = scores[i];
      
      if (label.contains('military') || label.contains('nuclear') || label.contains('terrorism')) {
        totalScore += score * 30;
      } else if (label.contains('cyber') || label.contains('political')) {
        totalScore += score * 20;
      } else if (label.contains('economic')) {
        totalScore += score * 15;
      } else if (label.contains('peaceful') || label.contains('diplomatic')) {
        totalScore -= score * 15;
      }
    }
    
    return totalScore.clamp(15.0, 85.0);
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
      
      // Extract threat score from different analysis types
      if (analysis['sentiment'] != null) {
        threatScore = analysis['sentiment']['threat_score'] ?? 25.0;
        confidence = analysis['sentiment']['confidence'] ?? 0.5;
      } else if (analysis['aiAnalysis'] != null) {
        threatScore = analysis['aiAnalysis']['threat_score'] ?? 25.0;
        confidence = analysis['aiAnalysis']['confidence'] ?? 0.5;
        if (analysis['aiAnalysis']['reasoning'] != null) {
          allReasonings.add(analysis['aiAnalysis']['reasoning']);
        }
      } else if (analysis['enhancedAnalysis'] != null) {
        threatScore = analysis['enhancedAnalysis']['threat_score'] ?? 25.0;
        confidence = analysis['enhancedAnalysis']['confidence'] ?? 0.5;
        if (analysis['enhancedAnalysis']['categories'] != null) {
          List<String> categories = List<String>.from(analysis['enhancedAnalysis']['categories']);
          for (String category in categories) {
            categoryCount[category] = (categoryCount[category] ?? 0) + 1;
          }
        }
      }
      
      // Weight by confidence
      totalScore += threatScore * confidence;
      totalConfidence += confidence;
    }
    
    double averageScore = totalConfidence > 0 ? totalScore / totalConfidence : 25.0;
    
    // Apply time decay
    averageScore = _applyTimeDecay(averageScore, newsItems);
    
    return ThreatData(
      threatLevel: averageScore.clamp(15.0, 85.0),
      timestamp: DateTime.now(),
      primaryThreat: _identifyPrimaryThreat(categoryCount),
      regionalScores: _calculateRegionalScores(newsItems),
      keyFactors: _extractKeyFactors(allReasonings, categoryCount),
    );
  }

  static double _applyTimeDecay(double score, List<NewsItem> newsItems) {
    if (newsItems.isEmpty) return score;
    
    double timeWeight = 0.0;
    int count = 0;
    
    for (NewsItem item in newsItems.take(10)) {
      int hoursAgo = DateTime.now().difference(item.publishedAt).inHours;
      if (hoursAgo <= 6) timeWeight += 1.0;
      else if (hoursAgo <= 24) timeWeight += 0.8;
      else if (hoursAgo <= 72) timeWeight += 0.6;
      else timeWeight += 0.3;
      count++;
    }
    
    double avgTimeWeight = count > 0 ? timeWeight / count : 0.5;
    return score * (0.7 + avgTimeWeight * 0.3);
  }

  static ThreatData _createDefaultThreatData() {
    return ThreatData(
      threatLevel: 20.0,
      timestamp: DateTime.now(),
      primaryThreat: 'Global Monitoring Active',
      regionalScores: {'Global': 20.0},
      keyFactors: ['AI analysis in progress'],
    );
  }

  static String _identifyPrimaryThreat(Map<String, int> categoryCount) {
    if (categoryCount.isEmpty) return 'Global Monitoring';
    
    String primaryCategory = categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
        
    Map<String, String> categoryNames = {
      'nuclear_weapons': 'Nuclear Threats',
      'active_conflict': 'Active Conflicts',
      'military_buildup': 'Military Tensions',
      'diplomatic_crisis': 'Diplomatic Crisis',
      'cyber_attack': 'Cyber Threats',
    };
    
    return categoryNames[primaryCategory] ?? 'Security Monitoring';
  }

  static Map<String, double> _calculateRegionalScores(List<NewsItem> newsItems) {
    // Simplified regional analysis
    Map<String, double> regions = {
      'Global': 25.0,
      'Europe': 25.0,
      'Asia': 25.0,
      'Middle East': 25.0,
      'North America': 25.0,
    };
    
    // You can enhance this with AI-powered region detection
    return regions;
  }

  static List<String> _extractKeyFactors(List<String> reasonings, Map<String, int> categories) {
    List<String> factors = [];
    
    // Add top categories
    categories.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(3)
        .forEach((entry) => factors.add(entry.key.replaceAll('_', ' ')));
    
    // Add key reasonings
    factors.addAll(reasonings.take(2));
    
    return factors.isEmpty ? ['AI analysis complete'] : factors.take(4).toList();
  }
}