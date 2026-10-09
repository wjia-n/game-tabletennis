import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/tt_themes.dart';
import '../theme/tt_widgets.dart';

/// Table Tennis PRO: Free-vs-Pro comparison, real purchase, restore,
/// and tip jar. All prices come from the store — never hardcoded, never
/// placeholders.
class ProScreen extends StatefulWidget {
  final TTAudio audio;
  final TTSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  TTTheme get _t =>
      TTThemes.byId(widget.settings.themeId, custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy everything!',
              style: Arena.body(15, theme: _t)),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Arena.body(15, theme: _t)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
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
          title: Text('Table Tennis PRO', style: Arena.display(22, theme: t)),
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
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 16),
                  _TipsCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.
class _ComparisonCard extends StatelessWidget {
  final TTTheme theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete table tennis game', true, true),
      ('All official rally rules', true, true),
      ('Easy & Medium bot modes', true, true),
      ('2-player pass-and-play', true, true),
      ('Renameable players', true, true),
      ('Music & sound effects', true, true),
      ('Table themes', '4', '14'),
      ('Paddle rubber styles', '4', '12'),
      ('Ball styles', '4', '12'),
      ('Custom theme creator', false, true),
      ('Hard bot mode', false, true),
      ('Exclusive arena accents', false, true),
    ];
    return ArenaCard(
      theme: theme,
      child: Column(
        children: [
          Text('Free vs PRO', style: Arena.display(20, theme: theme)),
          const SizedBox(height: 4),
          Text(
            'One purchase. Yours forever.',
            style: Arena.body(13,
                theme: theme,
                color: theme.text.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          // Header row.
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('FREE',
                      style: Arena.label(12, theme: theme),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('PRO',
                      style: Arena.label(12, theme: theme),
                      textAlign: TextAlign.center)),
            ],
          ),
          const Divider(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(r.$1, style: Arena.body(13, theme: theme)),
                  ),
                  Expanded(flex: 2, child: _Cell(value: r.$2, theme: theme)),
                  Expanded(flex: 2, child: _Cell(value: r.$3, theme: theme)),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.accent.withValues(alpha: 0.25),
                  border: Border.all(color: theme.accent),
                ),
                child: Text('✦ PRO ACTIVE ✦',
                    style: Arena.label(14, theme: theme)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Object value; // bool | String
  final TTTheme theme;
  const _Cell({required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (value is bool) {
      final v = value as bool;
      return Text(
        v ? '✓' : '—',
        style: Arena.body(15,
            theme: theme,
            color: v
                ? theme.accent
                : theme.text.withValues(alpha: 0.4)),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      value as String,
      style: Arena.label(12, theme: theme),
      textAlign: TextAlign.center,
    );
  }
}

// ---------------------------------------------------------------------------
class _BuyCard extends StatelessWidget {
  final TTTheme theme;
  final TTSettings settings;
  final StoreService store;
  final TTAudio audio;
  const _BuyCard({
    required this.theme,
    required this.settings,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final pro = store.proProduct;
    return ArenaCard(
      theme: theme,
      child: Column(
        children: [
          Text('Unlock PRO', style: Arena.display(20, theme: theme)),
          const SizedBox(height: 8),
          if (settings.isPro)
            Text('You already own PRO — thank you!',
                style: Arena.body(14, theme: theme),
                textAlign: TextAlign.center)
          else if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Arena.body(14,
                  theme: theme,
                  color: theme.text.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            )
          else if (pro != null) ...[
            Text(pro.description.isNotEmpty
                ? pro.description
                : 'Unlock everything in Table Tennis, forever.',
                style: Arena.body(14, theme: theme),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => ArenaButton(
                label: busy ? 'Working…' : 'Get PRO — ${pro.price}',
                width: 260,
                fontSize: 17,
                theme: theme,
                onTap: busy
                    ? () {}
                    : () {
                        audio.click();
                        store.buyPro();
                      },
              ),
            ),
          ],
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(err,
                        style: Arena.body(13,
                            theme: theme,
                            color: const Color(0xFFE08A8A)),
                        textAlign: TextAlign.center),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              audio.click();
              store.restore();
            },
            child: Text('Restore purchases',
                style: Arena.label(13, theme: theme)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Consumable tips — pure support, with real store prices.
class _TipsCard extends StatelessWidget {
  final TTTheme theme;
  final StoreService store;
  final TTAudio audio;
  const _TipsCard(
      {required this.theme, required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    return ArenaCard(
      theme: theme,
      child: Column(
        children: [
          Text('Tip the Maker', style: Arena.display(20, theme: theme)),
          const SizedBox(height: 8),
          Text(
            'Table Tennis is free forever. A small tip keeps new games coming!',
            style: Arena.body(14, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Arena.body(13,
                  theme: theme,
                  color: theme.text.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            )
          else if (tips.isEmpty)
            Text('Tips coming soon.',
                style: Arena.body(13,
                    theme: theme,
                    color: theme.text.withValues(alpha: 0.6)))
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _TipChip(
                    theme: theme,
                    label:
                        '${p.id == StoreService.chocolateId ? '🍫' : '☕'} ${p.price}',
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final TTTheme theme;
  final String label;
  final VoidCallback onTap;
  const _TipChip(
      {required this.theme, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black.withValues(alpha: 0.3),
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(label, style: Arena.label(14, theme: theme)),
      ),
    );
  }
}
