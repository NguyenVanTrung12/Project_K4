import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:themis_trust_mobile/models/lawyer_model.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_profile_page/lawyer_case_list_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_profile_page/lawyer_consultation_request_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_profile_page/lawyer_list_client.dart';
import 'package:themis_trust_mobile/services/lawyer_service.dart';

import 'package:themis_trust_mobile/screens/lawyer/lawyer_profile_page/lawyer_edit_profile_screen.dart';

class LawyerProfileScreen extends StatefulWidget {
  const LawyerProfileScreen({
    super.key,
  });

  @override
  State<LawyerProfileScreen> createState() =>
      _LawyerProfileScreenState();
}

class _LawyerProfileScreenState
    extends State<LawyerProfileScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _navy = Color(0xFF123963);
  static const Color _gold = Color(0xFFF0A52B);
  static const Color _muted = Color(0xFF70869D);
  static const Color _border = Color(0xFFE4EAF1);
  static const Color _background = Color(0xFFF8FAFD);

  // ============================================================
  // STATE
  // ============================================================

  LawyerModel? _lawyer;

  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadLawyer();
  }

  // ============================================================
  // LOAD LAWYER
  // ============================================================

  Future<void> _loadLawyer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs =
      await SharedPreferences.getInstance();

      final lawyerId = prefs.getString('userId');

      if (lawyerId == null || lawyerId.isEmpty) {
        throw Exception(
          'Không tìm thấy thông tin tài khoản đăng nhập.',
        );
      }

      final lawyer =
      await LawyerService().getLawyerById(lawyerId);

      if (!mounted) return;

      setState(() {
        _lawyer = lawyer;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: _buildBody(context),
            ),
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
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _border,
            width: 1,
          ),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Trang cá nhân',
              style: TextStyle(
                color: _navy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _gold,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 45,
              ),

              const SizedBox(height: 12),

              const Text(
                'Không thể tải thông tin luật sư',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _loadLawyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_lawyer == null) {
      return const Center(
        child: Text(
          'Không có thông tin luật sư.',
          style: TextStyle(
            color: _muted,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _gold,
      onRefresh: _loadLawyer,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 30,
        ),
        child: Column(
          children: [
            _buildProfileInformation(
              context,
              _lawyer!,
            ),

            const SizedBox(height: 12),

            _buildContactInformation(
              context,
            ),

            const SizedBox(height: 12),

            _buildLogout(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE INFORMATION
  // ============================================================

  Widget _buildProfileInformation(
      BuildContext context,
      LawyerModel lawyer,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ======================================================
          // AVATAR
          // ======================================================

          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildAvatar(
                    lawyer.avatarUrl,
                  ),
                ),
              ),

              // Verified
              Positioned(
                right: -1,
                bottom: 1,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: _gold,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 15),

          // ======================================================
          // NAME + ROLE
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  lawyer.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 7),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4DF),
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.gavel_rounded,
                        color: _gold,
                        size: 14,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        lawyer.title?.isNotEmpty == true
                            ? lawyer.title!
                            : 'Luật sư',
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // EDIT
          // ======================================================

          // Material(
          //   color: const Color(0xFFF1F5F9),
          //   borderRadius: BorderRadius.circular(10),
          //   child: InkWell(
          //     borderRadius: BorderRadius.circular(10),
          //     onTap: () async {
          //       await Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (_) =>
          //           const LawyerEditProfileScreen(),
          //         ),
          //       );
          //
          //       // Quay lại thì gọi API lại
          //       _loadLawyer();
          //     },
          //     child: const Padding(
          //       padding: EdgeInsets.all(9),
          //       child: Icon(
          //         Icons.edit_rounded,
          //         color: _navy,
          //         size: 18,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFFE7EDF4),
        child: const Icon(
          Icons.person_rounded,
          size: 42,
          color: _navy,
        ),
      );
    }

    String url = avatarUrl.trim();

    if (url.startsWith('/')) {
      url = 'http://10.0.2.2:5000$url';
    } else if (url.startsWith('http://localhost')) {
      url = url.replaceFirst(
        'http://localhost',
        'http://10.0.2.2',
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        return Container(
          color: const Color(0xFFE7EDF4),
          child: const Icon(
            Icons.person_rounded,
            size: 42,
            color: _navy,
          ),
        );
      },
    );
  }

  // ============================================================
  // CONTACT INFORMATION
  // ============================================================

  Widget _buildContactInformation(
      BuildContext context,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.contact_page_rounded,
            iconBackground: const Color(0xFFF0F4F8),
            iconColor: _navy,
            title: 'Thông tin liên hệ',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const LawyerEditProfileScreen(),
                ),
              );

              _loadLawyer();
            },
          ),

          _buildDivider(),

          _buildMenuItem(
            icon: Icons.people_alt_rounded,
            iconBackground: const Color(0xFFF0F4F8),
            iconColor: _navy,
            title: 'Khách hàng',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LawyerListClientScreen(),
                ),
              );
            },
          ),

          _buildDivider(),

          _buildMenuItem(
            icon: Icons.folder_special_rounded,
            iconBackground: const Color(0xFFF0F4F8),
            iconColor: _navy,
            title: 'Hồ sơ vụ án',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LawyerCaseListScreen(),
                ),
              );
            },
          ),

          _buildDivider(),

          _buildMenuItem(
            icon: Icons.assignment_rounded,
            iconBackground: const Color(0xFFF0F4F8),
            iconColor: _navy,
            title: 'Yêu cầu tư vấn',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LawyerConsultationRequestScreen(),
                ),
              );
            },
          ),

          _buildDivider(),

          _buildMenuItem(
            icon: Icons.settings_rounded,
            iconBackground: const Color(0xFFF0F4F8),
            iconColor: _navy,
            title: 'Cài đặt',
            onTap: () {
              // TODO:
              // Chuyển tới trang cài đặt
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: _muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: _border,
      indent: 63,
      endIndent: 12,
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Widget _buildLogout(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF0D9D9),
        ),
      ),
      child: _buildMenuItem(
        icon: Icons.logout_rounded,
        iconBackground: const Color(0xFFFFF0F0),
        iconColor: const Color(0xFFD94A4A),
        title: 'Đăng xuất',
        onTap: () {
          _showLogoutDialog(context);
        },
      ),
    );
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================
// ============================================================
// LOGOUT
// ============================================================

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('userName');
      await prefs.remove('userEmail');
      await prefs.remove('userPhone');
      await prefs.remove('userRole');
      await prefs.remove('avatarUrl');
      await prefs.remove('expiresAt');

      debugPrint('===== LOGOUT =====');
      debugPrint('Session đã được xóa');
      debugPrint('==================');

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );
    } catch (e) {
      debugPrint('LOGOUT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể đăng xuất. Vui lòng thử lại.'),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
            style: TextStyle(
              color: _muted,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Đóng dialog trước
                Navigator.pop(dialogContext);

                // Xóa session và quay về Home
                await _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFD94A4A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'Đăng xuất',
              ),
            ),
          ],
        );
      },
    );
  }
}