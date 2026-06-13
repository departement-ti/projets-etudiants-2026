import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color _primaryColor = Color(0xFF5B5EA6);
  static const Color _secondaryColor = Color(0xFFE8865E);
  static const Color _scaffoldBg = Color(0xFFFFF9F5);
  static const Color _surfaceColor = Colors.white;
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF2D2B3A);
  static const Color _textOnPrimary = Colors.white;
  static const Color _errorColor = Color(0xFFC63B3B);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      surface: _surfaceColor,
      error: _errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _scaffoldBg,

      textTheme: GoogleFonts.robotoTextTheme(
        TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
          displaySmall: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          headlineLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          titleLarge: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          titleMedium: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
          titleSmall: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
          bodyLarge: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: _textPrimary,
          ),
          bodyMedium: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: _textPrimary,
          ),
          bodySmall: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _textPrimary,
          ),
          labelLarge: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          labelMedium: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
          labelSmall: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _textPrimary,
          ),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: _textOnPrimary,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _textOnPrimary,
        ),
        iconTheme: IconThemeData(
          color: _textOnPrimary,
          size: 28,
        ),
        toolbarHeight: 64,
      ),

      cardTheme: CardThemeData(
        color: _cardColor,
        elevation: 3,
        shadowColor: const Color(0xFFD4C5E2).withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        surfaceTintColor: Colors.transparent,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _textPrimary.withValues(alpha: 0.7),
        ),
        leadingAndTrailingTextStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _primaryColor,
        ),
        iconColor: _primaryColor,
        horizontalTitleGap: 16,
        minLeadingWidth: 40,
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryColor.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          elevation: 2,
          shadowColor: _primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD4C5E2), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD4C5E2), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryColor, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _errorColor, width: 2.5),
        ),
        labelStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _textPrimary.withValues(alpha: 0.8),
        ),
        hintStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _textPrimary.withValues(alpha: 0.4),
        ),
        errorStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _errorColor,
        ),
        helperStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _scaffoldBg,
        indicatorColor: _primaryColor.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primaryColor, size: 28);
          }
          return IconThemeData(
            color: _textPrimary.withValues(alpha: 0.6),
            size: 26,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            );
          }
          return GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: _textPrimary.withValues(alpha: 0.6),
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 72,
        elevation: 2,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _scaffoldBg,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _textPrimary.withValues(alpha: 0.5),
        selectedLabelStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.roboto(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        elevation: 2,
        type: BottomNavigationBarType.fixed,
      ),

      dividerTheme: DividerThemeData(
        color: const Color(0xFFE8E0EE),
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: _primaryColor.withValues(alpha: 0.08),
        labelStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _primaryColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        contentTextStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _textPrimary,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _secondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        extendedTextStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconSize: 28,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return const Color(0xFFB8A9C9);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor.withValues(alpha: 0.4);
          }
          return const Color(0xFFE2D8EC);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        thumbIcon: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Icon(Icons.check, size: 16, color: Colors.white);
          }
          return null;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        side: const BorderSide(color: Color(0xFFB8A9C9), width: 2),
        visualDensity: VisualDensity.comfortable,
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return const Color(0xFFB8A9C9);
        }),
        visualDensity: VisualDensity.comfortable,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: _primaryColor,
        inactiveTrackColor: _primaryColor.withValues(alpha: 0.2),
        thumbColor: _primaryColor,
        overlayColor: _primaryColor.withValues(alpha: 0.12),
        valueIndicatorColor: _primaryColor,
        valueIndicatorTextStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _primaryColor,
        contentTextStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
        actionTextColor: Colors.white,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _textPrimary,
        ),
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: _secondaryColor,
        textColor: Colors.white,
        textStyle: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _primaryColor,
        linearTrackColor: _primaryColor.withValues(alpha: 0.15),
        circularTrackColor: _primaryColor.withValues(alpha: 0.15),
      ),

      tooltipTheme: TooltipThemeData(
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        decoration: BoxDecoration(
          color: _textPrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),

      visualDensity: VisualDensity.comfortable,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
