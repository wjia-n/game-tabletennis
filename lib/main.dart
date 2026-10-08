import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const TableTennisApp());

class TableTennisApp extends StatelessWidget {
  const TableTennisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Table Tennis',
      tagline: 'Spin and smash in lightning table tennis rallies',
      emoji: '🏓',
      slug: 'tabletennis',
      howToPlay:
          '• The ball arcs back and forth — TAP just as it reaches your paddle!\n• Perfect timing = rocket return. Sloppy timing = into the net. 😬\n• Swipe UP for topspin (fast) or DOWN for backspin (tricky) before tapping.\n• First to 11, win by 2. Serve swaps every 2 points.\n• Solo? The bot reads spin… mostly. 🤖',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => TableTennisScreen(players: players, callbacks: cb),
    );
  }
}
