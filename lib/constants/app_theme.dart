import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    // 기본 텍스트 테마 설정 (Google Fonts 적용)
    // 한글 가독성을 위해 Noto Sans KR 사용 (Pretendard와 유사한 느낌)
    final textTheme = GoogleFonts.notoSansKrTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      
      // Color Scheme 정의
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primaryColor,
        secondary: AppConstants.secondaryColor,
        surface: AppConstants.surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppConstants.textPrimaryColor,
        error: AppConstants.errorColor,
        outline: AppConstants.textSecondaryColor,
      ),

      // Typography
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: AppConstants.textPrimaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          color: AppConstants.textPrimaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: AppConstants.textPrimaryColor,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: AppConstants.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: AppConstants.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: AppConstants.textPrimaryColor,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppConstants.textSecondaryColor,
          fontSize: 14,
          height: 1.5,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimaryColor,
        ),
        iconTheme: const IconThemeData(
          color: AppConstants.textPrimaryColor,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppConstants.surfaceColor,
        elevation: 0, // Flat style with border looks cleaner in modern dark mode
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          side: const BorderSide(
            color: Color(0xFF334155), // Subtle border
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          minimumSize: const Size(0, 48), // Comfortable touch target
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          side: const BorderSide(color: AppConstants.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.textPrimaryColor,
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
        ),
      ),

      // Input Decoration Theme (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.surfaceColor,
        hintStyle: TextStyle(color: AppConstants.textSecondaryColor.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: Color(0xFF334155), // Subtle border
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: Color(0xFF334155),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: AppConstants.errorColor,
            width: 1,
          ),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppConstants.textSecondaryColor,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 1,
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppConstants.surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppConstants.textPrimaryColor,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppConstants.primaryColor,
        linearTrackColor: Color(0xFF334155),
      ),
    );
  }
}
