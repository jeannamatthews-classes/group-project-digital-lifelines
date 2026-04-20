import 'package:flutter/material.dart';

import 'screens/about/about_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/record/record_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // App entry point.
  runApp(const DigitalLifelinesApp());
}

// Root app widget that wires global theme and initial route.
class DigitalLifelinesApp extends StatelessWidget {
  const DigitalLifelinesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Lifelines',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(nextScreen: RootNavScreen()),
    );
  }
}

class RootNavScreen extends StatefulWidget {
  const RootNavScreen({super.key});

  @override
  State<RootNavScreen> createState() => _RootNavScreenState();
}

class _RootNavScreenState extends State<RootNavScreen> {
  int _currentIndex = 0;

  // We keep tabs alive by using IndexedStack in build.
  final List<Widget> _screens = const [
    HomeScreen(),
    RecordScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves each screen state while switching tabs.
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph_outlined),
            activeIcon: Icon(Icons.auto_graph),
            label: 'Lifelines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
