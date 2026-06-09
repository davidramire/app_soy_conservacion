import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:soy_conservacion/providers/theme_provider.dart';
import 'package:soy_conservacion/widgets/ux/bouncing_wrapper.dart';

class AboutScreen extends StatelessWidget {
  final String language;
  
  const AboutScreen({super.key, required this.language});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final isEn = language == 'en';
    
    // Translations
    final tAbout = isEn ? 'About' : 'Acerca de';
    final tVersion = isEn ? 'Version' : 'Versión';
    final tMission = isEn 
      ? 'Our mission is to connect citizens, scientists, and nature lovers to protect the biodiversity of our region. Through technology, we make visible what needs to be protected.'
      : 'Nuestra misión es conectar a los ciudadanos, científicos y amantes de la naturaleza para proteger la biodiversidad de nuestra región. A través de la tecnología, hacemos visible lo que necesita ser protegido.';
    final tVisitWebsite = isEn ? 'Visit website' : 'Visitar sitio web';
    final tFollowInstagram = isEn ? 'Follow us on Instagram' : 'Síguenos en Instagram';
    final tContactUs = isEn ? 'Contact us' : 'Contáctanos';
    final tDevSupport = isEn ? 'Development and Support' : 'Desarrollo y Soporte';
    final tDevSubtitle = isEn ? 'Uses synchronized data with ODK and iNaturalist.' : 'Utiliza datos sincronizados con ODK e iNaturalist.';
    final tCopyright = isEn ? '© ${DateTime.now().year} Soy Conservación.\nAll rights reserved.' : '© ${DateTime.now().year} Soy Conservación.\nTodos los derechos reservados.';
    
    // Apple system colors
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? const Color(0xFFEBEBF5).withValues(alpha: 0.6) : const Color(0xFF3C3C43).withValues(alpha: 0.6);
    final primaryColor = const Color(0xFF007AFF); // Apple Blue
    final separatorColor = isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: BouncingWrapper(
            isCircular: true,
            onTap: () {
              Future.delayed(const Duration(milliseconds: 150), () {
                if (context.mounted) Navigator.of(context).pop();
              });
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              child: Icon(LucideIcons.chevronLeft, color: primaryColor, size: 28),
            ),
          ),
        ),
        title: Text(
          tAbout,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            // Logo as an iOS-style App Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/images/soy_conservacion_logo.png',
                errorBuilder: (context, error, stackTrace) => 
                    Icon(LucideIcons.leaf, size: 50, color: const Color(0xFF34C759)), // Apple Green
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Soy Conservación',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$tVersion 1.0.0',
              style: TextStyle(
                fontSize: 15,
                color: secondaryTextColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 36),

            // Inset Grouped List for Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tMission,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Inset Grouped List for Links
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildAppleListTile(
                      icon: LucideIcons.globe,
                      iconBgColor: const Color(0xFF007AFF),
                      title: tVisitWebsite,
                      onTap: () => _launchUrl('https://www.soyconservacion.org/'),
                      textColor: textColor,
                      hasBorder: true,
                      separatorColor: separatorColor,
                    ),
                    _buildAppleListTile(
                      icon: LucideIcons.instagram,
                      iconBgColor: const Color(0xFFE1306C),
                      title: tFollowInstagram,
                      onTap: () => _launchUrl('https://www.instagram.com/soy_conservacion/'),
                      textColor: textColor,
                      hasBorder: true,
                      separatorColor: separatorColor,
                    ),
                    _buildAppleListTile(
                      icon: LucideIcons.mail,
                      iconBgColor: const Color(0xFF34C759),
                      title: tContactUs,
                      onTap: () => _launchUrl('mailto:diegogomez@soyconservacion.org'),
                      textColor: textColor,
                      hasBorder: false,
                      separatorColor: separatorColor,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Inset Grouped List for Dev Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildAppleListTile(
                  icon: LucideIcons.code,
                  iconBgColor: const Color(0xFF5856D6), // Apple Purple
                  title: tDevSupport,
                  subtitle: tDevSubtitle,
                  onTap: () {},
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  hasBorder: false,
                  separatorColor: separatorColor,
                  showChevron: false,
                ),
              ),
            ),

            const SizedBox(height: 40),
            Text(
              tCopyright,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleListTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color textColor,
    Color? secondaryTextColor,
    required bool hasBorder,
    required Color separatorColor,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: BouncingWrapper(
        isCircular: false,
        onTap: () {
          Future.delayed(const Duration(milliseconds: 150), () {
            onTap();
          });
        },
        child: Container(
          padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: hasBorder
                      ? Border(
                          bottom: BorderSide(
                            color: separatorColor,
                            width: 0.5,
                          ),
                        )
                      : null,
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
                              fontSize: 17,
                              color: textColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryTextColor,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showChevron) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Icon(
                          LucideIcons.chevronRight,
                          color: const Color(0xFFC6C6C8),
                          size: 20,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
