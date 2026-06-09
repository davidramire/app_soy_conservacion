import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:soy_conservacion/providers/theme_provider.dart';
import 'package:soy_conservacion/widgets/ux/bouncing_wrapper.dart';

class PrivacyScreen extends StatelessWidget {
  final String language;
  
  const PrivacyScreen({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final isEn = language == 'en';
    
    // Translations
    final tPrivacy = isEn ? 'Privacy' : 'Privacidad';
    final tPolicyTerms = isEn ? 'Privacy Policy & Terms of Use' : 'Políticas de Privacidad y Términos de Uso';
    final tLastUpdated = isEn ? 'Last updated: June 2026' : 'Actualizado: Junio de 2026';
    final tIntro = isEn
      ? 'Your privacy and the security of biodiversity data are our priority. Here we clearly explain how our app works.'
      : 'Tu privacidad y la seguridad de los datos de biodiversidad son nuestra prioridad. Aquí te explicamos claramente cómo funciona nuestra aplicación.';
    
    final tGpsTitle = isEn ? 'Use of your Location' : 'Uso de tu Ubicación';
    final tGpsContent = isEn
      ? 'The application uses your device\'s GPS only to locate your position on the map and facilitate the creation of georeferenced records. Your real-time location is not shared with third parties or tracked in the background.'
      : 'La aplicación utiliza el GPS de tu dispositivo únicamente para localizar tu posición en el mapa y facilitar la creación de registros georeferenciados. Tu ubicación en tiempo real no se comparte con terceros ni se rastrea en segundo plano.';
      
    final tPushTitle = isEn ? 'Push Notifications' : 'Notificaciones Push';
    final tPushContent = isEn
      ? 'We use Firebase Cloud Messaging (FCM) to send you alerts about new species registered in your area of interest. You can disable these alerts at any time from the main menu.'
      : 'Utilizamos Firebase Cloud Messaging (FCM) para enviarte alertas sobre nuevas especies registradas en tu zona de interés. Puedes desactivar estas alertas en cualquier momento desde el menú principal.';
      
    final tDataTitle = isEn ? 'Biodiversity Data' : 'Datos de Biodiversidad';
    final tDataContent = isEn
      ? 'All taxonomic and spatial information shown is aggregated through collaborative sources (ODK and iNaturalist). The data is used exclusively for research, conservation, and education purposes.'
      : 'Toda la información taxonómica y espacial mostrada es agregada a través de fuentes colaborativas (ODK y iNaturalist). Los datos son utilizados exclusivamente con fines de investigación, conservación y educación.';

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
          tPrivacy,
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
            // Header Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(LucideIcons.shieldCheck, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                tPolicyTerms,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tLastUpdated,
              style: TextStyle(
                fontSize: 15,
                color: secondaryTextColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 32),
            
            // Introduction Inset List
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
                  tIntro,
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

            // Accordion Inset List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildAppleAccordionItem(
                      title: tGpsTitle,
                      icon: LucideIcons.mapPin,
                      iconBgColor: const Color(0xFF007AFF), // Blue
                      content: tGpsContent,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      hasBorder: true,
                      separatorColor: separatorColor,
                    ),
                    _buildAppleAccordionItem(
                      title: tPushTitle,
                      icon: LucideIcons.bell,
                      iconBgColor: const Color(0xFFFF9500), // Orange
                      content: tPushContent,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      hasBorder: true,
                      separatorColor: separatorColor,
                    ),
                    _buildAppleAccordionItem(
                      title: tDataTitle,
                      icon: LucideIcons.leaf,
                      iconBgColor: const Color(0xFF34C759), // Green
                      content: tDataContent,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      hasBorder: false,
                      separatorColor: separatorColor,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleAccordionItem({
    required String title,
    required IconData icon,
    required Color iconBgColor,
    required String content,
    required Color textColor,
    required Color secondaryTextColor,
    required bool hasBorder,
    required Color separatorColor,
  }) {
    return Theme(
      data: ThemeData().copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.only(left: 16, right: 16),
        childrenPadding: const EdgeInsets.only(left: 62, right: 16, bottom: 16),
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        iconColor: const Color(0xFFC6C6C8),
        collapsedIconColor: const Color(0xFFC6C6C8),
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400, // Apple uses regular weight for settings lists
              color: textColor,
              letterSpacing: -0.4,
            ),
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 8),
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
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: secondaryTextColor,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
