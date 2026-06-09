// brand_config.dart
//
// Configuración centralizada de la identidad visual (colores y estilos) para
// los marcadores y elementos de la plataforma.
//
// Sigue las mejores prácticas 2026: centralización, tokens semánticos y
// diseño independiente por año y fuente.

import 'package:flutter/material.dart';

/// Token de diseño para una fuente o año.
class BrandConfig {
  const BrandConfig({
    required this.label,
    required this.primary,
    required this.dark,
    required this.glow,
    required this.strokeWidth,
  });

  final String label;
  final Color primary;
  final Color dark;
  final Color glow;
  final double strokeWidth;
}

/// Convierte un hex string (#rrggbb) a [Color] con opacidad opcional (0–1).
/// Disponible para uso externo si se necesita construir colores dinámicamente.
Color brandHexToColor(String hex, [double alpha = 1.0]) {
  final value = int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000;
  final base = Color(value);
  return alpha == 1.0 ? base : base.withValues(alpha: alpha);
}

/// Identidad visual de la plataforma.
/// Cada fuente y cada año tiene un diseño independiente y completo.
/// Paleta Natural 2026: Basada en minerales, tierras y elementos botánicos.
class BrandIdentity {
  BrandIdentity._();

  static const BrandConfig inaturalist = BrandConfig(
    label: 'iNaturalist',
    primary: Color(0xFF10b981), // Emerald 500
    dark: Color(0xFF064e3b),    // Emerald 900
    glow: Color(0x4D064e3b),
    strokeWidth: 1.8,
  );

  static const BrandConfig odk = BrandConfig(
    label: 'ODK',
    primary: Color(0xFF2563eb), // Blue 600
    dark: Color(0xFF1e3a8a),    // Blue 900
    glow: Color(0x591e3a8a),
    strokeWidth: 1.8,
  );

  // --- Serie Histórica y Futura (Diseño Independiente 2010 – 2040) ---

  static const BrandConfig y2010 = BrandConfig(label: '2010', primary: Color(0xFF9d7a8a), dark: Color(0xFF6b4a52), glow: Color(0x409d7a8a), strokeWidth: 1.6);
  static const BrandConfig y2011 = BrandConfig(label: '2011', primary: Color(0xFF8a6a9d), dark: Color(0xFF523d6b), glow: Color(0x408a6a9d), strokeWidth: 1.6);
  static const BrandConfig y2012 = BrandConfig(label: '2012', primary: Color(0xFFc48a6a), dark: Color(0xFF7a523d), glow: Color(0x40c48a6a), strokeWidth: 1.6);
  static const BrandConfig y2013 = BrandConfig(label: '2013', primary: Color(0xFFb89a6a), dark: Color(0xFF7a623d), glow: Color(0x40b89a6a), strokeWidth: 1.6);
  static const BrandConfig y2014 = BrandConfig(label: '2014', primary: Color(0xFFd49a5a), dark: Color(0xFF8a5a3d), glow: Color(0x40d49a5a), strokeWidth: 1.6);
  static const BrandConfig y2015 = BrandConfig(label: '2015', primary: Color(0xFFc4aa6a), dark: Color(0xFF7a6a3d), glow: Color(0x40c4aa6a), strokeWidth: 1.6);
  static const BrandConfig y2016 = BrandConfig(label: '2016', primary: Color(0xFF8a9a5a), dark: Color(0xFF5a6a3d), glow: Color(0x408a9a5a), strokeWidth: 1.6);
  static const BrandConfig y2017 = BrandConfig(label: '2017', primary: Color(0xFF5a9a7a), dark: Color(0xFF3d6a4a), glow: Color(0x405a9a7a), strokeWidth: 1.6);
  static const BrandConfig y2018 = BrandConfig(label: '2018', primary: Color(0xFF5a8a9a), dark: Color(0xFF3d5a6a), glow: Color(0x405a8a9a), strokeWidth: 1.6);
  static const BrandConfig y2019 = BrandConfig(label: '2019', primary: Color(0xFF6a9a8a), dark: Color(0xFF3d6a5a), glow: Color(0x406a9a8a), strokeWidth: 1.6);
  static const BrandConfig y2020 = BrandConfig(label: '2020', primary: Color(0xFF7a8a9c), dark: Color(0xFF4a5a6b), glow: Color(0x407a8a9c), strokeWidth: 1.6);
  static const BrandConfig y2021 = BrandConfig(label: '2021', primary: Color(0xFF5a7247), dark: Color(0xFF334526), glow: Color(0x405a7247), strokeWidth: 1.6);
  static const BrandConfig y2022 = BrandConfig(label: '2022', primary: Color(0xFFd98c60), dark: Color(0xFF995733), glow: Color(0x40d98c60), strokeWidth: 1.6);
  static const BrandConfig y2023 = BrandConfig(label: '2023', primary: Color(0xFFc2a06e), dark: Color(0xFF8c6f42), glow: Color(0x40c2a06e), strokeWidth: 1.6);
  static const BrandConfig y2024 = BrandConfig(label: '2024', primary: Color(0xFF4e6e5d), dark: Color(0xFF2b4235), glow: Color(0x404e6e5d), strokeWidth: 1.6);
  static const BrandConfig y2025 = BrandConfig(label: '2025', primary: Color(0xFF8c5b52), dark: Color(0xFF5c342d), glow: Color(0x408c5b52), strokeWidth: 1.6);
  static const BrandConfig y2026 = BrandConfig(label: '2026', primary: Color(0xFF427b8a), dark: Color(0xFF234d58), glow: Color(0x40427b8a), strokeWidth: 1.6);
  static const BrandConfig y2027 = BrandConfig(label: '2027', primary: Color(0xFFa39171), dark: Color(0xFF6b5d43), glow: Color(0x40a39171), strokeWidth: 1.6);
  static const BrandConfig y2028 = BrandConfig(label: '2028', primary: Color(0xFF784e4e), dark: Color(0xFF4d2e2e), glow: Color(0x40784e4e), strokeWidth: 1.6);
  static const BrandConfig y2029 = BrandConfig(label: '2029', primary: Color(0xFF6a8a73), dark: Color(0xFF3f5945), glow: Color(0x406a8a73), strokeWidth: 1.6);
  static const BrandConfig y2030 = BrandConfig(label: '2030', primary: Color(0xFFac7a54), dark: Color(0xFF734c2e), glow: Color(0x40ac7a54), strokeWidth: 1.6);
  static const BrandConfig y2031 = BrandConfig(label: '2031', primary: Color(0xFF4a5d6e), dark: Color(0xFF2a3744), glow: Color(0x404a5d6e), strokeWidth: 1.6);
  static const BrandConfig y2032 = BrandConfig(label: '2032', primary: Color(0xFF926e55), dark: Color(0xFF5e4330), glow: Color(0x40926e55), strokeWidth: 1.6);
  static const BrandConfig y2033 = BrandConfig(label: '2033', primary: Color(0xFF587968), dark: Color(0xFF31493c), glow: Color(0x40587968), strokeWidth: 1.6);
  static const BrandConfig y2034 = BrandConfig(label: '2034', primary: Color(0xFFb66d57), dark: Color(0xFF7a4232), glow: Color(0x40b66d57), strokeWidth: 1.6);
  static const BrandConfig y2035 = BrandConfig(label: '2035', primary: Color(0xFF7a899c), dark: Color(0xFF4a5666), glow: Color(0x407a899c), strokeWidth: 1.6);
  static const BrandConfig y2036 = BrandConfig(label: '2036', primary: Color(0xFF665f52), dark: Color(0xFF3d382e), glow: Color(0x40665f52), strokeWidth: 1.6);
  static const BrandConfig y2037 = BrandConfig(label: '2037', primary: Color(0xFF9d814b), dark: Color(0xFF614e28), glow: Color(0x409d814b), strokeWidth: 1.6);
  static const BrandConfig y2038 = BrandConfig(label: '2038', primary: Color(0xFF3f6759), dark: Color(0xFF213d33), glow: Color(0x403f6759), strokeWidth: 1.6);
  static const BrandConfig y2039 = BrandConfig(label: '2039', primary: Color(0xFF8f554a), dark: Color(0xFF5c3128), glow: Color(0x408f554a), strokeWidth: 1.6);
  static const BrandConfig y2040 = BrandConfig(label: '2040', primary: Color(0xFF546b7c), dark: Color(0xFF2f404d), glow: Color(0x40546b7c), strokeWidth: 1.6);

  /// Mapa de año → config para acceso dinámico.
  static const Map<int, BrandConfig> byYear = {
    2010: y2010, 2011: y2011, 2012: y2012, 2013: y2013, 2014: y2014,
    2015: y2015, 2016: y2016, 2017: y2017, 2018: y2018, 2019: y2019,
    2020: y2020, 2021: y2021, 2022: y2022, 2023: y2023, 2024: y2024,
    2025: y2025, 2026: y2026, 2027: y2027, 2028: y2028, 2029: y2029,
    2030: y2030, 2031: y2031, 2032: y2032, 2033: y2033, 2034: y2034,
    2035: y2035, 2036: y2036, 2037: y2037, 2038: y2038, 2039: y2039,
    2040: y2040,
  };
}

/// Utilidades para acceder a los tokens de diseño de forma tipada y segura.
class BrandPersonality {
  BrandPersonality._();

  static BrandConfig get forInaturalist => BrandIdentity.inaturalist;
  static BrandConfig get forOdk => BrandIdentity.odk;

  /// Obtiene la configuración de diseño para un año específico.
  /// Devuelve [BrandIdentity.odk] como fallback si el año no está definido.
  static BrandConfig forYear(int year) =>
      BrandIdentity.byYear[year] ?? BrandIdentity.odk;

  /// Obtiene la configuración completa por el nombre de la fuente.
  static BrandConfig forSource(String? source) {
    final normalized = source?.toLowerCase() ?? '';
    if (normalized.contains('inaturalist')) return BrandIdentity.inaturalist;
    return BrandIdentity.odk;
  }

  /// Obtiene la config por fuente o, si se proporciona un año, por año.
  static BrandConfig resolve({String? source, int? year}) {
    if (year != null) return forYear(year);
    return forSource(source);
  }
}
