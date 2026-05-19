import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Se activará tras el primer build
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
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
                  color: _isDarkMode ? Colors.white.withOpacity(0.25) : Colors.transparent,
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
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0008) // Perspectiva 3D más sutil
                ..translate((1 - curvedValue) * 120) // Un recorrido de entrada más largo para que se sienta el deslizamiento
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
                            // ... resto del código interno
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
                                      activeColor: Colors.blueAccent,
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
                                    _t('version') + ' 1.0.0',
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
        body: FlutterMap(
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                  ? Colors.blueAccent.withOpacity(0.15)
                  : (_isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F2F5)),
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
}
