import 'package:flutter/material.dart';

import 'package:themis_trust_mobile/screens/client/client_login_page/client_login_screen.dart';
import 'package:themis_trust_mobile/screens/client/client_home_page/client_home_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_home_page/lawyer_home_screen.dart';

class AuthNavigationService {
  static Future<String?> loginAndRedirect(
      BuildContext context,
      ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientLoginScreen(),
      ),
    );

    if (!context.mounted || result == null) {
      return null;
    }

    final role = result.toString().trim().toLowerCase();

    debugPrint('================================');
    debugPrint('AUTH NAVIGATION');
    debugPrint('ROLE: $role');
    debugPrint('================================');

    if (role == 'lawyer') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LawyerHomeScreen(),
        ),
            (route) => false,
      );

      return role;
    }

    if (role == 'client') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );

      return role;
    }

    return null;
  }
}