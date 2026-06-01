import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/map_snapshot.dart';
import '../providers/filter_provider.dart';
import '../theme/app_theme.dart';
import '../utils/marker_filters.dart';

class DateFilterPanel extends StatelessWidget {
  const DateFilterPanel({
    super.key,
    required this.markers,
    required this.onClose,
    required this.onApply,
  });

  final List<MapMarkerData> markers;
  final VoidCallback onClose;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<FilterProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredCount = applyMapFilters(markers, filters).length;
    final dateFormat = DateFormat('d MMM yyyy', 'es');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Row(
                children: [
                  Icon(LucideIcons.calendar, color: AppTheme.textPrimary(isDark)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Filtro por fecha',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(isDark),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, color: AppTheme.textSecondary(isDark)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$filteredCount observaciones visibles',
                style: TextStyle(
                  color: AppTheme.textSecondary(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Desde',
                      value: filters.isYearMode
                          ? '${filters.selectedYear ?? DateTime.now().year}'
                          : (filters.dateFrom != null
                              ? dateFormat.format(filters.dateFrom!)
                              : 'Seleccionar'),
                      isDark: isDark,
                      onTap: filters.isYearMode
                          ? null
                          : () => _pickDate(
                                context,
                                initial: filters.dateFrom ?? DateTime.now(),
                                onSelected: (value) async {
                                  final to = filters.dateTo ?? DateTime.now();
                                  await filters.setDateRange(
                                    value,
                                    value.isAfter(to) ? value : to,
                                  );
                                  onApply();
                                },
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Hasta',
                      value: filters.isYearMode
                          ? '${filters.selectedYear ?? DateTime.now().year}'
                          : (filters.dateTo != null
                              ? dateFormat.format(filters.dateTo!)
                              : 'Seleccionar'),
                      isDark: isDark,
                      onTap: filters.isYearMode
                          ? null
                          : () => _pickDate(
                                context,
                                initial: filters.dateTo ?? DateTime.now(),
                                onSelected: (value) async {
                                  final from = filters.dateFrom ?? value;
                                  await filters.setDateRange(
                                    value.isBefore(from) ? value : from,
                                    value,
                                  );
                                  onApply();
                                },
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Modo por año',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(isDark),
                  ),
                ),
                subtitle: Text(
                  'Filtra todas las observaciones de un año',
                  style: TextStyle(color: AppTheme.textSecondary(isDark)),
                ),
                value: filters.isYearMode,
                onChanged: (value) async {
                  await filters.setYearMode(value);
                  onApply();
                },
              ),
              if (filters.isYearMode) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    itemCount: filters.availableYears.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final year = filters.availableYears[index];
                      final selected = filters.selectedYear == year;
                      return Material(
                        color: selected
                            ? Colors.blueAccent.withValues(alpha: isDark ? 0.18 : 0.12)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03)),
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: selected
                                  ? Colors.blueAccent
                                  : (isDark ? Colors.white12 : Colors.black12),
                            ),
                          ),
                          leading: Icon(
                            LucideIcons.calendar,
                            color: selected ? Colors.blueAccent : AppTheme.textSecondary(isDark),
                          ),
                          title: Text(
                            '$year',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(isDark),
                            ),
                          ),
                          subtitle: Text(
                            'Período completo',
                            style: TextStyle(color: AppTheme.textSecondary(isDark)),
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                              : null,
                          onTap: () async {
                            await filters.setSelectedYear(year);
                            onApply();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Fuentes',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('ODK'),
                    selected: filters.includeOdk,
                    onSelected: (value) async {
                      await filters.toggleSource(odk: value);
                      onApply();
                    },
                  ),
                  FilterChip(
                    label: const Text('iNaturalist'),
                    selected: filters.includeInaturalist,
                    onSelected: (value) async {
                      await filters.toggleSource(inaturalist: value);
                      onApply();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await filters.reset();
                        onApply();
                      },
                      icon: const Icon(LucideIcons.rotateCcw, size: 18),
                      label: const Text('Restablecer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onClose,
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
  });

  final String label;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
