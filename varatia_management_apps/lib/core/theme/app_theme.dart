import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const primary = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF4338CA);
  static const secondary = Color(0xFF7C3AED);
  static const accent = Color(0xFF06B6D4);

  // Background Colors
  static const background = Color(0xFFF5F7FF);
  static const secondaryBackground = Color(0xFFEEF2FF);
  static const surface = Colors.white;
  static const surfaceSoft = Color(0xFFF0ECFF);
  static const sidebar = Color(0xFFF8FAFF);

  // Borders
  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);
  static const focusBorder = Color(0xFF6366F1);

  // Semantic Colors
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const danger = Color(0xFFB91C1C);
  static const error = Color(0xFFB91C1C);
  static const info = Color(0xFF0369A1);

  // Typography
  static const textPrimary = Color(0xFF172033);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF64748B);
  static const textWhite = Colors.white;

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const softGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFF0ECFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFF0ECFF), Color(0xFFE0F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppRadii {
  AppRadii._();

  static const double card = 18;
  static const double large = 26;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x141E293B), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x121E293B), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x080F172A), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x244F46E5), blurRadius: 28, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(color: Color(0x384F46E5), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

class AppTheme {
  AppTheme._();

  static TextStyle _font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static ThemeData light() {
    final baseTheme = ThemeData(useMaterial3: true);
    final textTheme = baseTheme.textTheme.apply(fontFamily: 'Poppins').copyWith(
          headlineLarge: _font(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.12,
          ),
          headlineSmall: _font(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.18,
          ),
          titleLarge: _font(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleMedium: _font(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: _font(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.55,
          ),
          bodyMedium: _font(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            height: 1.5,
          ),
          labelLarge: _font(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        );

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.danger,
          outline: AppColors.border,
        );

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium,
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.focusBorder, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.surfaceSoft,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => _font(
            fontSize: 12,
            height: 1,
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryDark
                : AppColors.textMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          textStyle: _font(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          textStyle: _font(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: _font(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSoft,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceSoft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        labelStyle: _font(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: _font(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        brightness: Brightness.light,
      ),
    );
  }
}
