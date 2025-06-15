// lib/services/historical_threat_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/historical_threat_data.dart';
import '../models/threat_trend.dart';
import '../models/threat_data.dart';

class HistoricalThreatService {
  static const String _storageKey = 'historical_threat_data';
  static const int _maxStorageDays = 90; // Keep 3 months of data

  // Save current threat data to history
  static Future<void> saveThreatData(ThreatData threatData, Map<String, double> categoryScores) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing data
      List<HistoricalThreatData> historicalData = await getHistoricalData();
      
      // Create new historical entry
      HistoricalThreatData newEntry = HistoricalThreatData(
        threatLevel: threatData.threatLevel,
        timestamp: threatData.timestamp,
        primaryThreat: threatData.primaryThreat,
        categoryScores: Map<String, double>.from(categoryScores),
        regionalScores: Map<String, double>.from(threatData.regionalScores),
      );
      
      // Add new entry
      historicalData.add(newEntry);
      
      // Remove old data (keep only last 90 days)
      final cutoffDate = DateTime.now().subtract(Duration(days: _maxStorageDays));
      historicalData.removeWhere((data) => data.timestamp.isBefore(cutoffDate));
      
      // Sort by timestamp
      historicalData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Save to storage
      List<Map<String, dynamic>> serializedData = historicalData
          .map((data) => data.toMap())
          .toList();
      
      await prefs.setString(_storageKey, json.encode(serializedData));
      
      print('Saved historical threat data: ${threatData.threatLevel} at ${threatData.timestamp}');
    } catch (e) {
      print('Error saving historical threat data: $e');
    }
  }

  // Get all historical threat data
  static Future<List<HistoricalThreatData>> getHistoricalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? dataString = prefs.getString(_storageKey);
      
      if (dataString == null) return [];
      
      List<dynamic> dataList = json.decode(dataString);
      return dataList.map((data) => HistoricalThreatData.fromMap(data)).toList();
    } catch (e) {
      print('Error loading historical threat data: $e');
      return [];
    }
  }

  // Calculate threat trend with change percentage
  static Future<ThreatTrend> calculateThreatTrend(ThreatData currentThreat) async {
    List<HistoricalThreatData> historicalData = await getHistoricalData();
    
    if (historicalData.isEmpty) {
      return ThreatTrend(
        currentLevel: currentThreat.threatLevel,
        previousLevel: currentThreat.threatLevel,
        changePercent: 0.0,
        changeDirection: 'stable',
        comparisonPeriod: DateTime.now().subtract(Duration(days: 30)),
        historicalData: [],
      );
    }

    // Get threat level from 30 days ago (or closest available)
    DateTime thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    HistoricalThreatData? pastData = _findClosestHistoricalData(historicalData, thirtyDaysAgo);
    
    if (pastData == null) {
      // Use oldest available data if less than 30 days of history
      pastData = historicalData.first;
    }

    // Calculate change percentage
    double changePercent = _calculateChangePercent(pastData.threatLevel, currentThreat.threatLevel);
    String changeDirection = _getChangeDirection(changePercent);

    return ThreatTrend(
      currentLevel: currentThreat.threatLevel,
      previousLevel: pastData.threatLevel,
      changePercent: changePercent,
      changeDirection: changeDirection,
      comparisonPeriod: pastData.timestamp,
      historicalData: historicalData,
    );
  }

  // Get weekly averages for the past month
  static Future<List<Map<String, dynamic>>> getWeeklyAverages() async {
    List<HistoricalThreatData> historicalData = await getHistoricalData();
    
    if (historicalData.isEmpty) return [];

    List<Map<String, dynamic>> weeklyData = [];
    DateTime now = DateTime.now();
    
    for (int week = 0; week < 4; week++) {
      DateTime weekStart = now.subtract(Duration(days: (week + 1) * 7));
      DateTime weekEnd = now.subtract(Duration(days: week * 7));
      
      List<HistoricalThreatData> weekData = historicalData
          .where((data) => data.timestamp.isAfter(weekStart) && data.timestamp.isBefore(weekEnd))
          .toList();
      
      if (weekData.isNotEmpty) {
        double averageThreat = weekData
            .map((data) => data.threatLevel)
            .reduce((a, b) => a + b) / weekData.length;
        
        weeklyData.add({
          'week': 4 - week,
          'average': averageThreat,
          'date': weekStart,
          'dataPoints': weekData.length,
        });
      }
    }
    
    return weeklyData.reversed.toList();
  }

  // Get category trend analysis
  static Future<Map<String, double>> getCategoryTrends() async {
    List<HistoricalThreatData> historicalData = await getHistoricalData();
    
    if (historicalData.length < 2) return {};

    Map<String, double> categoryTrends = {};
    
    // Get recent average (last 7 days) vs older average (8-14 days ago)
    DateTime now = DateTime.now();
    DateTime recentStart = now.subtract(Duration(days: 7));
    DateTime olderStart = now.subtract(Duration(days: 14));
    DateTime olderEnd = now.subtract(Duration(days: 7));
    
    List<HistoricalThreatData> recentData = historicalData
        .where((data) => data.timestamp.isAfter(recentStart))
        .toList();
    
    List<HistoricalThreatData> olderData = historicalData
        .where((data) => data.timestamp.isAfter(olderStart) && data.timestamp.isBefore(olderEnd))
        .toList();
    
    if (recentData.isEmpty || olderData.isEmpty) return {};

    // Calculate trends for each category
    Set<String> allCategories = <String>{};
    for (var data in [...recentData, ...olderData]) {
      allCategories.addAll(data.categoryScores.keys);
    }

    for (String category in allCategories) {
      double recentAvg = _calculateCategoryAverage(recentData, category);
      double olderAvg = _calculateCategoryAverage(olderData, category);
      
      if (olderAvg > 0) {
        categoryTrends[category] = _calculateChangePercent(olderAvg, recentAvg);
      }
    }

    return categoryTrends;
  }

  // Helper method to find closest historical data to a target date
  static HistoricalThreatData? _findClosestHistoricalData(List<HistoricalThreatData> data, DateTime targetDate) {
    if (data.isEmpty) return null;
    
    HistoricalThreatData closest = data.first;
    Duration smallestDiff = (data.first.timestamp.difference(targetDate)).abs();
    
    for (HistoricalThreatData item in data) {
      Duration diff = (item.timestamp.difference(targetDate)).abs();
      if (diff < smallestDiff) {
        smallestDiff = diff;
        closest = item;
      }
    }
    
    return closest;
  }

  // Calculate percentage change between two values
  static double _calculateChangePercent(double oldValue, double newValue) {
    if (oldValue == 0) return 0.0;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  // Determine change direction
  static String _getChangeDirection(double changePercent) {
    if (changePercent > 2) return 'up';
    if (changePercent < -2) return 'down';
    return 'stable';
  }

  // Calculate average category score from historical data
  static double _calculateCategoryAverage(List<HistoricalThreatData> data, String category) {
    List<double> scores = data
        .map((item) => item.categoryScores[category] ?? 0.0)
        .where((score) => score > 0)
        .toList();
    
    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  // Clear all historical data
  static Future<void> clearHistoricalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('Historical threat data cleared');
    } catch (e) {
      print('Error clearing historical data: $e');
    }
  }

  // Get data summary for debugging
  static Future<Map<String, dynamic>> getDataSummary() async {
    List<HistoricalThreatData> data = await getHistoricalData();
    
    if (data.isEmpty) {
      return {'totalEntries': 0, 'dateRange': 'No data'};
    }

    return {
      'totalEntries': data.length,
      'oldestEntry': data.first.timestamp.toString(),
      'newestEntry': data.last.timestamp.toString(),
      'averageThreatLevel': data.map((d) => d.threatLevel).reduce((a, b) => a + b) / data.length,
    };
  }
}
