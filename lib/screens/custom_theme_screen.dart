import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/tt_themes.dart';
import '../theme/tt_widgets.dart';

/// PRO: design your own club colors. Live preview on a mini table.
class CustomThemeScreen extends StatefulWidget {
  final TTAudio audio;
  final TTSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  static const _labels = {
    'tableTop': 'Table surface',
    'tableLine': 'Table lines',
    'net': 'Net',
    'arenaTop': 'Arena walls',
    'arenaBottom': 'Arena shadow',
    'accent': 'Accent gold',
    'ball': 'Ball',
    'paddle': 'Paddle rubber',
  };

  // A fixed warm palette to pick from — physical, club-appropriate colors.
  static const _palette = [
    0xFFB03030, 0xFF2B5F9E, 0xFF2E7D4F, 0xFFC9A227, 0xFFFDFDFD, 0xFF222222,
    0xFF7A2E3F, 0xFF1F6E8C, 0xFF9C6B3F, 0xFF5A6E7A, 0xFFF08A3A, 0xFF3F7A4E,
    0xFFD4A93C, 0xFF8A6D1A, 0xFF4A3220, 0xFF2A1D12, 0xFFEFE6D4, 0xFF6B4A2E,
  ];

  String? _editing;

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    if (!s.isPro) {
      // Belt-and-suspenders: the menu already gates this screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
    final t = s.customTheme;
    return ArenaBackdrop(
      theme: TTThemes.byId(s.themeId, custom: s.customTheme),
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
          title: Text('My Creation', style: Arena.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) {
              final theme = s.customTheme;
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Column(
                  children: [
                    // Live mini-table preview.
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [theme.arenaTop, theme.arenaBottom],
                        ),
                        border: Border.all(color: theme.accent, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 34,
                          decoration: BoxDecoration(
                            color: theme.tableTop,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: theme.tableLine, width: 2),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 3,
                                height: 34,
                                color: theme.tableLine,
                              ),
                              Container(
                                width: 2,
                                height: 60,
                                color: theme.net.withValues(alpha: 0.9),
                              ),
                              Positioned(
                                left: 30,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.ball,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ArenaCard(
                      theme: theme,
                      child: Column(
                        children: [
                          ArenaSection(text: 'Pick a color', theme: theme),
                          for (final e in _labels.entries)
                            _colorRow(s, theme, e.key, e.value),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_editing != null) ...[
                      ArenaCard(
                        theme: theme,
                        child: Column(
                          children: [
                            ArenaSection(
                                text: _labels[_editing] ?? '', theme: theme),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final c in _palette)
                                  GestureDetector(
                                    onTap: () {
                                      widget.audio.click();
                                      s.setCustomColor(_editing!, c);
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(c),
                                        border: Border.all(
                                          color: s.customColors[_editing] == c
                                              ? theme.accent
                                              : Colors.white24,
                                          width: s.customColors[_editing] == c
                                              ? 3
                                              : 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ArenaButton(
                          label: '✓  Use My Creation',
                          width: 220,
                          fontSize: 16,
                          theme: theme,
                          onTap: () {
                            widget.audio.gameStart();
                            s.setTheme('custom');
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            widget.audio.click();
                            s.resetCustomColors();
                          },
                          child: Text('Reset',
                              style: Arena.label(14, theme: theme)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _colorRow(
      TTSettings s, TTTheme theme, String key, String label) {
    final selected = _editing == key;
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        setState(() => _editing = key);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? theme.accent.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.25),
          border: Border.all(
            color: selected
                ? theme.accent
                : Colors.white.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(s.customColors[key] ?? 0xFF000000),
                border: Border.all(color: Colors.white54, width: 1.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label, style: Arena.body(15, theme: theme))),
            Icon(Icons.chevron_right, color: theme.muted),
          ],
        ),
      ),
    );
  }
}
