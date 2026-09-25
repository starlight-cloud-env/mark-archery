import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// "Ledger" — warm paper, ink, and a single stamp-red accent. Dark mode is a
// deliberate "night ledger" (dark leather-bound), not a naive inversion.
const _paperLight = Color(0xFFEFE9DD);
const _paperRaisedLight = Color(0xFFF7F3EA);
const _inkLight = Color(0xFF2B2620);
const _inkSoftLight = Color(0xFF5A5346);
const _ruleLight = Color(0xFFC9BFA8);
const _stampLight = Color(0xFF8C2F2F);

const _paperDark = Color(0xFF221D17);
const _paperRaisedDark = Color(0xFF2B241C);
const _inkDark = Color(0xFFEFE9DD);
const _inkSoftDark = Color(0xFFB8AD98);
const _ruleDark = Color(0xFF4A4030);
const _stampDark = Color(0xFFD9635F);

const _radius = 8.0;

/// Applies the mono/tabular-figures treatment used for every score, date,
/// and count in the app — the ledger reads as a real record book only if
/// numbers always line up. Use for any numeric display.
const _monoFeatures = [FontFeature.tabularFigures()];
TextStyle? mono(TextStyle? base) =>
    base?.copyWith(fontFamily: 'IBM Plex Mono', fontFeatures: _monoFeatures);

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
  primary: _stampLight,
  onPrimary: Colors.white,
  secondary: _stampLight,
  onSecondary: Colors.white,
  error: const Color(0xFFBA1A1A),
  onError: Colors.white,
  surface: _paperLight,
  onSurface: _inkLight,
  surfaceContainerHighest: _paperRaisedLight,
  onSurfaceVariant: _inkSoftLight,
  outline: _ruleLight,
  outlineVariant: _ruleLight,
);

final _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _stampDark,
  onPrimary: _paperDark,
  secondary: _stampDark,
  onSecondary: _paperDark,
  error: const Color(0xFFFFB4AB),
  onError: const Color(0xFF1A1A1A),
  surface: _paperDark,
  onSurface: _inkDark,
  surfaceContainerHighest: _paperRaisedDark,
  onSurfaceVariant: _inkSoftDark,
  outline: _ruleDark,
  outlineVariant: _ruleDark,
);

/// Headings/titles set in the serif, body/labels in sans — same split shown
/// in the Ledger style guide's type scale.
TextTheme _ledgerTextTheme(TextTheme base, Color color) {
  final serif = base.apply(
    fontFamily: 'IBM Plex Serif',
    bodyColor: color,
    displayColor: color,
  );
  final sans = base.apply(
    fontFamily: 'IBM Plex Sans',
    bodyColor: color,
    displayColor: color,
  );
  return sans.copyWith(
    displayLarge: serif.displayLarge,
    displayMedium: serif.displayMedium,
    displaySmall: serif.displaySmall,
    headlineLarge: serif.headlineLarge,
    headlineMedium: serif.headlineMedium,
    headlineSmall: serif.headlineSmall,
    titleLarge: serif.titleLarge,
    titleMedium: serif.titleMedium,
    titleSmall: serif.titleSmall,
  );
}

final lightTheme = _shared.copyWith(
  brightness: Brightness.light,
  scaffoldBackgroundColor: _lightColorScheme.surface,
  colorScheme: _lightColorScheme,
  textTheme: _ledgerTextTheme(_shared.textTheme, _lightColorScheme.onSurface),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    backgroundColor: _lightColorScheme.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: _lightColorScheme.surfaceContainerHighest,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
      side: BorderSide(color: _lightColorScheme.outlineVariant),
    ),
    margin: EdgeInsets.zero,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _lightColorScheme.primary,
      foregroundColor: _lightColorScheme.onPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      textStyle: const TextStyle(
        fontFamily: 'IBM Plex Mono',
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _lightColorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      side: BorderSide(color: _lightColorScheme.outline),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: false,
    contentPadding: const EdgeInsets.symmetric(vertical: 10),
    labelStyle: TextStyle(
      fontFamily: 'IBM Plex Mono',
      fontSize: 12,
      letterSpacing: 0.4,
      color: _lightColorScheme.onSurfaceVariant,
    ),
    border: UnderlineInputBorder(
      borderSide: BorderSide(color: _lightColorScheme.outline),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: _lightColorScheme.outline),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
    ),
  ),
);

final darkTheme = _shared.copyWith(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _darkColorScheme.surface,
  colorScheme: _darkColorScheme,
  textTheme: _ledgerTextTheme(_shared.textTheme, _darkColorScheme.onSurface),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    backgroundColor: _darkColorScheme.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: _darkColorScheme.surfaceContainerHighest,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
      side: BorderSide(color: _darkColorScheme.outlineVariant),
    ),
    margin: EdgeInsets.zero,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _darkColorScheme.primary,
      foregroundColor: _darkColorScheme.onPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      textStyle: const TextStyle(
        fontFamily: 'IBM Plex Mono',
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _darkColorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      side: BorderSide(color: _darkColorScheme.outline),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: false,
    contentPadding: const EdgeInsets.symmetric(vertical: 10),
    labelStyle: TextStyle(
      fontFamily: 'IBM Plex Mono',
      fontSize: 12,
      letterSpacing: 0.4,
      color: _darkColorScheme.onSurfaceVariant,
    ),
    border: UnderlineInputBorder(
      borderSide: BorderSide(color: _darkColorScheme.outline),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: _darkColorScheme.outline),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
    ),
  ),
);
