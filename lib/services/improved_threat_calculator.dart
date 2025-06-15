// Improved threat calculation with better scoring and context analysis
import '../models/news_item.dart';
import '../models/threat_data.dart';

class ImprovedThreatCalculator {
  // Reduced base scores to prevent overshooting
  static const Map<String, double> baseScores = {
    "military": 8.0,      // Reduced from 20
    "nuclear": 12.0,      // Reduced from 20
    "alliance": 6.0,      // Reduced from 20
    "diplomacy": 4.0,     // Reduced from 20
    "cyber": 7.0,         // Reduced from 20
    "economic": 5.0,      // Reduced from 20
    "unrest": 6.0,        // Reduced from 20
  };

  // More conservative intensity modifiers
  static const Map<String, double> intensityModifiers = {
    // High intensity keywords
    "crisis": 1.3,        // Reduced from 1.5
    "emergency": 1.2,     // Reduced from 1.4
    "urgent": 1.15,       // Reduced from 1.3
    "critical": 1.25,     // Reduced from 1.5
    "imminent": 1.3,      // Reduced from 1.6
    "escalation": 1.2,    // Reduced from 1.4
    "breaking": 1.1,      // Reduced from 1.2
    "alert": 1.15,        // Reduced from 1.3
    
    // Positive modifiers (reduce threat)
    "peace": 0.7,
    "agreement": 0.8,
    "resolution": 0.7,
    "cooperation": 0.8,
    "dialogue": 0.85,     // Less aggressive reduction
    "ceasefire": 0.6,
    "treaty": 0.75,       // Less aggressive reduction
  };

  // Context-aware keyword analysis
  static const Map<String, List<String>> negativeContexts = {
    "nuclear": [
      "power plant", "energy", "reactor maintenance", "safety inspection",
      "peaceful", "civilian", "medical", "research", "isotope", "treatment"
    ],
    "military": [
      "exercise", "training", "parade", "ceremony", "humanitarian",
      "peacekeeping", "aid", "rescue", "drill"
    ],
    "weapons": [
      "destruction", "disposal", "decommission", "treaty", "reduction",
      "control", "inspection", "verification"
    ]
  };

  static ThreatData calculateThreatLevel(List<NewsItem> newsItems) {
    if (newsItems.isEmpty) {
      return _createDefaultThreatData();
    }

    // Analyze top articles with weighted scoring
    List<double> articleScores = [];
    Map<String, double> categoryScores = {};
    
    // Initialize category scores
    for (String category in baseScores.keys) {
      categoryScores[category] = 0.0;
    }

    // Process articles with diminishing weight
    for (int i = 0; i < newsItems.length && i < 15; i++) {
      NewsItem item = newsItems[i];
      double weight = 1.0 / (1.0 + i * 0.2); // Diminishing weight for later articles
      
      Map<String, double> itemCategoryScores = _analyzeNewsItem(item);
      double itemScore = _calculateItemScore(itemCategoryScores);
      
      articleScores.add(itemScore * weight);
      
      // Accumulate category scores with weight
      itemCategoryScores.forEach((category, score) {
        categoryScores[category] = categoryScores[category]! + (score * weight);
      });
    }

    // Calculate weighted average (not sum to prevent inflation)
    double totalWeight = 0.0;
    double weightedSum = 0.0;
    
    for (int i = 0; i < articleScores.length; i++) {
      double weight = 1.0 / (1.0 + i * 0.2);
      weightedSum += articleScores[i];
      totalWeight += weight;
    }
    
    double averageScore = totalWeight > 0 ? weightedSum / totalWeight : 15.0;
    
    // Apply global context modifiers
    double finalScore = _applyGlobalModifiers(averageScore, categoryScores, newsItems);
    
    // Ensure reasonable bounds (15-85 instead of 0-100)
    finalScore = finalScore.clamp(15.0, 85.0);

    return ThreatData(
      threatLevel: finalScore,
      timestamp: DateTime.now(),
      primaryThreat: _identifyPrimaryThreat(categoryScores),
      regionalScores: _calculateRegionalScores(newsItems),
      keyFactors: _extractKeyFactors(categoryScores, newsItems),
    );
  }

  static Map<String, double> _analyzeNewsItem(NewsItem item) {
    String fullText = '${item.title} ${item.description}'.toLowerCase();
    Map<String, double> categoryScores = {};
    
    for (String category in baseScores.keys) {
      double score = _analyzeCategoryInText(fullText, category);
      categoryScores[category] = score;
    }
    
    return categoryScores;
  }

  static double _analyzeCategoryInText(String text, String category) {
    List<String> keywords = _getCategoryKeywords(category);
    double score = 0.0;
    int matches = 0;

    for (String keyword in keywords) {
      if (text.contains(keyword)) {
        matches++;
        
        // Check for negative context that reduces threat
        double contextModifier = _getContextModifier(text, keyword, category);
        double keywordScore = baseScores[category]! * contextModifier;
        
        // Apply intensity modifiers
        double intensityMod = _getIntensityModifier(text, keyword);
        keywordScore *= intensityMod;
        
        score += keywordScore;
      }
    }

    // Smaller bonus for multiple keywords (was too aggressive)
    if (matches > 1) {
      score *= (1.0 + (matches - 1) * 0.1); // 10% bonus per additional keyword
    }

    // Normalize to reasonable scale
    return (score / 3.0).clamp(0.0, 25.0); // Max 25 per category
  }

  static double _getContextModifier(String text, String keyword, String category) {
    List<String> negativeContextWords = negativeContexts[category] ?? [];
    
    // Find keyword position
    int keywordIndex = text.indexOf(keyword);
    if (keywordIndex == -1) return 1.0;

    // Check surrounding context (±100 characters)
    int start = (keywordIndex - 100).clamp(0, text.length);
    int end = (keywordIndex + keyword.length + 100).clamp(0, text.length);
    String context = text.substring(start, end);

    // Count negative context matches
    int negativeMatches = 0;
    for (String negativeWord in negativeContextWords) {
      if (context.contains(negativeWord)) {
        negativeMatches++;
      }
    }

    // Reduce score based on negative context
    if (negativeMatches > 0) {
      return (0.3 + (0.7 / (1 + negativeMatches * 0.5))); // Significant reduction
    }

    return 1.0;
  }

  static double _getIntensityModifier(String text, String keyword) {
    int keywordIndex = text.indexOf(keyword);
    if (keywordIndex == -1) return 1.0;

    int start = (keywordIndex - 50).clamp(0, text.length);
    int end = (keywordIndex + keyword.length + 50).clamp(0, text.length);
    String context = text.substring(start, end);

    double modifier = 1.0;
    intensityModifiers.forEach((intensityWord, modifierValue) {
      if (context.contains(intensityWord)) {
        modifier *= modifierValue;
      }
    });

    return modifier.clamp(0.4, 1.4); // Limit extreme modifiers
  }

  static double _calculateItemScore(Map<String, double> categoryScores) {
    double totalScore = 0.0;
    categoryScores.forEach((category, score) {
      totalScore += score;
    });
    return totalScore / categoryScores.length; // Average instead of sum
  }

  static double _applyGlobalModifiers(double baseScore, Map<String, double> categoryScores, List<NewsItem> newsItems) {
    // Time decay factor
    double timeWeight = _calculateTimeWeight(newsItems);
    double timeAdjustedScore = baseScore * (0.8 + timeWeight * 0.2);

    // Multiple threat categories modifier (less aggressive)
    int activeCategories = categoryScores.values.where((score) => score > 8).length;
    double diversityMultiplier = 1.0;
    if (activeCategories >= 4) {
      diversityMultiplier = 1.15; // Reduced from 1.2
    } else if (activeCategories >= 2) {
      diversityMultiplier = 1.05; // Reduced from 1.1
    }

    return timeAdjustedScore * diversityMultiplier;
  }

  static double _calculateTimeWeight(List<NewsItem> newsItems) {
    if (newsItems.isEmpty) return 0.5;

    double totalWeight = 0.0;
    int count = 0;

    for (NewsItem item in newsItems.take(10)) {
      int hoursAgo = DateTime.now().difference(item.publishedAt).inHours;
      totalWeight += _getTimeWeight(hoursAgo);
      count++;
    }

    return count > 0 ? totalWeight / count : 0.5;
  }

  static double _getTimeWeight(int hoursAgo) {
    if (hoursAgo <= 2) return 1.0;
    if (hoursAgo <= 12) return 0.9;
    if (hoursAgo <= 24) return 0.75;
    if (hoursAgo <= 72) return 0.6;
    if (hoursAgo <= 168) return 0.4;
    return 0.2;
  }

  static List<String> _getCategoryKeywords(String category) {
    // Simplified keyword lists (you can use the existing ones from your code)
    Map<String, List<String>> categoryKeywords = {
      "military": ["military", "army", "troops", "invasion", "attack", "weapons"],
      "nuclear": ["nuclear", "atomic", "uranium", "warhead", "reactor"],
      "alliance": ["nato", "alliance", "treaty", "coalition"],
      "diplomacy": ["diplomacy", "sanctions", "agreement", "talks"],
      "cyber": ["cyber", "hacking", "cyberattack"],
      "economic": ["economic", "sanctions", "trade war", "crisis"],
      "unrest": ["protest", "riot", "uprising", "violence"],
    };
    
    return categoryKeywords[category] ?? [];
  }

  static ThreatData _createDefaultThreatData() {
    return ThreatData(
      threatLevel: 20.0,
      timestamp: DateTime.now(),
      primaryThreat: 'Global Monitoring',
      regionalScores: {
        'Global': 20.0,
      },
      keyFactors: ['Monitoring for updates'],
    );
  }

  // Placeholder implementations (use your existing code)
  static String _identifyPrimaryThreat(Map<String, double> categoryScores) {
    String maxCategory = 'Global Monitoring';
    double maxScore = 0.0;
    
    categoryScores.forEach((category, score) {
      if (score > maxScore) {
        maxScore = score;
        maxCategory = category;
      }
    });
    
    return maxCategory;
  }

  static Map<String, double> _calculateRegionalScores(List<NewsItem> newsItems) {
    // Use your existing implementation
    return {
      'Global': 25.0,
      'Middle East': 30.0,
      'Europe': 20.0,
      'Asia': 25.0,
    };
  }

  static List<String> _extractKeyFactors(Map<String, double> categoryScores, List<NewsItem> newsItems) {
    List<String> factors = [];
    
    categoryScores.forEach((category, score) {
      if (score > 10) {
        factors.add(category);
      }
    });
    
    return factors.take(3).toList();
  }
}