import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/tt_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = TTSettings();
  await settings.load();
  final audio = TTAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(TableTennisApp(settings: settings, audio: audio));
}

class TableTennisApp extends StatefulWidget {
  final TTSettings settings;
  final TTAudio audio;
  const TableTennisApp({super.key, required this.settings, required this.audio});

  @override
  State<TableTennisApp> createState() => _TableTennisAppState();
}

class _TableTennisAppState extends State<TableTennisApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final theme = TTThemes.byId(widget.settings.themeId,
            custom: widget.settings.customTheme);
        return MaterialApp(
          title: 'Table Tennis',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: theme.arenaBottom,
            colorScheme: ColorScheme.dark(
              primary: theme.accent,
              surface: theme.arenaTop,
              onSurface: theme.text,
            ),
          ),
          home: SplashScreen(audio: widget.audio, settings: widget.settings),
        );
      },
    );
  }
}
