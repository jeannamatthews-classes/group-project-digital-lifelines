import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/about/about_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/record/record_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_screen.dart';
import 'database/db_helper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase not configured for this platform, skipping: $e');
  }
  runApp(const DigitalLifelinesApp());
}

class DigitalLifelinesApp extends StatelessWidget {
  const DigitalLifelinesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Lifelines',
      theme: AppTheme.lightTheme,
 /*   home: StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (snapshot.hasData && snapshot.data != null) {
      return FutureBuilder(
        future: DBHelper.instance.syncFromFirebase(),
        builder: (context, syncSnapshot) {
          if (syncSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your data...'),
                  ],
                ),
              ),
            );
          }
          return const RootNavScreen();
        },
      );
    }
    return const LoginScreen();
  },
),*/
// ✅ Just go straight home!
home: const RootNavScreen(),
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
  final List<Widget> _screens = const [
    HomeScreen(),
    RecordScreen(),
    AboutScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
