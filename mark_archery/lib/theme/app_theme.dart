import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

const _bronzeAccent = Color(0xFFA0632D);
const _goldAccent = Color(0xFFD8B24A);
const _radius = 14.0;

final _shared = ThemeData(
  useMaterial3: true,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  splashFactory: InkSparkle.splashFactory,
);

final _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: _bronzeAccent,
  onPrimary: Colors.white,
  secondary: _bronzeAccent,
  onSecondary: Colors.white,
  error: const Color(0xFFBA1A1A),
  onError: Colors.white,
  surface: const Color(0xFFF2F2F0),
  onSurface: const Color(0xFF1A1A1A),
  surfaceContainerHighest: Colors.white,
  onSurfaceVariant: const Color(0xFF6E6E6E),
  outline: const Color(0xFFDDDDDD),
  outlineVariant: const Color(0xFFE8E8E8),
);

final _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _goldAccent,
  onPrimary: const Color(0xFF1A1A1A),
  secondary: _goldAccent,
  onSecondary: const Color(0xFF1A1A1A),
  error: const Color(0xFFFFB4AB),
  onError: const Color(0xFF1A1A1A),
  surface: const Color(0xFF1A1A1A),
  onSurface: const Color(0xFFF2F2F0),
  surfaceContainerHighest: const Color(0xFF262626),
  onSurfaceVariant: const Color(0xFF9E9E9E),
  outline: const Color(0xFF3A3A3A),
  outlineVariant: const Color(0xFF2E2E2E),
);

final lightTheme = _shared.copyWith(
  brightness: Brightness.light,
  scaffoldBackgroundColor: _lightColorScheme.surface,
  colorScheme: _lightColorScheme,
  textTheme: _shared.textTheme.apply(
    fontFamily: 'IBM Plex Sans',
    bodyColor: _lightColorScheme.onSurface,
    displayColor: _lightColorScheme.onSurface,
  ),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    backgroundColor: _lightColorScheme.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: _lightColorScheme.surfaceContainerHighest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
    margin: EdgeInsets.zero,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _lightColorScheme.primary,
      foregroundColor: _lightColorScheme.onPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      side: BorderSide(color: _lightColorScheme.outline),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 64,
    elevation: 0,
    backgroundColor: _lightColorScheme.surface,
    indicatorColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      return TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
        color: states.contains(WidgetState.selected)
            ? _lightColorScheme.primary
            : _lightColorScheme.onSurfaceVariant,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      return IconThemeData(
        color: states.contains(WidgetState.selected)
            ? _lightColorScheme.primary
            : _lightColorScheme.onSurfaceVariant,
        size: 22,
      );
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _lightColorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide.none,
    ),
  ),
);

final darkTheme = _shared.copyWith(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _darkColorScheme.surface,
  colorScheme: _darkColorScheme,
  textTheme: _shared.textTheme.apply(
    fontFamily: 'IBM Plex Sans',
    bodyColor: _darkColorScheme.onSurface,
    displayColor: _darkColorScheme.onSurface,
  ),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    backgroundColor: _darkColorScheme.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: _darkColorScheme.surfaceContainerHighest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
    margin: EdgeInsets.zero,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _darkColorScheme.primary,
      foregroundColor: _darkColorScheme.onPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      side: BorderSide(color: _darkColorScheme.outline),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 64,
    elevation: 0,
    backgroundColor: _darkColorScheme.surface,
    indicatorColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      return TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
        color: states.contains(WidgetState.selected)
            ? _darkColorScheme.primary
            : _darkColorScheme.onSurfaceVariant,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      return IconThemeData(
        color: states.contains(WidgetState.selected)
            ? _darkColorScheme.primary
            : _darkColorScheme.onSurfaceVariant,
        size: 22,
      );
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _darkColorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide.none,
    ),
  ),
);
