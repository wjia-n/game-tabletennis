import 'package:flutter/material.dart';

/// Table-tennis art direction: a real physical club table — warm arena
/// lighting, wooden or painted table tops, felt-like surroundings.
/// No neon, no cyberpunk, no AI-dashboard looks. Every theme is a real
/// sports-hall you could walk into.
class TTTheme {
  final String id;
  final String name;
  final bool pro;
  // Table.
  final Color tableTop;
  final Color tableTopDark;
  final Color tableLine;
  final Color tableEdge;
  final Color net;
  // Arena surroundings.
  final Color arenaTop;
  final Color arenaBottom;
  final Color floor;
  // UI.
  final Color accent;
  final Color accentDark;
  final Color text;
  final Color muted;
  // The two player paddles' base colors.
  final List<Color> playerColors;
  final Color ball;

  const TTTheme({
    required this.id,
    required this.name,
    this.pro = false,
    required this.tableTop,
    required this.tableTopDark,
    required this.tableLine,
    required this.tableEdge,
    required this.net,
    required this.arenaTop,
    required this.arenaBottom,
    required this.floor,
    required this.accent,
    required this.accentDark,
    required this.text,
    required this.muted,
    required this.playerColors,
    required this.ball,
  });
}

class TTThemes {
  static const List<TTTheme> all = [
    TTTheme(
      id: 'classic', name: 'Classic Club Blue',
      tableTop: Color(0xFF2B5F9E), tableTopDark: Color(0xFF1C4270),
      tableLine: Color(0xFFF2F2F2), tableEdge: Color(0xFF14304F),
      net: Color(0xFFD8D8D8),
      arenaTop: Color(0xFF4A3220), arenaBottom: Color(0xFF2A1D12),
      floor: Color(0xFF6B4A2B),
      accent: Color(0xFFC9A227), accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFF5EFE0), muted: Color(0xFFB8A88A),
      playerColors: [Color(0xFFB03030), Color(0xFF303030)],
      ball: Color(0xFFFDFDFD),
    ),
    TTTheme(
      id: 'championship', name: 'Championship Green',
      tableTop: Color(0xFF2E7D4F), tableTopDark: Color(0xFF1F5A38),
      tableLine: Color(0xFFF5F5F5), tableEdge: Color(0xFF123A24),
      net: Color(0xFFD8D8D8),
      arenaTop: Color(0xFF3A3A32), arenaBottom: Color(0xFF23231E),
      floor: Color(0xFF5C4A2E),
      accent: Color(0xFFD4A93C), accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFF7F4E8), muted: Color(0xFFB5B09A),
      playerColors: [Color(0xFFB03030), Color(0xFF1F1F1F)],
      ball: Color(0xFFFDFDFD),
    ),
    TTTheme(
      id: 'timber', name: 'Timber Wood',
      tableTop: Color(0xFF9C6B3F), tableTopDark: Color(0xFF7A4E28),
      tableLine: Color(0xFFFFF6E6), tableEdge: Color(0xFF4A2E14),
      net: Color(0xFFE8E0D0),
      arenaTop: Color(0xFF40301E), arenaBottom: Color(0xFF241A0E),
      floor: Color(0xFF5E4023),
      accent: Color(0xFFC98A2B), accentDark: Color(0xFF7A5418),
      text: Color(0xFFFFF3DC), muted: Color(0xFFC4A97E),
      playerColors: [Color(0xFFB03030), Color(0xFF2B2B2B)],
      ball: Color(0xFFFFFBF0),
    ),
    TTTheme(
      id: 'midnight', name: 'Midnight Arena',
      tableTop: Color(0xFF3B4A63), tableTopDark: Color(0xFF2A3649),
      tableLine: Color(0xFFF0EAD8), tableEdge: Color(0xFF151D2B),
      net: Color(0xFFCFCFCF),
      arenaTop: Color(0xFF1C2230), arenaBottom: Color(0xFF0E1119),
      floor: Color(0xFF2E2A26),
      accent: Color(0xFFD4A93C), accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFF2EEE2), muted: Color(0xFF9AA0AE),
      playerColors: [Color(0xFFC0392B), Color(0xFFE0D6C0)],
      ball: Color(0xFFFFF4D6),
    ),
    // ---------------- Pro themes ----------------
    TTTheme(
      id: 'royal', name: 'Royal Burgundy', pro: true,
      tableTop: Color(0xFF7A2E3F), tableTopDark: Color(0xFF5A1F2D),
      tableLine: Color(0xFFF2E8D8), tableEdge: Color(0xFF3A1420),
      net: Color(0xFFD8CBB8),
      arenaTop: Color(0xFF3A2230), arenaBottom: Color(0xFF201420),
      floor: Color(0xFF4A3230),
      accent: Color(0xFFD4A93C), accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFF7EEE0), muted: Color(0xFFB89A9A),
      playerColors: [Color(0xFF1F1F1F), Color(0xFFD4A93C)],
      ball: Color(0xFFFDFDFD),
    ),
    TTTheme(
      id: 'sandstone', name: 'Sandstone Desert', pro: true,
      tableTop: Color(0xFFC99A5B), tableTopDark: Color(0xFFA07743),
      tableLine: Color(0xFF4A3A28), tableEdge: Color(0xFF6B4E2E),
      net: Color(0xFF5A4630),
      arenaTop: Color(0xFF8A6A44), arenaBottom: Color(0xFF54402A),
      floor: Color(0xFFA88050),
      accent: Color(0xFF5A3A1A), accentDark: Color(0xFF3A2410),
      text: Color(0xFF2E2014), muted: Color(0xFF6B5540),
      playerColors: [Color(0xFF8A2E2E), Color(0xFF2E4A6B)],
      ball: Color(0xFFFFF6E6),
    ),
    TTTheme(
      id: 'ocean', name: 'Deep Ocean', pro: true,
      tableTop: Color(0xFF1F6E8C), tableTopDark: Color(0xFF145062),
      tableLine: Color(0xFFF0F8F8), tableEdge: Color(0xFF0C323E),
      net: Color(0xFFCFE8E8),
      arenaTop: Color(0xFF14303C), arenaBottom: Color(0xFF0A1A22),
      floor: Color(0xFF2E4A56),
      accent: Color(0xFF7FD4E8), accentDark: Color(0xFF3A8CA8),
      text: Color(0xFFF0F8FA), muted: Color(0xFF8AB4C0),
      playerColors: [Color(0xFFB03030), Color(0xFFF0D060)],
      ball: Color(0xFFFDFDFD),
    ),
    TTTheme(
      id: 'forest', name: 'Forest Dawn', pro: true,
      tableTop: Color(0xFF3F7A4E), tableTopDark: Color(0xFF2C5A38),
      tableLine: Color(0xFFF2F4E8), tableEdge: Color(0xFF1A3823),
      net: Color(0xFFD8E0D0),
      arenaTop: Color(0xFF2A4030), arenaBottom: Color(0xFF16241A),
      floor: Color(0xFF4A5A3A),
      accent: Color(0xFFC9A227), accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFF2F4E8), muted: Color(0xFFA8B894),
      playerColors: [Color(0xFFB03030), Color(0xFF1F1F1F)],
      ball: Color(0xFFFFFBEF),
    ),
    TTTheme(
      id: 'graphite', name: 'Graphite Pro', pro: true,
      tableTop: Color(0xFF4A4E55), tableTopDark: Color(0xFF35393F),
      tableLine: Color(0xFFF2EFE6), tableEdge: Color(0xFF1E2126),
      net: Color(0xFFC8C8C8),
      arenaTop: Color(0xFF24262B), arenaBottom: Color(0xFF121316),
      floor: Color(0xFF3A3A3A),
      accent: Color(0xFFD4A93C), accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFF2EFE6), muted: Color(0xFF9A9A98),
      playerColors: [Color(0xFFC0392B), Color(0xFF3A8CA8)],
      ball: Color(0xFFFFF4D6),
    ),
    TTTheme(
      id: 'cherrywood', name: 'Cherrywood Hall', pro: true,
      tableTop: Color(0xFF8A3B2E), tableTopDark: Color(0xFF662A20),
      tableLine: Color(0xFFF2E4D4), tableEdge: Color(0xFF401A14),
      net: Color(0xFFD8C4B0),
      arenaTop: Color(0xFF40241E), arenaBottom: Color(0xFF221410),
      floor: Color(0xFF5C3A2E),
      accent: Color(0xFFD4A93C), accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFF7EEE0), muted: Color(0xFFC4A494),
      playerColors: [Color(0xFF1F1F1F), Color(0xFFD4A93C)],
      ball: Color(0xFFFDFDFD),
    ),
    TTTheme(
      id: 'sage', name: 'Sage Garden', pro: true,
      tableTop: Color(0xFF7A9A7E), tableTopDark: Color(0xFF5A7A5E),
      tableLine: Color(0xFF2E4030), tableEdge: Color(0xFF3A5240),
      net: Color(0xFF3A4A3E),
      arenaTop: Color(0xFF5A7A62), arenaBottom: Color(0xFF3A5242),
      floor: Color(0xFF6B8A6E),
      accent: Color(0xFF3A5240), accentDark: Color(0xFF243528),
      text: Color(0xFF1E2A20), muted: Color(0xFF4A5E4E),
      playerColors: [Color(0xFF8A2E2E), Color(0xFF2E4A6B)],
      ball: Color(0xFFFFFBF0),
    ),
    TTTheme(
      id: 'amber', name: 'Amber Glow', pro: true,
      tableTop: Color(0xFFB07A2E), tableTopDark: Color(0xFF8A5A20),
      tableLine: Color(0xFFFFF2DC), tableEdge: Color(0xFF5A3A14),
      net: Color(0xFFE8D4B0),
      arenaTop: Color(0xFF4A3018), arenaBottom: Color(0xFF241606),
      floor: Color(0xFF6B4A24),
      accent: Color(0xFFD4A93C), accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFFFF3DC), muted: Color(0xFFD4B484),
      playerColors: [Color(0xFF8A2E2E), Color(0xFF2E2E2E)],
      ball: Color(0xFFFFFBF0),
    ),
    TTTheme(
      id: 'slate', name: 'Slate Court', pro: true,
      tableTop: Color(0xFF5A6E7A), tableTopDark: Color(0xFF42525C),
      tableLine: Color(0xFFF2F2EE), tableEdge: Color(0xFF2A363C),
      net: Color(0xFFD0D8DC),
      arenaTop: Color(0xFF2E3A42), arenaBottom: Color(0xFF161D22),
      floor: Color(0xFF424E56),
      accent: Color(0xFFC9A227), accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFF2F4F4), muted: Color(0xFF9AA8B0),
      playerColors: [Color(0xFFB03030), Color(0xFFF0D060)],
      ball: Color(0xFFFDFDFD),
    ),
    TTTheme(
      id: 'marble', name: 'Marble Club', pro: true,
      tableTop: Color(0xFFD8D4CC), tableTopDark: Color(0xFFB8B4AC),
      tableLine: Color(0xFF3A3A3A), tableEdge: Color(0xFF8A8680),
      net: Color(0xFF4A4A4A),
      arenaTop: Color(0xFF4A4A4A), arenaBottom: Color(0xFF242424),
      floor: Color(0xFF6B6B6B),
      accent: Color(0xFF8A6D1A), accentDark: Color(0xFF5A4810),
      text: Color(0xFF2A2A2A), muted: Color(0xFF6B6B6B),
      playerColors: [Color(0xFF8A2E2E), Color(0xFF2E4A6B)],
      ball: Color(0xFFFF8A3A),
    ),
  ];

  static TTTheme byId(String id, {TTTheme? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static bool isProTheme(String id) => all.any((t) => t.id == id && t.pro);
}

/// Paddle rubber styles: physical rubber + wood handle looks.
class PaddleStyle {
  final String name;
  final Color rubber;
  final Color handle;
  final bool pro;
  const PaddleStyle(this.name, this.rubber, this.handle, {this.pro = false});
}

class PaddleStyles {
  static const names = [
    'Club Red', 'Jet Black', 'Walnut', 'Honey Oak', 'Forest', 'Ocean',
    'Burgundy', 'Charcoal', 'Cherry', 'Slate', 'Cream', 'Rosewood',
  ];
  static const List<PaddleStyle> all = [
    PaddleStyle('Club Red', Color(0xFFB03030), Color(0xFF7A4E28)),
    PaddleStyle('Jet Black', Color(0xFF222222), Color(0xFF5C3A21)),
    PaddleStyle('Walnut', Color(0xFF6B4A2E), Color(0xFF4A2E14)),
    PaddleStyle('Honey Oak', Color(0xFFC98A2B), Color(0xFF7A5418)),
    PaddleStyle('Forest', Color(0xFF2E6B4F), Color(0xFF4A2E14), pro: true),
    PaddleStyle('Ocean', Color(0xFF2E6B8C), Color(0xFF4A3A28), pro: true),
    PaddleStyle('Burgundy', Color(0xFF7A2E3F), Color(0xFF3A2410), pro: true),
    PaddleStyle('Charcoal', Color(0xFF3A3E44), Color(0xFF1E2126), pro: true),
    PaddleStyle('Cherry', Color(0xFF8A3B2E), Color(0xFF401A14), pro: true),
    PaddleStyle('Slate', Color(0xFF5A6E7A), Color(0xFF2A363C), pro: true),
    PaddleStyle('Cream', Color(0xFFEFE6D4), Color(0xFF8A6B45), pro: true),
    PaddleStyle('Rosewood', Color(0xFF5A2E28), Color(0xFF2E1A14), pro: true),
  ];
  static bool isPro(int i) => i >= 0 && i < all.length && all[i].pro;
}

/// Ball styles: real celluloid/plastic ball looks.
class BallStyle {
  final String name;
  final Color color;
  final Color seam;
  final bool pro;
  const BallStyle(this.name, this.color, this.seam, {this.pro = false});
}

class BallStyles {
  static const names = [
    'Classic White', 'Training Orange', 'Lemon', 'Cream', 'Silver',
    'Gold', 'Mint', 'Coral', 'Sky', 'Rose', 'Lime', 'Slate',
  ];
  static const List<BallStyle> all = [
    BallStyle('Classic White', Color(0xFFFDFDFD), Color(0xFFD8D8D8)),
    BallStyle('Training Orange', Color(0xFFF08A3A), Color(0xFFC96A2A)),
    BallStyle('Lemon', Color(0xFFF2E85A), Color(0xFFC9BE3A)),
    BallStyle('Cream', Color(0xFFFFF6E6), Color(0xFFD8CDB8)),
    BallStyle('Silver', Color(0xFFD8D8D8), Color(0xFFA8A8A8), pro: true),
    BallStyle('Gold', Color(0xFFD4A93C), Color(0xFF8A6D1A), pro: true),
    BallStyle('Mint', Color(0xFFA8D8B8), Color(0xFF7AB898), pro: true),
    BallStyle('Coral', Color(0xFFE88A7A), Color(0xFFC86A5A), pro: true),
    BallStyle('Sky', Color(0xFFA8CCE8), Color(0xFF7AACC8), pro: true),
    BallStyle('Rose', Color(0xFFE8A8B8), Color(0xFFC88898), pro: true),
    BallStyle('Lime', Color(0xFFB8D84A), Color(0xFF98B83A), pro: true),
    BallStyle('Slate', Color(0xFF8A9AA8), Color(0xFF6A7A88), pro: true),
  ];
  static bool isPro(int i) => i >= 0 && i < all.length && all[i].pro;
}
