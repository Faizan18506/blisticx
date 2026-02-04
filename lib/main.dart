import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blisticx/core/theme/app_theme.dart';
import 'package:blisticx/src/screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TODO: Add providers here (e.g. AnalysisProvider, SettingsProvider)
        Provider<String>.value(value: "Placeholder"), 
      ],
      child: MaterialApp(
        title: 'Dispersion Analyzer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(), // We might want a light theme option later
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Force dark mode for premium feel
        home: const DashboardScreen(),
      ),
    );
  }
}
