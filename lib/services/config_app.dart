import 'package:flutter/material.dart';

class AppConfig {
  // Storage keys
  static const String dailyConsosKey = 'daily_consos';
  static const String characterProfileKey = 'character_profile';

  // Character settings
  static const int xpPerLevel = 100;
  static const int maxCharacterLevel = 100;
  static const int defaultMaxPv = 100;
  static const int dailyXpReward = 10;
  static const double healthThresholdForXp = 0.75;

  // Risk calculation
  static const double criticalRiskThreshold = 0.15;
  static const int maxReasonableConsos = 50;
  static const int maxDataAgeInDays = 730; // 2 years

  // Animation durations
  static const Duration gaugeAnimationDuration = Duration(milliseconds: 420);
  static const Duration bubbleAnimationDuration = Duration(seconds: 8);
  static const Duration calendarAnimationDuration = Duration(milliseconds: 400);
  static const Duration shadowAnimationDuration = Duration(milliseconds: 2600);
  static const Duration audioFadeOutDuration = Duration(milliseconds: 800);

  // UI constants
  static const double mainButtonSize = 88.0;
  static const double innerButtonSize = 64.0;
  static const double resetButtonSize = 32.0;
  static const double calendarCellSize = 38.0;

  // Colors
  static const Color primaryGradientStart = Color(0xFF95C6F4);
  static const Color primaryGradientEnd = Colors.white;
  static const Color statusBarColor = Color(0xFF95C6F4);
  static const Color calendarButtonStart = Color(0xFFF7D83F);
  static const Color calendarButtonEnd = Color(0xFFF6C84A);

  // Health zones thresholds
  static const double powerZoneThreshold = 0.75;
  static const double warningZoneThreshold = 0.50;
  static const double dangerZoneThreshold = 0.25;

  // Audio settings
  static const String beerSoundAsset = 'beer_sound.mp3';
  static const int audioFadeStepMs = 60;
  static const int bubbleOpacity = 40;
  static const int bubbleCount = 16;

  // Validation limits
  static const int maxDailyConsos = 20;
  static const int minLevel = 1;
  static const int maxWeeklyConsos = 50;

  // Assets
  static const String characterMessagesAsset = 'assets/character_messages.json';
  static const String avatarAsset = 'assets/avatar.png';
}

class ThemeConfig {
  static const Map<String, Color> healthZoneColors = {
    'power': Colors.green,
    'warning': Colors.orange,
    'danger': Colors.deepOrange,
    'critical': Colors.red,
    'dead': Colors.black54,
  };

  static const Map<String, List<Color>> consumptionLevelColors = {
    'low': [
      Color(0xFF4CAF50),
      Color(0xFF66BB6A),
    ], // Green gradient for 0-2 drinks
    'moderate': [
      Color(0xFFFFB74D),
      Color(0xFFFFA726),
    ], // Orange gradient for 3-4 drinks
    'high': [
      Color(0xFFFF7043),
      Color(0xFFFF5722),
    ], // Deep orange for 5-6 drinks
    'excessive': [
      Color(0xFFE53935),
      Color(0xFFD32F2F),
    ], // Red gradient for 7+ drinks
  };

  static const Map<String, Color> calendarDayColors = {
    'safe': Color(0xFF4CAF50), // Green for <= 2 drinks
    'moderate': Color(0xFFFFB74D), // Yellow for 3-4 drinks
    'risky': Color(0xFFFF7043), // Orange for 5-6 drinks
    'dangerous': Color(0xFFE53935), // Red for 7+ drinks
  };

  // Button styling
  static const List<Color> primaryButtonGradient = [
    Color(0xFFF7D83F),
    Color(0xFFF6C84A),
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFF95C6F4),
    Colors.white,
  ];

  static const List<Color> calendarDialogGradient = [
    Color.fromARGB(255, 250, 225, 100),
    Color.fromARGB(255, 245, 200, 80),
  ];

  // Shadow and glass effects
  static const Color shadowColor = Colors.black;
  static const double shadowOpacity = 0.2;
  static const double glassOpacity = 0.28;
  static const Color glassHighlight = Colors.white;
  static const double glassBorderOpacity = 0.35;

  // Text styles
  static const TextStyle headerTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle captionTextStyle = TextStyle(
    fontSize: 12,
    color: Colors.black54,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontWeight: FontWeight.w800,
    color: Colors.black87,
  );

  // Calendar specific colors
  static const Color calendarBackground = Colors.white;
  static const double calendarBackgroundOpacity = 0.85;
  static const Color calendarSelectedDay = Color(0xFFF7D83F);
  static const Color calendarBorder = Colors.grey;

  // Animation curves
  static const Curve defaultAnimationCurve = Curves.easeInOutCubic;
  static const Curve buttonPressCurve = Curves.easeOut;

  // Bubble effect colors
  static const List<Color> bubbleColors = [
    Colors.white,
    Colors.blueAccent,
    Colors.lightBlueAccent,
  ];

  // Health bar colors based on percentage
  static Color getHealthBarColor(double healthPercent) {
    if (healthPercent > 0.75) return Colors.green.shade600;
    if (healthPercent > 0.50) return Colors.orange.shade600;
    if (healthPercent > 0.25) return Colors.deepOrange.shade600;
    if (healthPercent > 0.0) return Colors.red.shade600;
    return Colors.black54;
  }

  // Get consumption level color based on daily count
  static Color getConsumptionColor(int count) {
    if (count <= 2) return calendarDayColors['safe']!;
    if (count <= 4) return calendarDayColors['moderate']!;
    if (count <= 6) return calendarDayColors['risky']!;
    return calendarDayColors['dangerous']!;
  }

  // Get consumption level gradient based on daily count
  static List<Color> getConsumptionGradient(int count) {
    if (count <= 2) return consumptionLevelColors['low']!;
    if (count <= 4) return consumptionLevelColors['moderate']!;
    if (count <= 6) return consumptionLevelColors['high']!;
    return consumptionLevelColors['excessive']!;
  }

  // Box shadow presets
  static const List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.2),
      offset: Offset(0, 8),
      blurRadius: 20,
    ),
  ];

  // Border radius presets
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius mediumRadius = BorderRadius.all(
    Radius.circular(16),
  );
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius circularRadius = BorderRadius.all(
    Radius.circular(50),
  );
}
