import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final double radiusXL;
  final double radiusMD;
  final EdgeInsets paddingMD;
  const AppTokens({
    required this.radiusXL,
    required this.radiusMD,
    required this.paddingMD,
  });
  @override
  AppTokens copyWith({
    double? radiusXL,
    double? radiusMD,
    EdgeInsets? paddingMD,
  }) => AppTokens(
    radiusXL: radiusXL ?? this.radiusXL,
    radiusMD: radiusMD ?? this.radiusMD,
    paddingMD: paddingMD ?? this.paddingMD,
  );
  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    final o = other as AppTokens;
    return AppTokens(
      radiusXL: radiusXL + (o.radiusXL - radiusXL) * t,
      radiusMD: radiusMD + (o.radiusMD - radiusMD) * t,
      paddingMD: EdgeInsets.lerp(paddingMD, o.paddingMD, t)!,
    );
  }
}

class UnimetPalette {
  static const Color primary = Color(0xFF003087); // Azul institucional
  static const Color secondary = Color(0xFF1859A9); // Azul secundario
  static const Color accent = Color(0xFFF68629); // Naranja acento
  static const Color accentStrong = Color(
    0xFFFF8200,
  ); // Variante intensa del acento
  static const Color base = Color(0xFFFFFFFF); // Fondo base (blanco)
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: UnimetPalette.primary,
      onPrimary: Colors.white,
      secondary: UnimetPalette.secondary,
      onSecondary: Colors.white,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      background: UnimetPalette.base,
      onBackground: Colors.black,
      surface: UnimetPalette.base,
      onSurface: UnimetPalette.primary.withOpacity(0.8),
      primaryContainer: UnimetPalette.accent.withOpacity(0.15),
      onPrimaryContainer: UnimetPalette.primary,
      secondaryContainer: UnimetPalette.secondary.withOpacity(0.1),
      onSecondaryContainer: UnimetPalette.secondary,
      surfaceVariant: const Color(0xFFEFEFF2),
      outlineVariant: const Color(0xFFD2D6DC),
      outline: const Color(0xFFD0D5DD),
      tertiary: UnimetPalette.accent,
      onTertiary: Colors.white,
      tertiaryContainer: UnimetPalette.accentStrong.withOpacity(0.15),
      onTertiaryContainer: UnimetPalette.accentStrong,
      shadow: Colors.black.withOpacity(0.1),
      inverseSurface: const Color(0xFF111111),
      onInverseSurface: Colors.white,
      inversePrimary: UnimetPalette.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: UnimetPalette.accent,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        backgroundColor: scheme.surfaceVariant,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        // Tamaño consistente del área del ícono (evita colapsos)
        prefixIconColor: UnimetPalette.primary,
        suffixIconColor: UnimetPalette.primary,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),

        // Estados SIN error
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFFD2D6DC),
          ), // outlineVariant
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: UnimetPalette.primary,
            width: 1.5,
          ),
        ),

        // Estados CON error (evita que cambie a un borde diferente y colapse)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
        ),

        // Estilos del texto de ayuda/error (opcional)
        errorStyle: const TextStyle(height: 1.2),
        helperStyle: const TextStyle(height: 1.2),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      extensions: const [
        AppTokens(radiusXL: 24, radiusMD: 14, paddingMD: EdgeInsets.all(12)),
      ],
    );
  }
}
