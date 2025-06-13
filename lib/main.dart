import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shopito/pages/initial_screen.dart';
import 'pages/cadastrar_lista_page.dart';
import 'pages/listar_listas_page.dart';

final ColorScheme customColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF43A047),      // Verde principal do carrinho
  onPrimary: Colors.white,
  secondary: Color(0xFFFFB300),    // Amarelo/laranja da fruta
  onSecondary: Colors.black,
  error: Color(0xFFD32F2F),
  onError: Colors.white,
  surface: Color(0xFFF1F8E9),   // Verde bem claro de fundo
  onSurface: Color(0xFF33691E), // Verde escuro (folha)
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supermercado',
      theme: ThemeData(
        colorScheme: customColorScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: customColorScheme.primary,
          foregroundColor: customColorScheme.onPrimary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: customColorScheme.secondary,
            foregroundColor: customColorScheme.onSecondary,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        scaffoldBackgroundColor: customColorScheme.surface,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF424242)),
        ),
      ),
      home: const InitialScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('pt', 'BR'),
        Locale('pt', 'PT'),
        Locale('en', 'US'),
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    CadastrarListaPage(),
    ListarListasPage(),
    Placeholder(), // Terceira página, pode ser implementada depois
  ];

  void _onSelectPage(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Fecha o Drawer
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Supermercado'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('Menu'),
            ),
            ListTile(
              title: const Text('Cadastrar Lista'),
              onTap: () => _onSelectPage(0),
            ),
            ListTile(
              title: const Text('Listar Lista'),
              onTap: () => _onSelectPage(1),
            ),
            ListTile(
              title: const Text('Outra Página'),
              onTap: () => _onSelectPage(2),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}