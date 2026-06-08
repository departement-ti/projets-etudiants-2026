import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rayhan_erp/constants/custom_page_transition.dart';

abstract final class AppTheme {
  // ── Color Palette ──────────────────────────────────────────────
  // Palette: https://colorhunt.co/palette/39b1d1d6fb61f6850cde3e3e
  static const Color kPrimaryRed = Color(0xFF39B1D1);
  static const Color kPrimaryOrange = Color(0xFFF6850C);
  static const Color kPrimaryRedDark = Color(0xFFDE3E3E);

  // Background / surface
  static const Color kBackgroundCream = Color(0xFFF0F8FA);
  static const Color kSecondaryGold = Color(0xFFD6FB61);
  static const Color kSurfaceGlass = Color(0xBFF0F8FA);
  static const Color kSurfaceWhite = Color(0xFFFFFFFF);

  // Text
  static const Color kTextPrimary = Color(0xFF1A1A2E);
  static const Color kTextSecondary = Color(0xFF5A6B7A);
  static const Color kTextHint = Color(0xFF8A9BA8);

  // Input / borders
  static const Color kInputFill = Color(0xFFEAF2F5);
  static const Color kBorderLight = Color(0xFFC8D4DC);

  // Status colors
  static const Color kSuccessGreen = Color(0xFF4CAF50);
  static const Color kSuccessGreenLight = Color(0xFFC8E6C9);
  static const Color kWarningAmber = Color(0xFFFFA726);
  static const Color kWarningAmberLight = Color(0xFFFFE0B2);
  static const Color kErrorRed = Color(0xFFDE3E3E);
  static const Color kErrorRedLight = Color(0xFFF5C8C8);

  // Neutrals
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kBlack = Color(0xFF000000);
  static const Color kDividerColor = Color(0xFFC8D4DC);

  // ── Glassmorphism helpers (glossy) ─────────────────────────────
  static BoxDecoration glassCard({
    Color? tint,
    double blur = 24,
    double radius = 16,
    double opacity = 0.55,
  }) {
    return BoxDecoration(
      color: (tint ?? kBackgroundCream).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: kWhite.withValues(alpha: 0.45),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: kBlack.withValues(alpha: 0.08),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: kBlack.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: kWhite.withValues(alpha: 0.3),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static Widget withGlass({
    required Widget child,
    Color? tint,
    double blur = 24,
    double radius = 16,
    double opacity = 0.55,
    EdgeInsets? margin,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          margin: margin,
          decoration: glassCard(
            tint: tint,
            radius: radius,
            opacity: opacity,
            blur: blur,
          ),
          child: Stack(
            children: [
              child,
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          kWhite.withValues(alpha: 0.15),
                          kWhite.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Deprecated aliases (backwards compat) ──────────────────────
  @Deprecated('Use kPrimaryRed instead')
  static const Color kPrimaryBurgundy = kPrimaryRed;
  @Deprecated('Use kPrimaryOrange instead')
  static const Color kPrimaryBurgundyLight = kPrimaryOrange;
  @Deprecated('Use kPrimaryRedDark instead')
  static const Color kPrimaryBurgundyDark = kPrimaryRedDark;
  @Deprecated('Use kBackgroundCream instead')
  static const Color kSecondaryCream = kBackgroundCream;
  @Deprecated('Use kSecondaryGold instead')
  static const Color kSecondaryTan = kSecondaryGold;
  @Deprecated('Use kBackgroundCream instead')
  static const Color kBackgroundWarm = kBackgroundCream;
  @Deprecated('Use kBackgroundWarm instead')
  static const Color kBackgroundOffWhite = kBackgroundWarm;
  @Deprecated('Use kPrimaryRed instead')
  static const Color kPrimaryTeal = kPrimaryRed;
  @Deprecated('Use kPrimaryOrange instead')
  static const Color kPrimaryTealLight = kPrimaryOrange;
  @Deprecated('Use kPrimaryRedDark instead')
  static const Color kPrimaryTealDark = kPrimaryRedDark;
  @Deprecated('Use kSecondaryGold instead')
  static const Color kSecondaryAmber = kSecondaryGold;
  @Deprecated('Use kWarningAmberLight instead')
  static const Color kSecondaryAmberLight = kWarningAmberLight;
  @Deprecated('Use kPrimaryOrange instead')
  static const Color kCtaOrange = kPrimaryOrange;
  @Deprecated('Use kWarningAmberLight instead')
  static const Color kCtaOrangeLight = kWarningAmberLight;
  @Deprecated('Use kPrimaryOrange instead')
  static const Color blueLightTinted = kPrimaryOrange;
  @Deprecated('Use kPrimaryOrange instead')
  static const Color blueLightest = kPrimaryOrange;
  @Deprecated('Use kTextPrimary instead')
  static const Color blueStrongHighlight = kTextPrimary;
  @Deprecated('Use kPrimaryOrange instead')
  static const Color greenLight = kPrimaryOrange;
  @Deprecated('Use kSurfaceWhite instead')
  static const Color whiteSurface = kSurfaceWhite;
  @Deprecated('Use kSuccessGreenLight instead')
  static const Color whiteSurface2 = kSuccessGreenLight;
  @Deprecated('Use kPrimaryOrange instead')
  static const Color whiteTintedorGreyAddAlpha02 = kPrimaryOrange;
  @Deprecated('Use kPrimaryRedDark instead')
  static const Color greenStrong = kPrimaryRedDark;
  @Deprecated('Use kErrorRed instead')
  static const Color red = kErrorRed;
  @Deprecated('Use kWarningAmber instead')
  static const Color yellow = kWarningAmber;
  @Deprecated('Use kSuccessGreen instead')
  static const Color greenBright = kSuccessGreen;
  @Deprecated('Use kPrimaryRed instead')
  static const Color greenMatte = kPrimaryRed;
  @Deprecated('Use kTextSecondary instead')
  static const Color grey = kTextSecondary;
  @Deprecated('Use kTextHint instead')
  static const Color greyLight = kTextHint;
  @Deprecated('Use kPrimaryRed instead')
  static const Color blueLight = kPrimaryRed;

  // ── Spacing ────────────────────────────────────────────────────
  static const double sp4 = 4.0;
  static const double sp8 = 8.0;
  static const double sp10 = 10.0;
  static const double sp12 = 12.0;
  static const double sp14 = 14.0;
  static const double sp16 = 16.0;
  static const double sp20 = 20.0;
  static const double sp24 = 24.0;
  static const double sp32 = 32.0;
  static const double sp40 = 40.0;

  // ── Tinted surfaces ────────────────────────────────────────────
  static Color get kSectionBg => Color.lerp(kBackgroundCream, kPrimaryOrange, 0.08)!;

  // ── Gradients ──────────────────────────────────────────────────
  static const kPrimaryGradient = LinearGradient(
    colors: [kPrimaryRed, kPrimaryRedDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const kAccentGradient = LinearGradient(
    colors: [kSecondaryGold, kPrimaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const kCtaGradient = LinearGradient(
    colors: [kPrimaryOrange, kPrimaryRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const kWarmGradient = LinearGradient(
    colors: [kBackgroundCream, kSecondaryGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: kBlack.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: kBlack.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: kBlack.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: kBlack.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: kBlack.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  // ── Decorations ────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => glassCard();
  static BoxDecoration get cardDecorationMd =>
      glassCard(blur: 28, opacity: 0.6);

  static BoxDecoration get inputDecoration => BoxDecoration(
        color: kInputFill,
        borderRadius: BorderRadius.circular(12),
      );

  // ── Button styles ──────────────────────────────────────────────
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: kPrimaryRed,
        foregroundColor: kWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        shadowColor: Colors.transparent,
      );

  static ButtonStyle get accentButton => ElevatedButton.styleFrom(
        backgroundColor: kSecondaryGold,
        foregroundColor: kTextPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        shadowColor: Colors.transparent,
      );

  static ButtonStyle get ctaButton => ElevatedButton.styleFrom(
        backgroundColor: kPrimaryOrange,
        foregroundColor: kWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        shadowColor: Colors.transparent,
      );

  // ── Glassmorphism background ───────────────────────────────────
  static Widget glassBackground(
      {required Widget child, LinearGradient? gradient}) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kBackgroundCream,
                kSecondaryGold.withValues(alpha: 0.4),
                kBackgroundCream,
              ],
            ),
      ),
      child: child,
    );
  }

  // ── Gradient header bar (replaces withGlass for header/search bars) ──
  static Widget gradientBar({required Widget child, LinearGradient? gradient}) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kSurfaceWhite,
                kPrimaryOrange.withValues(alpha: 0.06),
              ],
            ),
        boxShadow: shadowSm,
      ),
      child: child,
    );
  }

  // ── Typography ─────────────────────────────────────────────────
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.35,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.4,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get titleLarge => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.45,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get labelLarge => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.4,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.3,
      );

  static TextStyle get bodyMediumItalic => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        height: 1.6,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );

  // ── ThemeData ──────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.light(
        primary: kPrimaryRed,
        secondary: kSecondaryGold,
        tertiary: kPrimaryOrange,
        surface: kBackgroundCream,
        error: kErrorRed,
        onPrimary: kWhite,
        onSecondary: kTextPrimary,
        onSurface: kTextPrimary,
        onError: kWhite,
      ),
      scaffoldBackgroundColor: kBackgroundCream,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: kSurfaceGlass,
        foregroundColor: kTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: kSurfaceGlass,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kPrimaryRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kErrorRed),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: kTextSecondary),
        hintStyle: TextStyle(color: kTextHint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButton,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: kPrimaryRed,
        foregroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: kPrimaryOrange.withValues(alpha: 0.2),
        checkmarkColor: kPrimaryRed,
        labelStyle: TextStyle(fontSize: 12, color: kTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(color: kBorderLight, thickness: 1),
      drawerTheme: DrawerThemeData(
        backgroundColor: kBackgroundCream,
        shape: const RoundedRectangleBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        TargetPlatform.android: MySlideFadePageTransitionsBuilder(),
        TargetPlatform.iOS: MySlideFadePageTransitionsBuilder(),
        TargetPlatform.windows: MySlideFadePageTransitionsBuilder(),
        TargetPlatform.macOS: MySlideFadePageTransitionsBuilder(),
        TargetPlatform.linux: MySlideFadePageTransitionsBuilder(),
      }),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.dark(
        primary: kPrimaryOrange,
        secondary: kSecondaryGold,
        tertiary: kPrimaryRed,
        surface: const Color(0xFF1A142E),
        error: kErrorRed,
        onPrimary: kWhite,
        onSecondary: kWhite,
        onSurface: kBackgroundCream,
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0A1A),
      textTheme: textTheme.apply(
        bodyColor: kBackgroundCream,
        displayColor: kBackgroundCream,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A142E),
        foregroundColor: kBackgroundCream,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A142E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2340),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: kPrimaryOrange,
        foregroundColor: kWhite,
      ),
      dividerTheme:
          DividerThemeData(color: kWhite.withValues(alpha: 0.12), thickness: 1),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        TargetPlatform.android: MySlideFadePageTransitionsBuilder(),
        TargetPlatform.iOS: MySlideFadePageTransitionsBuilder(),
        TargetPlatform.windows: MySlideFadePageTransitionsBuilder(),
        TargetPlatform.macOS: MySlideFadePageTransitionsBuilder(),
        TargetPlatform.linux: MySlideFadePageTransitionsBuilder(),
      }),
    );
  }
}
