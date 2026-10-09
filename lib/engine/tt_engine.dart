import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Table Tennis engine: deterministic rally rules, state, and bot AI.
/// UI-agnostic — the UI only renders [notifyListeners] snapshots.
///
/// Phases (engine-owned, watchdog-guarded — stuck states impossible):
/// - [Phase.serve]: waiting for the server to serve. AI serves itself with
///   visible narration; a human serves via [serve].
/// - [Phase.rally]: ball in flight toward the defender. Human taps via
///   [tapHit]; the AI's outcome is precomputed but always shown with a
///   visible swing + narration beat — never silently auto-played.
/// - [Phase.beat]: short narration beat between shots (AI swings, SMASH
///   callouts). No input accepted; always advances on the engine timer.
/// - [Phase.point]: point awarded, brief celebration beat, then next serve.
/// - [Phase.over]: match finished.
class TTPlayer {
  String name;
  final bool isBot;
  TTPlayer({required this.name, required this.isBot});
}

enum Phase { serve, rally, beat, rallyPause, point, over }

/// 0 = easy, 1 = medium, 2 = hard (RULES.md §11).
enum TTDifficulty { easy, medium, hard }

class TTEngine extends ChangeNotifier {
  final List<TTPlayer> players; // exactly 2
  final TTDifficulty botDifficulty;

  final pts = [0, 0];
  int server = 0;
  Phase phase = Phase.serve;
  bool over = false;
  int? winner;

  // Rally flight state (UI renders the ball from these).
  int fromSide = 0;
  int startMs = 0;
  int durationMs = 900;
  double arcH = 0.2;
  int spin = 0; // -1 backspin, 0 flat, 1 topspin
  bool qualityPerfect = false;

  // Human defender input for the in-flight rally.
  bool tapped = false;
  int tapMs = 0; // when the human tapped (ms epoch)
  int pendingSpin = 0; // chosen via swipe before the tap

  // AI defender's precomputed outcome (set at launch).
  bool aiHits = false;
  bool aiPerfect = false;

  String banner = '';
  String narration = ''; // visible "X is lining up…" line
  int rally = 0; // successful returns in the current rally
  int longestRally = 0;
  int gameSmashes = 0;
  int _pendingPoint = -1; // point winner stashed across the celebration beat

  /// UI hook for sounds / haptics. Set by the screen.
  void Function(TTEvent event)? onEvent;

  final _rand = Random();
  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;
  int _pauseMs = 0;

  static const int tapWindowMs = 200;
  static const int perfectMs = 90;

  TTEngine({required this.players, this.botDifficulty = TTDifficulty.medium}) {
    banner = players[server].isBot
        ? '${players[server].name} to serve…'
        : '${players[server].name}, serve when ready!';
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    _afterServePhase();
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;
  int get arrivalMs => startMs + durationMs;
  int get defender => 1 - fromSide;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer (rally flight shifts with the pause).
  /// Resume re-arms the current phase via the watchdog.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _pauseMs = _now;
      _timer?.cancel();
      _timer = null;
    } else {
      final dt = _now - _pauseMs;
      if (phase == Phase.rally) startMs += dt;
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress, recover.
  /// This makes stuck states impossible by construction. Respects [paused].
  /// Human-input phases (serve by human) are legal resting states.
  void _recover() {
    if (_disposed || over || paused || _timer != null) return;
    switch (phase) {
      case Phase.rally:
        _arrive(); // rally with no timer: resolve the arrival immediately
      case Phase.serve:
        _afterServePhase(); // AI serve with no timer: kick it off
      case Phase.beat:
        _afterBeat();
      case Phase.point:
        // Point beat with no timer: award the stashed point, else serve.
        if (_pendingPoint >= 0) {
          _point(_pendingPoint);
        } else {
          _toServe('');
        }
      case Phase.over:
        break;
      case Phase.rallyPause:
        _afterBeat();
    }
  }

  // ------------------------------------------------------------ serve flow
  /// Called whenever we enter the serve phase: bots serve themselves.
  void _afterServePhase() {
    if (over || phase != Phase.serve) return;
    final s = players[server];
    if (s.isBot) {
      narration = '${s.name} is tossing the ball…';
      notifyListeners();
      _arm(const Duration(milliseconds: 1100), () {
        if (over || phase != Phase.serve) return;
        narration = '${s.name} serves! 🏓';
        onEvent?.call(TTEvent.serve);
        notifyListeners();
        _arm(const Duration(milliseconds: 650), _doServe);
      });
    } else {
      narration = '';
      notifyListeners();
    }
  }

  /// Human serve action (tap the Serve button).
  void serve() {
    if (over || phase != Phase.serve || players[server].isBot) return;
    onEvent?.call(TTEvent.serve);
    _doServe();
  }

  void _doServe() {
    if (over || phase != Phase.serve) return;
    narration = '';
    rally = 0;
    _launch(from: server, dur: 1050, arc: 0.22, spin: 0, perfect: false);
  }

  // ------------------------------------------------------------ rally flow
  void _launch({
    required int from,
    required int dur,
    required double arc,
    required int spin,
    required bool perfect,
  }) {
    fromSide = from;
    startMs = _now;
    durationMs = dur;
    arcH = arc;
    this.spin = spin;
    qualityPerfect = perfect;
    tapped = false;
    tapMs = 0;
    pendingSpin = 0;
    final d = defender;
    if (players[d].isBot) {
      // Bot timing error: grows with ball speed, spin trickiness, and
      // shrinks with difficulty. Precomputed so the outcome is fair, but
      // ALWAYS shown with a visible swing + narration — never silent.
      final diff = botDifficulty;
      final sigma = switch (diff) {
        TTDifficulty.easy => 165.0,
        TTDifficulty.medium => 105.0,
        TTDifficulty.hard => 62.0,
      } + (spin != 0 ? 40 : 0) + (dur < 650 ? 30 : 0);
      final err =
          ((_rand.nextDouble() + _rand.nextDouble() + _rand.nextDouble()) / 3 * 2 - 1) *
              sigma * 1.6;
      aiHits = err.abs() <= tapWindowMs;
      aiPerfect = err.abs() <= perfectMs;
    }
    phase = Phase.rally;
    notifyListeners();
    _arm(Duration(milliseconds: dur), _arrive);
  }

  /// Human defender taps to return. Records the swing moment; the outcome is
  /// resolved at arrival so early/late swings visibly miss.
  void tapHit() {
    if (over || phase != Phase.rally || tapped) return;
    if (players[defender].isBot) return;
    tapped = true;
    tapMs = _now;
    onEvent?.call(TTEvent.swing);
    notifyListeners();
  }

  /// Swipe up/down before tapping to choose spin for the return.
  void setSpin(int s) {
    if (over || phase != Phase.rally || tapped) return;
    if (players[defender].isBot) return;
    pendingSpin = s.clamp(-1, 1);
    notifyListeners();
  }

  /// Engine-owned arrival — the UI never calls this. No desync possible.
  void _arrive() {
    if (over || phase != Phase.rally) return;
    final d = defender;
    final attacker = fromSide;
    bool hit;
    bool perfect;
    int useSpin;
    if (players[d].isBot) {
      hit = aiHits;
      perfect = aiPerfect;
      useSpin = 0;
    } else {
      final err = tapped ? (tapMs - arrivalMs).abs() : 1 << 30;
      hit = err <= tapWindowMs;
      perfect = err <= perfectMs;
      useSpin = pendingSpin;
    }
    pendingSpin = 0;
    if (!hit) {
      _miss(d, attacker);
      return;
    }
    rally++;
    if (rally > longestRally) longestRally = rally;
    final isAI = players[d].isBot;
    // Build the return shot.
    int dur;
    double arc;
    int shotSpin;
    String callout;
    if (isAI) {
      // AI shot selection by difficulty (RULES §11): hard plays fast and
      // spins; easy lobs it back gently.
      final fast = botDifficulty == TTDifficulty.hard
          ? (perfect || _rand.nextDouble() < 0.45)
          : botDifficulty == TTDifficulty.medium
              ? (perfect || _rand.nextDouble() < 0.2)
              : false;
      shotSpin = botDifficulty == TTDifficulty.hard && _rand.nextDouble() < 0.4
          ? (_rand.nextBool() ? 1 : -1)
          : 0;
      dur = fast ? 560 + _rand.nextInt(120) : 800 + _rand.nextInt(220);
      arc = fast ? 0.10 : 0.17;
      callout = fast
          ? '${players[d].name} SMASHES it! 💥'
          : '${players[d].name} returns it! 🏓';
      if (fast) gameSmashes++;
    } else {
      final top = useSpin == 1;
      final back = useSpin == -1;
      dur = perfect
          ? (top ? 560 : (back ? 950 : 700))
          : (top ? 720 : 860);
      arc = perfect ? (top ? 0.10 : (back ? 0.22 : 0.14)) : 0.18;
      shotSpin = useSpin;
      callout = perfect ? 'SMASH! 💥' : 'Nice return! 🏓';
      if (perfect) gameSmashes++;
    }
    // Visible narration beat: the swing is SEEN, then the ball flies back.
    phase = Phase.beat;
    banner = callout;
    narration = isAI ? '${players[d].name} is winding up…' : '';
    if (perfect) {
      onEvent?.call(TTEvent.smash);
    } else {
      onEvent?.call(TTEvent.paddleHit);
    }
    final next = _ReturnShot(from: d, dur: dur, arc: arc, spin: shotSpin, perfect: perfect);
    notifyListeners();
    _arm(const Duration(milliseconds: 700), () {
      _afterBeatShot(next);
    });
  }

  void _afterBeatShot(_ReturnShot shot) {
    if (over || phase != Phase.beat) return;
    banner = '';
    narration = '';
    _launch(
      from: shot.from,
      dur: shot.dur,
      arc: shot.arc,
      spin: shot.spin,
      perfect: shot.perfect,
    );
  }

  /// Fallback beat advance (watchdog path when no shot is queued).
  void _afterBeat() {
    if (over || phase != Phase.beat) return;
    banner = '';
    narration = '';
    _toServe('');
  }

  void _miss(int defenderIdx, int attacker) {
    final dName = players[defenderIdx].name;
    final aName = players[attacker].name;
    final aiMissed = players[defenderIdx].isBot;
    phase = Phase.point;
    _pendingPoint = attacker;
    banner = aiMissed
        ? '$dName can\'t reach it! 😅'
        : '$dName ${['into the net! 😬', 'whiffs it! 😅', 'clips the table edge! 😱'][_rand.nextInt(3)]}';
    narration = '$aName takes the point!';
    onEvent?.call(TTEvent.miss);
    notifyListeners();
    _arm(const Duration(milliseconds: 1400), () => _point(attacker));
  }

  void _point(int w) {
    if (over) return;
    _pendingPoint = -1;
    pts[w]++;
    final humanWonPoint = !players[w].isBot;
    onEvent?.call(humanWonPoint ? TTEvent.pointHuman : TTEvent.pointAI);
    if (pts[w] >= 11 && pts[w] - pts[1 - w] >= 2) {
      _finish(w);
      return;
    }
    _toServe(players[w].isBot
        ? '${players[w].name} takes it! 🏓'
        : '${players[w].name} scores!');
  }

  void _toServe(String msg) {
    if (over) return;
    phase = Phase.serve;
    banner = msg;
    narration = '';
    // Official service rotation (RULES §8): every 2 points, every point at deuce.
    final total = pts[0] + pts[1];
    final deuce = pts[0] >= 10 && pts[1] >= 10;
    server = deuce ? (total % 2) : ((total ~/ 2) % 2);
    notifyListeners();
    _afterServePhase();
  }

  void _finish(int w) {
    over = true;
    phase = Phase.over;
    winner = w;
    banner = '${players[w].name} wins ${pts[0]}–${pts[1]}! 🏆';
    narration = 'Table legend. 🏓';
    notifyListeners();
    onEvent?.call(players[w].isBot ? TTEvent.botWon : TTEvent.humanWon);
  }

  void restart() {
    _timer?.cancel();
    paused = false;
    pts[0] = 0;
    pts[1] = 0;
    server = 0;
    phase = Phase.serve;
    over = false;
    winner = null;
    banner = '';
    narration = '';
    rally = 0;
    longestRally = 0;
    gameSmashes = 0;
    tapped = false;
    pendingSpin = 0;
    _pendingPoint = -1;
    notifyListeners();
    _afterServePhase();
  }
}

class _ReturnShot {
  final int from;
  final int dur;
  final double arc;
  final int spin;
  final bool perfect;
  _ReturnShot({
    required this.from,
    required this.dur,
    required this.arc,
    required this.spin,
    required this.perfect,
  });
}

enum TTEvent {
  serve, // serve toss
  swing, // human swung the paddle
  paddleHit, // clean return
  smash, // perfect power return
  miss, // a return missed
  pointHuman,
  pointAI,
  humanWon,
  botWon,
}
