import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:themis_trust_mobile/models/user_model.dart';
import 'package:themis_trust_mobile/screens/client/client_login_page/client_login_screen.dart';
import 'package:themis_trust_mobile/screens/client/client_profile_page/client_consultation_calendar_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_home_page/lawyer_home_screen.dart';
import 'package:themis_trust_mobile/services/user_service.dart';
import 'package:themis_trust_mobile/services/auth_navigation_service.dart';

import 'package:themis_trust_mobile/screens/client/client_personal_info_page/client_personal_info_screen.dart';

// =============================================================
// COLORS
// =============================================================

const Color clientProfileNavy = Color(0xFF123963);
const Color clientProfileDarkNavy = Color(0xFF0D2E52);
const Color clientProfileGold = Color(0xFFC68A2B);
const Color clientProfileText = Color(0xFF173A63);
const Color clientProfileMuted = Color(0xFF7187A0);
const Color clientProfileBorder = Color(0xFFE3EAF2);

// =============================================================
// SCREEN
// =============================================================

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => ClientProfileScreenState();
}

// =============================================================
// STATE
// =============================================================

class ClientProfileScreenState extends State<ClientProfileScreen> {
  // ============================================================
  // SERVICE
  // ============================================================

  final UserService _userService = UserService();

  // ============================================================
  // USER DATA
  // ============================================================

  UserModel? _user;

  String? _currentUserId;

  bool _isLoading = true;

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadUserProfile();
  }
  Future<void> refreshAfterTabChange() async {
    if (!mounted) return;

    await _loadUserProfile();
  }
  // ============================================================
  // GET CURRENT USER ID
  // ============================================================

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('userId');

    debugPrint('PROFILE USER ID: $userId');

    return userId;
  }

  // ============================================================
  // LOAD USER PROFILE
  // ============================================================

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      debugPrint('PROFILE TOKEN: ${token != null ? 'Có' : 'Không'}');
      debugPrint('PROFILE USER ID: $userId');

      // ============================================================
      // CHƯA ĐĂNG NHẬP
      // ============================================================

      if (token == null ||
          token.trim().isEmpty ||
          userId == null ||
          userId.trim().isEmpty) {
        debugPrint('PROFILE: Chưa đăng nhập');

        if (!mounted) return;

        setState(() {
          _user = null;
          _currentUserId = null;
          _isLoading = false;
        });

        return;
      }

      // ============================================================
      // ĐÃ ĐĂNG NHẬP
      // ============================================================

      debugPrint('PROFILE: Đang lấy user $userId');

      final user = await _userService.getUserById(userId);

      debugPrint(
        'PROFILE: Lấy user thành công: ${user.fullName}',
      );

      if (!mounted) return;

      setState(() {
        _user = user;
        _currentUserId = userId;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _user = null;
        _currentUserId = null;
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }
// ============================================================
// LOGOUT
// ============================================================

  Future<void> _handleLogout() async {
    // Hiện hộp thoại xác nhận
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(
              color: clientProfileDarkNavy,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại?',
            style: TextStyle(
              color: clientProfileMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: clientProfileMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64545),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    // Người dùng chọn Hủy
    if (shouldLogout != true) {
      return;
    }

    // ==========================================================
    // XÓA THÔNG TIN ĐĂNG NHẬP
    // ==========================================================

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');

    await prefs.remove('fullName');
    await prefs.remove('name');
    await prefs.remove('userName');
    await prefs.remove('clientName');

    await prefs.remove('phone');
    await prefs.remove('phoneNumber');
    await prefs.remove('mobile');
    await prefs.remove('mobilePhone');

    await prefs.remove('email');
    await prefs.remove('userEmail');

    debugPrint('LOGOUT: Đã xóa thông tin đăng nhập');

    if (!mounted) return;

    // ==========================================================
    // CHUYỂN VỀ MÀN HÌNH ĐĂNG NHẬP
    // ==========================================================

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientLoginScreen(),
      ),
          (route) => false,
    );
  }
  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _getErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'Không thể kết nối đến máy chủ';
    }

    if (message.contains('401')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại';
    }

    if (message.contains('403')) {
      return 'Bạn không có quyền xem thông tin này';
    }

    if (message.contains('404')) {
      return 'Không tìm thấy thông tin người dùng';
    }

    return 'Không thể tải thông tin. Vui lòng thử lại';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),

      // ========================================================
      // KHÔNG CÓ HEADER
      // KHÔNG CÓ FOOTER / BOTTOM NAVIGATION
      // ========================================================
      body: SafeArea(child: _buildBody()),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: clientProfileNavy),
      );
    }

    // ----------------------------------------------------------
    // CHƯA ĐĂNG NHẬP
    // ----------------------------------------------------------

    if (_currentUserId == null) {
      return _buildLoginRequiredState();
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // ----------------------------------------------------------
    // USER NULL
    // ----------------------------------------------------------

    if (_user == null) {
      return _buildErrorState();
    }

    // ----------------------------------------------------------
    // PROFILE
    // ----------------------------------------------------------

    return RefreshIndicator(
      color: clientProfileNavy,
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // ==================================================
            // TIÊU ĐỀ TRANG
            // ==================================================

            _buildHeader(),

            // ==================================================
            // PROFILE
            // ==================================================
            _buildProfileHero(),

            const SizedBox(height: 16),

            // ==================================================
            // MENU
            // ==================================================
            _buildProfileMenu(),

            const SizedBox(height: 16),

            _buildLogoutButton(),

            const SizedBox(height: 16),

            // ==================================================
            // SUPPORT
            // ==================================================
            _buildSupportCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trang cá nhân',
            style: TextStyle(
              color: clientProfileDarkNavy,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),

          SizedBox(height: 4),

          Text(
            'Quản lý thông tin và tài khoản của bạn',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: clientProfileMuted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE HERO
  // ============================================================

  Widget _buildProfileHero() {
    final user = _user!;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 245),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F7FB),
        border: Border(bottom: BorderSide(color: Color(0xFFE5ECF3))),
      ),
      child: Stack(
        children: [
          // ======================================================
          // BACKGROUND DECORATION
          // ======================================================

          Positioned(
            right: -55,
            top: -30,
            child: Opacity(
              opacity: 0.13,
              child: Icon(
                Icons.balance_rounded,
                size: 270,
                color: clientProfileNavy,
              ),
            ),
          ),

          Positioned(
            right: -20,
            bottom: -35,
            child: Opacity(
              opacity: 0.07,
              child: Icon(
                Icons.menu_book_rounded,
                size: 180,
                color: clientProfileGold,
              ),
            ),
          ),

          // ======================================================
          // CONTENT
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 25, 18, 25),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // AVATAR
                // =================================================

                _buildProfileAvatar(),

                const SizedBox(width: 20),

                // =================================================
                // INFORMATION
                // =================================================
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xin chào,',
                          style: TextStyle(
                            color: clientProfileNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          user.fullName.isNotEmpty
                              ? user.fullName
                              : 'Người dùng',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: clientProfileDarkNavy,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),

                        const SizedBox(height: 9),

                        const Text(
                          'Cảm ơn bạn đã tin tưởng Themis.',
                          style: TextStyle(
                            color: clientProfileNavy,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),

                        const Text(
                          'Chúng tôi luôn đồng hành cùng bạn.',
                          style: TextStyle(
                            color: clientProfileNavy,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // =================================================
                        // CHIPS
                        // =================================================
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _buildMemberChip(),

                            // _buildJoinDateChip(user.createdAt),
                          ],
                        ),
                      ],
                    ),
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
  // AVATAR
  // ============================================================

  Widget _buildProfileAvatar() {
    final avatarUrl = _user?.avatarUrl ?? '';

    return SizedBox(
      width: 137,
      height: 165,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 137,
            height: 165,
            decoration: BoxDecoration(
              color: const Color(0xFFE1E5EA),
              borderRadius: BorderRadius.circular(70),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(70),

              child: avatarUrl.isNotEmpty
                  ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,

                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
              )
                  : _buildDefaultAvatar(),
            ),
          ),

          // ========================================================
          // CAMERA
          // ========================================================
          Positioned(
            right: -3,
            bottom: 1,
            child: GestureDetector(
              onTap: _changeAvatar,
              child: Container(
                width: 51,
                height: 51,
                decoration: BoxDecoration(
                  color: clientProfileNavy,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEFAULT AVATAR
  // ============================================================

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFE1E5EA),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF8795A4),
        size: 78,
      ),
    );
  }

  // ============================================================
  // MEMBER CHIP
  // ============================================================

  Widget _buildMemberChip() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0D8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              color: Color(0xFFE0AD51),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),

          const SizedBox(width: 6),

          const Text(
            'Thành viên',
            style: TextStyle(
              color: clientProfileGold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // JOIN DATE
  // ============================================================

  Widget _buildJoinDateChip(DateTime createdAt) {
    final localDate = createdAt.toLocal();

    final month = localDate.month.toString().padLeft(2, '0');

    final year = localDate.year.toString();

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE5EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: clientProfileNavy,
            size: 16,
          ),

          const SizedBox(width: 5),

          Text(
            'Tham gia từ $month/$year',
            style: const TextStyle(
              color: clientProfileNavy,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE MENU
  // ============================================================

  Widget _buildProfileMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: clientProfileBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // 1. THÔNG TIN CÁ NHÂN
          // ======================================================

          ClientProfileMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Thông tin cá nhân',
            subtitle: 'Quản lý thông tin, số điện thoại, email...',
            onTap: _openProfileInfo,
          ),

          // ======================================================
          // 2. LỊCH TƯ VẤN
          // ======================================================
          ClientProfileMenuItem(
            icon: Icons.access_time_rounded,
            title: 'Lịch tư vấn',
            subtitle: 'Xem lịch tư vấn sắp tới và lịch sử',
            onTap: _openConsultationCalendar,
          ),

          // ======================================================
          // 3. YÊU CẦU TƯ VẤN
          // ======================================================
          ClientProfileMenuItem(
            icon: Icons.description_outlined,
            title: 'Yêu cầu tư vấn của tôi',
            subtitle: 'Theo dõi trạng thái các yêu cầu',
            onTap: _openConsultationRequests,
          ),

          // ======================================================
          // 4. LUẬT SƯ YÊU THÍCH
          // ======================================================
          ClientProfileMenuItem(
            icon: Icons.favorite_border_rounded,
            title: 'Luật sư yêu thích',
            subtitle: 'Danh sách luật sư bạn đã lưu',
            onTap: _openFavoriteLawyers,
          ),

          // ======================================================
          // 5. THÔNG BÁO
          // ======================================================
          // ClientProfileMenuItem(
          //   icon: Icons.notifications_none_rounded,
          //   title: 'Thông báo',
          //   subtitle: 'Cập nhật thông tin mới nhất',
          //   onTap: _openNotifications,
          // ),

          // ======================================================
          // 6. CÀI ĐẶT
          // ======================================================
          ClientProfileMenuItem(
            icon: Icons.settings_outlined,
            title: 'Cài đặt',
            subtitle: 'Bảo mật, ngôn ngữ, tùy chọn khác',
            onTap: _openSettings,
          ),

          // ======================================================
          // 7. TRỢ GIÚP
          // ======================================================
          ClientProfileMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Trợ giúp',
            subtitle: 'Câu hỏi thường gặp và hỗ trợ',
            showDivider: false,
            onTap: _openHelp,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUPPORT CARD
  // ============================================================

  Widget _buildSupportCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF1E2CA)),
      ),
      child: Row(
        children: [
          // ======================================================
          // ICON
          // ======================================================

          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEFD5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: clientProfileGold,
              size: 29,
            ),
          ),

          const SizedBox(width: 11),

          // ======================================================
          // TEXT
          // ======================================================
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cần hỗ trợ?',
                  style: TextStyle(
                    color: clientProfileGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Đội ngũ Themis luôn sẵn sàng giúp bạn 24/7',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: clientProfileNavy,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ======================================================
          // CONTACT BUTTON
          // ======================================================
          GestureDetector(
            onTap: _contactSupport,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: clientProfileGold,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Liên hệ ngay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(width: 7),

                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
// ============================================================
// LOGOUT BUTTON
// ============================================================

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFF0DADA),
              ),
            ),
            child: Row(
              children: [
                // ICON
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEEEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFD64545),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 13),

                // TEXT
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: Color(0xFFD13E3E),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Đăng xuất khỏi tài khoản hiện tại',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD13E3E),
                  size: 27,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
// LOGIN REQUIRED STATE
// ============================================================

  Widget _buildLoginRequiredState() {
    return Column(
      children: [
        _buildHeader(),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // =================================================
                  // ICON
                  // =================================================

                  Container(
                    width: 75,
                    height: 75,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF1F8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: clientProfileNavy,
                      size: 38,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // =================================================
                  // MESSAGE
                  // =================================================

                  const Text(
                    'Bạn cần đăng nhập để xem thông tin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: clientProfileText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // =================================================
                  // LOGIN BUTTON
                  // =================================================

                  SizedBox(
                    width: 150,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _openLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clientProfileNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 18,
                          ),

                          SizedBox(
                            width: 7,
                          ),

                          Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openLogin() async {
    await AuthNavigationService.loginAndRedirect(context);
  }
  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Column(
      children: [
        _buildHeader(),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(0xFFB7C5D4),
                    size: 58,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    _errorMessage ?? 'Không thể tải thông tin',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: clientProfileText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: clientProfileNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _openProfileInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClientPersonalInfoScreen()),
    );
  }

  void _openConsultationCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClientConsultationCalendarScreen()),
    );
  }

  void _openConsultationRequests() {
    _showMessage('Yêu cầu tư vấn của tôi');
  }

  void _openFavoriteLawyers() {
    _showMessage('Luật sư yêu thích');
  }

  // void _openNotifications() {
  //   _showMessage('Thông báo');
  // }

  void _openSettings() {
    _showMessage('Cài đặt');
  }

  void _openHelp() {
    _showMessage('Trợ giúp');
  }

  void _changeAvatar() {
    _showMessage('Thay đổi ảnh đại diện');
  }

  void _contactSupport() {
    _showMessage('Liên hệ hỗ trợ');
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message sẽ được kết nối sau.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// =================================================================
// PROFILE MENU ITEM
// =================================================================

class ClientProfileMenuItem extends StatelessWidget {
  const ClientProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.showDivider = true,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  final int? badge;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 9, 10),
              child: Row(
                children: [
                  // =================================================
                  // ICON
                  // =================================================

                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF5E6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFFC4811E), size: 28),
                  ),

                  const SizedBox(width: 13),

                  // =================================================
                  // TEXT
                  // =================================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF153B65),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7187A0),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================================================
                  // BADGE
                  // =================================================
                  if (badge != null) ...[
                    Container(
                      width: 29,
                      height: 29,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE52D35),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),
                  ],

                  // =================================================
                  // ARROW
                  // =================================================
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF7187A0),
                    size: 27,
                  ),
                ],
              ),
            ),

            if (showDivider)
              const Padding(
                padding: EdgeInsets.only(left: 81),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE7EDF3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
