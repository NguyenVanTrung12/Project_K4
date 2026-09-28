import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:themis_trust_mobile/screens/client/client_home_page/client_home_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_home_page/lawyer_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final role = prefs.getString('userRole');

    debugPrint('================================');
    debugPrint('AUTH GATE');
    debugPrint('TOKEN: ${token != null && token.isNotEmpty ? "CÓ" : "KHÔNG"}');
    debugPrint('ROLE: $role');
    debugPrint('================================');

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _role = null;
        _loading = false;
      });

      return;
    }

    if (role == 'lawyer') {
      setState(() {
        _role = 'lawyer';
        _loading = false;
      });

      return;
    }

    if (role == 'client') {
      setState(() {
        _role = 'client';
        _loading = false;
      });

      return;
    }

    // Session không hợp lệ
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhone');
    await prefs.remove('userRole');
    await prefs.remove('avatarUrl');
    await prefs.remove('expiresAt');

    if (!mounted) return;

    setState(() {
      _role = null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_role == 'lawyer') {
      return const LawyerHomeScreen();
    }

    // Chưa đăng nhập hoặc client
    return const ClientHomeScreen();
  }
}