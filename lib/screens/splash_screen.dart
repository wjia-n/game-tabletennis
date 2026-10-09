import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/tt_themes.dart';
import '../theme/tt_widgets.dart';
import 'menu_screen.dart';

/// Single launch splash in two moments:
/// 1. Company splash — the official WAJIHA logo, shown unaltered.
/// 2. Game splash — logo + name, animated loading line, "Credits: WAJIHA".
class SplashScreen extends StatefulWidget {
  final TTAudio audio;
  final TTSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyPhase = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    // Company moment: ~1.2s with the official WAJIHA logo, then the game.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _companyPhase = false);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TTThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    if (_companyPhase) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (_, v, _) => Opacity(
                  opacity: v,
                  child: Image.asset(
                    'assets/wajiha_logo.png',
                    width: 190,
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'WAJIHA',
                style: Arena.label(22, theme: theme),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: ArenaBackdrop(
        theme: theme,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.accent, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      offset: Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/tabletennis_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 22),
              Text('Table Tennis', style: Arena.display(46, theme: theme)),
              const SizedBox(height: 6),
              Text(
                'RALLY • SMASH • REPEAT',
                style: Arena.label(13, theme: theme),
              ),
              const SizedBox(height: 30),
              // Animated loading line.
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: _loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                              color: theme.accent.withValues(alpha: 0.5)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                colors: [
                                  theme.accent,
                                  theme.accentDark,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _loader.value < 1
                            ? 'Chalking the paddles…'
                            : 'Ready!',
                        style: Arena.body(13,
                            theme: theme,
                            color: theme.text.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Credits: WAJIHA',
                    style: Arena.label(14, theme: theme),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
