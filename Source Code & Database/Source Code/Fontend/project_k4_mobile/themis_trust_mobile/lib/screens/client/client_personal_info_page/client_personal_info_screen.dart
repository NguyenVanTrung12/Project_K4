import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:themis_trust_mobile/models/user_model.dart';
import 'package:themis_trust_mobile/screens/client/client_personal_info_page/client_personal_info_edit_screen.dart';
import 'package:themis_trust_mobile/services/user_service.dart';

class ClientPersonalInfoScreen extends StatefulWidget {
  const ClientPersonalInfoScreen({
    super.key,
  });

  @override
  State<ClientPersonalInfoScreen> createState() =>
      _ClientPersonalInfoScreenState();
}

class _ClientPersonalInfoScreenState
    extends State<ClientPersonalInfoScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF173B66);
  static const Color darkNavy = Color(0xFF102F55);
  static const Color gold = Color(0xFFC98B2E);
  static const Color muted = Color(0xFF7186A0);
  static const Color border = Color(0xFFE5EBF2);

  // ============================================================
  // API SERVER
  //
  // launchSettings.json:
  //
  // HTTP:
  // http://localhost:5000
  //
  // Android Emulator:
  // http://10.0.2.2:5000
  // ============================================================

  static const String _serverBaseUrl =
      'http://10.0.2.2:5000';

  // ============================================================
  // SERVICE
  // ============================================================

  final UserService _userService = UserService();

  // ============================================================
  // USER
  // ============================================================

  UserModel? _user;

  String? _currentUserId;

  bool _isLoading = true;

  String? _errorMessage;

  // ============================================================
  // EXTRA INFORMATION
  //
  // UserModel hiện tại chưa có:
  // - dateOfBirth
  // - gender
  // - address
  //
  // Tạm thời lấy từ SharedPreferences.
  // ============================================================

  String _dateOfBirth = '';
  String _gender = '';
  String _address = '';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadUserProfile();
  }

  // ============================================================
  // GET CURRENT USER ID
  // ============================================================

  Future<String?> _getCurrentUserId() async {
    final prefs =
    await SharedPreferences.getInstance();

    final userId =
    prefs.getString('userId');

    debugPrint(
      '============================================',
    );

    debugPrint(
      'PERSONAL PROFILE USER ID: $userId',
    );

    debugPrint(
      '============================================',
    );

    return userId;
  }

  // ============================================================
  // LOAD EXTRA INFORMATION
  // ============================================================

  Future<void> _loadExtraInformation() async {
    final prefs =
    await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _dateOfBirth =
          prefs.getString('dateOfBirth') ??
              prefs.getString('dob') ??
              '';

      _gender =
          prefs.getString('gender') ?? '';

      _address =
          prefs.getString('address') ?? '';
    });

    debugPrint(
      'DATE OF BIRTH LOCAL: $_dateOfBirth',
    );

    debugPrint(
      'GENDER LOCAL: $_gender',
    );

    debugPrint(
      'ADDRESS LOCAL: $_address',
    );
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
      // ========================================================
      // LOAD EXTRA INFORMATION
      // ========================================================

      await _loadExtraInformation();

      // ========================================================
      // GET USER ID
      // ========================================================

      final userId =
      await _getCurrentUserId();

      if (userId == null ||
          userId.trim().isEmpty) {
        debugPrint(
          'PERSONAL PROFILE: Không tìm thấy userId',
        );

        if (!mounted) return;

        setState(() {
          _user = null;
          _currentUserId = null;
          _isLoading = false;
          _errorMessage =
          'Không tìm thấy thông tin tài khoản';
        });

        return;
      }

      debugPrint(
        'PERSONAL PROFILE: Đang lấy user $userId',
      );

      // ========================================================
      // GET USER FROM API
      // ========================================================

      final user =
      await _userService.getUserById(
        userId,
      );

      debugPrint(
        '============================================',
      );

      debugPrint(
        'PERSONAL PROFILE: Lấy user thành công',
      );

      debugPrint(
        'USER ID: ${user.id}',
      );

      debugPrint(
        'USER NAME: ${user.fullName}',
      );

      debugPrint(
        'USER EMAIL: ${user.email}',
      );

      debugPrint(
        'USER PHONE: ${user.phone}',
      );

      debugPrint(
        'USER ROLE: ${user.role}',
      );

      debugPrint(
        'USER AVATAR: ${user.avatarUrl}',
      );

      debugPrint(
        '============================================',
      );

      if (!mounted) return;

      setState(() {
        _user = user;
        _currentUserId = userId;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        '============================================',
      );

      debugPrint(
        'PERSONAL PROFILE ERROR',
      );

      debugPrint(
        e.toString(),
      );

      debugPrint(
        '============================================',
      );

      if (!mounted) return;

      setState(() {
        _user = null;
        _isLoading = false;
        _errorMessage =
            _getErrorMessage(e);
      });
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _getErrorMessage(
      Object error,
      ) {
    final message =
    error.toString();

    if (message.contains(
      'SocketException',
    )) {
      return 'Không thể kết nối đến máy chủ';
    }

    if (message.contains('401')) {
      return 'Phiên đăng nhập đã hết hạn';
    }

    if (message.contains('403')) {
      return 'Bạn không có quyền xem thông tin này';
    }

    if (message.contains('404')) {
      return 'Không tìm thấy thông tin người dùng';
    }

    return 'Không thể tải thông tin người dùng';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF7F9FC),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color: navy,
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // ==========================================================
    // USER NULL
    // ==========================================================

    if (_user == null) {
      return _buildErrorState();
    }

    // ==========================================================
    // PROFILE
    // ==========================================================

    return RefreshIndicator(
      color: navy,
      onRefresh:
      _loadUserProfile,
      child:
      SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
        padding:
        const EdgeInsets.fromLTRB(
          10,
          5,
          10,
          25,
        ),
        child: Column(
          children: [
            // ==================================================
            // PROFILE BANNER
            // ==================================================

            _buildProfileBanner(),

            const SizedBox(
              height: 11,
            ),

            // ==================================================
            // BASIC INFORMATION
            // ==================================================

            _buildBasicInformation(),

            const SizedBox(
              height: 11,
            ),

            // ==================================================
            // ADDITIONAL INFORMATION
            // ==================================================

            _buildAdditionalInformation(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE BANNER
  // ============================================================

  Widget _buildProfileBanner() {
    final user = _user!;

    return Container(
      width: double.infinity,
      height: 141,
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(8),
        color:
        const Color(0xFFE9EEF3),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.04),
            blurRadius: 7,
            offset:
            const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(8),
        child: Stack(
          children: [
            // ==================================================
            // BACKGROUND
            // ==================================================

            Positioned.fill(
              child: Container(
                decoration:
                const BoxDecoration(
                  gradient:
                  LinearGradient(
                    begin:
                    Alignment.centerLeft,
                    end:
                    Alignment.centerRight,
                    colors: [
                      Color(0xFFF1E8DC),
                      Color(0xFFF8F8F6),
                      Color(0xFFE6E8E8),
                    ],
                  ),
                ),
              ),
            ),

            // ==================================================
            // DECORATIVE SCALE
            // ==================================================

            Positioned(
              right: 4,
              top: -18,
              child: Opacity(
                opacity: 0.20,
                child: Icon(
                  Icons
                      .balance_rounded,
                  size: 155,
                  color: gold,
                ),
              ),
            ),

            // ==================================================
            // DECORATIVE BOOK
            // ==================================================

            Positioned(
              right: -15,
              bottom: -15,
              child: Opacity(
                opacity: 0.12,
                child: Icon(
                  Icons
                      .menu_book_rounded,
                  size: 145,
                  color: navy,
                ),
              ),
            ),

            // ==================================================
            // MAIN CONTENT
            // ==================================================

            Padding(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              child: Row(
                children: [
                  // ============================================
                  // AVATAR
                  // ============================================

                  _buildAvatar(),

                  const SizedBox(
                    width: 18,
                  ),

                  // ============================================
                  // USER INFORMATION
                  // ============================================

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Text(
                          user.fullName
                              .isNotEmpty
                              ? user.fullName
                              : 'Người dùng',
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            color:
                            darkNavy,
                            fontSize: 18,
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        // ======================================
                        // MEMBER TYPE
                        // ======================================

                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFFFF1D9,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                          ),
                          child: Row(
                            mainAxisSize:
                            MainAxisSize
                                .min,
                            children: [
                              const Icon(
                                Icons
                                    .workspace_premium_rounded,
                                color:
                                gold,
                                size: 13,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Text(
                                _getMemberType(
                                  user.role,
                                ),
                                style:
                                const TextStyle(
                                  color:
                                  gold,
                                  fontSize:
                                  8.5,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          'Hiểu luật – Vững bước',
                          style:
                          TextStyle(
                            color: navy,
                            fontSize:
                            9.5,
                            fontStyle:
                            FontStyle
                                .italic,
                            fontWeight:
                            FontWeight
                                .w500,
                          ),
                        ),

                        const Text(
                          'An tâm trong mọi quyết định.',
                          style:
                          TextStyle(
                            color: navy,
                            fontSize:
                            9.5,
                            fontStyle:
                            FontStyle
                                .italic,
                            fontWeight:
                            FontWeight
                                .w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MEMBER TYPE
  // ============================================================

  String _getMemberType(
      String? role,
      ) {
    switch (
    role?.toLowerCase()) {
      case 'client':
        return 'Khách hàng';

      case 'lawyer':
        return 'Luật sư';

      case 'admin':
        return 'Quản trị viên';

      case 'staff':
        return 'Nhân viên';

      default:
        return 'Thành viên';
    }
  }

  // ============================================================
  // GET AVATAR URL
  // ============================================================

  String? _getAvatarUrl() {
    final rawUrl =
        _user?.avatarUrl?.trim() ??
            '';

    if (rawUrl.isEmpty) {
      debugPrint(
        'AVATAR: Không có avatarUrl',
      );

      return null;
    }

    String finalUrl =
        rawUrl;

    // ==========================================================
    // RELATIVE URL
    //
    // /uploads/avatars/xxx.png
    // ==========================================================

    if (finalUrl.startsWith('/')) {
      finalUrl =
      '$_serverBaseUrl$finalUrl';
    }

    // ==========================================================
    // HTTPS LOCALHOST
    //
    // https://localhost:5001/...
    // ==========================================================

    else if (finalUrl.startsWith(
      'https://localhost:5001',
    )) {
      finalUrl =
          finalUrl.replaceFirst(
            'https://localhost:5001',
            _serverBaseUrl,
          );
    }

    // ==========================================================
    // HTTP LOCALHOST
    //
    // http://localhost:5000/...
    // ==========================================================

    else if (finalUrl.startsWith(
      'http://localhost:5000',
    )) {
      finalUrl =
          finalUrl.replaceFirst(
            'http://localhost:5000',
            _serverBaseUrl,
          );
    }

    // ==========================================================
    // HTTPS 10.0.2.2
    // ==========================================================

    else if (finalUrl.startsWith(
      'https://10.0.2.2:5001',
    )) {
      finalUrl =
          finalUrl.replaceFirst(
            'https://10.0.2.2:5001',
            _serverBaseUrl,
          );
    }

    // ==========================================================
    // HTTP 10.0.2.2
    // ==========================================================

    else if (finalUrl.startsWith(
      'http://10.0.2.2:5000',
    )) {
      // Đã đúng URL
    }

    debugPrint(
      '============================================',
    );

    debugPrint(
      'AVATAR RAW URL: $rawUrl',
    );

    debugPrint(
      'AVATAR FINAL URL: $finalUrl',
    );

    debugPrint(
      '============================================',
    );

    return finalUrl;
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar() {
    final avatarUrl =
    _getAvatarUrl();

    debugPrint(
      '============================================',
    );

    debugPrint(
      'CLIENT AVATAR URL: $avatarUrl',
    );

    debugPrint(
      '============================================',
    );

    return SizedBox(
      width: 105,
      height: 115,
      child: Stack(
        clipBehavior:
        Clip.none,
        children: [
          // ======================================================
          // AVATAR
          // ======================================================

          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 100,
              height: 100,
              decoration:
              BoxDecoration(
                shape:
                BoxShape.circle,
                border:
                Border.all(
                  color:
                  Colors.white,
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: avatarUrl !=
                    null &&
                    avatarUrl
                        .isNotEmpty
                    ? Image.network(
                  avatarUrl,
                  width: 100,
                  height: 100,
                  fit:
                  BoxFit.cover,

                  // ======================================
                  // LOADING
                  // ======================================

                  loadingBuilder:
                      (
                      context,
                      child,
                      loadingProgress,
                      ) {
                    if (loadingProgress ==
                        null) {
                      debugPrint(
                        'CLIENT AVATAR: Tải ảnh thành công',
                      );

                      return child;
                    }

                    return const Center(
                      child:
                      SizedBox(
                        width: 24,
                        height: 24,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color:
                          navy,
                        ),
                      ),
                    );
                  },

                  // ======================================
                  // ERROR
                  // ======================================

                  errorBuilder:
                      (
                      context,
                      error,
                      stackTrace,
                      ) {
                    debugPrint(
                      '============================================',
                    );

                    debugPrint(
                      'CLIENT AVATAR LOAD ERROR',
                    );

                    debugPrint(
                      'URL: $avatarUrl',
                    );

                    debugPrint(
                      'ERROR: $error',
                    );

                    debugPrint(
                      '============================================',
                    );

                    return _buildDefaultAvatar();
                  },
                )
                    : _buildDefaultAvatar(),
              ),
            ),
          ),

          // ======================================================
          // BACK BUTTON
          // ======================================================

          Positioned(
            top: -8,
            left: -8,
            child:
            _buildBackButton(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BACK BUTTON
  // ============================================================

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(
          context,
        );
      },
      child: Container(
        width: 38,
        height: 38,
        decoration:
        BoxDecoration(
          color:
          Colors.white,
          shape:
          BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.15),
              blurRadius: 6,
              offset:
              const Offset(
                0,
                2,
              ),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          color:
          Color(0xFF1B365D),
          size: 22,
        ),
      ),
    );
  }

  // ============================================================
  // DEFAULT AVATAR
  // ============================================================

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      color:
      const Color(0xFFDDE2E7),
      child: const Icon(
        Icons.person_rounded,
        color:
        Color(0xFF8996A3),
        size: 60,
      ),
    );
  }

  // ============================================================
  // BASIC INFORMATION
  // ============================================================

  Widget _buildBasicInformation() {
    final user = _user!;

    return Container(
      width: double.infinity,
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          9,
        ),
        border:
        Border.all(
          color: border,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets
            .symmetric(
          horizontal: 13,
          vertical: 8,
        ),
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
              crossAxisAlignment:
              CrossAxisAlignment
                  .center,
              children: [
                Expanded(
                  child:
                  _buildSectionHeader(
                    icon: Icons
                        .person_outline_rounded,
                    title:
                    'Thông tin cơ bản',
                    subtitle:
                    'Thông tin của bạn được bảo mật tuyệt đối',
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                // ==============================================
                // EDIT BUTTON
                // ==============================================

                GestureDetector(
                  onTap: () async {
                    final result =
                    await Navigator
                        .push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const ClientPersonalInfoEditScreen(),
                      ),
                    );

                    if (result ==
                        true &&
                        mounted) {
                      await _loadUserProfile();
                    }
                  },
                  child: Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFF1B365D,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        10,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize:
                      MainAxisSize
                          .min,
                      children: [
                        Icon(
                          Icons
                              .edit_outlined,
                          color:
                          Colors.white,
                          size: 16,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          'Chỉnh sửa',
                          style:
                          TextStyle(
                            color: Colors
                                .white,
                            fontSize: 12,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 4,
            ),

            // ==================================================
            // FULL NAME
            // ==================================================

            ClientPersonalInfoRow(
              icon:
              Icons
                  .person_outline_rounded,
              label:
              'Họ và tên',
              value:
              user.fullName
                  .isNotEmpty
                  ? user.fullName
                  : 'Chưa cập nhật',
            ),

            // ==================================================
            // EMAIL
            // ==================================================

            ClientPersonalInfoRow(
              icon:
              Icons
                  .mail_outline_rounded,
              label:
              'Email',
              value:
              user.email
                  .isNotEmpty
                  ? user.email
                  : 'Chưa cập nhật',
            ),

            // ==================================================
            // PHONE
            // ==================================================

            ClientPersonalInfoRow(
              icon:
              Icons.phone_outlined,
              label:
              'Số điện thoại',
              value:
              user.phone !=
                  null &&
                  user.phone!
                      .isNotEmpty
                  ? user.phone!
                  : 'Chưa cập nhật',
            ),

            // ==================================================
            // DATE OF BIRTH
            // ==================================================

            ClientPersonalInfoRow(
              icon: Icons
                  .calendar_month_outlined,
              label:
              'Ngày sinh',
              value:
              _dateOfBirth
                  .isNotEmpty
                  ? _dateOfBirth
                  : 'Chưa cập nhật',
            ),

            // ==================================================
            // ADDRESS
            // ==================================================

            ClientPersonalInfoRow(
              icon: Icons
                  .location_on_outlined,
              label:
              'Địa chỉ',
              value:
              _address
                  .isNotEmpty
                  ? _address
                  : 'Chưa cập nhật',
            ),

            // ==================================================
            // GENDER
            // ==================================================

            ClientPersonalInfoRow(
              icon:
              Icons.wc_outlined,
              label:
              'Giới tính',
              value:
              _gender
                  .isNotEmpty
                  ? _gender
                  : 'Chưa cập nhật',
            ),

            // ==================================================
            // LANGUAGE
            // ==================================================

            ClientPersonalInfoRow(
              icon:
              Icons
                  .language_outlined,
              label:
              'Ngôn ngữ',
              value:
              'Tiếng Việt',
            ),

            // ==================================================
            // CCCD
            // ==================================================

            ClientPersonalInfoRow(
              icon: Icons
                  .description_outlined,
              label:
              'CMND/CCCD',
              value:
              'Chưa cập nhật',
              showDivider:
              false,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADDITIONAL INFORMATION
  // ============================================================

  Widget _buildAdditionalInformation() {
    return Container(
      width: double.infinity,
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          9,
        ),
        border:
        Border.all(
          color: border,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets
            .symmetric(
          horizontal: 13,
          vertical: 8,
        ),
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            _buildSectionHeader(
              icon: Icons
                  .description_outlined,
              title:
              'Thông tin bổ sung',
              subtitle:
              'Giúp chúng tôi hiểu bạn hơn',
            ),

            const SizedBox(
              height: 4,
            ),

            // ==================================================
            // JOB
            // ==================================================

            ClientPersonalInfoRow(
              icon: Icons
                  .business_center_outlined,
              label:
              'Nghề nghiệp',
              value:
              'Chưa cập nhật',
              showArrow:
              true,
              onTap: () {
                _editAdditionalInfo(
                  'Nghề nghiệp',
                );
              },
            ),

            // ==================================================
            // EDUCATION
            // ==================================================

            ClientPersonalInfoRow(
              icon: Icons
                  .school_outlined,
              label:
              'Trình độ học vấn',
              value:
              'Chưa cập nhật',
              showArrow:
              true,
              onTap: () {
                _editAdditionalInfo(
                  'Trình độ học vấn',
                );
              },
            ),

            // ==================================================
            // MARITAL STATUS
            // ==================================================

            ClientPersonalInfoRow(
              icon: Icons
                  .people_outline_rounded,
              label:
              'Tình trạng hôn nhân',
              value:
              'Chưa cập nhật',
              showArrow:
              true,
              showDivider:
              false,
              onTap: () {
                _editAdditionalInfo(
                  'Tình trạng hôn nhân',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration:
          const BoxDecoration(
            color:
            Color(0xFFFFF4E4),
            shape:
            BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: gold,
            size: 20,
          ),
        ),

        const SizedBox(
          width: 9,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                title,
                style:
                const TextStyle(
                  color:
                  darkNavy,
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                subtitle,
                style:
                const TextStyle(
                  color:
                  muted,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADDITIONAL INFO ACTION
  // ============================================================

  void _editAdditionalInfo(
      String field,
      ) {
    _showMessage(
      'Chỉnh sửa $field',
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets
            .symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .cloud_off_rounded,
              color:
              Color(0xFFB7C5D4),
              size: 58,
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              _errorMessage ??
                  'Không thể tải thông tin',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color:
                darkNavy,
                fontSize: 14,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            ElevatedButton(
              onPressed:
              _loadUserProfile,
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                navy,
                foregroundColor:
                Colors.white,
                elevation: 0,
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
              ),
              child: const Text(
                'Thử lại',
                style:
                TextStyle(
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '$message sẽ được kết nối API.',
        ),
        duration:
        const Duration(
          seconds: 1,
        ),
      ),
    );
  }
}

// =================================================================
// INFORMATION ROW
// =================================================================

class ClientPersonalInfoRow
    extends StatelessWidget {
  const ClientPersonalInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.showArrow = false,
    this.showDivider = true,
    this.onTap,
  });

  final IconData icon;

  final String label;

  final String value;

  final bool showArrow;

  final bool showDivider;

  final VoidCallback? onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    final Widget content =
    Padding(
      padding:
      const EdgeInsets
          .symmetric(
        vertical: 5,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 30,
                height: 30,
                decoration:
                const BoxDecoration(
                  color:
                  Color(0xFFF3F6FA),
                  shape:
                  BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color:
                  const Color(
                    0xFF264C78,
                  ),
                  size: 16,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // ==================================================
              // LABEL
              // ==================================================

              SizedBox(
                width: 125,
                child: Text(
                  label,
                  style:
                  const TextStyle(
                    color:
                    Color(
                      0xFF6F8299,
                    ),
                    fontSize: 9.5,
                  ),
                ),
              ),

              // ==================================================
              // VALUE
              // ==================================================

              Expanded(
                child: Text(
                  value.isNotEmpty
                      ? value
                      : 'Chưa cập nhật',
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  const TextStyle(
                    color:
                    Color(
                      0xFF365A82,
                    ),
                    fontSize: 9.5,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ),

              // ==================================================
              // ARROW
              // ==================================================

              if (showArrow)
                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                  Color(
                    0xFF7187A0,
                  ),
                  size: 20,
                ),
            ],
          ),

          // ==================================================
          // DIVIDER
          // ==================================================

          if (showDivider)
            const Padding(
              padding:
              EdgeInsets.only(
                left: 40,
              ),
              child: Divider(
                height: 1,
                thickness: 1,
                color:
                Color(0xFFEAF0F5),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color:
        Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}