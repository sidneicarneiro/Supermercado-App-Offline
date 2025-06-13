import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/splash_screen.dart';

final Color primaryColor = Color(0xFFFF6F00); // Laranja
final Color secondaryColor = Color(0xFFD32F2F); // Vermelho
final Color accentColor = Color(0xFFFFC107); // Amarelo
final Color greenColor = Color(0xFF43A047); // Verde
final Color darkColor = Color(0xFF2D2946); // Roxo escuro

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiggy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: Colors.white,
          background: accentColor.withOpacity(0.05),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: darkColor,
          onBackground: darkColor,
          error: secondaryColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: secondaryColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const SplashScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('pt', 'BR'),
      ],
    );
  }
}