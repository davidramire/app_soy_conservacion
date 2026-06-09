import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/map_snapshot.dart';
import '../providers/filter_provider.dart';
import '../providers/map_provider.dart';
import '../theme/app_theme.dart';
import '../utils/marker_filters.dart';
import 'ux/bouncing_wrapper.dart';

class DateFilterPanel extends StatefulWidget {
  const DateFilterPanel({
    super.key,
    required this.language,
    required this.markers,
    required this.onClose,
    required this.onApply,
  });

  final String language;
  final List<MapMarkerData> markers;
  final VoidCallback onClose;
  final VoidCallback onApply;

  @override
  State<DateFilterPanel> createState() => _DateFilterPanelState();
}

class _DateFilterPanelState extends State<DateFilterPanel> {
  Future<void> _applyPreset(String preset, FilterProvider filters) async {
    final now = DateTime.now();
    DateTime from;
    DateTime to = now;

    await filters.setYearMode(false);

    switch (preset) {
      case 'Última semana':
        from = now.subtract(const Duration(days: 7));
        break;
      case 'Último mes':
        from = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'Último año':
        from = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        from = now;
    }

    await filters.setDateRange(from, to);
    widget.onApply();
  }

  String? _currentPreset(FilterProvider filters) {
    if (filters.isYearMode || filters.dateFrom == null) return null;
    final now = DateTime.now();
    final to = filters.dateTo;
    final from = filters.dateFrom;

    if (to != null && from != null && to.year == now.year && to.month == now.month && to.day == now.day) {
      final diff = to.difference(from).inDays;
      if (diff >= 6 && diff <= 8) return 'Última semana';
      if (diff >= 28 && diff <= 32) return 'Último mes';
      if (diff >= 360) return 'Último año';
    }
    return null;
  }

  // Traducciones
  String _t(String key) {
    final isEn = widget.language == 'en';
    switch (key) {
      case 'timeFilter': return isEn ? 'Time Filter' : 'Filtro Temporal';
      case 'updating': return isEn ? 'Updating...' : 'Actualizando...';
      case 'observations': return isEn ? 'observations' : 'observaciones';
      case 'week': return isEn ? 'Week' : 'Semana';
      case 'month': return isEn ? 'Month' : 'Mes';
      case 'year': return isEn ? 'Year' : 'Año';
      case 'yearMode': return isEn ? 'Yearly mode' : 'Modo por año';
      case 'sources': return isEn ? 'Sources' : 'Fuentes';
      case 'reset': return isEn ? 'Reset' : 'Restablecer';
      case 'viewMap': return isEn ? 'View Map' : 'Ver Mapa';
      case 'from': return isEn ? 'From' : 'Desde';
      case 'to': return isEn ? 'To' : 'Hasta';
      case 'select': return isEn ? 'Select' : 'Seleccionar';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<FilterProvider>();
    final mapProvider = context.watch<MapProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentMarkers = mapProvider.snapshot?.markers ?? const <MapMarkerData>[];
    final filteredCount = applyMapFilters(currentMarkers, filters).length;
    final dateFormat = DateFormat('d MMM yyyy', widget.language == 'en' ? 'en' : 'es');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.85) 
                : const Color(0xFFF2F2F7).withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                  // Encabezado (Ícono, Título y Contador agrupados)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Ícono con fondo azul redondeado
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.calendarDays, size: 24, color: CupertinoColors.activeBlue),
                          ),
                          const SizedBox(width: 14),
                          // Textos (Título arriba, contador abajo)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t('timeFilter'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary(isDark),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Counter / Loading
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: mapProvider.isLoading
                                    ? Row(
                                        key: const ValueKey('loading_count'),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textSecondary(isDark)),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _t('updating'),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white60 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        '$filteredCount ${_t('observations')}',
                                        key: ValueKey(filteredCount),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Botón Cerrar (X)
                      BouncingWrapper(
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 150), () {
                            if (mounted) widget.onClose();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 24, color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sliding Segmented Control for Presets
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      backgroundColor: isDark ? const Color(0x2E767680) : Colors.black.withValues(alpha: 0.05),
                      thumbColor: isDark ? const Color(0xFF636366) : Colors.white,
                      groupValue: _currentPreset(filters),
                      children: {
                        'Última semana': _buildSegment(_t('week'), isDark),
                        'Último mes': _buildSegment(_t('month'), isDark),
                        'Último año': _buildSegment(_t('year'), isDark),
                      },
                      onValueChanged: (val) {
                        if (val != null) {
                          _applyPreset(val, filters);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Year Mode Switch (Inset Grouped)
                  _buildInsetGroup(
                    isDark: isDark,
                    children: [
                      _buildSwitchTile(
                        title: _t('yearMode'),
                        icon: LucideIcons.calendarDays,
                        value: filters.isYearMode,
                        onChanged: (val) async {
                          await filters.setYearMode(val);
                          widget.onApply();
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dynamic Size for Dates or Grid
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: filters.isYearMode
                        ? _buildYearsGrid(filters, isDark)
                        : _buildDateFields(filters, dateFormat, isDark),
                  ),

                  const SizedBox(height: 20),

                  // Título de Fuentes de datos
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _t('sources'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(isDark),
                      ),
                    ),
                  ),

                  // Fuentes de datos compactas (Botones estilo Apple Maps)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSourceToggle(
                          title: 'ODK',
                          accentColor: Colors.orangeAccent,
                          isSelected: filters.includeOdk,
                          onTap: () async {
                            await filters.toggleSource(odk: !filters.includeOdk);
                            widget.onApply();
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSourceToggle(
                          title: 'iNaturalist',
                          accentColor: Colors.green,
                          isSelected: filters.includeInaturalist,
                          onTap: () async {
                            await filters.toggleSource(inaturalist: !filters.includeInaturalist);
                            widget.onApply();
                          },
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botones inferiores (Restablecer y Ver Mapa en la misma fila)
                  Row(
                    children: [
                      // Botón Restablecer (Secundario)
                      Expanded(
                        flex: 1,
                        child: BouncingWrapper(
                          isCircular: false,
                          onTap: () async {
                            await filters.reset();
                            widget.onApply();
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.rotateCcw,
                                  size: 16,
                                  color: AppTheme.textPrimary(isDark),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _t('reset'),
                                  style: TextStyle(
                                    color: AppTheme.textPrimary(isDark),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón Ver Mapa (Primario)
                      Expanded(
                        flex: 1,
                        child: BouncingWrapper(
                          isCircular: false,
                          onTap: () {
                            Future.delayed(const Duration(milliseconds: 150), () {
                              if (mounted) widget.onClose();
                            });
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _t('viewMap'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ), // Cierre del SingleChildScrollView
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary(isDark),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildInsetGroup({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: isDark ? Colors.white70 : Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary(isDark),
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeColor: CupertinoColors.activeBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDateFields(FilterProvider filters, DateFormat dateFormat, bool isDark) {
    return _buildInsetGroup(
      isDark: isDark,
      children: [
        _buildDateRow(
          _t('from'),
          filters.dateFrom,
          isDark,
          dateFormat,
          () => _pickDate(
            context,
            initial: filters.dateFrom ?? DateTime.now(),
            onSelected: (val) async {
              final to = filters.dateTo ?? DateTime.now();
              await filters.setDateRange(val, val.isAfter(to) ? val : to);
              widget.onApply();
            },
          ),
        ),
        Divider(height: 1, indent: 16, color: isDark ? Colors.white12 : Colors.black12),
        _buildDateRow(
          _t('to'),
          filters.dateTo,
          isDark,
          dateFormat,
          () => _pickDate(
            context,
            initial: filters.dateTo ?? DateTime.now(),
            onSelected: (val) async {
              final from = filters.dateFrom ?? val;
              await filters.setDateRange(val.isBefore(from) ? val : from, val);
              widget.onApply();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(String label, DateTime? date, bool isDark, DateFormat format, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary(isDark),
              letterSpacing: -0.3,
            ),
          ),
          BouncingWrapper(
            isCircular: false,
            onTap: () {
              Future.delayed(const Duration(milliseconds: 150), () {
                onTap();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date != null ? format.format(date) : _t('select'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
                  color: date != null ? CupertinoColors.activeBlue : AppTheme.textSecondary(isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearsGrid(FilterProvider filters, bool isDark) {
    return SizedBox(
      height: 125,
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.35,
        ),
        itemCount: filters.availableYears.length,
        itemBuilder: (context, index) {
          final year = filters.availableYears[index];
          final selected = filters.selectedYear == year;

          return BouncingWrapper(
            isCircular: false,
            onTap: () async {
              await filters.setSelectedYear(year);
              widget.onApply();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected 
                    ? CupertinoColors.activeBlue 
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$year',
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                  color: selected ? Colors.white : AppTheme.textPrimary(isDark),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // Aplicar los colores azulados para mantener la estética
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: CupertinoColors.activeBlue,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1C1C1E),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: CupertinoColors.activeBlue,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (newDate != null) {
      onSelected(newDate);
    }
  }

  Widget _buildSourceToggle({
    required String title,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return BouncingWrapper(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? accentColor.withValues(alpha: 0.15) 
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor.withValues(alpha: 0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 16,
              color: isSelected ? accentColor : AppTheme.textSecondary(isDark),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? accentColor : AppTheme.textPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
