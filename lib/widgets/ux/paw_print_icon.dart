import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PawPrintSvgIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool isFilled;

  const PawPrintSvgIcon({
    super.key,
    this.size = 24.0,
    this.color,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final iconColor = color ?? iconTheme.color ?? Colors.black;
    final iconSize = size; // Could also use iconTheme.size
    
    final fillStyle = isFilled ? 'currentColor' : 'none';
    final strokeStyle = isFilled ? 'none' : 'currentColor';
    final circleRadius = isFilled ? '2.8' : '2';

    final svgString = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="$fillStyle" stroke="$strokeStyle" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-paw-print-icon lucide-paw-print">
  <circle cx="11" cy="4" r="$circleRadius"/>
  <circle cx="18" cy="8" r="$circleRadius"/>
  <circle cx="20" cy="16" r="$circleRadius"/>
  <path d="M9 10a5 5 0 0 1 5 5v3.5a3.5 3.5 0 0 1-6.84 1.045Q6.52 17.48 4.46 16.84A3.5 3.5 0 0 1 5.5 10Z"/>
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
