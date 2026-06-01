import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/filter_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

enum _AnalysisTab { inicio, rankings, graficos }

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  _AnalysisTab _activeTab = _AnalysisTab.inicio;
  bool _isLoading = true;
  String? _errorMessage;
  bool _initialized = false;

  List<TaxonomicGroupStat> _groups = const [];
  List<UserRankingItem> _users = const [];
  List<SpeciesRankingItem> _species = const [];
  int _totalRecords = 0;

  bool _includeOdk = true;
  bool _includeInaturalist = true;

  static const List<Color> _chartColors = [
    Color(0xFF059669),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
    Color(0xFFDB2777),
    Color(0xFF65A30D),
    Color(0xFFCA8A04),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadData();
    }
  }

  String get _sourceQuery {
    if (_includeOdk && _includeInaturalist) {
      return 'all';
    }
    if (_includeOdk) {
      return 'odk';
    }
    return 'inaturalist';
  }

  Future<void> _loadData() async {
    final service = context.read<AnalyticsService>();
    final filters = context.read<FilterProvider>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final range = filters.effectiveDateRange;
      final results = await Future.wait([
        service.fetchTaxonomicGroups(dateRange: range, source: _sourceQuery),
        service.fetchUserRanking(dateRange: range, source: _sourceQuery, limit: 100),
        service.fetchSpeciesRanking(dateRange: range, source: _sourceQuery, limit: 12),
      ]);

      final groups = results[0] as List<TaxonomicGroupStat>;
      final users = results[1] as List<UserRankingItem>;
      final species = results[2] as List<SpeciesRankingItem>;
      final total = groups.fold<int>(0, (sum, group) => sum + group.total);

      if (!mounted) {
        return;
      }

      setState(() {
        _groups = groups;
        _users = users;
        _species = species;
        _totalRecords = total;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Análisis'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSourceToggles(isDark),
          _buildTabs(isDark),
          Expanded(
            child: _errorMessage != null
                ? _buildError(isDark)
                : _buildActivePanel(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceToggles(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('ODK'),
            selected: _includeOdk,
            onSelected: (value) {
              setState(() {
                _includeOdk = value;
                if (!_includeOdk && !_includeInaturalist) {
                  _includeInaturalist = true;
                }
              });
              _loadData();
            },
          ),
          FilterChip(
            label: const Text('iNaturalist'),
            selected: _includeInaturalist,
            onSelected: (value) {
              setState(() {
                _includeInaturalist = value;
                if (!_includeOdk && !_includeInaturalist) {
                  _includeOdk = true;
                }
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _tabButton('Inicio', LucideIcons.home, _AnalysisTab.inicio, isDark),
          const SizedBox(width: 8),
          _tabButton('Rankings', LucideIcons.trophy, _AnalysisTab.rankings, isDark),
          const SizedBox(width: 8),
          _tabButton('Gráficos', LucideIcons.barChart3, _AnalysisTab.graficos, isDark),
        ],
      ),
    );
  }

  Widget _tabButton(
    String label,
    IconData icon,
    _AnalysisTab tab,
    bool isDark,
  ) {
    final active = _activeTab == tab;
    return Expanded(
      child: Material(
        color: active
            ? Colors.teal.withValues(alpha: isDark ? 0.18 : 0.12)
            : AppTheme.surfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _activeTab = tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 18, color: active ? Colors.teal : AppTheme.textSecondary(isDark)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.teal : AppTheme.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, color: AppTheme.textSecondary(isDark), size: 40),
            const SizedBox(height: 12),
            Text(
              'No fue posible cargar el análisis',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary(isDark)),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadData, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePanel(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return switch (_activeTab) {
      _AnalysisTab.inicio => _buildInicioPanel(isDark),
      _AnalysisTab.rankings => _buildRankingsPanel(isDark),
      _AnalysisTab.graficos => _buildChartsPanel(isDark),
    };
  }

  Widget _buildInicioPanel(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statCard(
          isDark: isDark,
          title: 'Registros totales',
          value: '$_totalRecords',
          icon: LucideIcons.leaf,
          color: Colors.teal,
        ),
        const SizedBox(height: 12),
        _statCard(
          isDark: isDark,
          title: 'Participantes con registros',
          value: '${_users.length}',
          icon: LucideIcons.users,
          color: Colors.blue,
          subtitle: 'Hasta 100 con observaciones',
        ),
        const SizedBox(height: 12),
        _statCard(
          isDark: isDark,
          title: 'Grupos taxonómicos',
          value: '${_groups.length}',
          icon: LucideIcons.layers,
          color: Colors.deepPurple,
        ),
      ],
    );
  }

  Widget _statCard({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary(isDark),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary(isDark),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsPanel(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Top observadores',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        ..._users.take(12).map(
              (item) => _rankingTile(
                isDark: isDark,
                title: item.username,
                subtitle: 'Observador',
                value: item.total,
              ),
            ),
        const SizedBox(height: 24),
        Text(
          'Top especies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        ..._species.map(
              (item) => _rankingTile(
                isDark: isDark,
                title: item.scientificName,
                subtitle: item.taxonomicGroup,
                value: item.views,
              ),
            ),
      ],
    );
  }

  Widget _rankingTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required int value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(isDark),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: AppTheme.textSecondary(isDark)),
                ),
              ],
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsPanel(bool isDark) {
    if (_groups.isEmpty) {
      return Center(
        child: Text(
          'No hay datos para graficar',
          style: TextStyle(color: AppTheme.textSecondary(isDark)),
        ),
      );
    }

    final topGroups = _groups.take(8).toList();
    final topSpecies = _species.take(8).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _chartCard(
          isDark: isDark,
          title: 'Registros por grupo taxonómico',
          height: 260,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: [
                for (var i = 0; i < topGroups.length; i++)
                  PieChartSectionData(
                    value: topGroups[i].total.toDouble(),
                    title: topGroups[i].total.toString(),
                    color: _chartColors[i % _chartColors.length],
                    radius: 56,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _chartCard(
          isDark: isDark,
          title: 'Especies con más registros',
          height: 280,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: topSpecies.isEmpty
                  ? 1
                  : topSpecies.map((item) => item.views).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= topSpecies.length) {
                        return const SizedBox.shrink();
                      }
                      final label = topSpecies[index].scientificName.split(' ').first;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary(isDark),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < topSpecies.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: topSpecies[i].views.toDouble(),
                        color: _chartColors[i % _chartColors.length],
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chartCard({
    required bool isDark,
    required String title,
    required double height,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}
