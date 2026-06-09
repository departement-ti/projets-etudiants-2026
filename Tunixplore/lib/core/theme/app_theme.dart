import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// Old Theme

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.dmSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.dmSans(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.dmSans(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// New Theme

// class AppTheme {
//   static ThemeData get lightTheme {
//     final colorScheme = ColorScheme(
//       brightness: Brightness.light,
//       primary: AppColors.primary,           // #247D7F
//       onPrimary: Colors.white,
//       secondary: AppColors.accent,          // #C29450
//       onSecondary: Colors.white,
//       surface: AppColors.surface,
//       onSurface: AppColors.textPrimary,
//       error: AppColors.error,
//       onError: Colors.white,
//       outline: AppColors.border,
//     );

//     return ThemeData(
//       useMaterial3: true,
//       colorScheme: colorScheme,
//       scaffoldBackgroundColor: AppColors.background,

//       textTheme: GoogleFonts.dmSansTextTheme().copyWith(
//         displayLarge: GoogleFonts.dmSans(
//           fontSize: 32,
//           fontWeight: FontWeight.w800,
//           color: AppColors.textPrimary,
//           letterSpacing: -1,
//         ),
//         displayMedium: GoogleFonts.dmSans(
//           fontSize: 26,
//           fontWeight: FontWeight.w700,
//           color: AppColors.textPrimary,
//           letterSpacing: -0.5,
//         ),
//         displaySmall: GoogleFonts.dmSans(
//           fontSize: 22,
//           fontWeight: FontWeight.w700,
//           color: AppColors.textPrimary,
//         ),
//         headlineMedium: GoogleFonts.dmSans(
//           fontSize: 18,
//           fontWeight: FontWeight.w700,
//           color: AppColors.textPrimary,
//         ),
//         headlineSmall: GoogleFonts.dmSans(
//           fontSize: 16,
//           fontWeight: FontWeight.w600,
//           color: AppColors.textPrimary,
//         ),
//         bodyLarge: GoogleFonts.dmSans(
//           fontSize: 15,
//           fontWeight: FontWeight.w400,
//           color: AppColors.textPrimary,
//         ),
//         bodyMedium: GoogleFonts.dmSans(
//           fontSize: 13,
//           fontWeight: FontWeight.w400,
//           color: AppColors.textSecondary,
//         ),
//         labelLarge: GoogleFonts.dmSans(
//           fontSize: 14,
//           fontWeight: FontWeight.w600,
//           color: AppColors.textPrimary,
//         ),
//       ),

//       appBarTheme: AppBarTheme(
//         backgroundColor: AppColors.surface,
//         elevation: 0,
//         scrolledUnderElevation: 0.5,
//         centerTitle: false,
//         titleTextStyle: GoogleFonts.dmSans(
//           fontSize: 18,
//           fontWeight: FontWeight.w700,
//           color: AppColors.textPrimary,
//         ),
//         iconTheme: const IconThemeData(color: AppColors.textPrimary),
//       ),

//       cardTheme: CardThemeData(
//         color: AppColors.surface,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//           side: const BorderSide(color: AppColors.border, width: 1),
//         ),
//       ),

//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.accent, // gold CTA
//           foregroundColor: Colors.white,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//           textStyle: GoogleFonts.dmSans(
//             fontSize: 15,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),

//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: AppColors.surfaceVariant,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide.none,
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: AppColors.border),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(
//             color: AppColors.primary, // switched to primary for consistency
//             width: 1.5,
//           ),
//         ),
//         hintStyle: GoogleFonts.dmSans(
//           color: AppColors.textHint,
//           fontSize: 14,
//         ),
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       ),

//       dividerColor: AppColors.border,

//       // Optional polish
//       iconTheme: const IconThemeData(color: AppColors.textPrimary),

//       chipTheme: ChipThemeData(
//         backgroundColor: AppColors.surfaceVariant,
//         selectedColor: AppColors.primary.withOpacity(0.1),
//         labelStyle: GoogleFonts.dmSans(color: AppColors.textPrimary),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }
// }