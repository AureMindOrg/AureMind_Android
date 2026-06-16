import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'services/database_helper.dart';
import 'services/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initDb();
  await NotificationHelper.init(); // Initialize notifications
  runApp(const AureMindApp());
} // <--- This was missing!

class AureMindApp extends StatelessWidget {
  const AureMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AureMind Offline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF3B82F6),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}