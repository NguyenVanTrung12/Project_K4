import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/services/api_service.dart';


class LawyerEditProfileScreen extends StatefulWidget {
  const LawyerEditProfileScreen({
    super.key,
  });

  @override
  State<LawyerEditProfileScreen> createState() =>
      _LawyerEditProfileScreenState();
}

class _LawyerEditProfileScreenState
    extends State<LawyerEditProfileScreen> {

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _navy = Color(0xFF123963);
  static const Color _gold = Color(0xFFC68A2B);
  static const Color _text = Color(0xFF173A63);
  static const Color _muted = Color(0xFF71869D);
  static const Color _border = Color(0xFFDCE5EF);
  static const Color _background = Color(0xFFF7FAFD);

  // ============================================================
  // API
  // ============================================================

  final ApiService _api = ApiService();

  static const String _serverUrl =
      'http://10.0.2.2:5000';

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  // ============================================================
  // DATA
  // ============================================================

  String? _userId;

  String? _avatarUrl;

  File? _newAvatar;

  bool _isLoading = true;

  bool _isSaving = false;

  bool _isEditing = false;

  String? _errorMessage;

  // ============================================================
  // OLD DATA
  // Dùng cho nút HỦY
  // ============================================================

  String _oldName = '';
  String _oldPhone = '';
  String _oldEmail = '';
  String? _oldAvatarUrl;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadUserProfile();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        throw Exception(
          'Không tìm thấy thông tin người dùng.',
        );
      }

      final data = await _api.get(
        '/users/$userId',
      );

      if (!mounted) return;

      final String fullName =
          data['fullName']?.toString() ?? '';

      final String phone =
          data['phone']?.toString() ?? '';

      final String email =
          data['email']?.toString() ?? '';

      final String? avatar =
      data['avatarUrl']?.toString();

      setState(() {
        _userId = userId;

        _nameController.text = fullName;

        _phoneController.text = phone;

        _emailController.text = email;

        _avatarUrl = avatar;

        // Lưu dữ liệu cũ để Hủy
        _oldName = fullName;

        _oldPhone = phone;

        _oldEmail = email;

        _oldAvatarUrl = avatar;

        _isLoading = false;

        _errorMessage = null;
      });
    } catch (e) {
      debugPrint(
        'LOAD LAWYER PROFILE ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage =
        'Không thể tải thông tin cá nhân.';
      });
    }
  }

  // ============================================================
  // CHANGE AVATAR
  // ============================================================

  Future<void> _pickAvatar() async {
    if (!_isEditing) return;

    try {
      final picker = ImagePicker();

      final XFile? picked =
      await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);

      final size =
      await file.length();

      // 5MB
      if (size > 5 * 1024 * 1024) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Ảnh không được vượt quá 5MB.',
            ),
          ),
        );

        return;
      }

      if (!mounted) return;

      setState(() {
        _newAvatar = file;
      });
    } catch (e) {
      debugPrint(
        'PICK AVATAR ERROR: $e',
      );
    }
  }

  // ============================================================
  // UPLOAD AVATAR
  // POST /api/users/{id}/avatar
  // ============================================================

  Future<void> _uploadAvatar() async {
    if (_newAvatar == null) return;

    if (_userId == null) return;

    final prefs =
    await SharedPreferences.getInstance();

    final token =
    prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception(
        'Phiên đăng nhập đã hết hạn.',
      );
    }

    final uri = Uri.parse(
      '$_serverUrl/api/users/$_userId/avatar',
    );

    final request =
    http.MultipartRequest(
      'POST',
      uri,
    );

    request.headers['Authorization'] =
    'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        _newAvatar!.path,
      ),
    );

    final response =
    await request.send();

    final responseBody =
    await response.stream.bytesToString();

    debugPrint(
      'UPLOAD AVATAR STATUS: '
          '${response.statusCode}',
    );

    debugPrint(
      'UPLOAD AVATAR RESPONSE: '
          '$responseBody',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Không thể cập nhật ảnh đại diện.',
      );
    }

    try {
      final json =
      jsonDecode(responseBody);

      final String? avatarUrl =
      json['avatarUrl']?.toString();

      if (avatarUrl != null &&
          avatarUrl.isNotEmpty) {
        _avatarUrl = avatarUrl;
      }
    } catch (_) {
      // API có thể trả response không phải JSON
    }
  }

  // ============================================================
  // SAVE PROFILE
  // PATCH /api/users/{id}/profile
  // ============================================================

  Future<void> _saveProfile() async {
    if (_userId == null) return;

    final name =
    _nameController.text.trim();

    final phone =
    _phoneController.text.trim();

    final email =
    _emailController.text.trim();

    // ----------------------------------------------------------
    // VALIDATE
    // ----------------------------------------------------------

    if (name.isEmpty) {
      _showMessage(
        'Vui lòng nhập họ và tên.',
      );

      return;
    }

    if (email.isEmpty) {
      _showMessage(
        'Vui lòng nhập email.',
      );

      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(
        'Email không hợp lệ.',
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // ========================================================
      // 1. UPDATE PROFILE
      // ========================================================

      final profileData = {
        'fullName': name,
        'email': email,
        'phone': phone.isEmpty
            ? null
            : phone,
      };

      await _api.patch(
        '/users/$_userId/profile',
        body: profileData,
      );

      // ========================================================
      // 2. UPDATE AVATAR
      // ========================================================

      if (_newAvatar != null) {
        await _uploadAvatar();
      }

      // ========================================================
      // 3. SAVE LOCAL
      // ========================================================

      final prefs =
      await SharedPreferences.getInstance();

      await prefs.setString(
        'fullName',
        name,
      );

      await prefs.setString(
        'email',
        email,
      );

      await prefs.setString(
        'phone',
        phone,
      );

      // ========================================================
      // 4. UPDATE OLD DATA
      // ========================================================

      _oldName = name;

      _oldPhone = phone;

      _oldEmail = email;

      _oldAvatarUrl = _avatarUrl;

      _newAvatar = null;

      if (!mounted) return;

      setState(() {
        _isEditing = false;

        _isSaving = false;
      });

      _showMessage(
        'Đã lưu thay đổi.',
      );

    } catch (e) {
      debugPrint(
        'SAVE PROFILE ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Không thể lưu thay đổi.',
      );
    }
  }

  // ============================================================
  // CANCEL
  // ============================================================

  void _cancelEdit() {
    setState(() {
      _nameController.text =
          _oldName;

      _phoneController.text =
          _oldPhone;

      _emailController.text =
          _oldEmail;

      _avatarUrl =
          _oldAvatarUrl;

      _newAvatar = null;

      _isEditing = false;
    });
  }

  // ============================================================
  // START EDIT
  // ============================================================

  void _startEdit() {
    setState(() {
      _isEditing = true;
    });
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // AVATAR URL
  // ============================================================

  String? _getAvatarUrl() {
    if (_avatarUrl == null ||
        _avatarUrl!.isEmpty) {
      return null;
    }

    if (_avatarUrl!.startsWith('http')) {
      return _avatarUrl;
    }

    return '$_serverUrl$_avatarUrl';
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
              child: _buildBody(),
            ),

            if (!_isLoading &&
                _errorMessage == null)
              _buildBottomButtons(),
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
      height: 58,
      width: double.infinity,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // BACK
          Positioned(
            left: 10,
            child: _buildHeaderButton(
              icon:
              Icons.arrow_back_ios_new_rounded,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),

          // TITLE
          const Text(
            'Thông tin cá nhân',
            style: TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER BUTTON
  // ============================================================

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF4F7FA),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder:
        const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: _navy,
            size: 19,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _navy,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    return RefreshIndicator(
      color: _navy,
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.only(
          bottom: 30,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),

            _buildProfileCard(),

            const SizedBox(height: 10),

            _buildInformationCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 45,
            ),

            const SizedBox(height: 12),

            const Text(
              'Không thể tải thông tin',
              style: TextStyle(
                color: _navy,
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? '',
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });

                _loadUserProfile();
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 105,
                height: 105,
                padding:
                const EdgeInsets.all(3),
                decoration:
                const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child:
                  _buildAvatar(),
                ),
              ),

              if (_isEditing)
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration:
                      BoxDecoration(
                        color: _navy,
                        shape:
                        BoxShape.circle,
                        border:
                        Border.all(
                          color:
                          Colors.white,
                          width: 2,
                        ),
                      ),
                      child:
                      const Icon(
                        Icons
                            .camera_alt_rounded,
                        color:
                        Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            _nameController.text.isEmpty
                ? 'Chưa cập nhật'
                : _nameController.text,
            textAlign:
            TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Luật sư',
            style: TextStyle(
              color: _gold,
              fontSize: 12,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          if (!_isEditing)
            OutlinedButton.icon(
              onPressed: _startEdit,
              icon: const Icon(
                Icons.edit_rounded,
                size: 16,
              ),
              label:
              const Text('Thay đổi'),
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                _navy,
                side:
                const BorderSide(
                  color: _navy,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    7,
                  ),
                ),
              ),
            ),

          if (_isEditing)
            const Text(
              'Bạn có thể thay đổi thông tin cá nhân',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar() {
    // Ảnh mới vừa chọn
    if (_newAvatar != null) {
      return Image.file(
        _newAvatar!,
        fit: BoxFit.cover,
      );
    }

    // Ảnh từ API
    final avatarUrl =
    _getAvatarUrl();

    if (avatarUrl != null) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return _defaultAvatar();
        },
      );
    }

    return _defaultAvatar();
  }

  // ============================================================
  // DEFAULT AVATAR
  // ============================================================

  Widget _defaultAvatar() {
    return Container(
      color:
      const Color(0xFFE5EBF2),
      child: const Icon(
        Icons.person_rounded,
        size: 55,
        color: _navy,
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: _gold,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  color: _navy,
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          _buildInfoField(
            label: 'Họ và tên',
            icon:
            Icons.person_outline_rounded,
            controller:
            _nameController,
          ),

          const SizedBox(height: 12),

          _buildInfoField(
            label: 'Số điện thoại',
            icon:
            Icons.phone_outlined,
            controller:
            _phoneController,
            keyboardType:
            TextInputType.phone,
          ),

          const SizedBox(height: 12),

          _buildInfoField(
            label: 'Email',
            icon:
            Icons.email_outlined,
            controller:
            _emailController,
            keyboardType:
            TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO FIELD
  // ============================================================

  Widget _buildInfoField({
    required String label,
    required IconData icon,
    required TextEditingController
    controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _navy,
            fontSize: 11,
            fontWeight:
            FontWeight.w600,
          ),
        ),

        const SizedBox(height: 5),

        TextField(
          controller: controller,
          enabled: _isEditing,
          keyboardType:
          keyboardType,
          style: const TextStyle(
            color: _text,
            fontSize: 13,
            fontWeight:
            FontWeight.w500,
          ),
          decoration:
          InputDecoration(
            prefixIcon: Icon(
              icon,
              color: _muted,
              size: 18,
            ),
            filled: true,
            fillColor: _isEditing
                ? Colors.white
                : const Color(
              0xFFF7F9FC,
            ),
            contentPadding:
            const EdgeInsets
                .symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                7,
              ),
              borderSide:
              const BorderSide(
                color: _border,
              ),
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                7,
              ),
              borderSide:
              const BorderSide(
                color: _border,
              ),
            ),
            disabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                7,
              ),
              borderSide:
              const BorderSide(
                color: _border,
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                7,
              ),
              borderSide:
              const BorderSide(
                color: _navy,
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM BUTTONS
  // ============================================================

  Widget _buildBottomButtons() {
    if (!_isEditing) {
      return const SizedBox.shrink();
    }

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: _border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // HỦY
            Expanded(
              child: OutlinedButton(
                onPressed:
                _isSaving
                    ? null
                    : _cancelEdit,
                style:
                OutlinedButton.styleFrom(
                  minimumSize:
                  const Size(
                    0,
                    45,
                  ),
                  foregroundColor:
                  _navy,
                  side:
                  const BorderSide(
                    color: _border,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                  ),
                ),
                child:
                const Text(
                  'Hủy',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // LƯU
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                _isSaving
                    ? null
                    : _saveProfile,
                style:
                ElevatedButton.styleFrom(
                  minimumSize:
                  const Size(
                    0,
                    45,
                  ),
                  backgroundColor:
                  _navy,
                  foregroundColor:
                  Colors.white,
                  disabledBackgroundColor:
                  _navy.withOpacity(
                    0.5,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Text(
                  'Lưu thay đổi',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}