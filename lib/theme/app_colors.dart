import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import 'catppuccin.dart';

class AppColors {
  final Color base;
  final Color mantle;
  final Color surface0;
  final Color surface1;
  final Color surface2;
  final Color overlay0;
  final Color text;
  final Color subtext0;
  final Color primary;
  final Color secondary;
  final Color green;
  final Color red;
  final Color peach;
  final Color mauve;
  final Color teal;
  final Color yellow;
  final Color sapphire;
  final Color blue;
  final Color pink;
  final Color lavender;
  final Color maroon;
  final Color sky;
  final Color flamingo;

  const AppColors({
    required this.base,
    required this.mantle,
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.overlay0,
    required this.text,
    required this.subtext0,
    required this.primary,
    required this.secondary,
    required this.green,
    required this.red,
    required this.peach,
    required this.mauve,
    required this.teal,
    required this.yellow,
    required this.sapphire,
    required this.blue,
    required this.pink,
    required this.lavender,
    required this.maroon,
    required this.sky,
    required this.flamingo,
  });

  static AppColors of(AppThemeMode mode) {
    if (mode == AppThemeMode.tacticalGreen) {
      return AppColors(
        base: TacticalGreen.base,
        mantle: TacticalGreen.mantle,
        surface0: TacticalGreen.surface0,
        surface1: TacticalGreen.surface1,
        surface2: TacticalGreen.surface2,
        overlay0: TacticalGreen.overlay0,
        text: TacticalGreen.text,
        subtext0: TacticalGreen.subtext0,
        primary: TacticalGreen.primary,
        secondary: TacticalGreen.secondary,
        green: TacticalGreen.green,
        red: TacticalGreen.red,
        peach: TacticalGreen.peach,
        mauve: TacticalGreen.mauve,
        teal: TacticalGreen.teal,
        yellow: TacticalGreen.yellow,
        sapphire: TacticalGreen.sapphire,
        blue: TacticalGreen.blue,
        pink: TacticalGreen.pink,
        lavender: TacticalGreen.lavender,
        maroon: TacticalGreen.maroon,
        sky: TacticalGreen.sky,
        flamingo: TacticalGreen.flamingo,
      );
    }
    return const AppColors(
      base: CatppuccinMocha.base,
      mantle: CatppuccinMocha.mantle,
      surface0: CatppuccinMocha.surface0,
      surface1: CatppuccinMocha.surface1,
      surface2: CatppuccinMocha.surface2,
      overlay0: CatppuccinMocha.overlay0,
      text: CatppuccinMocha.text,
      subtext0: CatppuccinMocha.subtext0,
      primary: CatppuccinMocha.blue,
      secondary: CatppuccinMocha.mauve,
      green: CatppuccinMocha.green,
      red: CatppuccinMocha.red,
      peach: CatppuccinMocha.peach,
      mauve: CatppuccinMocha.mauve,
      teal: CatppuccinMocha.teal,
      yellow: CatppuccinMocha.yellow,
      sapphire: CatppuccinMocha.sapphire,
      blue: CatppuccinMocha.blue,
      pink: CatppuccinMocha.pink,
      lavender: CatppuccinMocha.lavender,
      maroon: CatppuccinMocha.maroon,
      sky: CatppuccinMocha.sky,
      flamingo: CatppuccinMocha.flamingo,
    );
  }
}
