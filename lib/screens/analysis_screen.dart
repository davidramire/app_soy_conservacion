import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/filter_provider.dart';
import '../repositories/analytics_repository.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ux/bouncing_wrapper.dart';

enum _AnalysisTab { inicio, rankings, graficos }

class AnalysisScreen extends StatefulWidget {
  final String language;
  const AnalysisScreen({super.key, required this.language});

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
    Color(0xFF34C759), // iOS Green
    Color(0xFF5AC8FA), // iOS Light Blue
    Color(0xFF007AFF), // iOS Blue
    Color(0xFF5856D6), // iOS Purple
    Color(0xFFFF2D55), // iOS Pink
    Color(0xFFFF9500), // iOS Orange
    Color(0xFFFFCC00), // iOS Yellow
    Color(0xFF8E8E93), // iOS Gray
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

  Future<void> _loadData({bool refresh = false}) async {
    final repository = context.read<AnalyticsRepository>();
    final filters = context.read<FilterProvider>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final range = filters.effectiveDateRange;
      final results = await Future.wait([
        repository.loadTaxonomicGroups(refresh: refresh, dateRange: range, source: _sourceQuery),
        repository.loadUserRanking(refresh: refresh, dateRange: range, source: _sourceQuery, limit: 100),
        repository.loadSpeciesRanking(refresh: refresh, dateRange: range, source: _sourceQuery, limit: 12),
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

  // Traducciones
  String _t(String key) {
    final isEn = widget.language == 'en';
    switch (key) {
      case 'analysis': return isEn ? 'Analysis' : 'Análisis';
      case 'update': return isEn ? 'Update' : 'Actualizar';
      case 'overview': return isEn ? 'Overview' : 'Inicio';
      case 'rankings': return isEn ? 'Rankings' : 'Rankings';
      case 'charts': return isEn ? 'Charts' : 'Gráficos';
      case 'errorLoading': return isEn ? 'Could not load analysis' : 'No fue posible cargar el análisis';
      case 'checkConnection': return isEn ? 'Check your internet connection and try again.' : 'Verifica tu conexión y vuelve a intentar.';
      case 'generalSummary': return isEn ? 'General Summary' : 'Resumen General';
      case 'totalRecords': return isEn ? 'Total Records' : 'Total de Registros';
      case 'taxonomicGroups': return isEn ? 'Taxonomic Groups' : 'Grupos Taxonómicos';
      case 'activeUsers': return isEn ? 'Active Users' : 'Usuarios Activos';
      case 'participants': return isEn ? 'Participants' : 'Participantes';
      case 'topUsers': return isEn ? 'Top 10 Users' : 'Top 10 Usuarios';
      case 'topSpecies': return isEn ? 'TOP SPECIES' : 'ESPECIES PRINCIPALES';
      case 'records': return isEn ? 'records' : 'registros';
      case 'recordsCap': return isEn ? 'Records' : 'Registros';
      case 'taxaGroups': return isEn ? 'Taxa Groups' : 'Grupos Tax.';
      case 'observationsByGroup': return isEn ? 'Observations by Group' : 'Observaciones por Grupo';
      case 'mostViewedSpecies': return isEn ? 'MOST VIEWED SPECIES' : 'ESPECIES MÁS VISTAS';
      case 'outstandingObservers': return isEn ? 'OUTSTANDING OBSERVERS' : 'OBSERVADORES DESTACADOS';
      case 'contributedRecords': return isEn ? 'Contributed records' : 'Registros aportados';
      case 'topObservers': return isEn ? 'TOP OBSERVERS' : 'TOP OBSERVADORES';
      case 'observer': return isEn ? 'Observer' : 'Observador';
      case 'noData': return isEn ? 'Not enough data' : 'No hay datos suficientes';
      case 'noDataToChart': return isEn ? 'No data to chart' : 'No hay datos para graficar';
      case 'recordsByGroup': return isEn ? 'Records by Group' : 'Registros por Grupo';
      case 'chartGroups': return isEn ? 'Registered taxonomic groups' : 'Grupos taxonómicos registrados';
      case 'chartSpecies': return isEn ? 'Registered species' : 'Especies registradas';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C2B28) : const Color(0xFFD0E6DB), // Pastel ligeramente más oscuro
        elevation: 0,
        scrolledUnderElevation: 0, // Evita que cambie de color al deslizar
        surfaceTintColor: Colors.transparent, // Asegura el color fijo
        centerTitle: true,
        title: Text(
          _t('analysis'),
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF1A4D3E),
          ),
        ),
        actions: [
          Tooltip(
            message: _t('update'),
            child: BouncingWrapper(
              isCircular: true,
              onTap: () {
                Future.delayed(const Duration(milliseconds: 150), () {
                  _loadData(refresh: true);
                });
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Icon(LucideIcons.refreshCw, color: isDark ? Colors.white70 : const Color(0xFF1A4D3E)),
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPillToggle(
            label: 'ODK',
            isActive: _includeOdk,
            color: const Color(0xFFF97316), // Premium Orange
            isDark: isDark,
            onTap: () {
              setState(() {
                _includeOdk = !_includeOdk;
                if (!_includeOdk && !_includeInaturalist) _includeInaturalist = true;
              });
              _loadData();
            },
          ),
          const SizedBox(width: 12),
          _buildPillToggle(
            label: 'iNaturalist',
            isActive: _includeInaturalist,
            color: const Color(0xFF10B981), // Premium Emerald
            isDark: isDark,
            onTap: () {
              setState(() {
                _includeInaturalist = !_includeInaturalist;
                if (!_includeOdk && !_includeInaturalist) _includeOdk = true;
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillToggle({
    required String label,
    required bool isActive,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive 
              ? color.withValues(alpha: isDark ? 0.25 : 0.15) 
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color.withValues(alpha: isDark ? 0.3 : 0.2) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              Icon(LucideIcons.checkCircle2, color: color, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? color : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<_AnalysisTab>(
          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
          thumbColor: isDark ? const Color(0xFF3A3A3C) : Colors.white,
          groupValue: _activeTab,
          children: {
            _AnalysisTab.inicio: _buildTabSegment(_t('overview'), LucideIcons.home, _activeTab == _AnalysisTab.inicio, isDark),
            _AnalysisTab.rankings: _buildTabSegment(_t('rankings'), LucideIcons.trophy, _activeTab == _AnalysisTab.rankings, isDark),
            _AnalysisTab.graficos: _buildTabSegment(_t('charts'), LucideIcons.barChart3, _activeTab == _AnalysisTab.graficos, isDark),
          },
          onValueChanged: (val) {
            if (val != null) {
              setState(() => _activeTab = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildTabSegment(String text, IconData icon, bool isActive, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.black54),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.black54),
            ),
          ),
        ],
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
              _t('errorLoading'),
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
            CupertinoButton(
              color: AppTheme.textPrimary(isDark).withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderRadius: BorderRadius.circular(99),
              onPressed: () => _loadData(refresh: true),
              child: Text(
                'Reintentar',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePanel(bool isDark) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    return switch (_activeTab) {
      _AnalysisTab.inicio => _buildInicioPanel(isDark),
      _AnalysisTab.rankings => _buildRankingsPanel(isDark),
      _AnalysisTab.graficos => _buildChartsPanel(isDark),
    };
  }

  Widget _buildInicioPanel(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 140),
      children: [
        // Widget Hero (Registros totales)
        _buildStatCard(
          isDark: isDark,
          title: _t('totalRecords'),
          value: '$_totalRecords',
          icon: LucideIcons.leaf,
          color: const Color(0xFF10B981), // Emerald
        ),
        const SizedBox(height: 24),
        // Fila de Widgets Cuadrados
        Row(
          children: [
            Expanded(
              child: _squareStatCard(
                isDark: isDark,
                title: _t('participants'),
                value: '${_users.length}',
                icon: LucideIcons.users,
                color: const Color(0xFF3B82F6), // Blue
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _squareStatCard(
                isDark: isDark,
                title: _t('taxaGroups'),
                value: '${_groups.length}',
                icon: LucideIcons.layers,
                color: const Color(0xFF8B5CF6), // Purple
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 40),
        
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            _t('mostViewedSpecies'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.textSecondary(isDark),
            ),
          ),
        ),
        _buildInsetGroupedList(
          isDark: isDark,
          items: _species.take(3).toList(),
          builder: (item, index, isLast) => _rankingListRow(
            isDark: isDark,
            title: item.scientificName,
            subtitle: item.taxonomicGroup,
            value: item.views,
            index: index,
            isLast: isLast,
          ),
        ),
        
        const SizedBox(height: 32),
        
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            _t('outstandingObservers'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.textSecondary(isDark),
            ),
          ),
        ),
        _buildInsetGroupedList(
          isDark: isDark,
          items: _users.take(3).toList(),
          builder: (item, index, isLast) => _rankingListRow(
            isDark: isDark,
            title: item.username,
            subtitle: _t('contributedRecords'),
            value: item.total,
            index: index,
            isLast: isLast,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(isDark),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
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

  Widget _squareStatCard({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(isDark),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppTheme.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.textPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsPanel(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 140),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            _t('topObservers'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.textSecondary(isDark),
            ),
          ),
        ),
        _buildInsetGroupedList(
          isDark: isDark,
          items: _users.take(12).toList(),
          builder: (item, index, isLast) => _rankingListRow(
            isDark: isDark,
            title: item.username,
            subtitle: _t('observer'),
            value: item.total,
            index: index,
            isLast: isLast,
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            _t('topSpecies'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.textSecondary(isDark),
            ),
          ),
        ),
        _buildInsetGroupedList(
          isDark: isDark,
          items: _species,
          builder: (item, index, isLast) => _rankingListRow(
            isDark: isDark,
            title: item.scientificName,
            subtitle: item.taxonomicGroup,
            value: item.views,
            index: index,
            isLast: isLast,
            isItalic: false,
          ),
        ),
      ],
    );
  }

  Widget _buildInsetGroupedList<T>({
    required bool isDark,
    required List<T> items,
    required Widget Function(T item, int index, bool isLast) builder,
  }) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(isDark),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            _t('noData'),
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary(isDark),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(isDark),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return builder(items[index], index, index == items.length - 1);
        }),
      ),
    );
  }

  Widget _rankingListRow({
    required bool isDark,
    required String title,
    String? subtitle,
    required int value,
    required int index,
    required bool isLast,
    bool isItalic = false,
  }) {
    final rank = index + 1;
    final isTop3 = rank <= 3;
    
    Color? medalColor;
    if (rank == 1) medalColor = const Color(0xFFF59E0B); // Oro
    else if (rank == 2) medalColor = const Color(0xFF94A3B8); // Plata
    else if (rank == 3) medalColor = const Color(0xFFD97706); // Bronce

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: isTop3
                    ? Icon(LucideIcons.medal, color: medalColor, size: 22)
                    : Text(
                        '$rank',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary(isDark).withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                        color: AppTheme.textPrimary(isDark),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$value',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            ),
          ),
      ],
    );
  }

  Widget _buildChartsPanel(bool isDark) {
    if (_groups.isEmpty) {
      return Center(
        child: Text(
          _t('noDataToChart'),
          style: TextStyle(color: AppTheme.textSecondary(isDark)),
        ),
      );
    }

    final topGroups = _groups.take(6).toList();
    final topSpecies = _species.take(5).toList();

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 140),
      children: [
        _chartCard(
          isDark: isDark,
          title: _t('chartGroups'),
          height: 330,
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    sections: [
                      for (var i = 0; i < topGroups.length; i++)
                        PieChartSectionData(
                          value: topGroups[i].total.toDouble(),
                          title: '${topGroups[i].total}',
                          color: _chartColors[i % _chartColors.length],
                          radius: 45,
                          titleStyle: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < topGroups.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _chartColors[i % _chartColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          topGroups[i].name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _chartCard(
          isDark: isDark,
          title: _t('chartSpecies'),
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: topSpecies.isEmpty
                  ? 1
                  : topSpecies.map((item) => item.views).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value == value.toInt()) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary(isDark),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= topSpecies.length) return const SizedBox.shrink();
                      
                      final parts = topSpecies[index].scientificName.split(' ');
                      final label = parts.length > 1 ? '${parts[0][0]}. ${parts[1]}' : parts[0];
                      
                      return SideTitleWidget(
                        meta: meta,
                        angle: -0.4,
                        space: 8,
                        child: Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < topSpecies.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: topSpecies[i].views.toDouble(),
                        color: _chartColors[i % _chartColors.length],
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: topSpecies.isEmpty ? 1 : topSpecies.map((item) => item.views).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                        ),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4, bottom: 20),
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppTheme.textPrimary(isDark),
              ),
            ),
          ),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}
