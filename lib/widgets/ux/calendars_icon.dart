import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CalendarsSvgIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool isFilled;

  const CalendarsSvgIcon({
    super.key,
    this.size = 24.0,
    this.color,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final iconColor = color ?? iconTheme.color ?? Colors.black;
    final iconSize = size; 
    
    if (!isFilled) {
      final svgString = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-calendar-days">
  <path d="M8 2v4"/>
  <path d="M16 2v4"/>
  <rect width="18" height="18" x="3" y="4" rx="2"/>
  <path d="M3 10h18"/>
  <path d="M8 14h.01"/>
  <path d="M12 14h.01"/>
  <path d="M16 14h.01"/>
  <path d="M8 18h.01"/>
  <path d="M12 18h.01"/>
  <path d="M16 18h.01"/>
</svg>
''';
      return SvgPicture.string(
        svgString,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    } else {
      final svgString = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <defs>
    <mask id="calendarMask">
      <rect width="24" height="24" fill="white" />
      <path d="M3 10h18" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M8 14h.01" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M12 14h.01" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M16 14h.01" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M8 18h.01" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M12 18h.01" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M16 18h.01" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    </mask>
  </defs>

  <!-- Cuerpo principal relleno con recortes reales usando la máscara -->
  <rect x="3" y="4" width="18" height="18" rx="2" fill="currentColor" mask="url(#calendarMask)" />
  
  <!-- Anillas superiores dibujadas con el color principal -->
  <path d="M16 2v4" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  <path d="M8 2v4" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';
      return SvgPicture.string(
        svgString,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }
  }
}
