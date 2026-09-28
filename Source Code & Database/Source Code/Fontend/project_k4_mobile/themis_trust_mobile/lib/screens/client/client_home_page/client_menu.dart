import 'package:flutter/material.dart';

class ClientHomeMenuWidget extends StatelessWidget {
  const ClientHomeMenuWidget({
    super.key,
    this.onNotificationPressed,
    this.onMenuPressed,
  });

  final VoidCallback? onNotificationPressed;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF08233D),
      ),
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                // =================================================
                // LOGO THEMIS
                // =================================================

                _buildThemisLogo(),

                const Spacer(),

                // =================================================
                // MENU BUTTON
                // =================================================
                _buildMenuButton(),
              ],
            ),
          ),
        ),
    );
  }

  // =============================================================
  // THEMIS LOGO
  // =============================================================

  Widget _buildThemisLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ---------------------------------------------------------
        // ICON CÁI CÂN
        // ---------------------------------------------------------

        SizedBox(
          width: 40,
          height: 42,
          child: Center(
            child: Icon(
              Icons.balance,
              size: 38,
              color: const Color(0xFFE3BE69),
            ),
          ),
        ),

        const SizedBox(width: 9),

        // ---------------------------------------------------------
        // TÊN THEMIS TRUST
        // ---------------------------------------------------------
        const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THEMIS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                height: 1.0,
              ),
            ),

            SizedBox(height: 4),

            Text(
              'TRUST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =============================================================
  // MENU
  // =============================================================

  Widget _buildMenuButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onMenuPressed,
        borderRadius: BorderRadius.circular(30),
        child: const SizedBox(
          width: 38,
          height: 50,
          child: Center(
            child: Icon(Icons.menu_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
