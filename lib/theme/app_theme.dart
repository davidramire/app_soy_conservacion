import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seed = Color(0xFF4A90E2);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        splashColor: _seed.withOpacity(0.1),
        highlightColor: _seed.withOpacity(0.05),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.black54,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            splashFactory: InkRipple.splashFactory,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            splashFactory: InkRipple.splashFactory,
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
          surface: const Color(0xFF171717),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        splashColor: _seed.withOpacity(0.15),
        highlightColor: _seed.withOpacity(0.1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF171717),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF171717),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white54,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            splashFactory: InkRipple.splashFactory,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            splashFactory: InkRipple.splashFactory,
          ),
        ),
      );

  static Color surfaceColor(bool isDark) =>
      isDark ? const Color(0xFF171717) : Colors.white;

  static Color textPrimary(bool isDark) =>
      isDark ? Colors.white : Colors.black87;

  static Color textSecondary(bool isDark) =>
      isDark ? Colors.white60 : Colors.black54;
}
