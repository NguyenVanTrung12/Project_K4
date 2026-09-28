import 'package:flutter/material.dart';

import 'package:themis_trust_mobile/screens/auth/auth_gate.dart';
import 'package:themis_trust_mobile/screens/client/client_home_page/client_home_screen.dart';
import 'package:themis_trust_mobile/screens/client/client_login_page/client_login_screen.dart';
import 'package:themis_trust_mobile/screens/client/client_login_page/client_register_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_home_page/lawyer_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Themis Trust',

      home: const AuthGate(),

      routes: {
        '/home': (context) => const ClientHomeScreen(),
        '/login': (context) => const ClientLoginScreen(),
        '/register': (context) => const ClientRegisterScreen(),
        '/lawyer/home': (context) => const LawyerHomeScreen(),
      },
    );
  }
}