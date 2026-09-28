import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_consultation_page/lawyer_consultation_calendar.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_message_page/lawyer_messages_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_notification_page/lawyer_notifications_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_profile_page/lawyer_edit_profile_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_profile_page/lawyer_profile_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_request_page/lawyer_consultation_request.dart';
import 'package:themis_trust_mobile/services/api_service.dart';

// ============================================================
// IMPORT CÁC TRANG LAWYER
// ============================================================

class LawyerHomeScreen extends StatefulWidget {
  const LawyerHomeScreen({super.key});

  @override
  State<LawyerHomeScreen> createState() => _LawyerHomeScreenState();
}

class _LawyerHomeScreenState extends State<LawyerHomeScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF0D3558);
  static const Color darkNavy = Color(0xFF092E50);
  static const Color gold = Color(0xFFC78A2C);
  static const Color lightGold = Color(0xFFFFF3DF);
  static const Color background = Color(0xFFF5F8FB);
  static const Color inactiveColor = Color(0xFF71839A);
  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  int _selectedIndex = 0;

  // ============================================================
  // BADGE
  // ============================================================

  int consultationRequestCount = 5;

  int messageCount = 2;

  int notificationCount = 3;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            LawyerHomeTab(
              onOpenCalendar: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),

            const LawyerConsultationCalendar(),

            const LawyerMessagesScreen(),

            const LawyerNotificationScreen(),

            const LawyerProfileScreen(),
          ],
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION CỐ ĐỊNH
      // ========================================================
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      height: 78,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(17),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavItem(
              index: 0,
              icon: Icons.home_rounded,
              title: 'Trang chủ',
            ),
          ),

          Expanded(
            child: _buildNavItem(
              index: 1,
              icon: Icons.calendar_month_rounded,
              title: 'Lịch tư vấn',
            ),
          ),

          Expanded(
            child: _buildNavItem(
              index: 2,
              icon: Icons.chat_bubble_rounded,
              title: 'Tin nhắn',
              showDot: messageCount > 0,
            ),
          ),

          Expanded(
            child: _buildNavItem(
              index: 3,
              icon: Icons.notifications_rounded,
              title: 'Thông báo',
              showDot: notificationCount > 0,
            ),
          ),

          Expanded(
            child: _buildNavItem(
              index: 4,
              icon: Icons.person_rounded,
              title: 'Hồ sơ',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAV ITEM
  // ============================================================

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String title,
    bool showDot = false,
  }) {
    final bool isSelected = _selectedIndex == index;


    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;

          // Click Tin nhắn -> tắt chấm đỏ
          if (index == 2) {
            messageCount = 0;
          }

          // Click Thông báo -> tắt chấm đỏ
          if (index == 3) {
            notificationCount = 0;
          }
        });

        // Giữ nguyên phần chuyển trang hiện tại của bạn ở đây
        // Ví dụ:
        // _onBottomNavigationTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 25,
                color: isSelected ? gold : inactiveColor,
              ),

              if (showDot)
                Positioned(
                  right: -4,
                  top: -3,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? gold : inactiveColor,
              fontSize: 10.5,
              fontWeight: isSelected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// TRANG CHỦ LAWYER
// =================================================================

class LawyerHomeTab extends StatefulWidget {
  final VoidCallback onOpenCalendar;

  const LawyerHomeTab({
    super.key,
    required this.onOpenCalendar,
  });

  @override
  State<LawyerHomeTab> createState() =>
      _LawyerHomeTabState();
}

class _LawyerHomeTabState extends State<LawyerHomeTab> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF0D3558);
  static const Color darkNavy = Color(0xFF092E50);
  static const Color gold = Color(0xFFC78A2C);
  static const Color lightGold = Color(0xFFFFF3DF);
  static const Color blue = Color(0xFF1675D1);
  static const Color muted = Color(0xFF71839A);
  static const Color background = Color(0xFFF5F8FB);
  static const Color border = Color(0xFFE1E8F0);

  // ============================================================
  // DỮ LIỆU
  // ============================================================

  final ApiService _api = ApiService();

  String lawyerName = '';
  String lawyerTitle = '';
  String lawyerAvatar = '';

  bool isLoadingLawyer = true;

  int todayAppointments = 0;
  int newConsultationRequests = 0;
  int followingCustomers = 0;
  double averageRating = 0;

  @override
  void initState() {
    super.initState();
    _loadLawyerDashboard();
  }

  Future<void> _loadLawyerDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        debugPrint('LAWYER DASHBOARD: Không có token');
        return;
      }

      final data = await _api.get('/lawyer-dashboard', token: token);

      debugPrint('LAWYER DASHBOARD RESPONSE: $data');

      if (data is! Map<String, dynamic>) {
        throw Exception('Dữ liệu dashboard không hợp lệ');
      }

      if (!mounted) return;

      setState(() {
        lawyerName = data['fullName']?.toString() ?? '';

        lawyerTitle = data['title']?.toString() ?? '';

        lawyerAvatar = data['avatarUrl']?.toString() ?? '';

        todayAppointments =
            int.tryParse(data['todayAppointments']?.toString() ?? '0') ?? 0;

        newConsultationRequests =
            int.tryParse(data['newConsultationRequests']?.toString() ?? '0') ??
                0;

        followingCustomers =
            int.tryParse(data['followingCustomers']?.toString() ?? '0') ?? 0;

        averageRating =
            double.tryParse(data['averageRating']?.toString() ?? '0') ?? 0.0;

        isLoadingLawyer = false;
      });
    } catch (e, stackTrace) {
      debugPrint('LOAD LAWYER DASHBOARD ERROR: $e');

      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() {
        isLoadingLawyer = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(11, 8, 11, 15),
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            _buildHeader(),

            const SizedBox(height: 10),

            // ==================================================
            // BANNER
            // ==================================================
            _buildWelcomeBanner(),

            const SizedBox(height: 10),

            // ==================================================
            // STATISTICS
            // ==================================================
            _buildStatistics(),

            const SizedBox(height: 10),

            // ==================================================
            // TODAY CONSULTATION
            // ==================================================
            _buildTodayConsultation(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // ======================================================
          // LOGO
          // ======================================================

          _buildLogo(),

          const Spacer(),

          // ======================================================
          // AVATAR
          // ======================================================
          _buildHeaderAvatar(),
        ],
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: const BoxDecoration(
            color: lightGold,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.balance_rounded, color: gold, size: 25),
        ),

        const SizedBox(width: 7),

        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THEMIS',
              style: TextStyle(
                color: darkNavy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),

            Text(
              'TRUST',
              style: TextStyle(
                color: navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // HEADER AVATAR
  // ============================================================

  Widget _buildHeaderAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE0E5EA),
          ),
          child: ClipOval(
            child: lawyerAvatar.isNotEmpty
                ? Image.network(
              lawyerAvatar,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _defaultAvatar();
              },
            )
                : _defaultAvatar(),
          ),
        ),

        // ======================================================
        // ONLINE
        // ======================================================
        Positioned(
          right: -1,
          bottom: 1,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF19A875),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DEFAULT AVATAR
  // ============================================================

  Widget _defaultAvatar() {
    return const Icon(Icons.person_rounded, color: Color(0xFF8290A0), size: 27);
  }

  // ============================================================
  // WELCOME BANNER
  // ============================================================

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      height: 145,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(9)),
      child: Stack(
        children: [
          // ====================================================
          // BACKGROUND IMAGE
          // ====================================================

          Positioned.fill(
            child: Image.asset('assets/images/banner2.png', fit: BoxFit.cover),
          ),

          // ====================================================
          // OVERLAY
          // ====================================================
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withOpacity(0.92),
                    Colors.white.withOpacity(0.72),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // CONTENT
          // ====================================================
          Positioned(
            left: 17,
            top: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chào mừng trở lại,',
                  style: TextStyle(
                    color: gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$lawyerTitle $lawyerName',
                  style: const TextStyle(
                    color: darkNavy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Container(width: 70, height: 2, color: gold),

                const SizedBox(height: 10),

                const Text(
                  '"Pháp luật không chỉ bảo vệ quyền lợi,',
                  style: TextStyle(
                    color: navy,
                    fontSize: 8.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'mà còn kiến tạo niềm tin."',
                  style: TextStyle(
                    color: navy,
                    fontSize: 8.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatisticCard(
            icon: Icons.calendar_month_rounded,
            iconColor: blue,
            backgroundColor: const Color(0xFFEAF4FF),
            value: '$todayAppointments',
            title: 'Lịch tư vấn\nhôm nay',
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: _buildStatisticCard(
            icon: Icons.description_rounded,
            iconColor: gold,
            backgroundColor: const Color(0xFFFFF3DF),
            value: '$newConsultationRequests',
            title: 'Yêu cầu tư vấn\nmới',
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: _buildStatisticCard(
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFFD83D63),
            backgroundColor: const Color(0xFFFFE9EE),
            value: '$followingCustomers',
            title: 'Khách hàng\nđang theo dõi',
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: _buildStatisticCard(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFF19A875),
            backgroundColor: const Color(0xFFE6F7EE),
            value: averageRating.toStringAsFixed(1),
            title: 'Đánh giá\ntrung bình',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTIC CARD
  // ============================================================

  Widget _buildStatisticCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String value,
    required String title,
  }) {
    return Container(
      height: 119,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: navy, fontSize: 7.5, height: 1.3),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY CONSULTATION
  // ============================================================

  Widget _buildTodayConsultation() {
    return Container(
      width: double.infinity,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: darkNavy,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          // ====================================================
          // ICON
          // ====================================================

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          // ====================================================
          // TEXT
          // ====================================================
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch tư vấn hôm nay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Bạn có $todayAppointments lịch tư vấn trong ngày hôm nay.',
                  style: const TextStyle(color: Color(0xFFCBD8E6), fontSize: 7),
                ),
              ],
            ),
          ),

          // ====================================================
          // BUTTON
          // ====================================================
          GestureDetector(
            onTap: widget.onOpenCalendar,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem lịch',
                    style: TextStyle(
                      color: navy,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(width: 7),

                  Icon(
                    Icons.arrow_forward_rounded,
                    color: navy,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
