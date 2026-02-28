import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../app_strings.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.userName,
    required this.isDark,
    required this.onOpenProfile,
    required this.onOpenStats,
    required this.onOpenMenu,
  });

  final String userName;
  final bool isDark;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final cleanName = userName.trim();
    final displayName = cleanName.isEmpty ? l10n.friend : cleanName;
    final greeting = l10n.greetingForHour(DateTime.now().hour);

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      floating: true,
      snap: true,
      pinned: false,
      centerTitle: false,
      toolbarHeight: 68,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      flexibleSpace: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(11, 15, 26, 0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.25),
                    blurRadius: 30,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenProfile,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF5B6CFF), Color(0xFF8FD3FF)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: Colors.white.withOpacity(0.92),
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$greeting, ',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.22,
                            fontSize: 15.5,
                            color: scheme.onSurface.withOpacity(0.78),
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.28,
                            fontSize: 17.5,
                            color: scheme.onSurface.withOpacity(0.98),
                            height: 1.1,
                            shadows: const [
                              Shadow(
                                color: Color.fromRGBO(5, 8, 18, 0.28),
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        _GlassIconButton(
          icon: Icons.bar_chart_rounded,
          tooltip: l10n.stats,
          onTap: onOpenStats,
          isDark: isDark,
          emphasis: _IconEmphasis.primary,
        ),
        const SizedBox(width: 8),
        _GlassIconButton(
          icon: Icons.menu_rounded,
          tooltip: l10n.menu,
          onTap: onOpenMenu,
          isDark: isDark,
          emphasis: _IconEmphasis.secondary,
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _IconEmphasis { primary, secondary }

class _GlassIconButton extends StatefulWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
    required this.emphasis,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isDark;
  final _IconEmphasis emphasis;

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabledColor = widget.isDark
        ? Colors.white.withOpacity(0.3)
        : scheme.onSurface.withOpacity(0.3);
    final isPrimary = widget.emphasis == _IconEmphasis.primary;
    final iconColor = widget.onTap == null
        ? disabledColor
        : (isPrimary
              ? scheme.onSurface.withOpacity(_pressed ? 0.96 : 0.80)
              : scheme.onSurfaceVariant.withOpacity(_pressed ? 0.82 : 0.70));

    return Tooltip(
      message: widget.tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: BorderRadius.circular(15),
          splashColor: scheme.primary.withOpacity(0.08),
          highlightColor: scheme.primary.withOpacity(0.03),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: const Color.fromRGBO(255, 255, 255, 0.04),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.10),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    scale: _pressed ? 1.04 : 1.0,
                    child: Icon(widget.icon, size: 20, color: iconColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}




