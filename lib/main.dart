import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/foundation.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Se activará tras el primer build
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_cache_service.dart';
import 'core/storage/secure_token_storage.dart';
import 'models/map_snapshot.dart';
import 'models/species.dart';
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
  // Aseguramos que las ayudas de debug paint estén desactivadas en debug
  assert(() {
    rendering.debugPaintSizeEnabled = false;
    rendering.debugPaintBaselinesEnabled = false;
    rendering.debugPaintPointersEnabled = false;
    return true;
  }());
  // Extra: for some environments, also set them when kDebugMode is true
  if (kDebugMode) {
    try {
      rendering.debugPaintSizeEnabled = false;
      rendering.debugPaintBaselinesEnabled = false;
      rendering.debugPaintPointersEnabled = false;
    } catch (_) {
      // ignore: no-op in environments where these setters aren't available
    }
  }
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
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
            Image.asset('assets/images/soy_conservacion_logo.png', width: 120),
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
        theme: ThemeData(brightness: Brightness.light, fontFamily: 'Poppins'),
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

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  bool _isDarkMode = false;
  String _currentLanguage = 'es';
  String _mapStyle = 'outdoors-v12';
  String _taxonomyFocus = 'fauna';
  String? _activeTaxonomyGroup;
  final MapController _mapController = MapController();
  final Map<String, Future<String?>> _placeNameFutureCache = {};
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
      'selectMapView': 'Selecciona una vista del mapa',
      'base': 'Base',
      'years': 'Claro',
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
      'selectMapView': 'Select a map view',
      'base': 'Base',
      'years': 'Light',
      'satellite': 'Satellite',
      'dark': 'Dark',
      'footerName': 'I AM CONSERVATION',
      'fauna': 'Fauna',
      'flora': 'Flora',
      'date': 'Date',
      'analysis': 'Analysis',
      'version': 'Version',
    },
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
      duration: const Duration(
        milliseconds: 1000,
      ), // Un segundo completo para máxima suavidad
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
        icon: const Icon(Icons.pets),
        label: _t('fauna'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.eco),
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
        backgroundColor: _isDarkMode
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFDFDFDF),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
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
                      duration: const Duration(
                        milliseconds: 750,
                      ), // Ajustado: un poco más ágil
                      switchInCurve: Curves.easeInOutExpo,
                      switchOutCurve: Curves.easeInOutExpo,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: RotationTransition(
                            turns: Tween<double>(
                              begin: -0.05,
                              end: 0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        _menuController.value < 0.5
                            ? LucideIcons.menu
                            : LucideIcons.x,
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
          final curvedValue = CurvedAnimation(
            parent: _menuController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ).value;

          return Transform(
            transform: Matrix4.translationValues((1 - curvedValue) * 80, 0, 0)
              ..setEntry(3, 2, 0.001)
              ..rotateY((1 - curvedValue) * 0.02),
            alignment: Alignment.centerRight,
            child: Opacity(
              opacity: curvedValue.clamp(0.0, 1.0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                margin: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: MediaQuery.of(context).size.height * 0.16,
                  right: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isDarkMode ? 0.55 : 0.1),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: const Offset(-6, 0),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Contenido del menú
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? const Color(0xFF1C1C1E)
                              : const Color(0xFFFAFAFA),
                        ),
                        child: Drawer(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          child: Builder(
                            builder: (menuContext) => Column(
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.fromLTRB(24, 28, 16, 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        _t('menu'),
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: _isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF1C1C1E),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: _isDarkMode
                                              ? Colors.white.withValues(alpha: 0.12)
                                              : Colors.black.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: Icon(
                                            LucideIcons.x,
                                            size: 18,
                                            color: _isDarkMode
                                                ? Colors.white.withValues(alpha: 0.9)
                                                : Colors.black.withValues(alpha: 0.75),
                                          ),
                                          onPressed: () {
                                            Scaffold.of(menuContext).closeEndDrawer();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Línea divisora premium estilo Apple
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20),
                                  height: 0.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isDarkMode
                                          ? [
                                              Colors.transparent,
                                              Colors.white.withValues(alpha: 0.15),
                                              Colors.white.withValues(alpha: 0.15),
                                              Colors.transparent,
                                            ]
                                          : [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.1),
                                              Colors.black.withValues(alpha: 0.1),
                                              Colors.transparent,
                                            ],
                                    ),
                                  ),
                                ),

                                // Items distribuidos en todo el espacio
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildMenuItem(
                                          icon: LucideIcons.languages,
                                          title: _t('language'),
                                          isDark: _isDarkMode,
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4A90E2).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(7),
                                            ),
                                            child: Text(
                                              _currentLanguage == 'es' ? 'ES' : 'EN',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF4A90E2),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _currentLanguage =
                                                  (_currentLanguage == 'es') ? 'en' : 'es';
                                            });
                                            debugPrint(
                                              'BOTÓN PULSADO - Nuevo idioma: $_currentLanguage',
                                            );
                                          },
                                        ),
                                        _buildMenuItem(
                                          icon: LucideIcons.bell,
                                          title: _t('notifications'),
                                          isDark: _isDarkMode,
                                          onTap: () {},
                                        ),
                                        _buildMenuItem(
                                          icon: _isDarkMode
                                              ? LucideIcons.moon
                                              : LucideIcons.sun,
                                          title: _t('visualMode'),
                                          isDark: _isDarkMode,
                                          trailing: Transform.scale(
                                            scale: 0.8,
                                            child: Switch.adaptive(
                                              value: _isDarkMode,
                                              activeColor: const Color(0xFF4A90E2),
                                              onChanged: (value) {
                                                setState(() {
                                                  _isDarkMode = value;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        _buildMenuItem(
                                          icon: LucideIcons.helpCircle,
                                          title: _t('help'),
                                          isDark: _isDarkMode,
                                          onTap: () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Separador
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  height: 0.5,
                                  color: _isDarkMode
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),

                                // Botón salir
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: _buildMenuItem(
                                    icon: LucideIcons.logOut,
                                    title: _t('logout'),
                                    isDark: _isDarkMode,
                                    textColor: const Color(0xFFFF3B30),
                                    iconColor: const Color(0xFFFF3B30),
                                    onTap: () {},
                                  ),
                                ),

                                // Footer
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                                  child: Column(
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: Text(
                                          _t('footerName'),
                                          key: ValueKey(_currentLanguage),
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2.0,
                                            color: _isDarkMode
                                                ? Colors.white.withValues(alpha: 0.2)
                                                : Colors.black.withValues(alpha: 0.15),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_t('version')} 1.0.0',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: _isDarkMode
                                              ? Colors.white.withValues(alpha: 0.3)
                                              : Colors.black.withValues(alpha: 0.25),
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

                    // Borde fino premium — overlay encima del contenido
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isDarkMode
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : Colors.black.withValues(alpha: 0.1),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      body: Consumer2<SpeciesProvider, MapProvider>(
        builder: (context, speciesProvider, mapProvider, child) {
          final snapshot = mapProvider.snapshot;
          final markers = snapshot?.markers ?? const <MapMarkerData>[];
          final mapCenter = snapshot?.center ?? const LatLng(4.5709, -74.2973);
          final mapZoom = snapshot?.zoom ?? 4.0;
          final isCompactLayout = MediaQuery.of(context).size.width < 760;
          final bottomInset = MediaQuery.of(context).padding.bottom;
          final visibleMarkers = _visibleMarkersForTaxonomy(
            markers,
            speciesProvider.items,
          );

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                key: ValueKey(
                  '${mapCenter.latitude}_${mapCenter.longitude}_${mapZoom}_${visibleMarkers.length}_$_mapStyle',
                ),
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: mapZoom,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  initialRotation: 0.0,
                  interactionOptions: const InteractionOptions(
                    flags:
                        InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      const LatLng(-56.0, -110.0),
                      const LatLng(50.0, -30.0),
                    ),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://api.mapbox.com/styles/v1/mapbox/{styleId}/tiles/{z}/{x}/{y}@2x?access_token={accessToken}",
                    additionalOptions: {
                      'styleId': _mapStyle,
                      'accessToken': dotenv.get('MAPBOX_ACCESS_TOKEN'),
                    },
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: visibleMarkers
                        .map(
                          (marker) => Marker(
                            point: marker.position,
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: _buildMapMarker(marker),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              Positioned(
                right: 16,
                bottom: bottomInset + (isCompactLayout ? 226 : 248),
                child: _buildSourceLegend(),
              ),
              Positioned(
                left: 16,
                bottom: bottomInset + (isCompactLayout ? 40 : 52),
                child: FloatingActionButton(
                  heroTag: 'mapLayersButton',
                  backgroundColor: _isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  foregroundColor: Colors.blueAccent,
                  elevation: 4,
                  onPressed: () => _showMapLayerSelector(context),
                  child: const Icon(LucideIcons.layers, size: 18),
                ),
              ),
            ],
          );
        },
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
          currentIndex: _taxonomyFocus == 'flora' ? 1 : 0,
          onTap: (index) {
            setState(() {
              if (index == 0) {
                _taxonomyFocus = 'fauna';
                _activeTaxonomyGroup = null;
              } else if (index == 1) {
                _taxonomyFocus = 'flora';
                _activeTaxonomyGroup = null;
              }
            });
            // mostrar panel de selección de grupo para el foco actual
            Future.microtask(() => _showTaxonomyPanel(context));
          },
        ),
      ),
    );
  }

  Widget _buildSourceLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.black.withValues(alpha: 0.78)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendDot(color: Colors.blue, label: 'ODK'),
          const SizedBox(width: 10),
          _buildLegendDot(color: Colors.green, label: 'iNaturalist'),
        ],
      ),
    );
  }

  void _showMapLayerSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF171717) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.layers,
                        color: Colors.blueAccent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('mapLayers'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _t('selectMapView'),
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.1,
                              color: _isDarkMode
                                  ? Colors.white60
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.78,
                  children: [
                    _buildLayerOption(
                      label: _t('base'),
                      style: 'outdoors-v12',
                      icon: LucideIcons.map,
                      onTap: () {
                        setState(() {
                          _mapStyle = 'outdoors-v12';
                        });
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                    _buildLayerOption(
                      label: _t('years'),
                      style: 'light-v11',
                      icon: LucideIcons.sun,
                      onTap: () {
                        setState(() {
                          _mapStyle = 'light-v11';
                        });
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                    _buildLayerOption(
                      label: _t('satellite'),
                      style: 'satellite-streets-v12',
                      icon: LucideIcons.layers,
                      onTap: () {
                        setState(() {
                          _mapStyle = 'satellite-streets-v12';
                        });
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                    _buildLayerOption(
                      label: _t('dark'),
                      style: 'dark-v11',
                      icon: LucideIcons.moon,
                      onTap: () {
                        setState(() {
                          _mapStyle = 'dark-v11';
                        });
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMapMarker(MapMarkerData marker) {
    final source = marker.resolvedSourceType;
    final color = source == 'inaturalist' ? Colors.green : Colors.blue;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Icon(
          LucideIcons.mapPin,
          size: 44,
          color: color.withValues(alpha: 0.96),
        ),
        Positioned(
          top: 10,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
        ),
        Positioned(
          bottom: 1,
          child: Icon(
                            _taxonomyFocusIcon(),
            size: 14,
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  bool _markerIsFlora(MapMarkerData marker) {
    final text = '${marker.groupName} ${marker.title}'.toLowerCase();
    final normalized = _normalizeKey(text);
    return normalized.contains('plantae') ||
        normalized.contains('planta') ||
        normalized.contains('fungi') ||
        normalized.contains('hong') ||
        normalized.contains('hongo');
  }

  bool _markerIsFauna(MapMarkerData marker) {
    final text = '${marker.groupName} ${marker.title}'.toLowerCase();
    final normalized = _normalizeKey(text);
    
    final isAnimal = 
        normalized.contains('insect') ||
        normalized.contains('insecta') ||
        normalized.contains('coleoptera') ||
        normalized.contains('hymenoptera') ||
        normalized.contains('aves') ||
        normalized.contains('ave') ||
        normalized.contains('bird') ||
        normalized.contains('anfib') ||
        normalized.contains('amphib') ||
        normalized.contains('amphibia') ||
        normalized.contains('reptil') ||
        normalized.contains('reptilia') ||
        normalized.contains('lizard') ||
        normalized.contains('reptile') ||
        normalized.contains('fish') ||
        normalized.contains('pez') ||
        normalized.contains('pisces') ||
        normalized.contains('mammal') ||
        normalized.contains('mammalia') ||
        normalized.contains('mamif') ||
        normalized.contains('mamifer') ||
        normalized.contains('animal') ||
        normalized.contains('animalia');
    
    // Es fauna si es un animal específico Y NO es flora
    return isAnimal && !_markerIsFlora(marker);
  }

  IconData _taxonomyFocusIcon() {
    return _taxonomyFocus == 'flora' ? Icons.eco : Icons.pets;
  }

  List<MapMarkerData> _visibleMarkersForTaxonomy(
    List<MapMarkerData> markers,
    List<Species> species,
  ) {
    // Primero, filtrar por fauna/flora según el tab activo
    final filtered = markers.where((marker) {
      if (_taxonomyFocus == 'flora') {
        return _markerIsFlora(marker);
      } else {
        return _markerIsFauna(marker);
      }
    }).toList();

    // Si hay un grupo activo, filtrar también por ese grupo
    if (_activeTaxonomyGroup != null && _activeTaxonomyGroup!.isNotEmpty) {
      final active = _normalizeKey(_activeTaxonomyGroup!);
      final byGroup = filtered
          .where((m) => _normalizeKey(m.groupName ?? '') == active)
          .toList();
      if (byGroup.isNotEmpty) return byGroup;
    }

    return filtered;
  }

  void _showTaxonomyPanel(BuildContext context) {
    final mapProvider = context.read<MapProvider>();
    final allMarkers = mapProvider.snapshot?.markers ?? const <MapMarkerData>[];
    
    // Filtrar marcadores por fauna/flora según el tab activo
    final markers = allMarkers.where((marker) {
      if (_taxonomyFocus == 'flora') {
        return _markerIsFlora(marker);
      } else {
        return _markerIsFauna(marker);
      }
    }).toList();

    // Contadores por grupo y por fuente
    final Map<String, Map<String, int>> countsBySource = {};
    for (final m in markers) {
      final g = (m.groupName ?? '').trim();
      if (g.isEmpty) continue;
      final src = m.resolvedSourceType;
      countsBySource.putIfAbsent(g, () => {});
      countsBySource[g]![src] = (countsBySource[g]![src] ?? 0) + 1;
      countsBySource[g]!['total'] = (countsBySource[g]!['total'] ?? 0) + 1;
    }

    String sourceFilter = 'all'; // 'all' | 'inaturalist' | 'odk'

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Solo mostrar grupos que tengan al menos 1 observación según el filtro activo
            final groups = countsBySource.keys.where((g) {
              final counts = countsBySource[g] ?? {};
              if (sourceFilter == 'all') return (counts['total'] ?? 0) > 0;
              return (counts[sourceFilter] ?? 0) > 0;
            }).toList()
              ..sort((a, b) {
                final countA = sourceFilter == 'all'
                    ? (countsBySource[a]?['total'] ?? 0)
                    : (countsBySource[a]?[sourceFilter] ?? 0);
                final countB = sourceFilter == 'all'
                    ? (countsBySource[b]?['total'] ?? 0)
                    : (countsBySource[b]?[sourceFilter] ?? 0);
                final byCount = countB.compareTo(countA);
                if (byCount != 0) return byCount;
                return a.toLowerCase().compareTo(b.toLowerCase());
              });

            final displayedCount = sourceFilter == 'all'
              ? markers.length
              : markers
                  .where((marker) => marker.resolvedSourceType == sourceFilter)
                  .length;
            // Usar el mismo tamaño aumentado para Flora y Fauna
            final isLargeModal = _taxonomyFocus == 'fauna' || _taxonomyFocus == 'flora';

            return SafeArea(
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                constraints: isLargeModal ? BoxConstraints(maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7) : null,
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF171717) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: isLargeModal ? MainAxisSize.max : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _taxonomyFocus == 'flora' ? Icons.eco : Icons.pets,
                            color: _taxonomyFocus == 'flora' ? Colors.green : Colors.orangeAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _taxonomyFocus == 'fauna' || _taxonomyFocus == 'flora'
                                    ? 'Catálogo taxonómico'
                                    : 'Grupos taxonómicos',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _taxonomyFocus == 'fauna'
                                    ? 'Fauna'
                                    : _taxonomyFocus == 'flora'
                                        ? 'Flora'
                                        : 'Muestra solo los grupos reales que existen en la base de datos',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _isDarkMode ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLargeModal)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                            icon: Icon(Icons.close, size: 20, color: _isDarkMode ? Colors.white70 : Colors.black54),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.24),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            '$displayedCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF4F5F8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isDarkMode
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.035),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSourceFilterButton(
                              label: 'Todos',
                              isSelected: sourceFilter == 'all',
                              accentColor: Colors.blueAccent,
                              count: markers.length,
                              onTap: () => setModalState(() {
                                sourceFilter = 'all';
                                _activeTaxonomyGroup = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildSourceFilterButton(
                              label: 'ODK',
                              isSelected: sourceFilter == 'odk',
                              accentColor: Colors.orangeAccent,
                              count: countsBySource.values.fold<int>(
                                0,
                                (sum, counts) => sum + (counts['odk'] ?? 0),
                              ),
                              onTap: () => setModalState(() {
                                sourceFilter = 'odk';
                                _activeTaxonomyGroup = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildSourceFilterButton(
                              label: 'iNaturalist',
                              isSelected: sourceFilter == 'inaturalist',
                              accentColor: Colors.green,
                              count: countsBySource.values.fold<int>(
                                0,
                                (sum, counts) => sum + (counts['inaturalist'] ?? 0),
                              ),
                              onTap: () => setModalState(() {
                                sourceFilter = 'inaturalist';
                                _activeTaxonomyGroup = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No se encontraron grupos específicos',
                          style: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.black54),
                        ),
                      )
                    else if (isLargeModal)
                      // Vertical, scrollable list for fauna modal
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
                          physics: const BouncingScrollPhysics(),
                          itemCount: groups.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (c, i) {
                            final g = groups[i];
                            final counts = countsBySource[g] ?? {};
                            final total = counts['total'] ?? 0;
                            final visibleCount = sourceFilter == 'all' ? total : (counts[sourceFilter] ?? 0);
                            final normalized = _normalizeKey(g);
                            final selected = _normalizeKey(_activeTaxonomyGroup ?? '') == normalized;
                            final groupAccent = _taxonomyFocus == 'flora'
                                ? Colors.green
                                : Colors.orangeAccent;
                            final tileColor = selected
                                ? groupAccent.withValues(alpha: _isDarkMode ? 0.18 : 0.12)
                                : (_isDarkMode
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : const Color(0xFFF7F7FA));
                            final borderColor = selected
                                ? groupAccent.withValues(alpha: 0.42)
                                : (_isDarkMode
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05));
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () {
                                    setState(() {
                                      _activeTaxonomyGroup = selected ? null : g;
                                    });
                                    if (!selected) {
                                      // Abrir la lista del grupo encima del panel actual sin cerrarlo,
                                      // de modo que "Regresar" solo cierre esta ventana y revele
                                      // el panel de taxonomía en el mismo estado que antes.
                                      Future.microtask(() => _showGroupList(context, g, markers, sourceFilter: sourceFilter));
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: tileColor,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: borderColor),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: _isDarkMode ? 0.14 : 0.04,
                                          ),
                                          blurRadius: selected ? 18 : 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            gradient: selected
                                                ? LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      groupAccent.withValues(alpha: 0.26),
                                                      groupAccent.withValues(alpha: 0.14),
                                                    ],
                                                  )
                                                : null,
                                            color: selected
                                                ? null
                                                : groupAccent.withValues(alpha: _isDarkMode ? 0.14 : 0.10),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Center(
                                            child: _groupIconWidget(
                                              g,
                                              size: 18,
                                              color: groupAccent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          fit: FlexFit.loose,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                g,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.1,
                                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                selected ? 'Seleccionado' : 'Toca para ver observaciones',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  height: 1.1,
                                                  color: _isDarkMode ? Colors.white60 : Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? groupAccent.withValues(alpha: 0.95)
                                                : groupAccent.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '$visibleCount',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: selected ? Colors.white : groupAccent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          LucideIcons.chevronRight,
                                          size: 16,
                                          color: _isDarkMode ? Colors.white38 : Colors.black38,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: groups.map((g) {
                            final counts = countsBySource[g] ?? {};
                            final total = counts['total'] ?? 0;
                            final visibleCount = sourceFilter == 'all' ? total : (counts[sourceFilter] ?? 0);
                            final normalized = _normalizeKey(g);
                            final selected = _normalizeKey(_activeTaxonomyGroup ?? '') == normalized;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _groupIconWidget(g, size: 16, color: Colors.blueAccent),
                                    const SizedBox(width: 8),
                                    Text(g, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('$visibleCount', style: const TextStyle(fontSize: 11, color: Colors.blueAccent)),
                                    ),
                                  ],
                                ),
                                selected: selected,
                                onSelected: (sel) {
                                  setState(() {
                                    _activeTaxonomyGroup = sel ? g : null;
                                  });
                                  if (sel) {
                                    Future.microtask(() => _showGroupList(context, g, markers, sourceFilter: sourceFilter));
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showGroupList(BuildContext context, String group, List<MapMarkerData> markers, {String sourceFilter = 'all'}) {
    final normalized = _normalizeKey(group);
    // Filtrar por grupo Y por fuente activa
    final items = markers.where((m) {
      if (_normalizeKey(m.groupName ?? '') != normalized) return false;
      if (sourceFilter == 'all') return true;
      return m.resolvedSourceType == sourceFilter;
    }).toList();
    final groupAccent = _taxonomyFocus == 'flora' ? Colors.green : Colors.orangeAccent;
    final isAnimalGroup = normalized.contains('insect') || normalized.contains('insecta') || normalized.contains('coleoptera') || normalized.contains('hymenoptera') || normalized.contains('aves') || normalized.contains('ave') || normalized.contains('bird') || normalized.contains('anfib') || normalized.contains('amphib') || normalized.contains('amphibia') || normalized.contains('reptil') || normalized.contains('reptilia') || normalized.contains('lizard') || normalized.contains('reptile') || normalized.contains('fish') || normalized.contains('pez') || normalized.contains('pisces') || normalized.contains('mammal') || normalized.contains('mammalia') || normalized.contains('mamif') || normalized.contains('mamifer') || normalized.contains('animal') || normalized.contains('animalia');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(8),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.76),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF171717) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDarkMode ? 0.28 : 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                groupAccent.withValues(alpha: 0.28),
                                groupAccent.withValues(alpha: 0.14),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: _groupIconWidget(group, size: 22, color: groupAccent),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _taxonomyFocus == 'flora'
                                    ? 'Observaciones de flora dentro de este grupo'
                                    : 'Observaciones de fauna dentro de este grupo',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.15,
                                  color: _isDarkMode ? Colors.white60 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: groupAccent.withValues(alpha: _isDarkMode ? 0.18 : 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${items.length} registros',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: groupAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                        // Mostrar 'Flora' cuando el foco de taxonomía esté en flora,
                                        // 'Fauna' cuando sea un grupo animal en fauna, de lo contrario 'Grupo taxonómico'.
                                        _taxonomyFocus == 'flora'
                                          ? 'Flora'
                                          : (isAnimalGroup && _taxonomyFocus == 'fauna' ? 'Fauna' : 'Grupo taxonómico'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(
                            // Show a back arrow for the same-kind groups (fauna groups when in fauna,
                            // and flora groups — including plants and fungi — when in flora). Otherwise show close.
                            ((_taxonomyFocus == 'fauna' && isAnimalGroup) ||
                                    (_taxonomyFocus == 'flora' && (normalized.contains('planta') || normalized.contains('plant') || normalized.contains('plantae') || normalized.contains('fungi') || normalized.contains('hongo') || normalized.contains('hong'))))
                                ? Icons.arrow_back_rounded
                                : Icons.close_rounded,
                            size: 20,
                            color: _isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _isDarkMode ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.06),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: groupAccent.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      _groupIconWidget(group, size: 26, color: groupAccent) is Icon
                                          ? _iconForGroup(group)
                                          : Icons.search,
                                      color: groupAccent,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No hay observaciones para $group',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Prueba con otro grupo o revisa más tarde si aún no hay registros disponibles.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.25,
                                      color: _isDarkMode ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (c, i) {
                              final m = items[i];
                              final sourceType = m.resolvedSourceType;
                              final sourceColor = sourceType == 'odk' ? Colors.orangeAccent : Colors.green;
                              // removed author display for a cleaner, premium card layout
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () {
                                    _mapController.move(m.position, 14.5);
                                    Future.delayed(const Duration(milliseconds: 220), () {
                                      if (!mounted) return;
                                      _showObservationContextModal(context, m);
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : const Color(0xFFF7F8FB),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: _isDarkMode
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : Colors.black.withValues(alpha: 0.04),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: _isDarkMode ? 0.14 : 0.04),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: groupAccent.withValues(alpha: _isDarkMode ? 0.16 : 0.10),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Center(
                                            child: _markerIconWidget(m, size: 22, color: groupAccent),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      m.title,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.w800,
                                                        letterSpacing: -0.1,
                                                        color: _isDarkMode ? Colors.white : Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Wrap(
                                                      spacing: 8,
                                                      runSpacing: 6,
                                                      alignment: WrapAlignment.start,
                                                      crossAxisAlignment: WrapCrossAlignment.center,
                                                      children: [
                                                        // Source chip
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: sourceColor.withValues(alpha: _isDarkMode ? 0.16 : 0.12),
                                                            borderRadius: BorderRadius.circular(999),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.black.withValues(alpha: _isDarkMode ? 0.06 : 0.02),
                                                                blurRadius: 6,
                                                                offset: const Offset(0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Text(
                                                            sourceType == 'odk' ? 'ODK' : 'iNaturalist',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w800,
                                                              color: sourceColor,
                                                            ),
                                                          ),
                                                        ),
                                                        // Date chip (if available)
                                                        if (m.observedAt != null)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                            decoration: BoxDecoration(
                                                              color: _isDarkMode
                                                                  ? Colors.white.withValues(alpha: 0.04)
                                                                  : Colors.black.withValues(alpha: 0.04),
                                                              borderRadius: BorderRadius.circular(999),
                                                            ),
                                                            child: Text(
                                                              _formatObservationDate(m.observedAt),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w700,
                                                                color: _isDarkMode ? Colors.white70 : Colors.black54,
                                                              ),
                                                            ),
                                                          ),
                                                        // Coordinates chip
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                          decoration: BoxDecoration(
                                                            color: _isDarkMode
                                                                ? Colors.white.withValues(alpha: 0.06)
                                                                : Colors.black.withValues(alpha: 0.06),
                                                            borderRadius: BorderRadius.circular(999),
                                                            border: Border.all(
                                                              color: _isDarkMode ? Colors.white10 : Colors.black12,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(
                                                                'Coordenadas  ',
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: _isDarkMode ? Colors.white54 : Colors.black45,
                                                                ),
                                                              ),
                                                              Flexible(
                                                                child: Text(
                                                                  '${m.position.latitude.toStringAsFixed(4)}, ${m.position.longitude.toStringAsFixed(4)}',
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w700,
                                                                    color: _isDarkMode ? Colors.white : Colors.black87,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Small separate open icon to the right of the chips
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(8),
                                                      onTap: () {
                                                        // Abrimos el detalle encima sin cerrar la lista
                                                        _mapController.move(m.position, 14.5);
                                                        Future.delayed(const Duration(milliseconds: 220), () {
                                                          if (!mounted) return;
                                                          _showObservationContextModal(context, m);
                                                        });
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(6),
                                                        child: Icon(
                                                          Icons.open_in_new,
                                                          size: 18,
                                                          color: _isDarkMode ? Colors.white38 : Colors.black38,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showObservationContextModal(BuildContext context, MapMarkerData marker) {
    final sourceType = marker.resolvedSourceType;
    final sourceColor = sourceType == 'odk' ? Colors.orangeAccent : Colors.green;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF171717) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDarkMode ? 0.28 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: sourceColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _markerIconWidget(marker, size: 22, color: sourceColor) is Icon
                            ? _iconForMarker(marker)
                            : Icons.place,
                        color: sourceColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marker.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: _isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Especie ubicada en el mapa con datos reales',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.15,
                              color: _isDarkMode ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildContextInfoChip(
                        label: 'Especie',
                        value: marker.title,
                        accentColor: sourceColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildContextInfoChip(
                        label: 'Autor',
                        value: (marker.subtitle?.trim().isNotEmpty == true)
                            ? marker.subtitle!.trim()
                            : 'No disponible',
                        accentColor: _isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                    Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<String?>(
                        future: _resolveObservationPlaceName(marker.position),
                        builder: (ctx, snap) {
                          final place = snap.data?.trim();
                          final value = place != null && place.isNotEmpty
                              ? place
                              : _formatObservationLocation(marker.position);
                          return _buildContextInfoChip(
                            label: 'Ubicación',
                            value: value,
                            accentColor: _isDarkMode ? Colors.white70 : Colors.black54,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Coordinates removed to avoid overflow; location shows short name
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sourceColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContextInfoChip({
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: _isDarkMode ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }


  IconData _iconForMarker(MapMarkerData m) {
    final group = (m.groupName ?? '').trim();
    if (group.isNotEmpty) {
      return _iconForGroup(group);
    }

    final keys = '${m.title} ${m.subtitle ?? ''}'.toLowerCase();
    final n = _normalizeKey(keys);
    if (n.contains('insect') || n.contains('insecta') || n.contains('coleoptera') || n.contains('hymenoptera')) {
      return Icons.bug_report;
    }
    if (n.contains('aves') || n.contains('ave') || n.contains('bird')) {
      return Icons.flutter_dash;

    }
    if (n.contains('anfib') || n.contains('amphib') || n.contains('amphibia')) {
      return Icons.water_drop;
    }
    if (n.contains('reptil') || n.contains('reptilia') || n.contains('lizard') || n.contains('reptile')) {
      return Icons.pets;
    }
    if (n.contains('fish') || n.contains('pez') || n.contains('pisces')) {
      return Icons.water;
    }
    if (n.contains('mammal') || n.contains('mammalia') || n.contains('mamifer') || n.contains('mamífer')) {
      return Icons.pets;
    }
    // flora
    if (n.contains('fungi') || n.contains('hongo') || n.contains('hong')) {
      return Icons.spa;
    }
    if (n.contains('flora') || n.contains('plant') || n.contains('planta') || n.contains('plantae')) {
      return Icons.eco;
    }

    return _taxonomyFocus == 'flora' ? Icons.eco : Icons.pets;
  }

  Widget _markerIconWidget(MapMarkerData m, {double size = 22, Color color = Colors.blueAccent}) {
    final group = (m.groupName ?? '').trim();
    final normalizedGroup = _normalizeKey(group);
    final emoji = _taxonomyEmojiForKey(normalizedGroup);
    if (emoji != null) {
      return Text(emoji, style: TextStyle(fontSize: size, height: 1, color: color));
    }
    if (normalizedGroup.contains('fungi') || normalizedGroup.contains('hongo') || normalizedGroup.contains('hong')) {
      return Text('🍄', style: TextStyle(fontSize: size, height: 1, color: color));
    }
    return Icon(_iconForMarker(m), size: size, color: color);
  }

  Widget _buildSourceFilterButton({
    required String label,
    required bool isSelected,
    required Color accentColor,
    required int count,
    required VoidCallback onTap,
  }) {
    final isAll = label.toLowerCase() == 'todos';
    final backgroundColor = isSelected
        ? (isAll
              ? accentColor.withValues(alpha: _isDarkMode ? 0.30 : 0.14)
              : accentColor.withValues(alpha: _isDarkMode ? 0.32 : 0.16))
        : Colors.transparent;
    final labelColor = isSelected
        ? (isAll ? Colors.white : Colors.white)
      : (_isDarkMode ? Colors.white.withValues(alpha: 0.72) : Colors.black54);
    final dotColor = isSelected
        ? Colors.white.withValues(alpha: 0.95)
        : accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubicEmphasized,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: isAll ? 0.18 : 0.28)
                  : (_isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: _isDarkMode ? 0.16 : 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isDarkMode ? 0.08 : 0.025),
                      blurRadius: 9,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.12,
                          color: labelColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubicEmphasized,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.14)
                      : (_isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : (_isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatObservationDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final monthIndex = date.month.clamp(1, 12) - 1;
    final month = months[monthIndex];
    return '${date.day} $month ${date.year}';
  }

  String _formatObservationLocation(LatLng position) {
    final lat = position.latitude.toStringAsFixed(2);
    final lng = position.longitude.toStringAsFixed(2);
    return '$lat, $lng';
  }

  String _placeCacheKey(LatLng position) {
    return '${position.latitude.toStringAsFixed(5)},${position.longitude.toStringAsFixed(5)}';
  }

  Future<String?> _resolveObservationPlaceName(LatLng position) async {
    final cacheKey = _placeCacheKey(position);
    final cachedFuture = _placeNameFutureCache[cacheKey];
    if (cachedFuture != null) {
      return cachedFuture;
    }

    final future = () async {
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
          'format': 'jsonv2',
          'lat': position.latitude.toString(),
          'lon': position.longitude.toString(),
          'zoom': '14',
          'addressdetails': '1',
        });

        final response = await http.get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'soy_conservacion/1.0 (Flutter)',
          },
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return null;
        }

        final address = decoded['address'];
        final addressMap = address is Map<String, dynamic> ? address : null;
        final displayName = decoded['display_name']?.toString().trim();

        String? pickAddressValue(List<String> keys) {
          for (final key in keys) {
            final value = addressMap?[key]?.toString().trim();
            if (value != null && value.isNotEmpty) {
              return value;
            }
          }
          return null;
        }

        final locality = pickAddressValue([
          'neighbourhood',
          'suburb',
          'quarter',
          'city_district',
          'village',
          'town',
          'city',
          'municipality',
          'county',
        ]);
        if (locality != null) {
          return locality;
        }

        if (displayName != null && displayName.isNotEmpty) {
          final shortParts = displayName.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
          if (shortParts.isNotEmpty) return shortParts.first;
        }

        return null;
      } catch (_) {
        return null;
      }
    }();

    _placeNameFutureCache[cacheKey] = future;
    return future;
  }

  IconData _iconForGroup(String group) {
    final n = _normalizeKey(group);
    if (n.contains('insect') || n.contains('insecta')) return Icons.bug_report;
    if (n.contains('aves') || n.contains('ave') || n.contains('bird')) return Icons.flutter_dash;
    if (n.contains('anfib') || n.contains('amphib') || n.contains('amphibia')) return Icons.water_drop;
    if (n.contains('reptil') || n.contains('reptilia') || n.contains('reptile') || n.contains('lizard')) return Icons.pets;
    if (n.contains('fish') || n.contains('pez') || n.contains('pisces')) return Icons.water;
    if (n.contains('mammal') || n.contains('mammalia') || n.contains('mamif') || n.contains('mamífer')) return Icons.pets;
    if (n.contains('animal') || n.contains('animalia')) return Icons.pets;
    if (n.contains('fungi') || n.contains('hongo') || n.contains('hong')) return Icons.spa;
    if (n.contains('flora') || n.contains('plant') || n.contains('planta') || n.contains('plantae')) return Icons.eco;
    return _taxonomyFocus == 'flora' ? Icons.eco : Icons.pets;
  }

  String? _taxonomyEmojiForKey(String normalizedKey) {
    if (normalizedKey.contains('arbol') || normalizedKey.contains('tree') || normalizedKey.contains('forest') || normalizedKey.contains('bosque')) {
      return '🌳';
    }
    if (normalizedKey.contains('flor') || normalizedKey.contains('flower')) {
      return '🌸';
    }
    if (normalizedKey.contains('cactus')) {
      return '🌵';
    }
    if (normalizedKey.contains('helecho') || normalizedKey.contains('fern')) {
      return '🌿';
    }
    if (normalizedKey.contains('hierba') || normalizedKey.contains('grass') || normalizedKey.contains('grama') || normalizedKey.contains('herb')) {
      return '🌱';
    }
    if (normalizedKey.contains('planta') || normalizedKey.contains('plant') || normalizedKey.contains('flora') || normalizedKey.contains('plantae')) {
      return '🪴';
    }
    if (normalizedKey.contains('insect') || normalizedKey.contains('insecta') || normalizedKey.contains('coleoptera') || normalizedKey.contains('hymenoptera')) {
      return '🐞';
    }
    if (normalizedKey.contains('aves') || normalizedKey.contains('ave') || normalizedKey.contains('bird')) {
      return '🐦';
    }
    if (normalizedKey.contains('anfib') || normalizedKey.contains('amphib') || normalizedKey.contains('amphibia')) {
      return '🐸';
    }
    if (normalizedKey.contains('reptil') || normalizedKey.contains('reptilia') || normalizedKey.contains('lizard') || normalizedKey.contains('reptile')) {
      return '🦎';
    }
    if (normalizedKey.contains('fish') || normalizedKey.contains('pez') || normalizedKey.contains('pisces')) {
      return '🐟';
    }
    if (normalizedKey.contains('mammal') || normalizedKey.contains('mammalia') || normalizedKey.contains('mamifer') || normalizedKey.contains('mamífer')) {
      return '🐾';
    }
    if (normalizedKey.contains('animal') || normalizedKey.contains('animalia')) {
      return '🐾';
    }
    if (normalizedKey.contains('fungi') || normalizedKey.contains('hongo') || normalizedKey.contains('hong')) {
      return '🍄';
    }
    return null;
  }

  Widget _groupIconWidget(String group, {double size = 16, Color color = Colors.blueAccent}) {
    final n = _normalizeKey(group);
    final emoji = _taxonomyEmojiForKey(n);
    if (emoji != null) {
      return Text(emoji, style: TextStyle(fontSize: size + 2, height: 1, color: color));
    }
    return Icon(_iconForGroup(group), size: size, color: color);
  }

  String _normalizeKey(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n');
  }

  /// Determina si una especie es FLORA (plantas y hongos solamente)
  /// Puede usarse para filtrar listas de especies
  bool _isFloraSpecies(Species species) {
    final text =
        '${species.kingdom ?? ''} ${species.category ?? ''} ${species.scientificName ?? ''} ${species.name}'
            .toLowerCase();
    final normalized = _normalizeKey(text);
    
    // Flora: plantas y hongos
    return normalized.contains('plantae') ||
        normalized.contains('planta') ||
        normalized.contains('fungi') ||
        normalized.contains('hong') ||
        normalized.contains('hongo');
  }

  /// Determina si una especie es FAUNA (animales solamente)
  /// Puede usarse para filtrar listas de especies
  // ignore: unused_element
  bool _isFaunaSpecies(Species species) {
    final text =
        '${species.kingdom ?? ''} ${species.category ?? ''} ${species.scientificName ?? ''} ${species.name}'
            .toLowerCase();
    final normalized = _normalizeKey(text);
    
    // Fauna: solo animales específicos (excluir plantas y hongos)
    final isAnimal = 
        normalized.contains('insect') ||
        normalized.contains('insecta') ||
        normalized.contains('coleoptera') ||
        normalized.contains('hymenoptera') ||
        normalized.contains('aves') ||
        normalized.contains('ave') ||
        normalized.contains('bird') ||
        normalized.contains('anfib') ||
        normalized.contains('amphib') ||
        normalized.contains('amphibia') ||
        normalized.contains('reptil') ||
        normalized.contains('reptilia') ||
        normalized.contains('lizard') ||
        normalized.contains('reptile') ||
        normalized.contains('fish') ||
        normalized.contains('pez') ||
        normalized.contains('pisces') ||
        normalized.contains('mammal') ||
        normalized.contains('mammalia') ||
        normalized.contains('mamif') ||
        normalized.contains('mamifer') ||
        normalized.contains('animal') ||
        normalized.contains('animalia');
    
    // Es fauna si es un animal específico Y NO es flora
    return isAnimal && !_isFloraSpecies(species);
  }

  Widget _buildLayerOption({
    required String label,
    required String style,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _mapStyle == style;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        scale: isSelected ? 1.03 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          height: 82,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blueAccent.withValues(alpha: 0.10)
                : (_isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF0F2F5)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.blueAccent.withValues(alpha: 0.85)
                  : Colors.transparent,
              width: 1.25,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blueAccent.withValues(alpha: 0.14)
                            : (_isDarkMode
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: 19,
                        color: isSelected
                            ? Colors.blueAccent
                            : (_isDarkMode ? Colors.white54 : Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.blueAccent
                            : (_isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  opacity: isSelected ? 1.0 : 0.0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutBack,
                    scale: isSelected ? 1.0 : 0.7,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _isDarkMode
                              ? const Color(0xFF171717)
                              : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    // Diseño compacto y premium estilo Apple
    final defaultTextColor = textColor ?? (isDark ? Colors.white : const Color(0xFF1C1C1E));
    final defaultIconColor = iconColor ?? (isDark ? Colors.white : const Color(0xFF1C1C1E));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF4A90E2).withValues(alpha: 0.08),
          highlightColor: const Color(0xFF4A90E2).withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono compacto
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: defaultIconColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Título
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: defaultTextColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                // Widget trailing
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                    child: trailing,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

}
