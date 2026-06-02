import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme.dart';

class HoverAnimatedElement extends StatefulWidget {
  final Widget child;
  final double scaleOnHover;
  final Duration duration;
  final bool enableGlow;
  final Color? glowColor;
  final double borderRadius;

  const HoverAnimatedElement({
    super.key,
    required this.child,
    this.scaleOnHover = 1.025,
    this.duration = const Duration(milliseconds: 220),
    this.enableGlow = true,
    this.glowColor,
    this.borderRadius = 20,
  });

  @override
  State<HoverAnimatedElement> createState() => _HoverAnimatedElementState();
}

class _HoverAnimatedElementState extends State<HoverAnimatedElement> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? AppTheme.primary;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0) // Floating effect
          ..scale(_isHovered ? widget.scaleOnHover : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isHovered && widget.enableGlow
              ? [
                  BoxShadow(
                    color: glow.withOpacity(0.18),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}
