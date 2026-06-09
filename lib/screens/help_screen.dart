import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:soy_conservacion/providers/theme_provider.dart';
import 'package:soy_conservacion/widgets/ux/bouncing_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  final String language;
  
  const HelpScreen({super.key, required this.language});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'soportesoyconservacion@gmail.com',
      queryParameters: {
        'subject': 'Soporte - App Soy Conservación',
        'body': 'Hola, necesito ayuda con la aplicación...'
      },
    );
    
    if (!await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir el correo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final isEn = language == 'en';
    
    // Translations
    final tHelpCenter = isEn ? 'Help Center' : 'Centro de Ayuda';
    final tHowCanWeHelp = isEn ? 'How can we help you?' : '¿Cómo podemos ayudarte?';
    final tContactSupport = isEn ? 'Contact Support' : 'Contactar a Soporte';
    final tFaqTitle = isEn ? 'FREQUENTLY ASKED QUESTIONS' : 'PREGUNTAS FRECUENTES';
    
    final tQ1 = isEn ? 'Why doesn\'t my record appear?' : '¿Por qué mi registro no aparece?';
    final tA1 = isEn 
      ? 'All records go through a validation process by experts before becoming public. This process may take a couple of days.'
      : 'Todos los registros pasan por un proceso de validación por parte de expertos antes de hacerse públicos. Este proceso puede tardar un par de días.';
      
    final tQ2 = isEn ? 'Offline synchronization' : 'Sincronización offline';
    final tA2 = isEn 
      ? 'You can make records without internet. The app will save them locally. When you have Wi-Fi or data connection again, they will sync automatically.'
      : 'Puedes hacer registros sin internet. La aplicación los guardará localmente. Cuando vuelvas a tener conexión Wi-Fi o datos, se sincronizarán automáticamente.';
      
    final tQ3 = isEn ? 'Dark mode' : 'Modo oscuro';
    final tA3 = isEn 
      ? 'You can toggle between Light and Dark visual mode from the main menu of the application, tapping the switch.'
      : 'Puedes alternar entre el modo visual Claro y Oscuro desde el menú principal de la aplicación, tocando el interruptor.';
      
    final tQ4 = isEn ? 'Map layers' : 'Capas del mapa';
    final tA4 = isEn 
      ? 'The map allows you to view different base layers such as "Satellite". You can change them from the main screen by tapping the floating button.'
      : 'El mapa permite visualizar distintas capas base como "Satélite". Puedes cambiarlas desde la pantalla principal tocando el botón flotante.';

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
          tHelpCenter,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            // Header Icon
            Center(
              child: Container(
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
                  child: Icon(LucideIcons.helpCircle, size: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  tHowCanWeHelp,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Contact Support Button (Inset Grouped style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Material(
                color: Colors.transparent,
                child: BouncingWrapper(
                  isCircular: false,
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 150), () {
                      _launchEmail();
                    });
                  },
                  child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.mail, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        tContactSupport,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: primaryColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // FAQ Section Title
            Padding(
              padding: const EdgeInsets.only(left: 20.0, bottom: 8.0),
              child: Text(
                tFaqTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                  letterSpacing: -0.1,
                ),
              ),
            ),

            // FAQ Accordions (Inset Grouped List)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildAppleFaqItem(
                      question: tQ1,
                      answer: tA1,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      hasBorder: true,
                      separatorColor: separatorColor,
                    ),
                    _buildAppleFaqItem(
                      question: tQ2,
                      answer: tA2,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      hasBorder: true,
                      separatorColor: separatorColor,
                    ),
                    _buildAppleFaqItem(
                      question: tQ3,
                      answer: tA3,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      hasBorder: true,
                      separatorColor: separatorColor,
                    ),
                    _buildAppleFaqItem(
                      question: tQ4,
                      answer: tA4,
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

  Widget _buildAppleFaqItem({
    required String question,
    required String answer,
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
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
            question,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
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
              answer,
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
