import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double elevation;
  final BorderRadiusGeometry? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.elevation = 2.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final borderRad = borderRadius ?? BorderRadius.circular(16);

    Widget card = Card(
      margin: margin ?? EdgeInsets.zero,
      elevation: elevation,
      color: cardColor,
      shadowColor: isDark ? Colors.black45 : AppColors.borderLight.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: borderRad,
        side: isDark 
            ? const BorderSide(color: AppColors.borderDark, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRad.resolve(Directionality.of(context)),
        child: card,
      );
    }

    return card;
  }
}
