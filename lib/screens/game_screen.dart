import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../engine/tt_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/tt_themes.dart';
import '../theme/tt_widgets.dart';

/// Table Tennis match screen — renders the engine, owns nothing.
/// Every rally beat is visible: AI swings with narration, smashes get
/// callouts, misses play out. Nothing is silently auto-played.
class GameScreen extends StatefulWidget {
  final TTEngine engine;
  final TTAudio audio;
  final TTSettings settings;

  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  TTEngine get _e => widget.engine;
  TTTheme get _t =>
      TTThemes.byId(widget.settings.themeId, custom: widget.settings.customTheme);

  Timer? _tick; // ball + paddle animation driver
  double _progress = 0;
  bool _bounced = false;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _e.onEvent = _onEvent;
    widget.audio.startGameMusic();
    _e.addListener(_onEngine);
    _tick = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted || _e.over) return;
      if (_e.phase == Phase.rally) {
        final p = ((_nowMs() - _e.startMs) / _e.durationMs).clamp(0.0, 1.0);
        if (p >= 0.75 && !_bounced) {
          _bounced = true;
          widget.audio.tableBounce();
        }
        setState(() => _progress = p);
      } else {
        if (_progress != 0 && _e.phase == Phase.serve) {
          setState(() => _progress = 0);
        }
      }
    });
  }

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  void _onEngine() {
    if (!mounted) return;
    if (_e.phase != Phase.rally) _bounced = false;
    if (_e.over && !_resultShown) {
      _resultShown = true;
      _onMatchOver();
    }
    setState(() {});
  }

  void _onEvent(TTEvent ev) {
    final a = widget.audio;
    switch (ev) {
      case TTEvent.serve:
        a.serveToss();
      case TTEvent.swing:
        a.click();
      case TTEvent.paddleHit:
        a.paddleHit();
      case TTEvent.smash:
        a.smash();
      case TTEvent.miss:
        a.net();
      case TTEvent.pointHuman:
        a.paddleHit();
      case TTEvent.pointAI:
        a.tableBounce();
      case TTEvent.humanWon:
        a.win();
      case TTEvent.botWon:
        a.lose();
    }
  }

  Future<void> _onMatchOver() async {
    final w = _e.winner ?? 0;
    final humanWon = !_e.players[w].isBot;
    await widget.settings.recordGame(
      humanWon: humanWon,
      rally: _e.longestRally,
      gameSmashes: _e.gameSmashes,
    );
    // Sensible review moment: a human just won a match, a few games in.
    if (humanWon && widget.settings.gamesPlayed >= 3) {
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.black.withValues(alpha: 0.88),
            border: Border.all(color: _t.accent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(humanWon ? '🏆' : '😅',
                  style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(
                humanWon
                    ? '${_e.players[w].name} wins!'
                    : '${_e.players[w].name} takes the match!',
                style: Arena.display(26, theme: _t),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Final: ${_e.pts[0]} – ${_e.pts[1]}',
                style: Arena.label(16, theme: _t),
              ),
              if (_e.longestRally >= 4)
                Text(
                  'Longest rally: ${_e.longestRally} shots 🔥',
                  style: Arena.body(14, theme: _t),
                ),
              const SizedBox(height: 18),
              ArenaButton(
                label: '🔄  Play Again',
                width: 220,
                fontSize: 17,
                theme: _t,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _resultShown = false;
                  _e.restart();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  widget.audio.click();
                  Navigator.of(context).pop(); // dialog
                  Navigator.of(context).pop(); // game screen
                },
                child: Text('Back to menu',
                    style: Arena.label(15, theme: _t)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the rally when the app is interrupted; the user resumes manually.
    if (state == AppLifecycleState.paused && !_e.over) {
      _e.setPaused(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _e.removeListener(_onEngine);
    _e.onEvent = null;
    _e.dispose();
    super.dispose();
  }

  void _showPause() {
    _e.setPaused(true);
    widget.audio.click();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.black.withValues(alpha: 0.88),
            border: Border.all(color: _t.accent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⏸ Paused', style: Arena.display(26, theme: _t)),
              const SizedBox(height: 6),
              Text('${_e.pts[0]} – ${_e.pts[1]}',
                  style: Arena.label(16, theme: _t)),
              const SizedBox(height: 18),
              ArenaButton(
                label: '▶  Resume',
                width: 220,
                fontSize: 17,
                theme: _t,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _e.setPaused(false);
                },
              ),
              const SizedBox(height: 10),
              ArenaButton(
                label: '🔄  Restart',
                width: 220,
                fontSize: 17,
                theme: _t,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _e.restart();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  widget.audio.click();
                  Navigator.of(context).pop(); // dialog
                  Navigator.of(context).pop(); // game screen
                },
                child:
                    Text('Quit match', style: Arena.label(15, theme: _t)),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // If the dialog was dismissed any other way, stay paused-safe.
      if (mounted && _e.paused && !_e.over) {
        // The Resume/Restart buttons already handled unpausing.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final e = _e;
    final defender = e.defender;
    final incomingToHuman =
        e.phase == Phase.rally && !e.players[defender].isBot && !e.tapped;
    final deuce = e.pts[0] >= 10 && e.pts[1] >= 10;
    return ArenaBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.text),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Table Tennis', style: Arena.label(18, theme: t)),
          centerTitle: true,
          actions: [
            if (!e.over)
              IconButton(
                icon: Icon(Icons.pause, color: t.text),
                onPressed: _showPause,
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Scoreboard.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _scoreChip(0, t, active: e.server == 0),
                    Text('—',
                        style: Arena.display(28, theme: t)),
                    _scoreChip(1, t, active: e.server == 1),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  deuce
                      ? 'Deuce — win by 2! ${e.players[e.server].name} serves'
                      : 'First to 11 • ${e.players[e.server].name} serves',
                  style: Arena.body(12, theme: t, color: t.muted),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 30,
                  child: Text(e.banner,
                      style: Arena.display(17, theme: t),
                      textAlign: TextAlign.center),
                ),
                SizedBox(
                  height: 22,
                  child: Text(e.narration,
                      style: Arena.body(13, theme: t, color: t.muted),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: e.tapHit,
                    onVerticalDragEnd: (d) {
                      final v = d.primaryVelocity ?? 0;
                      if (v.abs() < 200) return;
                      e.setSpin(v < 0 ? 1 : -1);
                      widget.audio.click();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withValues(alpha: 0.25),
                        border: Border.all(
                            color: t.accent.withValues(alpha: 0.4), width: 2),
                      ),
                      child: Stack(
                        children: [
                          _table(t),
                          if (incomingToHuman && _progress > 0.5)
                            Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.85, end: 1.15),
                                duration:
                                    const Duration(milliseconds: 380),
                                builder: (_, s, _) => Transform.scale(
                                  scale: s,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: t.accent,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: const Text('TAP! 👆',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white)),
                                  ),
                                ),
                                onEnd: () {},
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (e.phase == Phase.serve && !e.over)
                  e.players[e.server].isBot
                      ? Text('${e.players[e.server].name} serving…',
                          style: Arena.body(14, theme: t, color: t.muted))
                      : ArenaButton(
                          label: '🏓  Serve',
                          width: 220,
                          fontSize: 17,
                          theme: t,
                          onTap: () {
                            widget.audio.click();
                            e.serve();
                          },
                        ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: t.accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Spin: ${_spinLabel(e.pendingSpin)}',
                        style: Arena.body(13, theme: t),
                      ),
                    ),
                  ],
                ),
                Text('Tap when the ball reaches you • swipe ↑/↓ for spin',
                    style: Arena.body(12, theme: t, color: t.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreChip(int i, TTTheme t, {required bool active}) {
    final e = _e;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: active
            ? t.accent.withValues(alpha: 0.85)
            : Colors.black.withValues(alpha: 0.35),
        border: Border.all(
            color: active ? t.accent : t.muted.withValues(alpha: 0.4),
            width: 2),
      ),
      child: Column(
        children: [
          Text(
            e.players[i].name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active ? const Color(0xFF241A08) : t.text,
            ),
          ),
          Text(
            '${e.pts[i]}',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: active ? const Color(0xFF241A08) : t.text,
            ),
          ),
        ],
      ),
    );
  }

  String _spinLabel(int s) =>
      s == 1 ? 'Topspin 🌀' : (s == -1 ? 'Backspin 🍃' : 'Flat ➖');

  Widget _table(TTTheme t) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth, h = c.maxHeight;
        const tableY = 0.62;
        final fromX = _e.fromSide == 0 ? 0.10 : 0.90;
        final toX = _e.fromSide == 0 ? 0.90 : 0.10;
        final p = _progress;
        final bx = fromX + (toX - fromX) * p;
        final by = tableY - sin(pi * p) * _e.arcH;
        final showBall = _e.phase == Phase.rally;
        final ballStyle = BallStyles.all[widget.settings.ballStyle
            .clamp(0, BallStyles.all.length - 1)];
        final paddleStyle = PaddleStyles.all[widget.settings.paddleStyle
            .clamp(0, PaddleStyles.all.length - 1)];
        return Stack(
          children: [
            // table surface
            Positioned(
              left: 16,
              right: 16,
              top: h * (tableY - 0.035),
              height: h * 0.07,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [t.tableTop, t.tableTopDark],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.tableLine, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 6),
                        blurRadius: 10)
                  ],
                ),
                child: CustomPaint(painter: _TableLines(t)),
              ),
            ),
            // net
            Positioned(
              left: w * 0.5 - 2,
              top: h * (tableY - 0.16),
              width: 4,
              height: h * 0.16,
              child: Container(
                decoration: BoxDecoration(
                  color: t.net.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // paddles (defender's paddle winds up just before arrival)
            Positioned(
              left: w * 0.055 - 20,
              top: h * tableY - 24 + _paddleBob(0),
              child: _paddle(paddleStyle, _e.defender == 0 && _windingUp()),
            ),
            Positioned(
              left: w * 0.945 - 20,
              top: h * tableY - 24 + _paddleBob(1),
              child: _paddle(paddleStyle, _e.defender == 1 && _windingUp()),
            ),
            // ball with shadow
            if (showBall) ...[
              Positioned(
                left: bx * w - 10,
                top: h * (tableY + 0.045) - 6,
                child: Container(
                  width: 20,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(
                        alpha: 0.30 * (1 - (tableY - by).clamp(0.0, 1.0))),
                  ),
                ),
              ),
              Positioned(
                left: bx * w - 12,
                top: by * h - 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.35),
                      colors: [Colors.white, ballStyle.color],
                    ),
                    border:
                        Border.all(color: ballStyle.seam, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black38,
                          offset: Offset(0, 3),
                          blurRadius: 6)
                    ],
                  ),
                ),
              ),
            ],
            // serve hint ball at server paddle
            if (_e.phase == Phase.serve)
              Positioned(
                left: (_e.server == 0 ? w * 0.055 : w * 0.945) - 12,
                top: h * tableY - 62,
                child: const Text('🏓', style: TextStyle(fontSize: 24)),
              ),
          ],
        );
      },
    );
  }

  /// True when the AI defender is visibly winding up for the swing.
  bool _windingUp() {
    final e = _e;
    if (e.phase != Phase.rally) return false;
    if (!e.players[e.defender].isBot) return false;
    final remain = e.arrivalMs - _nowMs();
    return remain < 450 && remain > 0;
  }

  /// Paddle bob: AI paddle lunges toward the incoming ball while winding up.
  double _paddleBob(int seat) {
    if (!_windingUp() || _e.defender != seat) return 0;
    final remain = (_e.arrivalMs - _nowMs()).clamp(0, 450);
    final k = 1 - remain / 450; // 0 → 1 as arrival nears
    final dir = seat == 0 ? 1 : -1; // lunge toward the table center
    return -6 * k + dir * 10 * k;
  }

  Widget _paddle(PaddleStyle ps, bool windingUp) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: windingUp ? 46 : 40,
      height: windingUp ? 54 : 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ps.rubber, ps.handle],
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2.5),
        boxShadow: [
          BoxShadow(
              color: ps.rubber.withValues(alpha: 0.45), blurRadius: 8)
        ],
      ),
      child: const Center(
          child: Text('🏓', style: TextStyle(fontSize: 20))),
    );
  }
}

/// White table lines (center line + edges) painted over the surface.
class _TableLines extends CustomPainter {
  final TTTheme t;
  _TableLines(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = t.tableLine.withValues(alpha: 0.9)
      ..strokeWidth = 2;
    // center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TableLines old) => old.t != t;
}
