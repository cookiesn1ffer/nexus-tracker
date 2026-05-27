import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'widgets/layout.dart';
import 'screens/dashboard.dart';
import 'screens/rules_manager.dart';
import 'screens/writeups_board.dart';
import 'screens/analytics.dart';
import 'constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const NexusTrackerApp(),
    ),
  );
}

class NexusTrackerApp extends StatelessWidget {
  const NexusTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          surface: AppColors.background,
        ),
        fontFamily: 'Inter',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _activeIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    RulesManagerScreen(),
    WriteupsBoardScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      activeIndex: _activeIndex,
      onNavigate: (index) => setState(() => _activeIndex = index),
      child: _screens[_activeIndex],
    );
  }
}
