import 'package:flutter/material.dart';

import 'package:themis_trust_mobile/screens/client/client_home_page/client_bottom_navigation.dart';
import 'package:themis_trust_mobile/screens/client/client_home_page/client_customer_reviews.dart';
import 'package:themis_trust_mobile/screens/client/client_home_page/client_featured_lawyers.dart';
import 'package:themis_trust_mobile/screens/client/client_home_page/client_legal_fields.dart';
import 'package:themis_trust_mobile/screens/client/client_home_page/client_statistics.dart';
import 'package:themis_trust_mobile/screens/client/client_home_page/client_usage_process.dart';
import 'package:themis_trust_mobile/screens/client/client_lawyer_page/client_lawyers_screen.dart';
import 'package:themis_trust_mobile/screens/client/client_message_page/client_messages_screen.dart';
import 'package:themis_trust_mobile/screens/client/client_notification_page/client_notifications_screen.dart';
import 'package:themis_trust_mobile/screens/client/client_profile_page/client_profile_screen.dart';

import 'client_menu.dart';
import 'client_home_banner.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // ============================================================
  // FOOTER SELECTED INDEX
  // ============================================================

  int selectedIndex = 0;

  // ============================================================
  // KEYS CHO CÁC TAB
  // ============================================================

  final GlobalKey<ClientMessagesScreenState> _messagesKey =
  GlobalKey<ClientMessagesScreenState>();

  final GlobalKey<ClientNotificationsScreenState> _notificationsKey =
  GlobalKey<ClientNotificationsScreenState>();

  final GlobalKey<ClientProfileScreenState> _profileKey =
  GlobalKey<ClientProfileScreenState>();

  // ============================================================
  // XỬ LÝ KHI CHUYỂN TAB
  // ============================================================

  void _onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });

    // ------------------------------------------------------------
    // TAB NHẮN TIN
    // ------------------------------------------------------------

    if (index == 2) {
      _messagesKey.currentState?.refreshAfterTabChange();
    }

    // ------------------------------------------------------------
    // TAB THÔNG BÁO
    // ------------------------------------------------------------

    if (index == 3) {
      _notificationsKey.currentState?.refreshAfterTabChange();
    }

    // ------------------------------------------------------------
    // TAB CÁ NHÂN
    // ------------------------------------------------------------

    if (index == 4) {
      _profileKey.currentState?.refreshAfterTabChange();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ==========================================================
      // BODY
      // ==========================================================

      body: IndexedStack(
        index: selectedIndex,
        children: [
          // ======================================================
          // 0. TRANG CHỦ
          // ======================================================

          _buildHomePage(),

          // ======================================================
          // 1. LUẬT SƯ
          // ======================================================

          const ClientLawyersScreen(),

          // ======================================================
          // 2. TIN NHẮN
          // ======================================================

          ClientMessagesScreen(
            key: _messagesKey,
          ),

          // ======================================================
          // 3. THÔNG BÁO
          // ======================================================

          ClientNotificationsScreen(
            key: _notificationsKey,
          ),

          // ======================================================
          // 4. TÀI KHOẢN
          // ======================================================

          ClientProfileScreen(
            key: _profileKey,
          ),
        ],
      ),

      // ==========================================================
      // FOOTER
      // ==========================================================

      bottomNavigationBar: ClientHomeBottomNavigationWidget(
        selectedIndex: selectedIndex,

        onItemSelected: _onTabSelected,
      ),
    );
  }

  // =============================================================
  // TRANG CHỦ
  // =============================================================

  Widget _buildHomePage() {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------

          const ClientHomeMenuWidget(),

          // ------------------------------------------------------
          // CONTENT
          // ------------------------------------------------------

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: const [
                  // =================================================
                  // BANNER
                  // =================================================

                  ClientHomeBannerWidget(),

                  // =================================================
                  // STATISTICS
                  // =================================================

                  ClientHomeStatisticsWidget(),

                  // =================================================
                  // LEGAL FIELDS
                  // =================================================

                  ClientHomeLegalFieldsWidget(),

                  // =================================================
                  // FEATURED LAWYERS
                  // =================================================

                  ClientHomeFeaturedLawyersWidget(),

                  // =================================================
                  // USAGE PROCESS
                  // =================================================

                  ClientHomeUsageProcessWidget(),

                  // =================================================
                  // CUSTOMER REVIEWS
                  // =================================================

                  ClientHomeCustomerReviewsWidget(),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}