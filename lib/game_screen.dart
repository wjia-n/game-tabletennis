import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Table Tennis - tap at the perfect moment, add spin with a swipe.
class TableTennisScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const TableTennisScreen({super.key, required this.players, required this.callbacks});

  @override
  State<TableTennisScreen> createState() => _TableTennisScreenState();
}

class _TableTennisScreenState extends State<TableTennisScreen> {
  final _rnd = Random();
  Timer? _timer;

  final pts = [0, 0];
  int server = 0;
  bool over = false;

  String phase = 'serve'; // serve | rally
  String banner = '';
  int pendingSpin = 0; // -1 backspin, 0 flat, 1 topspin

  // ball flight
  int fromSide = 0;
  int startMs = 0;
  int durationMs = 900;
  double arcH = 0.2;
  int spin = 0;
  bool tapped = false;
  int tapErr = 9999;
  // bot's precomputed response
  bool botHits = false;
  int botQuality = 0; // 0 good, 1 perfect

  double _progress = 0;

  @override
  void initState() {
    super.initState();
    widget.callbacks.setActivePlayer(0);
    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _toServe(''));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;

  void _tick(Timer t) {
    if (!mounted || over || phase != 'rally') return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final p = (_now - startMs) / durationMs;
    setState(() => _progress = p.clamp(0.0, 1.0));
    if (p >= 1) _arrive();
  }

  void _launch({required int from, required int dur, required double arc, required int spin}) {
    fromSide = from;
    startMs = _now;
    durationMs = dur;
    arcH = arc;
    this.spin = spin;
    tapped = false;
    tapErr = 9999;
    _progress = 0;
    final defender = 1 - from;
    if (widget.players[defender].isBot) {
      // bot reaction: error grows with ball speed and trickiness
      final sigma = (spin == -1 ? 105 : 70) + (dur < 650 ? 35 : 0);
      final err = ((_rnd.nextDouble() + _rnd.nextDouble() + _rnd.nextDouble()) / 3 * 2 - 1) * sigma * 1.6;
      botHits = err.abs() <= 200;
      botQuality = err.abs() <= 90 ? 1 : 0;
    }
    setState(() => phase = 'rally');
  }

  void _onTap() {
    if (over || phase != 'rally' || tapped) return;
    final defender = 1 - fromSide;
    if (widget.players[defender].isBot) return;
    tapped = true;
    tapErr = (_now - (startMs + durationMs)).abs();
    if (tapErr <= 200) {
      Sfx.tap();
    }
    // whiffs resolve at arrival
  }

  void _arrive() {
    if (over || phase != 'rally') return;
    final defender = 1 - fromSide;
    final attacker = fromSide;
    bool hit;
    int quality; // 0 good, 1 perfect
    int useSpin;
    if (widget.players[defender].isBot) {
      hit = botHits;
      quality = botQuality;
      useSpin = 0;
    } else {
      hit = tapped && tapErr <= 200;
      quality = tapErr <= 90 ? 1 : 0;
      useSpin = pendingSpin;
    }
    setState(() => pendingSpin = 0);
    if (!hit) {
      _point(attacker, missed: true);
      return;
    }
    // return the ball!
    final top = useSpin == 1;
    final back = useSpin == -1;
    final dur = quality == 1
        ? (top ? 550 : (back ? 950 : 700))
        : (top ? 700 : 850);
    final arc = quality == 1 ? (top ? 0.10 : (back ? 0.22 : 0.14)) : 0.18;
    if (quality == 1) {
      Sfx.click();
      setState(() => banner = defender == 0 ? 'SMASH! 💥' : '');
    }
    _launch(from: defender, dur: dur, arc: arc, spin: useSpin);
  }

  void _serveTap() {
    if (over || phase != 'serve') return;
    Sfx.tap();
    _launch(from: server, dur: 950, arc: 0.2, spin: 0);
  }

  void _point(int w, {bool missed = false}) {
    pts[w]++;
    widget.players[w].score = pts[w];
    widget.callbacks.refreshHud();
    if (pts[w] >= 11 && pts[w] - pts[1 - w] >= 2) {
      _finish(w);
      return;
    }
    if (w == 0) {
      Sfx.win();
    } else {
      Sfx.lose();
    }
    server = ((pts[0] + pts[1]) ~/ 2) % 2;
    _toServe(missed
        ? '${widget.players[w].name} takes it! 🏓'
        : '${widget.players[w].name} scores!');
  }

  void _toServe(String msg) {
    if (!mounted || over) return;
    setState(() {
      phase = 'serve';
      banner = msg;
      _progress = 0;
    });
    widget.callbacks.setActivePlayer(server);
    if (widget.players[server].isBot) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || over || phase != 'serve') return;
        _serveTap();
      });
    }
  }

  void _finish(int w) {
    setState(() => over = true);
    Sfx.win();
    final p = widget.players[w];
    widget.callbacks.finish(
      winner: p,
      headline: '${p.name} wins ${pts[0]}–${pts[1]}! 🏆',
      subline: 'Lightning reflexes. Table legend. 🏓',
    );
  }

  String get _spinLabel =>
      pendingSpin == 1 ? 'Topspin 🌀' : (pendingSpin == -1 ? 'Backspin 🍃' : 'Flat ➖');

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final defender = 1 - fromSide;
    final incomingToHuman = phase == 'rally' &&
        !widget.players[defender].isBot &&
        !tapped &&
        _progress > 0.5;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text('${pts[0]}  —  ${pts[1]}',
              style: TextStyle(color: t.text, fontSize: 34, fontWeight: FontWeight.w900)),
          Text(
            pts[0] >= 10 && pts[1] >= 10 ? 'Deuce — win by 2!' : 'First to 11 • ${widget.players[server].name} serves',
            style: TextStyle(color: t.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 26,
            child: Text(banner,
                style: TextStyle(color: t.accent, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GestureDetector(
              onTap: _onTap,
              onVerticalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v.abs() < 200) return;
                setState(() => pendingSpin = v < 0 ? 1 : -1);
                Sfx.click();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: t.radius,
                  border: Border.all(color: t.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: Stack(
                  children: [
                    _table(t),
                    // tap prompt
                    if (incomingToHuman)
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.2),
                          duration: const Duration(milliseconds: 400),
                          builder: (_, s, _) => Transform.scale(
                            scale: s,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: t.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('TAP! 👆',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
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
          if (phase == 'serve' && !over)
            widget.players[server].isBot
                ? Text('${widget.players[server].name} serving…',
                    style: TextStyle(color: t.muted, fontSize: 14))
                : WajihaButton(label: 'Serve', emoji: '🏓', primary: true, onTap: _serveTap),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: t.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.primary.withValues(alpha: 0.3)),
                ),
                child: Text('Spin: $_spinLabel', style: TextStyle(color: t.text, fontSize: 13)),
              ),
            ],
          ),
          Text('Tap when the ball reaches you • swipe ↑/↓ for spin',
              style: TextStyle(color: t.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _table(GameTheme t) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth, h = c.maxHeight;
        const tableY = 0.62;
        final fromX = fromSide == 0 ? 0.10 : 0.90;
        final toX = fromSide == 0 ? 0.90 : 0.10;
        final p = _progress;
        final bx = fromX + (toX - fromX) * p;
        final by = tableY - sin(pi * p) * arcH;
        final showBall = phase == 'rally';
        return Stack(
          children: [
            // table surface
            Positioned(
              left: 16, right: 16,
              top: h * (tableY - 0.035), height: h * 0.07,
              child: Container(
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.text.withValues(alpha: 0.5), width: 2),
                ),
              ),
            ),
            // net
            Positioned(
              left: w * 0.5 - 2, top: h * (tableY - 0.16),
              width: 4, height: h * 0.16,
              child: Container(color: t.text.withValues(alpha: 0.7)),
            ),
            // paddles
            Positioned(
              left: w * 0.055 - 20, top: h * tableY - 24,
              child: _paddle(widget.players[0].color, true),
            ),
            Positioned(
              left: w * 0.945 - 20, top: h * tableY - 24,
              child: _paddle(widget.players[1].color, false),
            ),
            // ball
            if (showBall)
              Positioned(
                left: bx * w - 12, top: by * h - 12,
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: t.muted, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6)],
                  ),
                ),
              ),
            // serve hint ball at server paddle
            if (phase == 'serve')
              Positioned(
                left: (server == 0 ? w * 0.055 : w * 0.945) - 12,
                top: h * tableY - 60,
                child: const Text('🏓', style: TextStyle(fontSize: 24)),
              ),
          ],
        );
      },
    );
  }

  Widget _paddle(Color color, bool left) {
    return Container(
      width: 40, height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8)],
      ),
      child: const Center(child: Text('🏓', style: TextStyle(fontSize: 20))),
    );
  }
}
