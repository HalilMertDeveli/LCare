import 'package:material_ui/material_ui.dart';

/// LEDCare OS brand: dark navy, white, neutral grays, blue accent.
abstract final class BrandColors {
  static const navy = Color(0xFF0B1A33);
  static const navyRaised = Color(0xFF13274A);
  static const navyDeep = Color(0xFF07111F);
  static const blue = Color(0xFF2F6BFF);
  static const blueLight = Color(0xFF7FA6FF);
  static const gray50 = Color(0xFFF5F7FA);
  static const gray100 = Color(0xFFEDF0F5);
  static const gray300 = Color(0xFFC9D0DB);
  static const gray500 = Color(0xFF6B7587);
  static const gray700 = Color(0xFF39424F);
}

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: BrandColors.blue,
      onPrimary: Colors.white,
      secondary: BrandColors.navy,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: BrandColors.navy,
      onSurfaceVariant: BrandColors.gray500,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: BrandColors.gray50,
      surfaceContainer: BrandColors.gray50,
      surfaceContainerHigh: BrandColors.gray100,
      outline: BrandColors.gray300,
      outlineVariant: BrandColors.gray100,
    );
    return _base(scheme, scaffold: BrandColors.gray50);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.blue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: BrandColors.blueLight,
      onPrimary: BrandColors.navyDeep,
      secondary: BrandColors.gray300,
      surface: BrandColors.navy,
      onSurface: Colors.white,
      onSurfaceVariant: BrandColors.gray300,
      surfaceContainerLowest: BrandColors.navyDeep,
      surfaceContainerLow: BrandColors.navy,
      surfaceContainer: BrandColors.navyRaised,
      surfaceContainerHigh: BrandColors.navyRaised,
      outline: BrandColors.gray700,
      outlineVariant: BrandColors.navyRaised,
    );
    return _base(scheme, scaffold: BrandColors.navyDeep);
  }

  static ThemeData _base(ColorScheme scheme, {required Color scaffold}) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        height: 68,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
