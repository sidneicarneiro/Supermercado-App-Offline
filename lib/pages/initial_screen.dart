// lib/pages/initial_screen.dart
import 'package:flutter/material.dart';
import '../utils/auth_utils.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import '../constants/api_constants.dart';
import 'package:http/http.dart' as http;

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final headers = await getAuthHeaders();
    final response = await http.get(
      Uri.parse('$kApiHost/validarToken'),
      headers: headers,
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}