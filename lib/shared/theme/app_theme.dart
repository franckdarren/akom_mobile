import 'package:flutter/material.dart';

// Couleurs alignées sur app/globals.css (akom_saas) — même charte que le web.
abstract final class AkomColors {
  static const primary = Color(0xFF3B82F6); // Blue 500 — couleur de marque Akôm (--primary)
  static const primaryDark = Color(0xFF2563EB); // Blue 600 (--primary-hover)
  static const secondary = Color(0xFF2563EB); // Blue 600 — pas d'accent distinct côté web
  static const secondaryLight = Color(0xFF93C5FD); // Blue 300
  static const background = Color(0xFFFAFAFA); // Zinc 50
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFDC2626); // Red 600 (--destructive)
  static const errorLight = Color(0xFFFEF2F2); // Red 50 (--destructive-subtle)
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onBackground = Color(0xFF09090B); // Zinc 950 (--foreground)
  static const onSurface = Color(0xFF09090B);
  static const onSurfaceVariant = Color(0xFF71717A); // Zinc 500 (--muted-foreground)
  static const divider = Color(0xFFE4E4E7); // Zinc 200 (--border)
  static const success = Color(0xFF22C55E); // Green 500 (--success)
  static const successLight = Color(0xFFF0FDF4); // Green 50 (--success-subtle)
  static const warning = Color(0xFFFBBF24); // Amber 400 (--warning)
  static const warningLight = Color(0xFFFFFBEB); // Amber 50 (--warning-subtle)
  static const offline = Color(0xFF71717A);
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
          primaryContainer: Color(0xFFDBEAFE), // Blue 100
          onPrimaryContainer: Color(0xFF1E3A8A), // Blue 900
          secondary: AkomColors.secondary,
          onSecondary: AkomColors.onSecondary,
          secondaryContainer: Color(0xFFDBEAFE), // Blue 100
          onSecondaryContainer: Color(0xFF1E3A8A), // Blue 900
          tertiary: Color(0xFF0EA5E9), // Sky 500 (--info web)
          onTertiary: Color(0xFFFFFFFF),
          tertiaryContainer: Color(0xFFE0F2FE), // Sky 100
          onTertiaryContainer: Color(0xFF0C4A6E), // Sky 900
          error: AkomColors.error,
          onError: Color(0xFFFFFFFF),
          errorContainer: AkomColors.errorLight,
          onErrorContainer: Color(0xFF7F1D1D), // Red 900
          surface: AkomColors.surface,
          onSurface: AkomColors.onSurface,
          surfaceContainerHighest: Color(0xFFF4F4F5), // Zinc 100
          onSurfaceVariant: AkomColors.onSurfaceVariant,
          outline: Color(0xFFD4D4D8), // Zinc 300
          shadow: Color(0xFF000000),
          inverseSurface: Color(0xFF18181B), // Zinc 900
          onInverseSurface: Color(0xFFFAFAFA), // Zinc 50
          inversePrimary: Color(0xFFBFDBFE), // Blue 200
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
