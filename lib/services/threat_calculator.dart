import '../models/news_item.dart';
import '../models/threat_data.dart';

class ThreatCalculator {
  // Weighted criteria for threat calculation
  static const Map<String, double> weights = {
    "military": 0.15,
    "nuclear": 0.10,
    "alliance": 0.08,
    "diplomacy": 0.10,
    "cyber": 0.07,
    "disinfo": 0.05,
    "economic": 0.05,
    "unrest": 0.05,
    "ai_weapons": 0.05,
    "coups": 0.05,
    "climate": 0.05,
    "space": 0.05,
    "biowarfare": 0.05
  };

  // Keywords for each threat category
  static const Map<String, List<String>> categoryKeywords = {
    "military": [
      "military", "army", "troops", "deployment", "invasion", "war", "attack", 
      "operation", "forces", "soldier", "combat", "battlefield", "missile", 
      "tank", "fighter", "bomber", "navy", "fleet", "submarine", "weapons",
      "arms", "defense", "offensive", "strike", "raid", "blockade"
    ],
    
    "nuclear": [
      "nuclear", "atomic", "uranium", "plutonium", "reactor", "enrichment",
      "warhead", "bomb", "icbm", "deterrent", "proliferation", "treaty",
      "non-proliferation", "iaea", "fissile", "radiation", "fallout"
    ],
    
    "alliance": [
      "nato", "alliance", "coalition", "partnership", "bloc", "pact",
      "treaty", "mutual defense", "collective security", "member state",
      "article 5", "joint", "cooperation", "bilateral", "multilateral"
    ],
    
    "diplomacy": [
      "diplomacy", "diplomatic", "ambassador", "embassy", "summit", "talks",
      "negotiation", "peace", "ceasefire", "agreement", "dialogue", "envoy",
      "foreign minister", "secretary of state", "un", "united nations",
      "sanctions", "embargo", "trade war", "tariff", "relations"
    ],
    
    "cyber": [
      "cyber", "hacking", "malware", "ransomware", "ddos", "breach",
      "cybersecurity", "data theft", "phishing", "botnet", "virus",
      "cyberattack", "digital", "online", "internet", "network", "server"
    ],
    
    "disinfo": [
      "disinformation", "misinformation", "propaganda", "fake news",
      "social media", "manipulation", "influence", "psyops", "troll",
      "bot", "deepfake", "conspiracy", "narrative", "media war"
    ],
    
    "economic": [
      "economic", "economy", "market", "trade", "gdp", "inflation",
      "recession", "crisis", "sanctions", "embargo", "supply chain",
      "oil", "gas", "energy", "dollar", "currency", "finance", "bank"
    ],
    
    "unrest": [
      "protest", "riot", "demonstration", "civil unrest", "uprising",
      "revolution", "insurgency", "rebellion", "violence", "chaos",
      "strike", "march", "activist", "civil disobedience", "coup attempt"
    ],
    
    "ai_weapons": [
      "ai weapons", "autonomous weapons", "killer robot", "lethal autonomous",
      "artificial intelligence", "machine learning", "drone swarm",
      "automated", "robotic", "ai warfare", "algorithm", "autonomous system"
    ],
    
    "coups": [
      "coup", "military coup", "government overthrow", "regime change",
      "junta", "martial law", "military takeover", "putsch", "political crisis",
      "constitutional crisis", "emergency powers", "authoritarian"
    ],
    
    "climate": [
      "climate change", "global warming", "natural disaster", "flood",
      "drought", "hurricane", "earthquake", "tsunami", "wildfire",
      "environmental", "refugee", "migration", "resource scarcity", "water"
    ],
    
    "space": [
      "space", "satellite", "orbital", "iss", "space station", "rocket",
      "space weapon", "anti-satellite", "debris", "space force",
      "astronaut", "mission", "launch", "space race", "mars"
    ],
    
    "biowarfare": [
      "biological", "bioweapon", "pathogen", "virus", "bacteria", "toxin",
      "pandemic", "epidemic", "outbreak", "disease", "biological warfare",
      "lab leak", "biosecurity", "anthrax", "smallpox", "chemical weapon"
    ]
  };

  // Threat level modifiers for different intensities
  static const Map<String, double> intensityModifiers = {
    // High intensity keywords
    "crisis": 1.5,
    "emergency": 1.4,
    "urgent": 1.3,
    "critical": 1.5,
    "imminent": 1.6,
    "escalation": 1.4,
    "breaking": 1.2,
    "alert": 1.3,
    
    // Medium intensity keywords
    "tension": 1.1,
    "concern": 1.05,
    "warning": 1.2,
    "threat": 1.3,
    "risk": 1.1,
    
    // Positive modifiers (reduce threat)
    "peace": 0.7,
    "agreement": 0.8,
    "resolution": 0.7,
    "cooperation": 0.8,
    "dialogue": 0.9,
    "ceasefire": 0.6,
    "treaty": 0.8,
    "stabilize": 0.8,
  };

  // Calculate overall threat level from news articles
  static ThreatData calculateThreatLevel(List<NewsItem> newsItems) {
    if (newsItems.isEmpty) {
      return ThreatData(
        threatLevel: 15.0,
        timestamp: DateTime.now(),
        primaryThreat: 'No current threats detected',
        regionalScores: {},
        keyFactors: ['Monitoring for updates'],
      );
    }

    // Calculate weighted threat scores for each category
    Map<String, double> categoryScores = _calculateCategoryScores(newsItems);
    
    // Calculate overall weighted threat level
    double overallThreatLevel = _calculateWeightedThreatLevel(categoryScores);
    
    // Apply time decay and regional factors
    double finalThreatLevel = _applyModifiers(overallThreatLevel, newsItems);
    
    // Calculate regional scores
    Map<String, double> regionalScores = _calculateRegionalScores(newsItems);
    
    // Identify primary threat and key factors
    String primaryThreat = _identifyPrimaryThreat(categoryScores);
    List<String> keyFactors = _extractKeyFactors(categoryScores, newsItems);

    return ThreatData(
      threatLevel: finalThreatLevel.clamp(0.0, 100.0),
      timestamp: DateTime.now(),
      primaryThreat: primaryThreat,
      regionalScores: regionalScores,
      keyFactors: keyFactors,
    );
  }

  // Calculate threat scores for each category
  static Map<String, double> _calculateCategoryScores(List<NewsItem> newsItems) {
    Map<String, List<double>> categoryArticleScores = {};
    
    // Initialize category scores
    for (String category in weights.keys) {
      categoryArticleScores[category] = [];
    }

    // Analyze each news item
    for (NewsItem item in newsItems.take(20)) { // Analyze top 20 articles
      String fullText = '${item.title} ${item.description}'.toLowerCase();
      
      // Check each category
      for (String category in weights.keys) {
        double categoryScore = _analyzeCategoryInText(fullText, category);
        if (categoryScore > 0) {
          categoryArticleScores[category]!.add(categoryScore);
        }
      }
    }

    // Calculate average scores for each category
    Map<String, double> categoryScores = {};
    for (String category in weights.keys) {
      List<double> scores = categoryArticleScores[category]!;
      if (scores.isNotEmpty) {
        // Use weighted average with emphasis on higher scores
        scores.sort((a, b) => b.compareTo(a));
        double weightedSum = 0;
        double totalWeight = 0;
        
        for (int i = 0; i < scores.length; i++) {
          double weight = 1.0 / (1 + i * 0.3); // Diminishing weight for lower scores
          weightedSum += scores[i] * weight;
          totalWeight += weight;
        }
        
        categoryScores[category] = totalWeight > 0 ? weightedSum / totalWeight : 0;
      } else {
        categoryScores[category] = 0;
      }
    }

    return categoryScores;
  }

  // Analyze specific category threat in text
  static double _analyzeCategoryInText(String text, String category) {
    List<String> keywords = categoryKeywords[category] ?? [];
    double score = 0;
    int matches = 0;

    // Check for keyword matches
    for (String keyword in keywords) {
      if (text.contains(keyword)) {
        matches++;
        score += 10; // Base score per keyword match
        
        // Check for intensity modifiers around the keyword
        score *= _getIntensityModifier(text, keyword);
      }
    }

    // Bonus for multiple keywords in same category
    if (matches > 1) {
      score *= (1 + (matches - 1) * 0.2); // 20% bonus per additional keyword
    }

    // Normalize to 0-100 scale
    return (score / 2).clamp(0.0, 100.0);
  }

  // Get intensity modifier based on context around keyword
  static double _getIntensityModifier(String text, String keyword) {
    int keywordIndex = text.indexOf(keyword);
    if (keywordIndex == -1) return 1.0;

    // Check surrounding words (±50 characters)
    int start = (keywordIndex - 50).clamp(0, text.length);
    int end = (keywordIndex + keyword.length + 50).clamp(0, text.length);
    String context = text.substring(start, end);

    double modifier = 1.0;
    for (String intensityWord in intensityModifiers.keys) {
      if (context.contains(intensityWord)) {
        modifier *= intensityModifiers[intensityWord]!;
      }
    }

    return modifier.clamp(0.3, 2.0); // Limit extreme modifiers
  }

  // Calculate weighted overall threat level
  static double _calculateWeightedThreatLevel(Map<String, double> categoryScores) {
    double weightedSum = 0;
    double totalWeight = 0;

    for (String category in weights.keys) {
      double score = categoryScores[category] ?? 0;
      double weight = weights[category]!;
      
      weightedSum += score * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? (weightedSum / totalWeight) * 100 : 15.0;
  }

  // Apply time decay and other modifiers
  static double _applyModifiers(double baseThreatLevel, List<NewsItem> newsItems) {
    if (newsItems.isEmpty) return baseThreatLevel;

    // Time decay factor
    double timeWeight = 0;
    double totalWeight = 0;

    for (NewsItem item in newsItems.take(10)) {
      int hoursAgo = DateTime.now().difference(item.publishedAt).inHours;
      double weight = _getTimeWeight(hoursAgo);
      
      timeWeight += weight;
      totalWeight += 1;
    }

    double timeDecayFactor = totalWeight > 0 ? timeWeight / totalWeight : 0.5;
    
    // Apply time decay
    double timAdjustedLevel = baseThreatLevel * (0.7 + timeDecayFactor * 0.3);

    // Global tension multiplier based on number of active threat categories
    Map<String, double> categoryScores = _calculateCategoryScores(newsItems);
    int activeCategories = categoryScores.values.where((score) => score > 20).length;
    
    double globalTensionMultiplier = 1.0;
    if (activeCategories >= 5) {
      globalTensionMultiplier = 1.2; // Multiple threat types = higher overall threat
    } else if (activeCategories >= 3) {
      globalTensionMultiplier = 1.1;
    }

    return timAdjustedLevel * globalTensionMultiplier;
  }

  // Calculate time weight (recent news = higher weight)
  static double _getTimeWeight(int hoursAgo) {
    if (hoursAgo <= 1) return 1.0;      // Last hour: full weight
    if (hoursAgo <= 6) return 0.9;      // Last 6 hours: 90% weight
    if (hoursAgo <= 24) return 0.7;     // Last day: 70% weight
    if (hoursAgo <= 72) return 0.5;     // Last 3 days: 50% weight
    if (hoursAgo <= 168) return 0.3;    // Last week: 30% weight
    return 0.1;                         // Older: 10% weight
  }

  // Calculate regional threat scores
  static Map<String, double> _calculateRegionalScores(List<NewsItem> newsItems) {
    Map<String, List<double>> regionScores = {
      'North America': [],
      'Europe': [],
      'Asia': [],
      'Middle East': [],
      'Africa': [],
      'South America': [],
      'Oceania': [],
    };

    for (NewsItem item in newsItems.take(15)) {
      String region = _identifyRegion(item);
      double itemThreatScore = _calculateItemThreatScore(item);
      
      if (regionScores.containsKey(region)) {
        regionScores[region]!.add(itemThreatScore);
      }
    }

    // Calculate average scores for each region
    Map<String, double> averageScores = {};
    regionScores.forEach((region, scores) {
      if (scores.isNotEmpty) {
        averageScores[region] = scores.reduce((a, b) => a + b) / scores.length;
      } else {
        averageScores[region] = 15.0; // Base low threat level
      }
    });

    return averageScores;
  }

  // Calculate threat score for individual news item using weighted categories
  static double _calculateItemThreatScore(NewsItem item) {
    String fullText = '${item.title} ${item.description}'.toLowerCase();
    Map<String, double> itemCategoryScores = {};

    // Analyze each category for this item
    for (String category in weights.keys) {
      itemCategoryScores[category] = _analyzeCategoryInText(fullText, category);
    }

    // Calculate weighted score
    return _calculateWeightedThreatLevel(itemCategoryScores);
  }

  // Identify which region news item relates to
  static String _identifyRegion(NewsItem item) {
    final text = '${item.title} ${item.description}'.toLowerCase();
    
    // Regional keywords
    Map<String, List<String>> regionKeywords = {
      'Europe': ['ukraine', 'russia', 'europe', 'nato', 'eu', 'germany', 'france', 'poland', 'uk', 'britain', 'italy', 'spain'],
      'Asia': ['china', 'taiwan', 'japan', 'korea', 'india', 'asia', 'pacific', 'philippines', 'vietnam', 'myanmar', 'singapore'],
      'Middle East': ['israel', 'palestine', 'iran', 'syria', 'iraq', 'saudi', 'turkey', 'lebanon', 'jordan', 'egypt', 'yemen'],
      'North America': ['usa', 'america', 'united states', 'canada', 'mexico', 'trump', 'biden', 'washington', 'pentagon'],
      'Africa': ['africa', 'sudan', 'congo', 'ethiopia', 'nigeria', 'south africa', 'kenya', 'ghana', 'morocco', 'algeria'],
      'South America': ['brazil', 'argentina', 'venezuela', 'colombia', 'chile', 'peru', 'bolivia', 'south america'],
      'Oceania': ['australia', 'new zealand', 'pacific islands', 'oceania'],
    };

    // Count matches for each region
    Map<String, int> regionMatches = {};
    regionKeywords.forEach((region, keywords) {
      int matches = 0;
      for (String keyword in keywords) {
        if (text.contains(keyword)) matches++;
      }
      regionMatches[region] = matches;
    });

    // Return region with most matches
    String bestRegion = 'Global';
    int maxMatches = 0;
    regionMatches.forEach((region, matches) {
      if (matches > maxMatches) {
        maxMatches = matches;
        bestRegion = region;
      }
    });

    return bestRegion;
  }

  // Identify primary threat from category scores
  static String _identifyPrimaryThreat(Map<String, double> categoryScores) {
    String primaryCategory = 'Global Monitoring';
    double maxScore = 0;

    categoryScores.forEach((category, score) {
      if (score > maxScore && score > 20) { // Minimum threshold
        maxScore = score;
        primaryCategory = category;
      }
    });

    return _formatThreatName(primaryCategory);
  }

  // Format threat category name for display
  static String _formatThreatName(String category) {
    switch (category.toLowerCase()) {
      case 'military': return 'Military Tensions';
      case 'nuclear': return 'Nuclear Concerns';
      case 'alliance': return 'Alliance Dynamics';
      case 'diplomacy': return 'Diplomatic Relations';
      case 'cyber': return 'Cyber Threats';
      case 'disinfo': return 'Information Warfare';
      case 'economic': return 'Economic Instability';
      case 'unrest': return 'Civil Unrest';
      case 'ai_weapons': return 'AI Weapons Concerns';
      case 'coups': return 'Political Instability';
      case 'climate': return 'Climate-Related Threats';
      case 'space': return 'Space Security';
      case 'biowarfare': return 'Biological Threats';
      default: return 'Global Security Monitoring';
    }
  }

  // Extract key factors from category analysis
  static List<String> _extractKeyFactors(Map<String, double> categoryScores, List<NewsItem> newsItems) {
    // Sort categories by score
    List<MapEntry<String, double>> sortedCategories = categoryScores.entries
        .where((entry) => entry.value > 15) // Minimum threshold
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<String> keyFactors = [];
    
    // Add top threat categories
    for (int i = 0; i < sortedCategories.length && i < 3; i++) {
      keyFactors.add(_formatThreatName(sortedCategories[i].key));
    }

    // Add geographic factors if multiple regions involved
    Set<String> involvedRegions = newsItems.take(10)
        .map((item) => _identifyRegion(item))
        .where((region) => region != 'Global')
        .toSet();
    
    if (involvedRegions.length >= 2) {
      keyFactors.add('Multi-regional tensions');
    }

    // Ensure we have at least some factors
    if (keyFactors.isEmpty) {
      keyFactors.add('Global monitoring active');
    }

    return keyFactors.take(4).toList();
  }
}