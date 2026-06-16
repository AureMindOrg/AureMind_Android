import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'services/database_helper.dart';
import 'services/notification_helper.dart';
import 'services/theme_provider.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initDb();
  await NotificationHelper.init(); 
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AureMindApp(),
    ),
  );
}

class AureMindApp extends StatelessWidget {
  const AureMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null && themeProvider.useDynamicColor) {
          // Use Material You (System Colors from Wallpaper)
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          // Use Custom Color Wheel Selection
          lightScheme = ColorScheme.fromSeed(seedColor: themeProvider.customColor, brightness: Brightness.light);
          darkScheme = ColorScheme.fromSeed(seedColor: themeProvider.customColor, brightness: Brightness.dark);
        }

        return MaterialApp(
          title: 'AureMind',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode, 
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(elevation: 1),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(elevation: 1),
          ),
          home: const DashboardScreen(), 
        );
      },
    );
  }
}