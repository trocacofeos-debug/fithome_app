
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// Paleta extraída do design no Figma ("FitHome Pro" — tema escuro).
class AppColors {
  static const background = Color(0xFF0D0D0D);
  static const foreground = Color(0xFFF0F0EE);
  static const card = Color(0xFF181818);
  static const secondary = Color(0xFF242424);
  static const muted = Color(0xFF1E1E1E);
  static const mutedForeground = Color(0xFF888880);
  static const border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  static const primary = Color(0xFFC8FF3E); // verde-limão
  static const primaryForeground = Color(0xFF0D0D0D);

  static const destructive = Color(0xFFFF4545);
  static const emerald = Color(0xFF34D399);
  static const amber = Color(0xFFFBBF24);

  // Cores por papel (usadas em ícones/tags de identificação do perfil)
  static const alunoColor = primary;
  static const instrutorColor = Color(0xFFFF6B35); // laranja
  static const adminColor = Color(0xFF7C3AED); // violeta

  // Mantidos por compatibilidade com telas antigas
  static const primaryDark = Color(0xFF9FCC2E);
  static const danger = destructive;
  static const warning = amber;
  static const textPrimary = foreground;
  static const textSecondary = mutedForeground;
  static const surface = card;

  static Color porRole(UserRole role) {
    switch (role) {
      case UserRole.aluno:
        return alunoColor;
      case UserRole.instrutor:
        return instrutorColor;
      case UserRole.admin:
        return adminColor;
    }
  }
}

/// Atalho para texto em Barlow Condensed (títulos grandes, valores de destaque).
TextStyle condensed({double fontSize = 24, Color color = AppColors.foreground, FontWeight weight = FontWeight.w900}) {
  return GoogleFonts.barlowCondensed(fontSize: fontSize, fontWeight: weight, color: color, height: 1.0);
}

class AppTheme {
  static TextTheme get _textTheme {
    final condensed = GoogleFonts.barlowCondensedTextTheme();
    final base = GoogleFonts.barlowTextTheme();
    return base.copyWith(
      displayLarge: condensed.displayLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.foreground),
      headlineLarge: condensed.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.foreground),
      headlineMedium: condensed.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.foreground),
      titleLarge: condensed.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.foreground),
      titleMedium: condensed.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.foreground),
      bodyLarge: base.bodyLarge?.copyWith(color: AppColors.foreground),
      bodyMedium: base.bodyMedium?.copyWith(color: AppColors.foreground),
      bodySmall: base.bodySmall?.copyWith(color: AppColors.mutedForeground),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.foreground),
    );
  }

  /// Fonte condensada e pesada usada em títulos grandes ("Barlow Condensed").
  static TextStyle heading({double fontSize = 24, Color color = AppColors.foreground, FontWeight weight = FontWeight.w900}) {
    return GoogleFonts.barlowCondensed(fontSize: fontSize, fontWeight: weight, color: color, height: 1.0);
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.barlow().fontFamily,
      textTheme: _textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.foreground,
        surface: AppColors.card,
        onSurface: AppColors.foreground,
        error: AppColors.destructive,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withValues(alpha: 0.95),
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: heading(fontSize: 16, weight: FontWeight.w900),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondary,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
        labelStyle: const TextStyle(color: AppColors.mutedForeground),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: AppColors.foreground, fontSize: 12, fontWeight: FontWeight.w700),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.secondary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
    );
  }

  // Compatibilidade com código existente que referenciava AppTheme.light
  static ThemeData get light => dark;
}
