import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF080808);
  static const Color surface = Color(0xFF111111);
  static const Color cardBackground = Color(0xFF0A0A0A);
  
  static const Color border = Color(0x0FFFFFFF);
  static const Color borderLight = Color(0x14FFFFFF);
  static const Color borderFocused = Color(0x33FFFFFF);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x80FFFFFF);
  static const Color textMuted = Color(0x66FFFFFF);
  static const Color textFaint = Color(0x4DFFFFFF);
  static const Color textSubtle = Color(0x40FFFFFF);
  
  static const Color iconDefault = Color(0x66FFFFFF);
  static const Color iconFaint = Color(0x33FFFFFF);
  static const Color iconSubtle = Color(0x1AFFFFFF);
  
  static const Color fill = Color(0x05FFFFFF);
  static const Color fillLight = Color(0x08FFFFFF);
  static const Color fillMedium = Color(0x0DFFFFFF);
}

class AppXP {
  static const int checklistComplete = 25;
  static const int checklistUndo = -25;
  
  static const int levelBase = 100;
  
  static const int achievementCentury = 100;
  static const int achievementHighRoller = 500;
  static const int achievementVeteranLevel = 5;
  
  static int xpForLevel(int level) => level * levelBase;
  static int xpForCurrentLevel(int level) => (level - 1) * levelBase;
}

class AppStrings {
  static const String appName = 'Nexus Tracker';
  static const String defaultUsername = 'local';
  
  static const String dashboard = 'Dashboard';
  static const String groundRules = 'Ground Rules';
  static const String notebook = 'Notebook';
  static const String analytics = 'Analytics';
  
  static const String newRule = 'New Rule';
  static const String editRule = 'Edit Rule';
  static const String createRule = 'Create Rule';
  static const String updateRule = 'Update Rule';
  static const String deleteRule = 'Delete Rule';
  
  static const String newWriteup = 'New Writeup';
  static const String editWriteup = 'Edit Writeup';
  static const String postNote = 'Post Note';
  static const String updateNote = 'Update Note';
  static const String deleteWriteup = 'Delete Writeup';
  
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String save = 'Save';
  
  static const String frequency = 'FREQUENCY';
  static const String difficulty = 'DIFFICULTY';
  
  static const List<String> frequencies = ['daily', 'weekly', 'one-time'];
  static const List<String> difficulties = ['easy', 'medium', 'hard'];
}

class AppDimensions {
  static const double borderRadius = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXL = 16.0;
  
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingScreen = 24.0;
  
  static const double iconSmall = 14.0;
  static const double iconMedium = 18.0;
  static const double iconLarge = 20.0;
  static const double iconXL = 48.0;
  
  static const double fontSizeSmall = 9.0;
  static const double fontSizeXS = 10.0;
  static const double fontSizeSmall2 = 12.0;
  static const double fontSizeMedium = 13.0;
  static const double fontSizeLarge = 14.0;
  static const double fontSizeXL = 15.0;
  static const double fontSizeTitle = 16.0;
  static const double fontSizeHeading = 24.0;
  
  static const double sidebarWidth = 240.0;
  static const double breakpointDesktop = 900.0;
}
