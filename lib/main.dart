import 'dart:ui' as ui;
import 'package:soy_conservacion/config/brand_config.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Se activará tras el primer build
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:soy_conservacion/screens/about_screen.dart';
import 'package:soy_conservacion/screens/privacy_screen.dart';
import 'package:soy_conservacion/screens/help_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_cache_service.dart';
import 'core/storage/secure_token_storage.dart';
import 'models/map_snapshot.dart';
import 'models/species.dart';
import 'providers/backend_status_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/map_provider.dart';
import 'providers/observations_provider.dart';
import 'providers/species_provider.dart';
import 'providers/theme_provider.dart';
import 'repositories/analytics_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/map_repository.dart';
import 'repositories/observations_repository.dart';
import 'repositories/species_repository.dart';
import 'repositories/users_repository.dart';
import 'screens/analysis_screen.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/map_service.dart';
import 'services/observations_service.dart';
import 'services/species_service.dart';
import 'services/users_service.dart';
import 'theme/app_theme.dart';
import 'utils/marker_filters.dart';
import 'widgets/date_filter_panel.dart';
import 'widgets/ux/animated_icon_button.dart';
import 'widgets/ux/bouncing_wrapper.dart';
import 'widgets/ux/custom_loader.dart';
import 'widgets/ux/paw_print_icon.dart';
import 'widgets/ux/calendars_icon.dart';
import 'widgets/ux/analysis_icon.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background message received: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Escuchar notificaciones cuando la app está abierta en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');
    final context = navigatorKey.currentState?.overlay?.context;
    if (context != null && message.notification != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(message.notification!.title ?? 'Alerta'),
          content: Text(message.notification!.body ?? ''),
          backgroundColor: const Color(0xFF4A90E2),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  });
  
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
  final preferences = await SharedPreferences.getInstance();
  runApp(MiApp(preferences: preferences));
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
            const CustomLoader(size: 40.0),
          ],
        ),
      ),
    );
  }
}

// Llave global para poder mostrar diálogos desde cualquier parte
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MiApp extends StatelessWidget {
  const MiApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final appConfig = AppConfig.fromEnvironment();

    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: appConfig),
        Provider<SharedPreferences>.value(value: preferences),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(context.read<SharedPreferences>()),
        ),
        ChangeNotifierProvider<FilterProvider>(
          create: (context) => FilterProvider(context.read<SharedPreferences>()),
        ),
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
        Provider<AnalyticsService>(
          create: (context) => AnalyticsService(apiClient: context.read<ApiClient>()),
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
        Provider<AnalyticsRepository>(
          create: (context) => AnalyticsRepository(
            service: context.read<AnalyticsService>(),
            cacheService: context.read<LocalCacheService>(),
            observationsRepository: context.read<ObservationsRepository>(),
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
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            locale: const Locale('es'),
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const SplashScreen(),
          );
        },
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
  String _currentLanguage = 'es';
  String _mapStyle = 'outdoors-v12';
  String _taxonomyFocus = 'fauna';
  int _selectedBottomIndex = 0;
  String? _activeTaxonomyGroup;
  final MapController _mapController = MapController();
  final Map<String, Future<String?>> _placeNameFutureCache = {};
  late final AnimationController _menuController;
  bool _isInitializingMap = true;
  bool _notificationsEnabled = false; // By default false, user must opt-in
  bool _isSearchActive = false;
  bool _isLayersPopoverOpen = false;
  bool _isLegendExpanded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    if (value) {
      final settings = await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.subscribeToTopic('biodiversity_updates');
      
      // Obtener el token del dispositivo para enviar pruebas directas sin esperar a la propagación del Topic
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint("FCM Token: $token");
      debugPrint("Status de Permisos: ${settings.authorizationStatus}");
      
      if (mounted) {
        // Se removió el copiado al portapapeles de prueba.
        // Se removió el AlertDialog de diagnóstico.
      }
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic('biodiversity_updates');
    }
  }

  Map<String, Map<String, String>> get _texts => {
    'es': {
      'appTitle': 'Visor de biodiversidad',
      'menu': 'Menú',
      'account': 'Mi Cuenta',
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'visualMode': 'Modo Visual',
      'help': 'Centro de Ayuda',
      'about': 'Acerca de Soy Conservación',
      'privacy': 'Privacidad y Condiciones',
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
      'version': 'Versión',
      'information': 'Información',
      'outdoors': 'Relieve',
      'taxonomicCatalog': 'Catálogo taxonómico',
      'taxonomicGroups': 'Grupos taxonómicos',
      'observations': 'observaciones',
      'showOnlyRealGroups': 'Muestra solo los grupos reales que existen en la base de datos',
      'all': 'Todos',
      'noSpecificGroups': 'No se encontraron grupos específicos',
    },
    'en': {
      'appTitle': 'Biodiversity Viewer',
      'menu': 'Menu',
      'account': 'My Account',
      'language': 'Language',
      'notifications': 'Notifications',
      'visualMode': 'Visual Mode',
      'help': 'Help Center',
      'about': 'About Soy Conservación',
      'privacy': 'Privacy & Terms',
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
      'information': 'Information',
      'outdoors': 'Outdoors',
      'taxonomicCatalog': 'Taxonomic Catalog',
      'taxonomicGroups': 'Taxonomic Groups',
      'observations': 'observations',
      'showOnlyRealGroups': 'Shows only real groups that exist in the database',
      'all': 'All',
      'noSpecificGroups': 'No specific groups found',
    },
  };

  String _t(String key) {
    final result = _texts[_currentLanguage]?[key] ?? _texts['es']?[key] ?? key;
    return result;
  }

  bool get _isDarkMode => context.watch<ThemeProvider>().isDarkMode;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final filterProvider = context.read<FilterProvider>();

      context.read<BackendStatusProvider>().checkBackend();
      context.read<SpeciesProvider>().loadSpecies();
      context.read<ObservationsProvider>().loadObservations();

      try {
        final bounds = await context.read<AnalyticsRepository>().loadDateBounds();
        filterProvider.setDateBounds(
          minDate: bounds.minDate,
          maxDate: bounds.maxDate,
        );
      } catch (_) {
        filterProvider.setDateBounds(maxDate: DateTime.now());
      }

      await context.read<MapProvider>().loadSnapshot(
            dateRange: filterProvider.effectiveDateRange,
          );

      if (mounted) {
        setState(() {
          _isInitializingMap = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _menuController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterProvider = context.watch<FilterProvider>();

    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
        icon: const Padding(padding: EdgeInsets.only(bottom: 0), child: PawPrintSvgIcon(size: 30)),
        activeIcon: const Padding(padding: EdgeInsets.only(bottom: 0), child: PawPrintSvgIcon(size: 30, isFilled: true)),
        label: _t('fauna'),
      ),
      BottomNavigationBarItem(
        icon: const Padding(padding: EdgeInsets.only(bottom: 0), child: Icon(Icons.eco_outlined, size: 32)),
        activeIcon: const Padding(padding: EdgeInsets.only(bottom: 0), child: Icon(Icons.eco, size: 32)),
        label: _t('flora'),
      ),
      BottomNavigationBarItem(
        icon: const Padding(padding: EdgeInsets.only(bottom: 0), child: CalendarsSvgIcon(size: 30)),
        activeIcon: const Padding(padding: EdgeInsets.only(bottom: 0), child: CalendarsSvgIcon(size: 30, isFilled: true)),
        label: _t('date'),
      ),
      BottomNavigationBarItem(
        icon: const Padding(padding: EdgeInsets.only(bottom: 0), child: AnalysisSvgIcon(size: 30)),
        activeIcon: const Padding(padding: EdgeInsets.only(bottom: 0), child: AnalysisSvgIcon(size: 30, isFilled: true)),
        label: _t('analysis'),
      ),
    ];

    return Stack(
      children: [
        IndexedStack(
            index: _selectedBottomIndex == 3 ? 1 : 0,
            children: [
          Scaffold(
            resizeToAvoidBottomInset: false, // Evitar que el teclado aplaste el mapa
            extendBodyBehindAppBar: true,
            drawerScrimColor: Colors.black.withValues(alpha: 0.15),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                offset: _isSearchActive ? const Offset(0, -1.5) : Offset.zero,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        color: _isDarkMode
                            ? const Color(0xFF1C1C1E).withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                  title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/images/soy_conservacion_logo.png',
                height: 36, // Increased logo size
              ),
            ),
            const SizedBox(width: 10), // Adjusted spacing to move title slightly left
            Text(
              _t('appTitle'),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: _isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (scaffoldContext) => AnimatedBuilder(
              animation: _menuController,
              builder: (animContext, child) {
                final animation = CurvedAnimation(
                  parent: _menuController,
                  curve: Curves.fastOutSlowIn,
                );
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isDarkMode
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    child: Transform.rotate(
                      angle: animation.value * (3.14159 / 2),
                      child: AnimatedIconButton(
                        icon: _menuController.value < 0.5
                            ? LucideIcons.menu
                            : LucideIcons.x,
                        color: _isDarkMode ? Colors.white : Colors.black,
                        onPressed: () {
                          if (!scaffoldContext.mounted) return;
                          Future.delayed(const Duration(milliseconds: 80), () {
                            if (!scaffoldContext.mounted) return;
                            if (_menuController.status == AnimationStatus.dismissed) {
                              _menuController.forward();
                              Scaffold.of(scaffoldContext).openEndDrawer();
                            } else {
                              Scaffold.of(scaffoldContext).closeEndDrawer();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8), // Añade espacio a la derecha, moviendo el icono hacia la izquierda
        ],
      ),
    ),
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
                  top: MediaQuery.of(context).padding.top + 24,
                  bottom: MediaQuery.of(context).padding.bottom + 130, // Mayor margen inferior para hacerlo más compacto
                  right: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isDarkMode ? 0.6 : 0.15),
                      blurRadius: 50,
                      spreadRadius: -2,
                      offset: const Offset(-8, 0),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Efecto Liquid Glass (Desenfoque muy alto)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                          child: const SizedBox(),
                        ),
                      ),
                    ),
                    // Capa de color base con gradiente Liquid Glass (Sin reflejo molesto)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isDarkMode
                                ? [
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.black.withValues(alpha: 0.5),
                                    Colors.black.withValues(alpha: 0.65),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.55),
                                    Colors.white.withValues(alpha: 0.45),
                                    Colors.white.withValues(alpha: 0.6),
                                  ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                          border: Border.all(
                            color: _isDarkMode
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
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
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _isDarkMode
                                              ? Colors.white.withValues(alpha: 0.15)
                                              : Colors.black.withValues(alpha: 0.06),
                                        ),
                                        child: AnimatedIconButton(
                                          padding: EdgeInsets.zero,
                                          icon: LucideIcons.x,
                                          size: 22,
                                          backgroundColor: Colors.transparent,
                                          color: _isDarkMode
                                              ? Colors.white.withValues(alpha: 0.9)
                                              : Colors.black.withValues(alpha: 0.75),
                                          onPressed: () {
                                            if (!menuContext.mounted) return;
                                            Future.delayed(const Duration(milliseconds: 80), () {
                                              if (!menuContext.mounted) return;
                                              Scaffold.of(menuContext).closeEndDrawer();
                                            });
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

                                // Items estilo iOS agrupados y distribuidos
                                Expanded(
                                  child: CustomScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    slivers: [
                                      SliverFillRemaining(
                                        hasScrollBody: false,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Grupo 1: Preferencias Principales
                                              _buildMenuGroup(
                                                isDark: _isDarkMode,
                                                children: [
                                                  _buildMenuItem(
                                                    icon: LucideIcons.languages,
                                                    title: _t('language'),
                                                    isDark: _isDarkMode,
                                                    trailing: Text(
                                                      _currentLanguage == 'es' ? 'ES' : 'EN',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                        color: _isDarkMode ? Colors.white54 : Colors.black54,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      HapticFeedback.selectionClick();
                                                      setState(() {
                                                        _currentLanguage = (_currentLanguage == 'es') ? 'en' : 'es';
                                                      });
                                                    },
                                                  ),
                                                  _buildMenuItem(
                                                    icon: _notificationsEnabled ? LucideIcons.bell : LucideIcons.bellOff,
                                                    title: _t('notifications'),
                                                    isDark: _isDarkMode,
                                                    trailing: Transform.scale(
                                                      scale: 0.85,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(16),
                                                          border: Border.all(
                                                            color: _isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                        child: CupertinoSwitch(
                                                          value: _notificationsEnabled,
                                                          activeColor: const Color(0xFF34C759),
                                                          onChanged: (val) {
                                                            HapticFeedback.lightImpact();
                                                            _toggleNotifications(val);
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  _buildMenuItem(
                                                    icon: _isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                                                    title: _t('visualMode'),
                                                    isDark: _isDarkMode,
                                                    trailing: Transform.scale(
                                                      scale: 0.85,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(16),
                                                          border: Border.all(
                                                            color: _isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                        child: CupertinoSwitch(
                                                          value: _isDarkMode,
                                                          activeColor: const Color(0xFF34C759),
                                                          onChanged: (value) {
                                                            HapticFeedback.lightImpact();
                                                            context.read<ThemeProvider>().setDarkMode(value);
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Grupo 2: Soporte e Información
                                              _buildMenuGroup(
                                                isDark: _isDarkMode,
                                                title: _t('information'),
                                                children: [
                                                  _buildMenuItem(
                                                    icon: LucideIcons.info,
                                                    title: _t('about'),
                                                    isDark: _isDarkMode,
                                                    showChevron: true,
                                                    onTap: () {
                                                      HapticFeedback.selectionClick();
                                                      Navigator.of(context).push(
                                                        CupertinoPageRoute(builder: (_) => AboutScreen(language: _currentLanguage)),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _buildMenuItem(
                                                    icon: LucideIcons.shieldCheck,
                                                    title: _t('privacy'),
                                                    isDark: _isDarkMode,
                                                    showChevron: true,
                                                    onTap: () {
                                                      HapticFeedback.selectionClick();
                                                      Navigator.of(context).push(
                                                        CupertinoPageRoute(builder: (_) => PrivacyScreen(language: _currentLanguage)),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _buildMenuItem(
                                                    icon: LucideIcons.helpCircle,
                                                    title: _t('help'),
                                                    isDark: _isDarkMode,
                                                    showChevron: true,
                                                    onTap: () {
                                                      HapticFeedback.selectionClick();
                                                      Navigator.of(context).push(
                                                        CupertinoPageRoute(builder: (_) => HelpScreen(language: _currentLanguage)),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
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
      body: Consumer3<SpeciesProvider, MapProvider, FilterProvider>(
        builder: (context, speciesProvider, mapProvider, filterProvider, child) {
          final snapshot = mapProvider.snapshot;
          final markers = snapshot?.markers ?? const <MapMarkerData>[];
          final mapCenter = snapshot?.center ?? const LatLng(4.5709, -74.2973);
          final mapZoom = snapshot?.zoom ?? 4.0;
          final isCompactLayout = MediaQuery.of(context).size.width < 760;
          final bottomInset = MediaQuery.of(context).padding.bottom;
          final filteredMarkers = applyMapFilters(markers, filterProvider);
          final visibleMarkers = _visibleMarkersForTaxonomy(
            filteredMarkers,
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
                      const LatLng(-68.0, -110.0), // Aumentamos un poquito para asegurar visibilidad total sin pasarnos
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
                            width: 36, // Restauramos un poco el ancho
                            height: 44, // Reducimos significativamente la altura para que la cola sea más corta
                            alignment: Alignment.bottomCenter,
                            child: _buildMapMarker(context, marker),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              if (mapProvider.isLoading || _isInitializingMap)
                Positioned.fill(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _isDarkMode 
                                ? Colors.black.withValues(alpha: 0.55)
                                : Colors.white.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isDarkMode 
                                  ? Colors.white.withValues(alpha: 0.15) 
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 0.5,
                            ),
                          ),
                          child: CupertinoActivityIndicator(
                            radius: 12,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 4,
                child: _buildSourceLegend(),
              ),
              Positioned(
                left: 16,
                bottom: bottomInset + (isCompactLayout ? 40 : 52) + 80,
                child: BouncingWrapper(
                  onTap: () {
                    setState(() {
                      _isLayersPopoverOpen = !_isLayersPopoverOpen;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.08),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isLayersPopoverOpen
                                ? (_isDarkMode 
                                    ? const Color(0xFF1C1C1E).withValues(alpha: 0.8) 
                                    : Colors.grey.shade300.withValues(alpha: 0.85))
                                : (_isDarkMode 
                                    ? const Color(0xFF2C2C2E).withValues(alpha: 0.7) 
                                    : Colors.white.withValues(alpha: 0.75)),
                            border: Border.all(
                              color: _isDarkMode ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.layers, color: _isLayersPopoverOpen ? Colors.grey : (_isDarkMode ? Colors.white : Colors.black87), size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Overlay invisible para cerrar el popover al tocar fuera
              if (_isLayersPopoverOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLayersPopoverOpen = false;
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              // Popover de Capas de Mapa (Estilo iOS Vertical)
              Positioned(
                left: 16,
                bottom: bottomInset + (isCompactLayout ? 40 : 52) + 80 + 70, // 70 = altura botón + separación
                child: IgnorePointer(
                  ignoring: !_isLayersPopoverOpen,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    opacity: _isLayersPopoverOpen ? 1.0 : 0.0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      scale: _isLayersPopoverOpen ? 1.0 : 0.6,
                      alignment: Alignment.bottomLeft,
                      child: _buildVerticalLayersPopover(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ), // Close Map Scaffold
    AnalysisScreen(language: _currentLanguage), // Child 1 of IndexedStack
  ],
), // Close IndexedStack
          // Overlay de atenuación del mapa
          if (_isSearchActive)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isSearchActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearchActive = false;
                      _searchFocusNode.unfocus();
                    });
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          // Sugerencias de Búsqueda
          if (_isSearchActive && _searchQuery.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 76,
              child: _buildSearchSuggestions(),
            ),
          // Buscador Superior
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            top: _isSearchActive ? MediaQuery.of(context).padding.top + 16 : -100,
            left: 16,
            right: 16,
            child: _buildTopSearchBar(),
          ),
          // Barra de Navegación Flotante
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _isSearchActive 
                ? -100 // Ocultar abajo
                : (MediaQuery.of(context).padding.bottom > 0 
                    ? MediaQuery.of(context).padding.bottom + 4
                    : 12),
            child: _buildBottomNavBar(navItems),
          ),
        ],
      );
  }

  Widget _buildBottomNavBar(List<BottomNavigationBarItem> navItems) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Main Nav Pill / Search Input
            Flexible(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.1),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: _isDarkMode 
                      ? const Color(0xFF2C2C2E).withValues(alpha: 0.65) 
                      : (_selectedBottomIndex == 3 
                          ? Colors.white.withValues(alpha: 0.5) 
                          : Colors.white.withValues(alpha: 0.65)),
                    border: Border.all(
                      color: _isDarkMode 
                          ? Colors.white.withValues(alpha: 0.15) 
                          : Colors.black.withValues(alpha: _selectedBottomIndex == 3 ? 0.2 : 0.08),
                      width: _selectedBottomIndex == 3 && !_isDarkMode ? 0.8 : 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(navItems.length, (index) {
                              final item = navItems[index];
                              final isSelected = _selectedBottomIndex == index;
                              final activeColor = _isDarkMode ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
                              final inactiveColor = _isDarkMode ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF8E8E93);
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedBottomIndex = index;
                                    if (index == 0) {
                                      _taxonomyFocus = 'fauna';
                                      _activeTaxonomyGroup = null;
                                    } else if (index == 1) {
                                      _taxonomyFocus = 'flora';
                                      _activeTaxonomyGroup = null;
                                    }
                                  });
                                  if (index == 0 || index == 1) {
                                    Future.microtask(() => _showTaxonomyPanel(context));
                                  } else if (index == 2) {
                                    Future.microtask(() => _showDateFilterPanel(context));
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 12 : 8,
                                    right: index == navItems.length - 1 ? 12 : 8,
                                    top: 6,
                                    bottom: 6,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 60),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? (_isDarkMode ? CupertinoColors.activeBlue.withValues(alpha: 0.28) : CupertinoColors.activeBlue.withValues(alpha: 0.15)) 
                                      : Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconTheme(
                                        data: IconThemeData(
                                          color: isSelected ? activeColor : inactiveColor,
                                          size: 22,
                                        ),
                                        child: isSelected ? item.activeIcon : item.icon,
                                      ),
                                      Text(
                                        item.label ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected ? activeColor : inactiveColor,
                                          fontSize: 9.0,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Search Toggle Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.1),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: BouncingWrapper(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isSearchActive = !_isSearchActive;
                      if (!_isSearchActive) {
                        _searchQuery = '';
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                      } else {
                        _searchFocusNode.requestFocus();
                      }
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isDarkMode 
                        ? const Color(0xFF2C2C2E).withValues(alpha: 0.65) 
                        : (_selectedBottomIndex == 3 
                            ? Colors.white.withValues(alpha: 0.5) 
                            : Colors.white.withValues(alpha: 0.65)),
                      border: Border.all(
                        color: _isDarkMode 
                            ? Colors.white.withValues(alpha: 0.15) 
                            : Colors.black.withValues(alpha: _selectedBottomIndex == 3 ? 0.2 : 0.08),
                        width: _selectedBottomIndex == 3 && !_isDarkMode ? 0.8 : 0.5,
                      ),
                    ),
                    child: Transform.translate(
                      offset: const Offset(0, -2),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: Icon(
                          _isSearchActive ? LucideIcons.x : LucideIcons.search,
                          key: ValueKey(_isSearchActive),
                          color: _isDarkMode ? Colors.white : Colors.black87,
                          size: 26,
                        ),
                      ),
                    ),
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

  Widget _buildTopSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.1),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _isDarkMode ? const Color(0xFF2C2C2E).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                border: Border.all(
                  color: _isDarkMode ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.8),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.search, color: _isDarkMode ? Colors.white54 : Colors.black54, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar especie...',
                        hintStyle: TextStyle(
                          color: _isDarkMode ? Colors.white54 : Colors.black54,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),

                  BouncingWrapper(
                    isCircular: false,
                    onTap: () {
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (mounted) {
                          setState(() {
                            _isSearchActive = false;
                            _searchController.clear();
                            _searchQuery = '';
                            _searchFocusNode.unfocus();
                          });
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final speciesProvider = context.read<SpeciesProvider>();
    final allMatches = speciesProvider.items.where((s) {
      final scientific = s.scientificName?.toLowerCase() ?? '';
      final common = s.name.toLowerCase();
      return scientific.contains(_searchQuery) || common.contains(_searchQuery);
    }).toList();

    allMatches.sort((a, b) {
      final aScientific = a.scientificName?.toLowerCase() ?? '';
      final aCommon = a.name.toLowerCase();
      final bScientific = b.scientificName?.toLowerCase() ?? '';
      final bCommon = b.name.toLowerCase();

      final aStarts = aScientific.startsWith(_searchQuery) || aCommon.startsWith(_searchQuery);
      final bStarts = bScientific.startsWith(_searchQuery) || bCommon.startsWith(_searchQuery);

      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return aCommon.compareTo(bCommon);
    });

    final results = allMatches.take(5).toList();

    if (results.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.1),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: _isDarkMode ? const Color(0xFF2C2C2E).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                border: Border.all(
                  color: _isDarkMode ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.8),
                  width: 0.5,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.search, color: _isDarkMode ? Colors.white54 : Colors.black38, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'No se encontraron resultados',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Intenta con otro nombre o especie.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.1),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: _isDarkMode ? const Color(0xFF2C2C2E).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                border: Border.all(
                  color: _isDarkMode ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.8),
                  width: 0.5,
                ),
              ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: _isDarkMode ? Colors.white12 : Colors.black12,
              ),
              itemBuilder: (itemContext, index) {
                final species = results[index];
                return ListTile(
                  title: Text(
                    species.scientificName ?? species.name,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    species.name,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    
                    setState(() {
                      _isSearchActive = false;
                      _searchQuery = '';
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                    });
                    
                    final markers = this.context.read<MapProvider>().snapshot?.markers ?? [];
                    try {
                      final marker = markers.firstWhere(
                        (m) => m.speciesId == species.id || m.title == species.name || (species.scientificName != null && m.title == species.scientificName)
                      );
                      _mapController.move(marker.position, 16.0);
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          _showObservationContextModal(this.context, marker);
                        }
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('No hay observaciones recientes para ${species.name}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceLegend() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isLegendExpanded = !_isLegendExpanded;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: _isLegendExpanded ? 16 : 10,
              vertical: _isLegendExpanded ? 10 : 10,
            ),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF1C1C1E).withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: _isDarkMode
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              child: _isLegendExpanded
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendDot(color: Colors.blueAccent, label: 'ODK'),
                        const SizedBox(width: 14),
                        _buildLegendDot(color: Colors.green, label: 'iNaturalist'),
                      ],
                    )
                  : Icon(
                      LucideIcons.info,
                      size: 20,
                      color: _isDarkMode ? Colors.white70 : Colors.black87,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalLayersPopover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: 250,
          padding: const EdgeInsets.only(top: 14, bottom: 10),
          decoration: BoxDecoration(
            color: _isDarkMode 
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.8) 
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 18, right: 18, bottom: 10),
                child: Text(
                  _t('mapLayers'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white54 : Colors.black54,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _buildVerticalLayerOption(style: 'outdoors-v12', icon: LucideIcons.mountain, label: _t('outdoors')),
              Divider(height: 1, thickness: 0.5, color: _isDarkMode ? Colors.white12 : Colors.black12),
              _buildVerticalLayerOption(style: 'light-v11', icon: LucideIcons.sun, label: _t('years')),
              Divider(height: 1, thickness: 0.5, color: _isDarkMode ? Colors.white12 : Colors.black12),
              _buildVerticalLayerOption(style: 'satellite-streets-v12', icon: LucideIcons.map, label: _t('satellite')),
              Divider(height: 1, thickness: 0.5, color: _isDarkMode ? Colors.white12 : Colors.black12),
              _buildVerticalLayerOption(style: 'dark-v11', icon: LucideIcons.moon, label: _t('dark')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalLayerOption({
    required String style,
    required dynamic icon, // Puede ser IconData o Widget
    required String label,
  }) {
    final isSelected = _mapStyle == style;
    final iconColor = isSelected 
        ? Colors.blueAccent 
        : (_isDarkMode ? Colors.white70 : Colors.black87);
    return InkWell(
      onTap: () {
        setState(() {
          _mapStyle = style;
          _isLayersPopoverOpen = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        color: isSelected 
            ? (_isDarkMode ? CupertinoColors.activeBlue.withValues(alpha: 0.15) : CupertinoColors.activeBlue.withValues(alpha: 0.08))
            : Colors.transparent,
        child: Row(
          children: [
            if (icon is IconData)
              Icon(
                icon,
                size: 22,
                color: iconColor,
              )
            else
              IconTheme(
                data: IconThemeData(size: 22, color: iconColor),
                child: icon as Widget,
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? Colors.blueAccent 
                      : (_isDarkMode ? Colors.white : Colors.black87),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                LucideIcons.check,
                size: 20,
                color: Colors.blueAccent,
              ),
          ],
        ),
      ),
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _isDarkMode ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMapMarker(BuildContext context, MapMarkerData marker) {
    final brand = BrandPersonality.resolve(
      source: marker.resolvedSourceType,
    );

    return GestureDetector(
      onTap: () {
        _mapController.move(marker.position, 17.5);
        _showObservationContextModal(context, marker);
      },
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        // Proporción más chata (36x44) para acortar la parte inferior (la punta)
        size: const Size(36, 44),
        painter: _MapPinPainter(primary: brand.primary, dark: brand.dark),
      ),
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
    // Para garantizar que el 100% de las observaciones aparezcan en el mapa,
    // clasificaremos en Fauna todo aquello que no haya sido detectado como Flora.
    return !_markerIsFlora(marker);
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

  Color _colorForGroup(String groupName) {
    final normalized = _normalizeKey(groupName);
    if (normalized.contains('ave')) return const Color(0xFF90C2E7); // Creamy Baby Blue
    if (normalized.contains('mamifer') || normalized.contains('mammal')) return const Color(0xFFBCA0DC); // Creamy Lavender
    if (normalized.contains('reptil')) return const Color(0xFF98C9A3); // Creamy Mint Green
    if (normalized.contains('anfibi')) return const Color(0xFF7ACFCE); // Creamy Aqua
    if (normalized.contains('insect')) return const Color(0xFFFFB5A7); // Creamy Peach/Salmon
    if (normalized.contains('pez') || normalized.contains('peces') || normalized.contains('actinopterygii')) return const Color(0xFF85C7F2); // Creamy Sky Blue
    if (normalized.contains('aracnid') || normalized.contains('arachnid')) return const Color(0xFFF2A6A6); // Creamy Soft Rose
    if (normalized.contains('hongo') || normalized.contains('fungi')) return const Color(0xFFDDA77B); // Creamy Sand/Ochre
    if (normalized.contains('planta') || normalized.contains('flora')) return const Color(0xFF6B9C7A); // Darker Sage Green
    
    // Default fallback colors depending on focus
    return _taxonomyFocus == 'flora' ? const Color(0xFF6B9C7A) : const Color(0xFFF4C27F); // Creamy Apricot for default fauna
  }


  void _showDateFilterPanel(BuildContext context) {
    final mapProvider = context.read<MapProvider>();
    final markers = mapProvider.snapshot?.markers ?? const <MapMarkerData>[];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: DateFilterPanel(
            language: _currentLanguage,
            markers: markers,
            onClose: () => Navigator.of(sheetContext).pop(),
            onApply: () {
              final filters = context.read<FilterProvider>();
              context.read<MapProvider>().refresh(
                    dateRange: filters.effectiveDateRange,
                  );
              if (mounted) {
                setState(() {});
              }
            },
          ),
        );
      },
    );
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

            return ClipRRect(
              borderRadius: BorderRadius.circular(32), // Aplica radio en todos lados para que no queden esquinas raras, aunque abajo esté pegado
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.of(context).padding.bottom),
                  decoration: BoxDecoration(
                      color: _isDarkMode 
                          ? Colors.black.withValues(alpha: 0.5) 
                          : Colors.white.withValues(alpha: 0.7),
                      border: Border(
                        top: BorderSide(
                          color: _isDarkMode ? Colors.white12 : Colors.black12,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _isDarkMode ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (_taxonomyFocus == 'flora' ? Colors.green : Colors.orangeAccent).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _taxonomyFocus == 'flora' ? Icons.eco : Icons.pets,
                                color: _taxonomyFocus == 'flora' ? Colors.green : Colors.orangeAccent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _taxonomyFocus == 'fauna' || _taxonomyFocus == 'flora'
                                    ? _t('taxonomicCatalog')
                                    : _t('taxonomicGroups'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _taxonomyFocus == 'fauna'
                                    ? '${_t('fauna')} • $displayedCount ${_t('observations')}'
                                    : _taxonomyFocus == 'flora'
                                        ? '${_t('flora')} • $displayedCount ${_t('observations')}'
                                        : _t('showOnlyRealGroups'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _isDarkMode ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLargeModal)
                          BouncingWrapper(
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 150), () {
                                if (sheetCtx.mounted) {
                                  Navigator.of(sheetCtx).pop();
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, size: 24, color: _isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20), // Apple HIG: More breathing room after header
                    // Sliding Segmented Control (Apple HIG)
                    Builder(builder: (context) {
                      Widget buildSegment(String label, int count, bool isSelected, Color accentColor) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected 
                                      ? (_isDarkMode ? Colors.white : Colors.black) 
                                      : (_isDarkMode ? Colors.white54 : Colors.black54),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? accentColor : (_isDarkMode ? Colors.white70 : Colors.black87),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<String>(
                          backgroundColor: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          thumbColor: _isDarkMode ? Colors.white.withValues(alpha: 0.22) : Colors.white,
                          groupValue: sourceFilter,
                          children: {
                            'all': buildSegment(_t('all'), markers.length, sourceFilter == 'all', Colors.blueAccent),
                            'odk': buildSegment('ODK', countsBySource.values.fold<int>(0, (sum, counts) => sum + (counts['odk'] ?? 0)), sourceFilter == 'odk', Colors.orangeAccent),
                            'inaturalist': buildSegment('iNaturalist', countsBySource.values.fold<int>(0, (sum, counts) => sum + (counts['inaturalist'] ?? 0)), sourceFilter == 'inaturalist', Colors.green),
                          },
                          onValueChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                sourceFilter = val;
                                _activeTaxonomyGroup = null;
                              });
                            }
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 20), // Apple HIG: Breathing room before the grid
                    if (groups.isEmpty)
                      SizedBox(
                        height: isLargeModal ? 290 : null,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _t('noSpecificGroups'),
                              style: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      )
                    else if (isLargeModal)
                      SizedBox(
                        height: 290, // Slightly taller so cards have more breathing room
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4, // Taller cards to prevent overflow
                          ),
                          itemCount: groups.length,
                          itemBuilder: (c, i) {
                            final g = groups[i];
                            final counts = countsBySource[g] ?? {};
                            final total = counts['total'] ?? 0;
                            final visibleCount = sourceFilter == 'all' ? total : (counts[sourceFilter] ?? 0);
                            final normalized = _normalizeKey(g);
                            final selected = _normalizeKey(_activeTaxonomyGroup ?? '') == normalized;
                            final groupAccent = _colorForGroup(g);
                            
                            final tileColor = selected
                                ? groupAccent.withValues(alpha: _isDarkMode ? 0.15 : 0.08)
                                : (_isDarkMode ? const Color(0xFF1C1C1E) : Colors.white);

                            return BouncingWrapper(
                              isCircular: false,
                              scaleFactor: 0.94,
                              onTap: () {
                                setState(() {
                                  _activeTaxonomyGroup = selected ? null : g;
                                });
                                setModalState(() {}); // Force modal rebuild
                                if (!selected) {
                                  // Wait for the animation to complete before showing the list
                                  Future.delayed(const Duration(milliseconds: 250), () {
                                    if (mounted) {
                                      _showGroupList(context, g, markers, sourceFilter: sourceFilter);
                                    }
                                  });
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCirc,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: selected 
                                      ? groupAccent 
                                      : (_isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03)),
                                  borderRadius: BorderRadius.circular(22), // Apple-style squircle radius
                                  border: Border.all(
                                    color: selected 
                                        ? groupAccent.withValues(alpha: 0.8)
                                        : (_isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02)),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    if (selected)
                                      BoxShadow(
                                        color: groupAccent.withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        spreadRadius: -2,
                                        offset: const Offset(0, 6),
                                      ),
                                    if (!selected && !_isDarkMode)
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Centered content
                                    Align(
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Icon
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: selected 
                                                  ? Colors.white.withValues(alpha: 0.2) 
                                                  : (_isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                                              borderRadius: BorderRadius.circular(14),
                                              boxShadow: (!selected && !_isDarkMode) 
                                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                                  : null,
                                            ),
                                            child: _groupIconWidget(
                                              g, 
                                              size: 22,
                                              color: selected ? Colors.white : groupAccent,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          // Title
                                          Text(
                                            g,
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.4,
                                              color: selected 
                                                  ? Colors.white 
                                                  : (_isDarkMode ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.8)),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          // Count (Subtitle)
                                          Text(
                                            '$visibleCount observaciones',
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.1,
                                              color: selected 
                                                  ? Colors.white.withValues(alpha: 0.8) 
                                                  : (_isDarkMode ? Colors.white54 : Colors.black54),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                            final groupColor = _colorForGroup(g);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: selected 
                                        ? groupColor.withValues(alpha: 0.5) 
                                        : (_isDarkMode ? Colors.white12 : Colors.black12),
                                  ),
                                ),
                                selectedColor: groupColor.withValues(alpha: 0.15),
                                backgroundColor: _isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _groupIconWidget(g, size: 16, color: groupColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      g, 
                                      style: TextStyle(
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                        color: selected ? groupColor : (_isDarkMode ? Colors.white : Colors.black87),
                                      )
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: groupColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('$visibleCount', style: TextStyle(fontSize: 11, color: groupColor)),
                                    ),
                                  ],
                                ),
                                selected: selected,
                                onSelected: (sel) {
                                  setState(() {
                                    _activeTaxonomyGroup = sel ? g : null;
                                  });
                                  setModalState(() {}); // Force modal rebuild
                                  if (sel) {
                                    Future.delayed(const Duration(milliseconds: 250), () {
                                      if (mounted) {
                                        _showGroupList(context, g, markers, sourceFilter: sourceFilter);
                                      }
                                    });
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
            ),
          );
          },
        );
      },
    );
  }

  void _showGroupList(BuildContext context, String group, List<MapMarkerData> markers, {String sourceFilter = 'all', bool isFromReturn = false}) {
    final normalized = _normalizeKey(group);
    // Filtrar por grupo Y por fuente activa
    final items = markers.where((m) {
      if (_normalizeKey(m.groupName ?? '') != normalized) return false;
      if (sourceFilter == 'all') return true;
      return m.resolvedSourceType == sourceFilter;
    }).toList();
    final groupAccent = _taxonomyFocus == 'flora' ? Colors.green : Colors.orangeAccent;
    final isAnimalGroup = normalized.contains('insect') || normalized.contains('insecta') || normalized.contains('coleoptera') || normalized.contains('hymenoptera') || normalized.contains('aves') || normalized.contains('ave') || normalized.contains('bird') || normalized.contains('anfib') || normalized.contains('amphib') || normalized.contains('amphibia') || normalized.contains('reptil') || normalized.contains('reptilia') || normalized.contains('lizard') || normalized.contains('reptile') || normalized.contains('fish') || normalized.contains('pez') || normalized.contains('peces') || normalized.contains('actinopterygii') || normalized.contains('pisces') || normalized.contains('mammal') || normalized.contains('mammalia') || normalized.contains('mamif') || normalized.contains('mamifer') || normalized.contains('animal') || normalized.contains('animalia') || normalized.contains('mollusc') || normalized.contains('molusco') || normalized.contains('arachnid') || normalized.contains('aracnid') || normalized.contains('desconocido') || normalized.contains('unknown');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF171717) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: _isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDarkMode ? 0.28 : 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: groupAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _groupIconWidget(group, size: 24, color: groupAccent),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_taxonomyFocus == 'flora' ? 'Flora' : (isAnimalGroup && _taxonomyFocus == 'fauna' ? 'Fauna' : 'Grupo taxonómico')} • ${items.length} registros',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _isDarkMode ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        BouncingWrapper(
                          onTap: () {
                            Future.delayed(const Duration(milliseconds: 150), () {
                              if (mounted) {
                                Navigator.of(ctx).pop();
                                if (isFromReturn && _taxonomyFocus != null) {
                                  Future.delayed(const Duration(milliseconds: 250), () {
                                    if (mounted) {
                                      _showTaxonomyPanel(this.context);
                                    }
                                  });
                                }
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              // Show a back arrow for the same-kind groups (fauna groups when in fauna,
                              // and flora groups — including plants and fungi — when in flora). Otherwise show close.
                              ((_taxonomyFocus == 'fauna' && isAnimalGroup) ||
                                      (_taxonomyFocus == 'flora' && (normalized.contains('planta') || normalized.contains('plant') || normalized.contains('plantae') || normalized.contains('fungi') || normalized.contains('hongo') || normalized.contains('hong'))))
                                  ? Icons.arrow_back_rounded
                                  : Icons.close_rounded,
                              size: 24,
                              color: _isDarkMode ? Colors.white70 : Colors.black54,
                            ),
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
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 16),
                            itemBuilder: (c, i) {
                              final m = items[i];
                              final sourceType = m.resolvedSourceType;
                              final sourceColor = sourceType == 'odk' ? Colors.orangeAccent : Colors.green;
                              // removed author display for a cleaner, premium card layout
                              return BouncingWrapper(
                                isCircular: false,
                                onTap: () {
                                  Future.delayed(const Duration(milliseconds: 150), () {
                                    if (!mounted) return;
                                    Navigator.popUntil(context, (route) => route.isFirst);
                                    _mapController.move(m.position, 17.5);
                                    Future.delayed(const Duration(milliseconds: 800), () {
                                      if (!mounted) return;
                                      _showObservationContextModal(
                                        this.context,
                                        m,
                                        onReturnToList: () {
                                          Future.delayed(const Duration(milliseconds: 250), () {
                                            if (mounted) {
                                              _showGroupList(this.context, group, markers, sourceFilter: sourceFilter, isFromReturn: true);
                                            }
                                          });
                                        },
                                      );
                                    });
                                  });
                                },
                                child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : const Color(0xFFF7F8FB),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: _isDarkMode
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : Colors.black.withValues(alpha: 0.03),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: groupAccent.withValues(alpha: _isDarkMode ? 0.16 : 0.10),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Center(
                                            child: _markerIconWidget(m, size: 24, color: groupAccent),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                m.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.3,
                                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    sourceType == 'odk' ? 'ODK' : 'iNaturalist',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: sourceColor,
                                                    ),
                                                  ),
                                                  if (m.observedAt != null) ...[
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                                      child: Text(
                                                        '•',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: _isDarkMode ? Colors.white30 : Colors.black26,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatObservationDate(m.observedAt),
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: _isDarkMode ? Colors.white60 : Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.location_on_rounded,
                                                    size: 18,
                                                    color: _isDarkMode ? Colors.white38 : Colors.black38,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${m.position.latitude.toStringAsFixed(4)}, ${m.position.longitude.toStringAsFixed(4)}',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: _isDarkMode ? Colors.white38 : Colors.black38,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 24,
                                          color: _isDarkMode ? Colors.white24 : Colors.black26,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
      },
    );
  }

  void _showObservationContextModal(BuildContext context, MapMarkerData marker, {VoidCallback? onReturnToList}) {
    final sourceType = marker.resolvedSourceType;
    final sourceColor = sourceType == 'odk' ? Colors.orangeAccent : Colors.green;
    
    // Buscar la información de la especie relacionada
    final speciesProvider = context.read<SpeciesProvider>();
    Species? relatedSpecies;
    try {
      relatedSpecies = speciesProvider.items.firstWhere(
        (s) => s.id == marker.speciesId || s.name == marker.title || (s.scientificName != null && s.scientificName == marker.title)
      );
    } catch (_) {}

    final displayImageUrl = marker.imageUrl?.isNotEmpty == true ? marker.imageUrl : relatedSpecies?.imageUrl;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                const SizedBox(height: 16),
                if (displayImageUrl != null && displayImageUrl.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 190,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: _isDarkMode ? 0.4 : 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(
                        displayImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: _isDarkMode 
                                ? Colors.white.withValues(alpha: 0.04) 
                                : Colors.black.withValues(alpha: 0.03),
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(sourceColor.withValues(alpha: 0.6)),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: _isDarkMode 
                              ? Colors.white.withValues(alpha: 0.04) 
                              : Colors.black.withValues(alpha: 0.03),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_rounded, 
                                color: _isDarkMode ? Colors.white24 : Colors.black26,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Imagen no disponible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isDarkMode ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: _isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (marker.groupName != null && marker.groupName!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Grupo taxonómico: ${marker.groupName!.trim()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _isDarkMode ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 14),
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
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildContextInfoChip(
                        label: 'Fuente',
                        value: marker.resolvedSourceType == 'odk' ? 'ODK' : 'iNaturalist',
                        accentColor: sourceColor,
                      ),
                    ),
                    if (marker.observedAt != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildContextInfoChip(
                          label: 'Fecha',
                          value: (() {
                            final date = marker.observedAt!;
                            if (_currentLanguage == 'en') {
                              const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              return '${date.day} ${monthsEn[date.month - 1]} ${date.year}';
                            } else {
                              const monthsEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
                              return '${date.day} ${monthsEs[date.month - 1]} ${date.year}';
                            }
                          })(),
                          accentColor: _isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                if (onReturnToList != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: sourceColor,
                        side: BorderSide(color: sourceColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(sourceColor.withValues(alpha: _isDarkMode ? 0.25 : 0.15)),
                      ),
                      onPressed: () {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                            onReturnToList();
                          }
                        });
                      },
                      child: const Text('Volver a la lista', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (onReturnToList != null) const SizedBox(height: 8),
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
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: _isDarkMode ? 0.35 : 0.2)),
                    ),
                    onPressed: () {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      });
                    },
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
    return _groupIconWidget(group, size: size, color: color);
  }

  Widget _buildSourceFilterButton({
    required String label,
    required bool isSelected,
    required Color accentColor,
    required int count,
    required VoidCallback onTap,
  }) {
    final backgroundColor = isSelected
        ? (_isDarkMode ? const Color(0xFF2C2C2E) : Colors.white)
        : Colors.transparent;

    final labelColor = isSelected
        ? (_isDarkMode ? Colors.white : Colors.black)
        : (_isDarkMode ? Colors.white54 : Colors.black54);
    
    final numberColor = isSelected
        ? accentColor
        : (_isDarkMode ? Colors.white70 : Colors.black87);

    return BouncingWrapper(
      isCircular: false,
      onTap: onTap,
      scaleFactor: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: _isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.05))
              : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12, // Slightly smaller label
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: labelColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '$count',
                key: ValueKey<int>(count),
                style: TextStyle(
                  fontSize: 15, // Slightly smaller count to balance
                  fontWeight: FontWeight.w800,
                  color: numberColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
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
    if (n.contains('insect') || n.contains('insecta') || n.contains('aracnid') || n.contains('arachnid') || n.contains('araña') || n.contains('mollusc') || n.contains('molusco')) return LucideIcons.bug;
    if (n.contains('aves') || n.contains('ave') || n.contains('bird')) return LucideIcons.bird;
    if (n.contains('anfib') || n.contains('amphib') || n.contains('amphibia')) return LucideIcons.droplets;
    if (n.contains('reptil') || n.contains('reptilia') || n.contains('reptile') || n.contains('lizard')) return CupertinoIcons.tortoise;
    if (n.contains('fish') || n.contains('pez') || n.contains('peces') || n.contains('pec') || n.contains('pisces')) return LucideIcons.fish;
    if (n.contains('mammal') || n.contains('mammalia') || n.contains('mamif') || n.contains('mamífer')) return Icons.cruelty_free;
    if (n.contains('animal') || n.contains('animalia')) return Icons.pets;
    if (n.contains('fungi') || n.contains('hongo') || n.contains('hong')) return Icons.spa;
    if (n.contains('arbol') || n.contains('tree') || n.contains('forest') || n.contains('bosque')) return Icons.park;
    if (n.contains('flor') || n.contains('flower')) return Icons.local_florist;
    if (n.contains('helecho') || n.contains('fern') || n.contains('hierba') || n.contains('grass') || n.contains('grama') || n.contains('herb')) return Icons.grass;
    if (n.contains('flora') || n.contains('plant') || n.contains('planta') || n.contains('plantae') || n.contains('cactus')) return Icons.eco;
    return _taxonomyFocus == 'flora' ? Icons.eco : Icons.pets;
  }

  Widget _groupIconWidget(String group, {double size = 16, Color color = Colors.blueAccent}) {
    final n = _normalizeKey(group);
    if (n.contains('flora') || n.contains('plant') || n.contains('planta') || n.contains('plantae') || n.contains('cactus')) {
      const String sproutSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-sprout-icon lucide-sprout"><path d="M14 9.536V7a4 4 0 0 1 4-4h1.5a.5.5 0 0 1 .5.5V5a4 4 0 0 1-4 4 4 4 0 0 0-4 4c0 2 1 3 1 5a5 5 0 0 1-1 3"/><path d="M4 9a5 5 0 0 1 8 4 5 5 0 0 1-8-4"/><path d="M5 21h14"/></svg>''';
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SvgPicture.string(
            sproutSvg,
            width: size * 1.05,
            height: size * 1.05,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      );
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

  Widget _buildMenuGroup({required bool isDark, String? title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.7),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
        ...children,
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    Widget? trailing,
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    final defaultTextColor = isDark ? Colors.white.withValues(alpha: 0.95) : Colors.black87;
    final iconColor = isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black54;
    
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: defaultTextColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
                if (showChevron) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.2),
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        child: onTap == null
            ? content
            : BouncingWrapper(
                isCircular: false,
                onTap: () {
                  Future.delayed(const Duration(milliseconds: 150), () {
                    onTap();
                  });
                },
                child: content,
              ),
      ),
    );
  }

}


class _MapPinPainter extends CustomPainter {
  const _MapPinPainter({required this.primary, required this.dark});

  final Color primary;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Use original relative proportions (which are mathematically perfect)
    // Because we use Size(36, 54), it will automatically be slender!
    final r = w * 0.425;
    final cy = r + h * 0.04;

    final path = _pinPath(cx, cy, r, w, h);

    // Se eliminó la sombra difusa externa a petición del usuario.

    // 2. Relleno
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - r * 0.22, cy - r * 0.28),
          r * 2.0,
          [_lighten(primary, 0.20), primary, _darken(primary, 0.20)],
          [0.0, 0.50, 1.0],
        )
        ..style = PaintingStyle.fill,
    );

    // 3. Brillo especular
    final specPath = _specularPath(cx, cy, r);
    canvas.drawPath(
      specPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, cy - r * 0.95),
          Offset(cx, cy + r * 0.10),
          [
            Colors.white.withValues(alpha: 0.36),
            Colors.white.withValues(alpha: 0.0),
          ],
        )
        ..style = PaintingStyle.fill,
    );

    // 4. Inner stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75,
    );

    // 5. Anillo blanco
    final ringR = r * 0.44;
    final center = Offset(cx, cy);
    canvas.drawCircle(
      center,
      ringR + 1.2,
      Paint()
        ..color = dark.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );
    canvas.drawCircle(center, ringR, Paint()..color = Colors.white);

    // 6. Punto central
    final dotR = ringR * 0.42;
    canvas.drawCircle(
      center,
      dotR,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - dotR * 0.25, cy - dotR * 0.25),
          dotR * 1.8,
          [_lighten(primary, 0.18), _darken(primary, 0.12)],
        )
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx - dotR * 0.30, cy - dotR * 0.30),
      dotR * 0.30,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
    );
  }

  ui.Path _pinPath(double cx, double cy, double r, double w, double h) {
    // Elegant teardrop using standard bezier scaled to our cx, cy, r
    final path = ui.Path();
    final tipY = h * 0.96;
    
    final s = r / 8.0;
    
    double mapX(double x) => cx + (x - 12) * s;
    double mapY(double y) {
      if (y <= 10) {
        return cy + (y - 10) * s;
      } else {
        // Smoothly stretch the bottom to reach tipY without bulging
        final stretch = (tipY - cy) / 12.0;
        return cy + (y - 10) * stretch;
      }
    }

    path.moveTo(mapX(12), mapY(22));
    path.cubicTo(
      mapX(4), mapY(15.5),
      mapX(4), mapY(10),
      mapX(4), mapY(10),
    );
    path.arcToPoint(
      Offset(mapX(20), mapY(10)),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.cubicTo(
      mapX(20), mapY(15.5),
      mapX(12), mapY(22),
      mapX(12), mapY(22),
    );
    path.close();
    return path;
  }

  ui.Path _specularPath(double cx, double cy, double r) {
    const k = 0.5523;
    final outerR = r * 0.88;
    final innerR = r * 0.52;

    final path = ui.Path();
    final startAngle = 2.44; 
    final endAngle   = 0.70; 

    final sx = cx + outerR * _fcos(startAngle);
    final sy = cy + outerR * _fsin(startAngle);
    path.moveTo(sx, sy);

    final topOuter = Offset(cx, cy - outerR);
    path.cubicTo(
      sx + outerR * k * 0.7,  sy - outerR * k * 0.5,
      topOuter.dx - outerR * k * 0.5, topOuter.dy,
      topOuter.dx, topOuter.dy,
    );
    final ex = cx + outerR * _fcos(endAngle);
    final ey = cy + outerR * _fsin(endAngle);
    path.cubicTo(
      topOuter.dx + outerR * k * 0.5, topOuter.dy,
      ex - outerR * k * 0.7,  ey - outerR * k * 0.5,
      ex, ey,
    );

    final topInner = Offset(cx, cy - innerR);
    final ix = cx + innerR * _fcos(endAngle);
    final iy = cy + innerR * _fsin(endAngle);
    path.lineTo(ix, iy);
    path.cubicTo(
      ix - innerR * k * 0.5, iy - innerR * k * 0.5,
      topInner.dx + innerR * k * 0.5, topInner.dy,
      topInner.dx, topInner.dy,
    );
    final isx = cx + innerR * _fcos(startAngle);
    final isy = cy + innerR * _fsin(startAngle);
    path.cubicTo(
      topInner.dx - innerR * k * 0.5, topInner.dy,
      isx + innerR * k * 0.7, isy - innerR * k * 0.5,
      isx, isy,
    );

    path.close();
    return path;
  }

  static double _fsin(double x) {
    const pi = 3.14159265358979;
    const twoPi = pi * 2;
    x = x - twoPi * (x / twoPi).floorToDouble();
    if (x > pi) { x -= twoPi; }
    final x2 = x * x;
    return x * (1.0 - x2 / 6.0 * (1.0 - x2 / 20.0 * (1.0 - x2 / 42.0)));
  }

  static double _fcos(double x) => _fsin(x + 1.5707963267948966);

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(_MapPinPainter old) =>
      old.primary != primary || old.dark != dark;
}
