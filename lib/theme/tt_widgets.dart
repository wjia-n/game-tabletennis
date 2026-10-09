import 'package:flutter/material.dart';
import 'tt_themes.dart';

/// Shared arena UI kit — warm sports-hall look, physical depth.
class Arena {
  static TextStyle display(double size, {required TTTheme theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: theme.text,
        letterSpacing: 0.5,
        shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)],
      );

  static TextStyle label(double size, {required TTTheme theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme.accent,
        letterSpacing: 1.2,
      );

  static TextStyle body(double size, {required TTTheme theme, Color? color}) =>
      TextStyle(fontSize: size, color: color ?? theme.text, height: 1.45);
}

/// Arena backdrop: wall gradient + subtle floor line.
class ArenaBackdrop extends StatelessWidget {
  final TTTheme theme;
  final Widget child;
  const ArenaBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.arenaTop, theme.arenaBottom],
        ),
      ),
      child: child,
    );
  }
}

/// Wood-trimmed card panel.
class ArenaCard extends StatelessWidget {
  final TTTheme theme;
  final Widget child;
  final EdgeInsets padding;
  const ArenaCard({
    super.key,
    required this.theme,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(color: theme.accent.withValues(alpha: 0.7), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 10)
        ],
      ),
      child: child,
    );
  }
}

/// Big physical button.
class ArenaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final TTTheme theme;
  final double width;
  final double fontSize;
  const ArenaButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    this.width = 260,
    this.fontSize = 19,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.accent, theme.accentDark],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black54, offset: Offset(0, 5), blurRadius: 10)
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF241A08),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Section header label.
class ArenaSection extends StatelessWidget {
  final String text;
  final TTTheme theme;
  const ArenaSection({super.key, required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 26, height: 3, color: theme.accent),
          const SizedBox(width: 10),
          Text(text.toUpperCase(), style: Arena.label(14, theme: theme)),
        ],
      ),
    );
  }
}

/// Segmented choice chips (difficulty, modes).
class ArenaChips<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final TTTheme theme;
  final bool Function(T)? locked;
  const ArenaChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.theme,
    this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final (v, label) in options)
          Builder(builder: (_) {
            final isLocked = locked?.call(v) ?? false;
            final selected = value == v;
            return GestureDetector(
              onTap: isLocked ? null : () => onChanged(v),
              child: Opacity(
                opacity: isLocked ? 0.55 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: selected
                        ? theme.accent.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.35),
                    border: Border.all(
                      color: selected ? theme.accent : theme.muted.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    isLocked ? '$label 🔒' : label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: selected ? const Color(0xFF241A08) : theme.text,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
