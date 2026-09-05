import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores arcade retro para Janosos Game
class RetroColors {
  const RetroColors._();

  static const Color cyan = Color(0xFF29FFE4);
  static const Color cyanDim = Color(0xFF0D6E62);
  static const Color magenta = Color(0xFFFF0055);
  static const Color gold = Color(0xFFFFB300);
  static const Color goldLight = Color(0xFFFFD54F);
  static const Color green = Color(0xFF00FF66);
  static const Color bgDark = Color(0xFF050A10);
  static const Color panelBg = Color(0xFF0C1420);
  static const Color panelBgLight = Color(0xFF132032);
  static const Color borderSubtle = Color(0xFF1B2E46);
  static const Color textBright = Color(0xFFEAFBFF);
  static const Color textMuted = Color(0xFF7A9BB8);
}

/// Helper para cargar los nuevos iconos de interfaz 8-bit con pixelado nítido y respaldo automático
class PixelIconAsset extends StatelessWidget {
  const PixelIconAsset({
    super.key,
    required this.assetName,
    this.size = 28,
    this.semanticLabel,
    this.fallbackIcon,
    this.fallbackColor,
  });

  final String assetName;
  final double size;
  final String? semanticLabel;
  final IconData? fallbackIcon;
  final Color? fallbackColor;

  static const String coin = 'assets/images/ui_coin_pixel.png';
  static const String trophy = 'assets/images/ui_trophy_pixel.png';
  static const String gamepad = 'assets/images/ui_gamepad_pixel.png';
  static const String heart = 'assets/images/ui_pixel_heart.png';
  static const String panelBg = 'assets/images/ui_retro_panel_bg.png';

  IconData _defaultIcon() {
    return switch (assetName) {
      coin => Icons.monetization_on,
      trophy => Icons.emoji_events,
      gamepad => Icons.sports_esports,
      heart => Icons.favorite,
      _ => Icons.videogame_asset,
    };
  }

  Color _defaultColor() {
    return switch (assetName) {
      coin => RetroColors.gold,
      trophy => RetroColors.gold,
      gamepad => RetroColors.cyan,
      heart => RetroColors.magenta,
      _ => RetroColors.cyan,
    };
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = fallbackColor ?? _defaultColor();
    final effectiveIcon = fallbackIcon ?? _defaultIcon();

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetName,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) =>
            Icon(effectiveIcon, size: size * 0.85, color: effectiveColor),
      ),
    );
  }
}

/// Tarjeta / panel arcade con sombra dura 3D estilo consola retro
class RetroArcadeCard extends StatelessWidget {
  const RetroArcadeCard({
    super.key,
    required this.child,
    this.borderColor = RetroColors.cyan,
    this.backgroundColor = RetroColors.panelBg,
    this.accentHeaderColor,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.glow = false,
    this.height,
  });

  final Widget child;
  final Color borderColor;
  final Color backgroundColor;
  final Color? accentHeaderColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool glow;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: accentHeaderColor != null
            ? Border(
                top: BorderSide(color: accentHeaderColor!, width: 4),
                left: BorderSide(color: borderColor, width: 2),
                right: BorderSide(color: borderColor, width: 2),
                bottom: BorderSide(color: borderColor, width: 2),
              )
            : Border.all(color: borderColor, width: 2),
        boxShadow: [
          // Sombra de píxel dura (hard arcade drop shadow)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
          if (glow)
            BoxShadow(
              color: borderColor.withValues(alpha: 0.35),
              offset: Offset.zero,
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: borderColor.withValues(alpha: 0.2),
          highlightColor: borderColor.withValues(alpha: 0.1),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Botón estilo máquina arcade con relieve 3D, texto tipográfico 8-bit y ajuste responsivo
class RetroArcadeButton extends StatefulWidget {
  const RetroArcadeButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.primaryColor = RetroColors.cyan,
    this.textColor = Colors.black,
    this.icon,
    this.pixelIcon,
    this.isFullWidth = false,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final String text;
  final VoidCallback? onPressed;
  final Color primaryColor;
  final Color textColor;
  final IconData? icon;
  final Widget? pixelIcon;
  final bool isFullWidth;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  State<RetroArcadeButton> createState() => _RetroArcadeButtonState();
}

class _RetroArcadeButtonState extends State<RetroArcadeButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final baseColor = enabled ? widget.primaryColor : Colors.grey.shade800;
    final currentTextColor = enabled ? widget.textColor : Colors.grey.shade500;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(
            _isPressed ? 3 : 0,
            _isPressed ? 3 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: baseColor,
            border: Border.all(
              color: _isHovered ? Colors.white : Colors.black,
              width: 2,
            ),
            boxShadow: _isPressed || !enabled
                ? []
                : [
                    const BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                    if (_isHovered)
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.5),
                        offset: const Offset(2, 2),
                        blurRadius: 8,
                      ),
                  ],
          ),
          padding: widget.padding,
          child: Row(
            mainAxisSize: widget.isFullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.pixelIcon != null) ...[
                widget.pixelIcon!,
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: currentTextColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.text.toUpperCase(),
                    style: GoogleFonts.pressStart2p(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      color: currentTextColor,
                      letterSpacing: 1.0,
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
}

/// Badge pixelado retro (etiqueta 8-bit)
class RetroBadge extends StatelessWidget {
  const RetroBadge({
    super.key,
    required this.text,
    this.color = RetroColors.cyan,
    this.backgroundColor,
    this.fontSize = 9,
    this.icon,
  });

  final String text;
  final Color color;
  final Color? backgroundColor;
  final double fontSize;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Text(
            text.toUpperCase(),
            style: GoogleFonts.pressStart2p(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Marquee / Título con estilo de gabinete arcade con luces de neón
class RetroArcadeMarquee extends StatelessWidget {
  const RetroArcadeMarquee({
    super.key,
    required this.title,
    this.subtitle,
    this.color = RetroColors.cyan,
  });

  final String title;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF070D16),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          const BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            offset: Offset.zero,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('★ ', style: TextStyle(color: color, fontSize: 14)),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.pressStart2p(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.8), blurRadius: 10),
                  ],
                ),
              ),
              Text(' ★', style: TextStyle(color: color, fontSize: 14)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: GoogleFonts.vt323(
                fontSize: 16,
                color: RetroColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
