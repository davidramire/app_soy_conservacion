import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnalysisSvgIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool isFilled;

  const AnalysisSvgIcon({
    super.key,
    this.size = 24.0,
    this.color,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final iconColor = color ?? iconTheme.color ?? Colors.black;
    
    final rectFill = isFilled ? 'currentColor' : 'none';
    final rectStroke = isFilled ? 'none' : 'currentColor';

    final svgString = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <path d="M3 3v16a2 2 0 0 0 2 2h16" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  <rect x="15" y="5" width="4" height="12" rx="1" fill="$rectFill" stroke="$rectStroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="7" y="8" width="4" height="9" rx="1" fill="$rectFill" stroke="$rectStroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}
