import 'package:flutter/material.dart';

// Original Palette

class AppColors {
  // Primary brand
  static const Color primary = Color(0xFF1A1A2E);
  static const Color primaryVariant = Color(0xFF16213E);
  static const Color accent = Color(0xFFE94560);
  static const Color accentLight = Color(0xFFFF6B81);

  // Secondary
  static const Color teal = Color(0xFF0F9B8E);
  static const Color tealLight = Color(0xFF2EC4B6);
  static const Color amber = Color(0xFFF7B731);

  // Neutrals
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F9);
  static const Color border = Color(0xFFE5E9F2);

  // Text
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color textHint = Color(0xFFB0BAD0);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Card gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE94560), Color(0xFFFF6B81)],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F9B8E), Color(0xFF2EC4B6)],
  );
}

// New Palette

// class AppColors {
//   // Primary brand (based on new palette)
//   static const Color primary = Color(0xFF247D7F); // deep teal
//   static const Color primaryVariant = Color(0xFF44916F); // green-teal
//   static const Color accent = Color(0xFFC29450); // gold
//   static const Color accentLight = Color(0xFFB2D9C4); // soft mint

//   // Secondary
//   static const Color teal = Color(0xFF247D7F);
//   static const Color tealLight = Color(0xFF80B9C8);
//   static const Color amber = Color(0xFFC29450);

//   // Neutrals
//   static const Color background = Color(0xFFF7FAF9); // very light minty bg
//   static const Color surface = Color(0xFFFFFFFF);
//   static const Color surfaceVariant = Color(0xFFEAF4F1);
//   static const Color border = Color(0xFFD6E5DF);

//   // Text
//   static const Color textPrimary = Color(0xFF1F3D3A); // dark greenish
//   static const Color textSecondary = Color(0xFF5F7F79);
//   static const Color textHint = Color(0xFFA3B8B2);
//   static const Color textOnDark = Color(0xFFFFFFFF);

//   // Status (adjusted to fit palette vibe)
//   static const Color success = Color(0xFF44916F);
//   static const Color warning = Color(0xFFC29450);
//   static const Color error = Color(0xFFB00020); // kept readable red
//   static const Color info = Color(0xFF80B9C8);

//   // Gradients
//   static const LinearGradient heroGradient = LinearGradient(
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     colors: [
//       Color(0xFF247D7F),
//       Color(0xFF44916F),
//       Color(0xFF80B9C8),
//     ],
//   );

//   static const LinearGradient cardGradient = LinearGradient(
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     colors: [
//       Color(0xFFC29450),
//       Color(0xFFB2D9C4),
//     ],
//   );

//   static const LinearGradient tealGradient = LinearGradient(
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     colors: [
//       Color(0xFF44916F),
//       Color(0xFF247D7F),
//     ],
//   );
// }
