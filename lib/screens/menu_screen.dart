import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/tt_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/tt_themes.dart';
import '../theme/tt_widgets.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — club edition.
/// Logo, PLAY, mode setup (vs AI difficulty / pass-and-play), theme picker,
/// paddle & ball styles, player renaming, share/rate, settings, PRO.
class MenuScreen extends StatefulWidget {
  final TTAudio audio;
  final TTSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();

  TTSettings get _s => widget.settings;
  TTTheme get _t => TTThemes.byId(_s.themeId, custom: _s.customTheme);

  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.tabletennis';

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Arena.body(15, theme: _t)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  
  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.gameStart();
    final players = [
      TTPlayer(name: _s.playerNames[0], isBot: false),
      TTPlayer(name: _s.playerNames[1], isBot: _s.mode == 0),
    ];
    final engine = TTEngine(
      players: players,
      botDifficulty: TTDifficulty.values[_s.difficulty],
    );
    // App-scoped music: keep playing across screens. GameScreen switches
    // to the game track on entry; we switch back to menu music on return.
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: _s,
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return ArenaBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo plaque.
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/tabletennis_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Table Tennis', style: Arena.display(42, theme: t)),
                  Text(
                    'RALLY • SMASH • REPEAT',
                    style: Arena.label(12, theme: t),
                  ),
                  const SizedBox(height: 22),
                  ArenaButton(
                      label: '▶  Play', onTap: _play, theme: t, width: 260),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProScreen(
                          audio: widget.audio,
                          settings: _s,
                          store: _store,
                        ),
                      ));
                    },
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(colors: [
                          t.accent.withValues(alpha: 0.9),
                          t.accentDark,
                        ]),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '✦  Get PRO',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF241A08),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ModeCard(theme: t, settings: _s, audio: widget.audio),
                  const SizedBox(height: 14),
                  _ThemeCard(theme: t, settings: _s, audio: widget.audio),
                  const SizedBox(height: 14),
                  _GearCard(theme: t, settings: _s, audio: widget.audio),
                  const SizedBox(height: 14),
                  _NamesCard(theme: t, settings: _s, audio: widget.audio),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          widget.audio.click();
                          await Share.share(
                              'Smash some rallies with me in Table Tennis! $_storeUrl');
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          widget.audio.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: _s,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 26),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to Play',
                        onTap: () {
                          widget.audio.click();
                          _showHowTo(context, t);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_s.gamesPlayed > 0)
                    Text(
                      'Wins: ${_s.wins}   •   Games: ${_s.gamesPlayed}${_s.bestRally > 0 ? '   •   Best rally: ${_s.bestRally}' : ''}',
                      style: Arena.label(12, theme: t),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Arena.label(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, TTTheme t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black.withValues(alpha: 0.85),
            border: Border.all(color: t.accent, width: 3),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How to Play', style: Arena.display(24, theme: t)),
                const SizedBox(height: 12),
                for (final line in [
                  '• The ball arcs back and forth — TAP just as it reaches your paddle!',
                  '• Perfect timing = rocket smash. Sloppy timing = into the net. 😬',
                  '• Swipe UP for topspin (fast) or DOWN for backspin (tricky) before tapping.',
                  '• First to 11, win by 2. Serve swaps every 2 points (every point at deuce).',
                  '• Vs the bot? It reads spin… mostly. 🤖',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(line, style: Arena.body(14, theme: t)),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: ArenaButton(
                    label: 'Got it!',
                    width: 180,
                    fontSize: 16,
                    theme: t,
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Renameable player slot. The controller lives in State (never rebuilt away),
/// every keystroke updates in-memory + debounced disk save, and focus loss
/// commits the trimmed name immediately.
class _NameField extends StatefulWidget {
  final TTSettings settings;
  final TTAudio audio;
  final TTTheme theme;
  final int index;
  final bool isBot;
  const _NameField({
    required this.settings,
    required this.audio,
    required this.theme,
    required this.index,
    required this.isBot,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.settings.playerNames[widget.index]);
    _focus = FocusNode();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      // Focus lost: commit the trimmed name right now.
      widget.settings.commitPlayerNames();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Expanded(
      child: TextField(
        controller: _ctrl,
        focusNode: _focus,
        style: Arena.body(16, theme: t),
        decoration: InputDecoration(
          hintText: widget.isBot
              ? 'Bot name'
              : 'Player ${widget.index + 1} name',
          hintStyle: Arena.body(14, theme: t, color: t.muted),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.accent.withValues(alpha: 0.5)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        // Save on EVERY keystroke — not just keyboard-done.
        onChanged: (v) => widget.settings.setPlayerNameLive(widget.index, v),
        onSubmitted: (_) {
          _focus.unfocus(); // triggers commit via focus-loss listener
        },
      ),
    );
  }
}
class _MenuIcon extends StatelessWidget {
  final TTTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: theme.accent, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: theme.accent, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: Arena.label(12, theme: theme)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Mode setup: vs AI (difficulty) or 2-player pass-and-play.
class _ModeCard extends StatelessWidget {
  final TTTheme theme;
  final TTSettings settings;
  final TTAudio audio;
  const _ModeCard(
      {required this.theme, required this.settings, required this.audio});

  @override
  Widget build(BuildContext context) {
    const diffNames = ['Easy', 'Medium', 'Hard'];
    return ArenaCard(
      theme: theme,
      child: Column(
        children: [
          ArenaSection(text: 'Game Mode', theme: theme),
          ArenaChips<int>(
            theme: theme,
            options: const [(0, '🤖 Vs Bot'), (1, '👥 2 Players')],
            value: settings.mode,
            onChanged: (v) {
              audio.click();
              settings.setMode(v);
            },
          ),
          if (settings.mode == 0) ...[
            const SizedBox(height: 14),
            Text('Bot difficulty', style: Arena.label(13, theme: theme)),
            const SizedBox(height: 8),
            ArenaChips<int>(
              theme: theme,
              options: [
                for (int i = 0; i < 3; i++) (i, diffNames[i]),
              ],
              value: settings.difficulty,
              locked: (i) => i == 2 && !settings.isPro,
              onChanged: (v) {
                audio.click();
                settings.setDifficulty(v);
              },
            ),
            if (!settings.isPro)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Hard mode is a PRO feature 🔒',
                  style: Arena.body(12, theme: theme, color: theme.muted),
                ),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Pass the phone — same rally, both players tap! 📱',
                style: Arena.body(13, theme: theme, color: theme.muted),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Table theme picker (grid of swatches) + custom creator entry.
class _ThemeCard extends StatelessWidget {
  final TTTheme theme;
  final TTSettings settings;
  final TTAudio audio;
  const _ThemeCard(
      {required this.theme, required this.settings, required this.audio});

  @override
  Widget build(BuildContext context) {
    final themes = TTThemes.all;
    return ArenaCard(
      theme: theme,
      child: Column(
        children: [
          ArenaSection(text: 'Table Theme', theme: theme),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemCount: themes.length + 1, // + custom creator
            itemBuilder: (_, i) {
              if (i == themes.length) {
                final locked = !settings.isPro;
                final selected = settings.themeId == 'custom';
                return _swatch(
                  selected: selected,
                  locked: locked,
                  label: 'Custom',
                  colors: const [Color(0xFFB03030), Color(0xFF2B5F9E)],
                  theme: theme,
                  onTap: locked
                      ? null
                      : () {
                          audio.click();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CustomThemeScreen(
                              audio: audio,
                              settings: settings,
                            ),
                          ));
                        },
                );
              }
              final th = themes[i];
              final locked = th.pro && !settings.isPro;
              return _swatch(
                selected: settings.themeId == th.id,
                locked: locked,
                label: th.name.split(' ').first,
                colors: [th.tableTop, th.arenaTop],
                theme: theme,
                onTap: locked
                    ? null
                    : () {
                        audio.click();
                        settings.setTheme(th.id);
                      },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _swatch({
    required bool selected,
    required bool locked,
    required String label,
    required List<Color> colors,
    required TTTheme theme,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: locked ? 0.5 : 1.0,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  border: Border.all(
                    color: selected ? theme.accent : Colors.white24,
                    width: selected ? 3 : 1.5,
                  ),
                ),
                child: locked
                    ? const Center(
                        child: Text('🔒', style: TextStyle(fontSize: 16)))
                    : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: Arena.body(10, theme: theme,
                  color: selected ? theme.accent : theme.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Paddle & ball style pickers.
class _GearCard extends StatelessWidget {
  final TTTheme theme;
  final TTSettings settings;
  final TTAudio audio;
  const _GearCard(
      {required this.theme, required this.settings, required this.audio});

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      theme: theme,
      child: Column(
        children: [
          ArenaSection(text: 'Paddle & Ball', theme: theme),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Paddle rubber', style: Arena.label(13, theme: theme)),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: PaddleStyles.all.length,
            itemBuilder: (_, i) {
              final ps = PaddleStyles.all[i];
              final locked = ps.pro && !settings.isPro;
              final selected = settings.paddleStyle == i;
              return GestureDetector(
                onTap: locked
                    ? null
                    : () {
                        audio.click();
                        settings.setPaddleStyle(i);
                      },
                child: Opacity(
                  opacity: locked ? 0.45 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [ps.rubber, ps.handle],
                      ),
                      border: Border.all(
                        color: selected ? theme.accent : Colors.white24,
                        width: selected ? 3 : 1.5,
                      ),
                    ),
                    child: locked
                        ? const Center(
                            child: Text('🔒',
                                style: TextStyle(fontSize: 12)))
                        : null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Ball', style: Arena.label(13, theme: theme)),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: BallStyles.all.length,
            itemBuilder: (_, i) {
              final bs = BallStyles.all[i];
              final locked = bs.pro && !settings.isPro;
              final selected = settings.ballStyle == i;
              return GestureDetector(
                onTap: locked
                    ? null
                    : () {
                        audio.click();
                        settings.setBallStyle(i);
                      },
                child: Opacity(
                  opacity: locked ? 0.45 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bs.color,
                      border: Border.all(
                        color: selected ? theme.accent : bs.seam,
                        width: selected ? 3 : 1.5,
                      ),
                    ),
                    child: locked
                        ? const Center(
                            child: Text('🔒',
                                style: TextStyle(fontSize: 12)))
                        : null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            '${PaddleStyles.names[settings.paddleStyle]} paddle • ${BallStyles.names[settings.ballStyle]} ball',
            style: Arena.body(12, theme: theme, color: theme.muted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Renameable players.
class _NamesCard extends StatelessWidget {
  final TTTheme theme;
  final TTSettings settings;
  final TTAudio audio;
  const _NamesCard(
      {required this.theme, required this.settings, required this.audio});

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      theme: theme,
      child: Column(
        children: [
          ArenaSection(text: 'Players', theme: theme),
          for (int i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.playerColors[i],
                      border: Border.all(color: theme.accent, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      settings.mode == 0 && i == 1 ? '🤖' : '${i + 1}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stable controller: survives rebuilds; saves on every
                  // keystroke, commits on focus loss.
                  _NameField(
                    settings: settings,
                    audio: audio,
                    theme: theme,
                    index: i,
                    isBot: settings.mode == 0 && i == 1,
                  ),
                ],
              ),
            ),
          Text(
            settings.mode == 0
                ? 'Tap a name to rename — the bot keeps its attitude. 🤖'
                : 'Tap a name to rename — pass-and-play! 📱',
            style: Arena.body(12, theme: theme, color: theme.muted),
          ),
        ],
      ),
    );
  }
}
