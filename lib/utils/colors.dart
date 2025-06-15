import 'package:flutter/material.dart';

class AppColors {
  // Threat Level Colors
  static const Color lowThreat = Color(0xFF4CAF50);    // Green
  static const Color mediumThreat = Color(0xFFFF9800);  // Orange
  static const Color highThreat = Color(0xFFF44336);    // Red
  static const Color criticalThreat = Color(0xFF9C27B0); // Purple
  
  // App Theme Colors
  static const Color primaryColor = Color(0xFF1A1A1A);
  static const Color secondaryColor = Color(0xFF2D2D2D);
  static const Color accentColor = Color(0xFF00BCD4);
  
  // Text Colors
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFB0B0B0);
  
  // Background Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  
  static Color getThreatColor(double threatLevel) {
    if (threatLevel < 30) return lowThreat;
    if (threatLevel < 50) return mediumThreat;
    if (threatLevel < 70) return highThreat;
    return criticalThreat;
  }
}