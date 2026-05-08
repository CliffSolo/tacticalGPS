import 'package:flutter/material.dart';

class CatppuccinMocha {
  static const Color base = Color(0xFF1E1E2E);
  static const Color mantle = Color(0xFF181825);
  static const Color crust = Color(0xFF11111B);
  static const Color surface0 = Color(0xFF313244);
  static const Color surface1 = Color(0xFF45475A);
  static const Color surface2 = Color(0xFF585B70);
  static const Color overlay0 = Color(0xFF6C7086);
  static const Color overlay1 = Color(0xFF7F849C);
  static const Color overlay2 = Color(0xFF9399B2);
  static const Color text = Color(0xFFCDD6F4);
  static const Color subtext0 = Color(0xFFA6ADC8);
  static const Color subtext1 = Color(0xFFBAC2DE);
  static const Color blue = Color(0xFF89B4FA);
  static const Color green = Color(0xFFA6E3A1);
  static const Color red = Color(0xFFF38BA8);
  static const Color peach = Color(0xFFFAB387);
  static const Color mauve = Color(0xFFCBA6F7);
  static const Color teal = Color(0xFF94E2D5);
  static const Color yellow = Color(0xFFF9E2AF);
  static const Color sapphire = Color(0xFF74C7EC);
  static const Color sky = Color(0xFF89DCEB);
  static const Color lavender = Color(0xFFB4BEFE);
  static const Color maroon = Color(0xFFEBA0AC);
  static const Color flamingo = Color(0xFFF2CDCD);
  static const Color pink = Color(0xFFF5C2E7);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: base,
        colorScheme: const ColorScheme.dark(
          surface: surface0,
          primary: blue,
          secondary: mauve,
          error: red,
          onSurface: text,
          onPrimary: base,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: text, letterSpacing: 2),
          bodyLarge: TextStyle(color: text),
          bodyMedium: TextStyle(color: subtext1),
          labelLarge: TextStyle(color: subtext0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: mantle,
          foregroundColor: text,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: surface0,
            foregroundColor: text,
          ),
        ),
      );
}

class TacticalGreen {
  static const Color base = Color(0xFF010C01);
  static const Color mantle = Color(0xFF012301);
  static const Color surface0 = Color(0xFF0A2E0A);
  static const Color surface1 = Color(0xFF1A4A1A);
  static const Color surface2 = Color(0xFF2E6B2E);
  static const Color overlay0 = Color(0xFF3D7A3D);
  static const Color text = Color(0xFF66BF2F);
  static const Color subtext0 = Color(0xFF439413);
  static const Color primary = Color(0xFF66BF2F);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color accent1 = Color(0xFF88D44E);
  static const Color accent2 = Color(0xFF2E7901);
  static const Color accent3 = Color(0xFF9CCC65);
  static const Color red = Color(0xFF4E9A2E);
  static const Color blue = Color(0xFF66BF2F);
  static const Color green = Color(0xFF88D44E);
  static const Color peach = Color(0xFF9CCC65);
  static const Color mauve = Color(0xFF4CAF50);
  static const Color teal = Color(0xFF66BF2F);
  static const Color yellow = Color(0xFF9CCC65);
  static const Color sapphire = Color(0xFF558B2F);
  static const Color pink = Color(0xFF88D44E);
  static const Color lavender = Color(0xFF9CCC65);
  static const Color maroon = Color(0xFF4CAF50);
  static const Color sky = Color(0xFF66BF2F);
  static const Color flamingo = Color(0xFF88D44E);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: base,
        colorScheme: const ColorScheme.dark(
          surface: surface0,
          primary: primary,
          secondary: secondary,
          onSurface: text,
          onPrimary: base,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: mantle,
          foregroundColor: text,
          elevation: 0,
        ),
      );
}
