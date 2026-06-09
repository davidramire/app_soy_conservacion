import 'package:flutter/material.dart';
import 'bouncing_wrapper.dart';

class AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24.0,
    this.padding = const EdgeInsets.all(8.0),
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.iconTheme.color;
    final isCircular = borderRadius == null;

    return BouncingWrapper(
      onTap: onPressed,
      isCircular: isCircular,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: borderRadius,
        ),
        child: Icon(
          icon,
          size: size,
          color: onPressed == null ? theme.disabledColor : iconColor,
        ),
      ),
    );
  }
}
