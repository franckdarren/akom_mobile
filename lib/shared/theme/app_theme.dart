import 'package:flutter/material.dart';

abstract final class AkomColors {
  static const primary = Color(0xFF00897B); // Teal 600
  static const primaryDark = Color(0xFF00695C); // Teal 700
  static const secondary = Color(0xFFFF8F00); // Amber 800
  static const secondaryLight = Color(0xFFFFB300); // Amber 600
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFD32F2F);
  static const errorLight = Color(0xFFFFEBEE);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onBackground = Color(0xFF212121);
  static const onSurface = Color(0xFF212121);
  static const onSurfaceVariant = Color(0xFF757575);
  static const divider = Color(0xFFE0E0E0);
  static const success = Color(0xFF388E3C);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFF57C00);
  static const warningLight = Color(0xFFFFF8E1);
  static const offline = Color(0xFF616161);
}

abstract final class AkomTextStyles {
  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AkomColors.onSurfaceVariant,
  );

  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AkomColors.primary,
    letterSpacing: -0.3,
  );

  static const priceLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AkomColors.primary,
    letterSpacing: -0.5,
  );
}

abstract final class AkomSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AkomRadius {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(16);
  static const xl = Radius.circular(24);
  static const full = Radius.circular(999);

  static const borderSm = BorderRadius.all(sm);
  static const borderMd = BorderRadius.all(md);
  static const borderLg = BorderRadius.all(lg);
  static const borderXl = BorderRadius.all(xl);
  static const borderFull = BorderRadius.all(full);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AkomColors.primary,
          onPrimary: AkomColors.onPrimary,
          primaryContainer: Color(0xFFB2DFDB),
          onPrimaryContainer: Color(0xFF004D40),
          secondary: AkomColors.secondary,
          onSecondary: AkomColors.onSecondary,
          secondaryContainer: Color(0xFFFFECB3),
          onSecondaryContainer: Color(0xFF4E3400),
          tertiary: Color(0xFF1565C0),
          onTertiary: Color(0xFFFFFFFF),
          tertiaryContainer: Color(0xFFBBDEFB),
          onTertiaryContainer: Color(0xFF003483),
          error: AkomColors.error,
          onError: Color(0xFFFFFFFF),
          errorContainer: AkomColors.errorLight,
          onErrorContainer: Color(0xFF7F0000),
          surface: AkomColors.surface,
          onSurface: AkomColors.onSurface,
          surfaceContainerHighest: Color(0xFFEEEEEE),
          onSurfaceVariant: AkomColors.onSurfaceVariant,
          outline: Color(0xFFBDBDBD),
          shadow: Color(0xFF000000),
          inverseSurface: Color(0xFF212121),
          onInverseSurface: Color(0xFFF5F5F5),
          inversePrimary: Color(0xFF80CBC4),
          scrim: Color(0xFF000000),
        ),
        scaffoldBackgroundColor: AkomColors.background,
        fontFamily: 'Roboto',

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AkomColors.primary,
          foregroundColor: AkomColors.onPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AkomColors.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: AkomColors.onPrimary),
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AkomColors.primary,
            foregroundColor: AkomColors.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: const RoundedRectangleBorder(
              borderRadius: AkomRadius.borderMd,
            ),
            textStyle: AkomTextStyles.labelLarge,
            elevation: 0,
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AkomColors.primary,
            minimumSize: const Size(double.infinity, 52),
            shape: const RoundedRectangleBorder(
              borderRadius: AkomRadius.borderMd,
            ),
            side: const BorderSide(color: AkomColors.primary, width: 1.5),
            textStyle: AkomTextStyles.labelLarge,
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AkomColors.primary,
            textStyle: AkomTextStyles.labelLarge,
          ),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AkomColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AkomSpacing.md,
            vertical: AkomSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: AkomRadius.borderMd,
            borderSide: const BorderSide(color: AkomColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AkomRadius.borderMd,
            borderSide: const BorderSide(color: AkomColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AkomRadius.borderMd,
            borderSide:
                const BorderSide(color: AkomColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AkomRadius.borderMd,
            borderSide: const BorderSide(color: AkomColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AkomRadius.borderMd,
            borderSide: const BorderSide(color: AkomColors.error, width: 1.5),
          ),
          labelStyle: AkomTextStyles.bodyMedium
              .copyWith(color: AkomColors.onSurfaceVariant),
          hintStyle: AkomTextStyles.bodyMedium
              .copyWith(color: AkomColors.onSurfaceVariant),
          errorStyle: AkomTextStyles.bodySmall.copyWith(color: AkomColors.error),
        ),

        // Cards
        cardTheme: const CardThemeData(
          elevation: 0,
          color: AkomColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AkomRadius.borderMd,
            side: BorderSide(color: AkomColors.divider),
          ),
          margin: EdgeInsets.zero,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: AkomColors.divider,
          thickness: 1,
          space: 1,
        ),

        // SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AkomColors.onBackground,
          contentTextStyle: AkomTextStyles.bodyMedium.copyWith(
            color: Colors.white,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AkomRadius.borderMd,
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // FAB
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AkomColors.secondary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: AkomRadius.borderLg),
        ),

        // Bottom navigation
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AkomColors.surface,
          indicatorColor: AkomColors.primary.withAlpha(26),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AkomColors.primary);
            }
            return const IconThemeData(color: AkomColors.onSurfaceVariant);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AkomTextStyles.bodySmall
                  .copyWith(color: AkomColors.primary);
            }
            return AkomTextStyles.bodySmall;
          }),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: AkomColors.background,
          selectedColor: AkomColors.primary.withAlpha(26),
          labelStyle: AkomTextStyles.bodySmall,
          padding: const EdgeInsets.symmetric(
            horizontal: AkomSpacing.sm,
            vertical: AkomSpacing.xs,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AkomRadius.borderFull,
            side: BorderSide(color: AkomColors.divider),
          ),
        ),

        // ListTile
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AkomSpacing.md,
            vertical: AkomSpacing.xs,
          ),
          tileColor: AkomColors.surface,
        ),
      );
}
