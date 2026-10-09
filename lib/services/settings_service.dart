import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/tt_themes.dart';

/// Persisted settings + stats for Table Tennis. Survives app restarts.
///
/// Stores: audio toggles, player names (2 slots), theme/appearance choices
/// (incl. custom theme colors), mode setup (vs AI difficulty / pass-and-play),
/// Pro unlock state, and lifetime stats.
class TTSettings extends ChangeNotifier {
  static const _kMusic = 'tt_music_on';
  static const _kSfx = 'tt_sfx_on';
  static const _kVolume = 'tt_volume';
  static const _kMode = 'tt_mode'; // 0 = vs AI, 1 = pass-and-play
  static const _kDifficulty = 'tt_bot_difficulty'; // 0 easy, 1 medium, 2 hard
  static const _kNames = 'tt_player_names'; // legacy unordered StringSet key
  static const _kNamesJsonLegacy =
      'tt_player_names_json'; // pre-exemplar JSON key
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so the
  /// old keys scrambled name order on every app restart. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'tabletennis_player_names_json';
  static const _kTheme = 'tt_theme_id';
  static const _kPaddle = 'tt_paddle_style';
  static const _kBall = 'tt_ball_style';
  static const _kWins = 'tt_wins';
  static const _kGames = 'tt_games_played';
  static const _kBestRally = 'tt_best_rally';
  static const _kSmashes = 'tt_smashes';
  static const _kIsPro = 'tt_is_pro';
  static const _kCustomPrefix = 'tt_custom_';

  static const defaultNames = ['You', 'Ace'];

  /// Encode the 2 player names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 2) {
        return [for (int i = 0; i < 2; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int mode = 0; // 0 vs AI, 1 pass-and-play
  int difficulty = 1; // medium default
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  int paddleStyle = 0;
  int ballStyle = 0;
  int wins = 0;
  int gamesPlayed = 0;
  int bestRally = 0;
  int smashes = 0;
  bool isPro = false;

  /// Custom theme colors (ARGB ints).
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'tableTop': 0xFF2B5F9E,
    'tableLine': 0xFFF2F2F2,
    'net': 0xFFD8D8D8,
    'arenaTop': 0xFF4A3220,
    'arenaBottom': 0xFF2A1D12,
    'accent': 0xFFC9A227,
    'ball': 0xFFFDFDFD,
    'paddle': 0xFFB03030,
  };

  /// Builds the user-designed custom theme from stored colors.
  TTTheme get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return TTTheme(
      id: 'custom',
      name: 'My Creation',
      tableTop: c('tableTop'),
      tableTopDark: c('tableTop').withValues(alpha: 0.75),
      tableLine: c('tableLine'),
      tableEdge: c('arenaBottom'),
      net: c('net'),
      arenaTop: c('arenaTop'),
      arenaBottom: c('arenaBottom'),
      floor: c('arenaTop').withValues(alpha: 0.8),
      accent: c('accent'),
      accentDark: c('accent').withValues(alpha: 0.6),
      text: const Color(0xFFF5EFE0),
      muted: const Color(0xFFB8A88A),
      playerColors: [c('paddle'), const Color(0xFF222222)],
      ball: c('ball'),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 1);
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // pre-exemplar JSON key, then the legacy StringList key once (one-time
    // migration); the StringList may already be scrambled on Android, which
    // is exactly the bug this replaces.
    String? namesRaw = p.getString(_kNamesJson);
    namesRaw ??= p.getString(_kNamesJsonLegacy);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.length == 2)
          ? [for (int i = 0; i < 2; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    paddleStyle = (p.getInt(_kPaddle) ?? 0).clamp(0, PaddleStyles.all.length - 1);
    ballStyle = (p.getInt(_kBall) ?? 0).clamp(0, BallStyles.all.length - 1);
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestRally = p.getInt(_kBestRally) ?? 0;
    smashes = p.getInt(_kSmashes) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kMode, mode);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNamesJsonLegacy); // drop the pre-exemplar key for good
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kPaddle, paddleStyle);
    await p.setInt(_kBall, ballStyle);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestRally, bestRally);
    await p.setInt(_kSmashes, smashes);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    // The custom theme creator is a Pro feature ('custom' is not covered by
    // TTThemes.isProTheme, so it needs an explicit check).
    if (themeId == 'custom' || TTThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (PaddleStyles.isPro(paddleStyle)) {
      paddleStyle = 0;
      changed = true;
    }
    if (BallStyles.isPro(ballStyle)) {
      ballStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setMode(int v) async {
    mode = v.clamp(0, 1);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    // Hard mode is a Pro feature.
    if (!isPro && v > 1) return;
    difficulty = v;
    notifyListeners();
    await _save();
  }

  /// Live per-keystroke name update: in-memory immediately (so the UI and
  /// match setup always see the latest text), persisted to disk on a short
  /// debounce so rapid typing doesn't hammer SharedPreferences.
  Future<void> setPlayerNameLive(int index, String name) async {
    if (index < 0 || index > 1) return;
    playerNames[index] = name;
    notifyListeners();
    _nameSaveTimer?.cancel();
    _nameSaveTimer =
        Timer(const Duration(milliseconds: 350), () => _saveNames());
  }

  /// Commit on focus loss: trims, applies defaults for empty names, and
  /// persists immediately.
  Future<void> commitPlayerNames() async {
    _nameSaveTimer?.cancel();
    _nameSaveTimer = null;
    for (int i = 0; i < 2; i++) {
      playerNames[i] = _cleanName(i, playerNames[i]);
    }
    notifyListeners();
    await _saveNames();
  }

  Future<void> _saveNames() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
  }

  Timer? _nameSaveTimer;

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 1) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. the custom theme creator) require Pro;
    // silently ignore otherwise (UI shows lock).
    if (!isPro && (id == 'custom' || TTThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setPaddleStyle(int v) async {
    v = v.clamp(0, PaddleStyles.all.length - 1);
    if (!isPro && PaddleStyles.isPro(v)) return;
    paddleStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setBallStyle(int v) async {
    v = v.clamp(0, BallStyles.all.length - 1);
    if (!isPro && BallStyles.isPro(v)) return;
    ballStyle = v;
    notifyListeners();
    await _save();
  }

  /// Clear lifetime stats.
  Future<void> resetStats() async {
    wins = 0;
    gamesPlayed = 0;
    bestRally = 0;
    smashes = 0;
    notifyListeners();
    await _save();
  }

  /// Record a finished game.
  Future<void> recordGame({
    required bool humanWon,
    required int rally,
    required int gameSmashes,
  }) async {
    gamesPlayed++;
    if (humanWon) wins++;
    if (rally > bestRally) bestRally = rally;
    smashes += gameSmashes;
    notifyListeners();
    await _save();
  }
}
