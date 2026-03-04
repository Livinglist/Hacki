import 'package:flutter/material.dart';
import 'package:hacki/models/font.dart';

extension ThemeDataExtension on ThemeData {
  Color get readGrey => colorScheme.onSurface.withValues(alpha: 0.6);

  Color get metadataColor => colorScheme.onSurface.withValues(alpha: 0.8);
}

class HackerNewsTheme {
  // 🎨 HN Colors
  static const Color hnOrange = Color(0xFFFF6600);
  static const Color hnBackground = Color(0xFFF6F6EF); // classic HN beige
  static const Color hnNavBar = Color(0xFFFF6600);
  static const Color hnText = Color(0xFF000000);
  static const Color hnSubtext = Color(0xFF828282); // points, time, username
  static const Color hnLink = Color(0xFF000000);
  static const Color hnVisitedLink = Color(0xFF828282);
  static const Color hnDivider = Color(0xFFE8E8E8);
  static const Color hnWhite = Color(0xFFFFFFFF);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: hnOrange,
          secondary: hnOrange,
          surface: hnBackground,
        ),

        // Background
        scaffoldBackgroundColor: hnBackground,

        // AppBar - HN orange bar
        appBarTheme: AppBarTheme(
          backgroundColor: hnOrange,
          foregroundColor: hnWhite,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: hnWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: Font.courier.name,
          ),
        ),

        fontFamily: Font.courier.name,
        // Text
        textTheme: TextTheme(
          // Story title
          titleMedium: TextStyle(
            color: hnText,
            fontSize: 16,
            fontFamily: Font.courier.name,
          ),
          // Points, time, username
          bodySmall: TextStyle(
            color: hnSubtext,
            fontSize: 14,
            fontFamily: Font.courier.name,
          ),
          // Body
          bodyMedium: TextStyle(
            color: hnText,
            fontSize: 15,
            fontFamily: Font.courier.name,
          ),
          labelSmall: TextStyle(
            color: hnLink, // for links/points
            fontSize: 14,
            fontFamily: Font.courier.name,
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: hnDivider,
          thickness: 1,
          space: 0,
        ),

        // List tiles (story rows)
        listTileTheme: const ListTileThemeData(
          tileColor: hnBackground,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          dense: true,
        ),

        // Buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: hnSubtext,
            textStyle: TextStyle(
              fontSize: 14,
              fontFamily: Font.courier.name,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          hintStyle: const TextStyle(color: hnSubtext, fontSize: 13),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: hnDivider,
            ),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: hnOrange),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: hnOrange.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
}

class HackerNewsDarkTheme {
  // 🎨 HN Dark Colors
  static const Color hnOrange = Color(0xFFFF6600);
  static const Color hnBackground = Color(0xFF1A1A1A);
  static const Color hnSurface = Color(0xFF242424);
  static const Color hnNavBar = Color(0xFF222222);
  static const Color hnText = Color(0xFFE6E6E6);
  static const Color hnSubtext = Color(0xFF828282);
  static const Color hnDivider = Color(0xFF333333);
  static const Color hnWhite = Color(0xFFFFFFFF);
  static const Color hnLink = Color(0xFFFF9A57); // orange-tinted links
  static const Color hnVisitedLink = Color(0xFF828282);
  static const Color hnCardBackground = Color(0xFF2C2C2C);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: hnOrange,
          secondary: hnOrange,
          surface: hnSurface,
          onPrimary: hnWhite,
          onSurface: hnText,
          outline: hnDivider,
        ),

        scaffoldBackgroundColor: hnSurface,

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: hnNavBar,
          foregroundColor: hnWhite,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: hnOrange,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: Font.courier.name,
          ),
        ),

        // Text
        fontFamily: Font.courier.name,
        textTheme: TextTheme(
          titleMedium: TextStyle(
            color: hnText,
            fontSize: 16,
            fontFamily: Font.courier.name,
          ),
          bodySmall: TextStyle(
            color: hnSubtext,
            fontSize: 14,
            fontFamily: Font.courier.name,
          ),
          bodyMedium: TextStyle(
            color: hnText,
            fontSize: 15,
            fontFamily: Font.courier.name,
          ),
          labelSmall: TextStyle(
            color: hnLink, // for links/points
            fontSize: 14,
            fontFamily: Font.courier.name,
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: hnDivider,
          thickness: 1,
          space: 0,
        ),

        // List tiles
        listTileTheme: const ListTileThemeData(
          tileColor: hnSurface,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          dense: true,
        ),

        // Buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: hnOrange,
            textStyle: TextStyle(
              fontSize: 14,
              fontFamily: Font.courier.name,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          hintStyle: const TextStyle(color: hnSubtext, fontSize: 13),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: hnDivider,
            ),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: hnOrange),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: hnOrange.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
}
