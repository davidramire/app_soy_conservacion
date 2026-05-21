import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Se activará tras el primer build
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_cache_service.dart';
import 'core/storage/secure_token_storage.dart';
import 'providers/backend_status_provider.dart';
import 'providers/map_provider.dart';
import 'providers/observations_provider.dart';
import 'providers/species_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/map_repository.dart';
import 'repositories/observations_repository.dart';
import 'repositories/species_repository.dart';
import 'repositories/users_repository.dart';
import 'services/auth_service.dart';
import 'services/map_service.dart';
import 'services/observations_service.dart';
import 'services/species_service.dart';
import 'services/users_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env.local");
  runApp(const MiApp());
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    
    // Navegar al mapa después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/soy_conservacion_logo.png',
              width: 120,
            ),
            const SizedBox(height: 40),
            const Text(
              'Bienvenido',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = AppConfig.fromEnvironment();

    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: appConfig),
        Provider<SecureTokenStorage>(create: (_) => const SecureTokenStorage()),
        Provider<LocalCacheService>(create: (_) => const LocalCacheService()),
        Provider<ApiClient>(
          create: (context) => ApiClient(
            config: context.read<AppConfig>(),
            tokenStorage: context.read<SecureTokenStorage>(),
          ),
        ),
        Provider<SpeciesService>(
          create: (context) => SpeciesService(apiClient: context.read<ApiClient>()),
        ),
        Provider<ObservationsService>(
          create: (context) => ObservationsService(apiClient: context.read<ApiClient>()),
        ),
        Provider<MapService>(
          create: (context) => MapService(apiClient: context.read<ApiClient>()),
        ),
        Provider<UsersService>(
          create: (context) => UsersService(apiClient: context.read<ApiClient>()),
        ),
        Provider<AuthService>(
          create: (context) => AuthService(
            apiClient: context.read<ApiClient>(),
            tokenStorage: context.read<SecureTokenStorage>(),
          ),
        ),
        Provider<SpeciesRepository>(
          create: (context) => SpeciesRepository(
            service: context.read<SpeciesService>(),
            cacheService: context.read<LocalCacheService>(),
          ),
        ),
        Provider<ObservationsRepository>(
          create: (context) => ObservationsRepository(
            service: context.read<ObservationsService>(),
            cacheService: context.read<LocalCacheService>(),
          ),
        ),
        Provider<MapRepository>(
          create: (context) => MapRepository(
            service: context.read<MapService>(),
            observationsRepository: context.read<ObservationsRepository>(),
            cacheService: context.read<LocalCacheService>(),
          ),
        ),
        Provider<UsersRepository>(
          create: (context) => UsersRepository(service: context.read<UsersService>()),
        ),
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            service: context.read<AuthService>(),
            tokenStorage: context.read<SecureTokenStorage>(),
          ),
        ),
        ChangeNotifierProvider<SpeciesProvider>(
          create: (context) => SpeciesProvider(repository: context.read<SpeciesRepository>()),
        ),
        ChangeNotifierProvider<ObservationsProvider>(
          create: (context) => ObservationsProvider(repository: context.read<ObservationsRepository>()),
        ),
        ChangeNotifierProvider<MapProvider>(
          create: (context) => MapProvider(repository: context.read<MapRepository>()),
        ),
        ChangeNotifierProvider<BackendStatusProvider>(
          create: (context) => BackendStatusProvider(
            apiClient: context.read<ApiClient>(),
            config: context.read<AppConfig>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Poppins',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  bool _isDarkMode = false;
  String _currentLanguage = 'es';
  String _mapStyle = 'outdoors-v12'; 
  late final AnimationController _menuController;

  final Map<String, Map<String, String>> _texts = {
    'es': {
      'appTitle': 'Visor de biodiversidad',
      'menu': 'Menú',
      'account': 'Mi Cuenta',
      'language': 'Idioma / Language',
      'notifications': 'Notificaciones',
      'visualMode': 'Modo Visual',
      'help': 'Centro de Ayuda',
      'logout': 'Salir de la App',
      'mapLayers': 'CAPAS DE MAPA',
      'base': 'Base',
      'years': 'Años',
      'satellite': 'Satélite',
      'dark': 'Oscuro',
      'footerName': 'SOY CONSERVACIÓN',
      'fauna': 'Fauna',
      'flora': 'Flora',
      'date': 'Fecha',
      'analysis': 'Análisis',
    },
    'en': {
      'appTitle': 'Biodiversity Viewer',
      'menu': 'Menu',
      'account': 'My Account',
      'language': 'Language / Idioma',
      'notifications': 'Notifications',
      'visualMode': 'Visual Mode',
      'help': 'Help Center',
      'logout': 'Exit App',
      'mapLayers': 'MAP LAYERS',
      'base': 'Base',
      'years': 'Years',
      'satellite': 'Satellite',
      'dark': 'Dark',
      'footerName': 'I AM CONSERVATION',
      'fauna': 'Fauna',
      'flora': 'Flora',
      'date': 'Date',
      'analysis': 'Analysis',
      'version': 'Version',
    }
  };

  String _t(String key) {
    debugPrint('Traduciendo: $key para idioma: $_currentLanguage');
    final result = _texts[_currentLanguage]?[key] ?? _texts['es']?[key] ?? key;
    debugPrint('Resultado: $result');
    return result;
  }

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Un segundo completo para máxima suavidad
      reverseDuration: const Duration(milliseconds: 800), 
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<BackendStatusProvider>().checkBackend();
      context.read<SpeciesProvider>().loadSpecies();
      context.read<ObservationsProvider>().loadObservations();
      context.read<MapProvider>().loadSnapshot();
    });
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definimos los items aquí para asegurar que se recalculen con el estado actual de _currentLanguage
    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
        icon: const Icon(LucideIcons.cat),
        label: _t('fauna'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(LucideIcons.flower2),
        label: _t('flora'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(LucideIcons.calendar),
        label: _t('date'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(LucideIcons.barChart3),
        label: _t('analysis'),
      ),
    ];

    return Scaffold(
        appBar: AppBar(
          backgroundColor: _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFDFDFDF),
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),

                ),
                child: Image.asset(
                  'assets/images/soy_conservacion_logo.png',
                  height: 28,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _t('appTitle'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          actions: [
            Builder(
              builder: (context) => AnimatedBuilder(
                animation: _menuController,
                builder: (context, child) {
                  final animation = CurvedAnimation(
                    parent: _menuController,
                    curve: Curves.fastOutSlowIn,
                  );
                  return Transform.rotate(
                    angle: animation.value * (3.14159 / 2), 
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 750), // Ajustado: un poco más ágil
                        switchInCurve: Curves.easeInOutExpo,
                        switchOutCurve: Curves.easeInOutExpo,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: RotationTransition(
                              turns: Tween<double>(begin: -0.05, end: 0).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          _menuController.value < 0.5 ? LucideIcons.menu : LucideIcons.x,
                          key: ValueKey(_menuController.value < 0.5),
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      onPressed: () {
                        if (_menuController.status == AnimationStatus.dismissed) {
                          _menuController.forward();
                          Scaffold.of(context).openEndDrawer();
                        } else {
                          Scaffold.of(context).closeEndDrawer();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        onEndDrawerChanged: (isOpen) {
          if (!isOpen) {
            _menuController.reverse();
          }
        },
        endDrawer: AnimatedBuilder(
          animation: _menuController,
          builder: (context, child) {
            // Diseño de animación premium: 
            // Curves.easeOutQuart para una entrada que desliza con elegancia y sin rebotes bruscos.
            final curvedValue = CurvedAnimation(
              parent: _menuController,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            ).value;
            
            return Transform(
              transform: Matrix4.translationValues((1 - curvedValue) * 120, 0, 0)
                ..setEntry(3, 2, 0.0008) // Perspectiva 3D más sutil
                ..rotateY((1 - curvedValue) * 0.05), // Rotación apenas perceptible
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: curvedValue.clamp(0.0, 1.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75, // Ligeramente más ancho para mejor balance visual
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: MediaQuery.of(context).size.height * 0.1,
                      right: 4, // Antes estaba en 16, ahora lo pegamos más al borde derecho
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Drawer(
                      elevation: 8,
                      backgroundColor: _isDarkMode ? const Color(0xFF171717) : Colors.white,
                      child: Builder(
                        builder: (menuContext) => Column(
                          children: [
                            _buildBackendSummaryCard(),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _t('menu'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _isDarkMode ? Colors.white38 : Colors.black38,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                    icon: Icon(
                                      LucideIcons.x,
                                      size: 20,
                                      color: _isDarkMode ? Colors.white54 : Colors.black54,
                                    ),
                                    onPressed: () {
                                      Scaffold.of(menuContext).closeEndDrawer();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            // --- Perfil del 
                            
                            // --- Opciones principales ---
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                children: [
                                  _buildMapLayerSection(),
                                  const Divider(height: 32, indent: 8, endIndent: 8),
                                  const SizedBox(height: 4),
                                  _buildMenuItem(
                                    icon: LucideIcons.languages,
                                    title: _t('language'),
                                    isDark: _isDarkMode,
                                    trailing: Text(
                                      _currentLanguage == 'es' ? 'ES' : 'EN',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _isDarkMode ? Colors.white54 : Colors.black54,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _currentLanguage = (_currentLanguage == 'es') ? 'en' : 'es';
                                      });
                                      debugPrint('BOTÓN PULSADO - Nuevo idioma: $_currentLanguage');
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  _buildMenuItem(
                                    icon: LucideIcons.bell,
                                    title: _t('notifications'),
                                    isDark: _isDarkMode,
                                    onTap: () {},
                                  ),
                                  const SizedBox(height: 4),
                                  _buildMenuItem(
                                    icon: _isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                                    title: _t('visualMode'),
                                    isDark: _isDarkMode,
                                    trailing: Switch.adaptive(
                                      value: _isDarkMode,
                                      onChanged: (value) {
                                        setState(() {
                                          _isDarkMode = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildMenuItem(
                                    icon: LucideIcons.helpCircle,
                                    title: _t('help'),
                                    isDark: _isDarkMode,
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ),
                            
                            // --- Footer ---
                            const Divider(indent: 30, endIndent: 30, thickness: 0.5),
                            _buildMenuItem(
                              icon: LucideIcons.logOut,
                              title: _t('logout'),
                              isDark: _isDarkMode,
                              textColor: Colors.redAccent,
                              iconColor: Colors.redAccent,
                              onTap: () {},
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      _t('footerName'),
                                      key: ValueKey(_currentLanguage),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
                                        color: _isDarkMode ? Colors.white12 : Colors.black12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_t('version')} 1.0.0',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: _isDarkMode ? Colors.white24 : Colors.black26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        body: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(4.5709, -74.2973),
                initialZoom: 4.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                initialRotation: 0.0, // Asegura que el mapa inicie perfectamente recto
                // Bloquea cualquier rotación para mantener la verticalidad absoluta
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
                // Limitar el movimiento a las Américas (aproximadamente)
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                    const LatLng(-56.0, -110.0), // Sur de Chile/Argentina
                    const LatLng(50.0, -30.0),   // Límite norte antes de entrar de lleno a USA y este en el Atlántico
                  ),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://api.mapbox.com/styles/v1/mapbox/{styleId}/tiles/{z}/{x}/{y}@2x?access_token={accessToken}",
                  additionalOptions: {
                    'styleId': _mapStyle,
                    'accessToken': dotenv.get('MAPBOX_ACCESS_TOKEN'),
                  },
                  userAgentPackageName: 'com.example.app',
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: _buildBackendSummaryCard(compact: true),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: _isDarkMode ? const Color(0xFF171717) : Colors.white,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: _isDarkMode ? Colors.white54 : Colors.black54,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: navItems,
          ),
        ),
      );
  }

  Widget _buildMapLayerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 12),
          child: Text(
            _t('mapLayers'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white38 : Colors.black38,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLayerOption(
              _t('base'),
              'outdoors-v12',
              LucideIcons.map,
            ),
            _buildLayerOption(
              _t('years'),
              'light-v11',
              LucideIcons.calendar,
            ),
            _buildLayerOption(
              _t('satellite'),
              'satellite-streets-v12',
              LucideIcons.layers,
            ),
            _buildLayerOption(
              _t('dark'),
              'dark-v11',
              LucideIcons.moon,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLayerOption(String label, String style, IconData icon) {
    bool isSelected = _mapStyle == style;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mapStyle = style;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: isSelected
                  ? Colors.blueAccent.withValues(alpha: 0.15)
                  : (_isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F2F5)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.blueAccent : (_isDarkMode ? Colors.white54 : Colors.black54),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blueAccent : (_isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(
        icon,
        color: iconColor ?? (isDark ? Colors.white70 : Colors.black87),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildBackendSummaryCard({bool compact = false}) {
    return Consumer4<BackendStatusProvider, SpeciesProvider, ObservationsProvider, MapProvider>(
      builder: (context, backendStatus, speciesProvider, observationsProvider, mapProvider, child) {
        final backgroundColor = _isDarkMode ? Colors.black.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.92);
        final borderColor = backendStatus.state == BackendConnectionState.online
            ? Colors.greenAccent.withValues(alpha: 0.45)
            : backendStatus.state == BackendConnectionState.degraded
              ? Colors.orangeAccent.withValues(alpha: 0.45)
              : Colors.blueAccent.withValues(alpha: 0.25);

        final card = Container(
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: backendStatus.state == BackendConnectionState.online
                          ? Colors.green
                          : backendStatus.state == BackendConnectionState.degraded
                              ? Colors.orange
                              : backendStatus.state == BackendConnectionState.checking
                                  ? Colors.blue
                                  : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Backend ${backendStatus.environmentLabel}',
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: _isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: backendStatus.isBusy
                        ? SizedBox(
                            width: compact ? 16 : 18,
                            height: compact ? 16 : 18,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            LucideIcons.refreshCw,
                            size: compact ? 16 : 18,
                            color: _isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                    onPressed: backendStatus.isBusy
                        ? null
                        : () {
                            context.read<BackendStatusProvider>().checkBackend();
                            context.read<SpeciesProvider>().refresh();
                            context.read<ObservationsProvider>().refresh();
                            context.read<MapProvider>().refresh();
                          },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                backendStatus.baseUri.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat('Species', speciesProvider.items.length.toString()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStat('Obs.', observationsProvider.items.length.toString()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStat('Map', (mapProvider.snapshot?.markers.length ?? 0).toString()),
                  ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 10),
                Text(
                  backendStatus.message ?? 'Sin comprobación reciente',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
              if (speciesProvider.errorMessage != null || observationsProvider.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  speciesProvider.errorMessage ?? observationsProvider.errorMessage ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
        );

        if (compact) {
          return card;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: card,
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: _isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
