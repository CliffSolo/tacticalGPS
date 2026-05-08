import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/catppuccin.dart';
import 'utils/app_state.dart';
import 'screens/main_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const TacticalCompassApp(),
    ),
  );
}

class TacticalCompassApp extends StatelessWidget {
  const TacticalCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final isGreen = appState.themeMode == AppThemeMode.tacticalGreen;
        return MaterialApp(
          title: 'Tactical GPS',
          debugShowCheckedModeBanner: false,
          theme: isGreen ? TacticalGreen.theme : CatppuccinMocha.theme,
          home: const MainDashboard(),
        );
      },
    );
  }
}
