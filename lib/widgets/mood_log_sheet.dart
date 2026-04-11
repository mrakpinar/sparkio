import 'dart:ui';
import 'package:flutter/material.dart';

class MoodLogSheet extends StatelessWidget {
  const MoodLogSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F141E).withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "You're all done!",
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "How are you feeling today?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MoodEmoji(emoji: '😖', value: 1, label: 'Struggling'),
                      _MoodEmoji(emoji: '😕', value: 2, label: 'Low'),
                      _MoodEmoji(emoji: '😐', value: 3, label: 'Neutral'),
                      _MoodEmoji(emoji: '🙂', value: 4, label: 'Good'),
                      _MoodEmoji(emoji: '🤩', value: 5, label: 'Amazing'),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodEmoji extends StatefulWidget {
  const _MoodEmoji({required this.emoji, required this.value, required this.label});
  
  final String emoji;
  final int value;
  final String label;

  @override
  State<_MoodEmoji> createState() => _MoodEmojiState();
}

class _MoodEmojiState extends State<_MoodEmoji> {
  bool _isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop(widget.value);
        },
        child: AnimatedScale(
          scale: _isHovering ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _isHovering ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 4,
                    )
                  ] : null,
                ),
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: _isHovering ? 1.0 : 0.6,
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
