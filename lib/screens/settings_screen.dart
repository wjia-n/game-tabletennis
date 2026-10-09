import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/tt_themes.dart';
import '../theme/tt_widgets.dart';
import 'custom_theme_screen.dart';

/// Settings: sound/music toggles + volume, custom theme entry, stats reset.
class SettingsScreen extends StatefulWidget {
  final TTAudio audio;
  final TTSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TTTheme get _t =>
      TTThemes.byId(widget.settings.themeId, custom: widget.settings.customTheme);

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final a = widget.audio;
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
              a.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Arena.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  ArenaCard(
                    theme: t,
                    child: Column(
                      children: [
                        ArenaSection(text: 'Audio', theme: t),
                        _toggleRow(
                          t: t,
                          label: '🎵 Music',
                          value: s.musicOn,
                          onChanged: (v) {
                            s.setMusic(v);
                            a.configure(
                                musicOn: v,
                                sfxOn: s.sfxOn,
                                volume: s.volume);
                            if (v) {
                              a.startMenuMusic();
                            } else {
                              a.stopMusic();
                            }
                          },
                        ),
                        _toggleRow(
                          t: t,
                          label: '🔊 Sound effects',
                          value: s.sfxOn,
                          onChanged: (v) {
                            s.setSfx(v);
                            a.configure(
                                musicOn: s.musicOn,
                                sfxOn: v,
                                volume: s.volume);
                            if (v) a.click();
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('🔈 Volume',
                                style: Arena.body(16, theme: t)),
                            Expanded(
                              child: Slider(
                                value: s.volume,
                                activeColor: t.accent,
                                inactiveColor:
                                    t.muted.withValues(alpha: 0.4),
                                onChanged: (v) {
                                  s.setVolume(v);
                                  a.configure(
                                      musicOn: s.musicOn,
                                      sfxOn: s.sfxOn,
                                      volume: v);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ArenaCard(
                    theme: t,
                    child: Column(
                      children: [
                        ArenaSection(text: 'Appearance', theme: t),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.palette, color: t.accent),
                          title: Text(
                            s.isPro
                                ? 'Custom theme creator'
                                : 'Custom theme creator 🔒',
                            style: Arena.body(16, theme: t),
                          ),
                          subtitle: Text(
                            'Design your own club colors',
                            style: Arena.body(13,
                                theme: t, color: t.muted),
                          ),
                          trailing: Icon(Icons.chevron_right,
                              color: t.accent),
                          onTap: s.isPro
                              ? () {
                                  a.click();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CustomThemeScreen(
                                        audio: a,
                                        settings: s,
                                      ),
                                    ),
                                  );
                                }
                              : () {
                                  a.invalid();
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'The custom theme creator is a PRO feature',
                                          style: Arena.body(14,
                                              theme: t)),
                                      backgroundColor: Colors.black87,
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ArenaCard(
                    theme: t,
                    child: Column(
                      children: [
                        ArenaSection(text: 'Stats', theme: t),
                        _statRow(t, 'Matches played', '${s.gamesPlayed}'),
                        _statRow(t, 'Matches won', '${s.wins}'),
                        _statRow(t, 'Longest rally',
                            s.bestRally > 0 ? '${s.bestRally} shots' : '—'),
                        _statRow(t, 'Smashes', '${s.smashes}'),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            a.click();
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: Colors.black87,
                                title: Text('Reset stats?',
                                    style: Arena.display(20, theme: t)),
                                content: Text(
                                    'Your wins, matches, rallies and smashes will be cleared.',
                                    style:
                                        Arena.body(14, theme: t)),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      a.click();
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel',
                                        style: Arena.label(14,
                                            theme: t)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      a.click();
                                      s.resetStats();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Reset',
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight:
                                                FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Reset stats',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
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

  Widget _toggleRow({
    required TTTheme t,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Arena.body(16, theme: t))),
        Switch(
          value: value,
          activeThumbColor: t.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _statRow(TTTheme t, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Arena.body(15, theme: t))),
          Text(value, style: Arena.label(15, theme: t)),
        ],
      ),
    );
  }
}
