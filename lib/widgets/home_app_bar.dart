import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.userName,
    required this.isDark,
    required this.reminderEnabled,
    required this.refreshing,
    required this.onContact,
    required this.onToggleTheme,
    required this.onToggleReminder,
    required this.onSendTestNotification,
    required this.onRefresh,
    required this.onOpenPerks,
    required this.onOpenMenu,
  });

  final String userName;
  final bool isDark;
  final bool reminderEnabled;
  final bool refreshing;
  final VoidCallback onContact;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleReminder;
  final VoidCallback onSendTestNotification;
  final VoidCallback? onRefresh;
  final VoidCallback onOpenPerks;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final topText = theme.textTheme;
    final cleanName = userName.trim();
    final displayName = cleanName.isEmpty ? 'Friend' : cleanName;

    return SliverAppBar(
      backgroundColor: scheme.background,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      centerTitle: false,
      toolbarHeight: 74,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withOpacity(0.28),
                  scheme.primary.withOpacity(0.16),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(Icons.bolt_rounded, color: scheme.primary, size: 27),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$displayName \u{1F44B}',
                  style: topText.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    fontSize: 20,
                    color: scheme.onSurface.withOpacity(0.94),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _ModernIconButton(
          iconAsset: refreshing ? null : 'assets/in_app_icons/sparkle.png',
          tooltip: refreshing ? 'Loading...' : 'New tasks',
          onTap: onRefresh,
          isDark: isDark,
          isLoading: refreshing,
          tone: _ActionTone.spark,
          filled: true,
        ),
        const SizedBox(width: 8),
        _ModernIconButton(
          iconAsset: 'assets/in_app_icons/premium.png',
          tooltip: 'Perks',
          onTap: onOpenPerks,
          isDark: isDark,
          tone: _ActionTone.premium,
          filled: false,
        ),
        const SizedBox(width: 8),
        _ModernIconButton(
          icon: Icons.menu_rounded,
          tooltip: 'Menu',
          onTap: onOpenMenu,
          isDark: isDark,
          tone: _ActionTone.menu,
          filled: false,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

enum _ActionTone { spark, premium, menu }

class _ModernIconButton extends StatefulWidget {
  const _ModernIconButton({
    this.icon,
    this.iconAsset,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
    required this.tone,
    this.filled = false,
    this.isLoading = false,
  });

  final IconData? icon;
  final String? iconAsset;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isDark;
  final _ActionTone tone;
  final bool filled;
  final bool isLoading;

  @override
  State<_ModernIconButton> createState() => _ModernIconButtonState();
}

class _ModernIconButtonState extends State<_ModernIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = _paletteForTone(widget.tone);

    final backgroundColor = widget.filled
        ? Color.alphaBlend(
            palette.$1.withOpacity(widget.isDark ? 0.16 : 0.12),
            scheme.surface.withOpacity(widget.isDark ? 0.56 : 0.62),
          )
        : scheme.surface.withOpacity(widget.isDark ? 0.52 : 0.62);

    final iconColor = widget.filled
        ? palette.$1.withOpacity(0.96)
        : scheme.onSurface.withOpacity(0.88);

    final disabledColor = widget.isDark
        ? Colors.white.withOpacity(0.3)
        : scheme.onSurface.withOpacity(0.3);
    final glowLevel = (_hovered ? 0.28 : 0.0) + (_pressed ? 0.22 : 0.0);
    final isInteractive = widget.onTap != null;

    return Tooltip(
      message: widget.tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) {
            if (_hovered == value) return;
            setState(() => _hovered = value);
          },
          onHighlightChanged: (value) {
            if (_pressed == value) return;
            setState(() => _pressed = value);
          },
          borderRadius: BorderRadius.circular(13),
          splashColor: scheme.primary.withOpacity(0.08),
          highlightColor: scheme.primary.withOpacity(0.03),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    if (isInteractive)
                      BoxShadow(
                        color: palette.$1.withOpacity(0.06 + glowLevel),
                        blurRadius: 10 + (glowLevel * 18),
                        spreadRadius: -2 + (glowLevel * 2),
                      ),
                  ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.filled
                                  ? Colors.white
                                  : (widget.isDark
                                        ? palette.$1
                                        : scheme.primary),
                            ),
                          ),
                        )
                      : (widget.iconAsset != null
                            ? Image.asset(
                                widget.iconAsset!,
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                                color: widget.onTap == null
                                    ? disabledColor
                                    : iconColor,
                                colorBlendMode: BlendMode.srcIn,
                              )
                            : Icon(
                                widget.icon,
                                size: 22,
                                color: widget.onTap == null
                                    ? disabledColor
                                    : iconColor,
                              )),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

(Color, Color) _paletteForTone(_ActionTone tone) {
  switch (tone) {
    case _ActionTone.spark:
      return (const Color(0xFF3E8BFF), const Color(0xFF3E8BFF));
    case _ActionTone.premium:
      return (const Color(0xFF8B5CF6), const Color(0xFF8B5CF6));
    case _ActionTone.menu:
      return (const Color(0xFF64748B), const Color(0xFF64748B));
  }
}
