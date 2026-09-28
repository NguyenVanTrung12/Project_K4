import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/models/user_model.dart';
import 'package:themis_trust_mobile/services/user_service.dart';

class ClientPersonalInfoEditScreen extends StatefulWidget {
  const ClientPersonalInfoEditScreen({
    super.key,
  });

  @override
  State<ClientPersonalInfoEditScreen> createState() =>
      _ClientPersonalInfoEditScreenState();
}

class _ClientPersonalInfoEditScreenState
    extends State<ClientPersonalInfoEditScreen> {
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? _user;

  bool _isLoading = true;
  bool _isSaving = false;

  String? _currentUserId;
  String? _errorMessage;

  File? _selectedAvatar;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _fullNameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _dateOfBirthController =
  TextEditingController();

  final TextEditingController _addressController =
  TextEditingController();

  // ============================================================
  // GIỚI TÍNH
  // ============================================================

  String? _selectedGender;

  final List<String> _genderOptions = [
    'Nam',
    'Nữ',
    'Khác',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET CURRENT USER ID
  // ============================================================

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('userId');

    debugPrint(
      'EDIT PROFILE USER ID: $userId',
    );

    return userId;
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> _loadUserProfile() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final userId = await _getCurrentUserId();

      if (userId == null || userId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
          'Không tìm thấy thông tin người dùng.';
        });

        return;
      }

      final user = await _userService.getUserById(userId);

      // ========================================================
      // BASIC
      // ========================================================

      _fullNameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';

      // ========================================================
      // DATE OF BIRTH
      //
      // UserModel có thể trả DateTime hoặc String tùy cách
      // parse trong model.
      // ========================================================

      _dateOfBirthController.text =
          _normalizeDateOfBirth(user.dateOfBirth);

      // ========================================================
      // GENDER
      // ========================================================

      final gender = user.gender?.toString().trim();

      if (gender != null &&
          gender.isNotEmpty &&
          _genderOptions.contains(gender)) {
        _selectedGender = gender;
      } else {
        _selectedGender = null;
      }

      // ========================================================
      // ADDRESS
      // ========================================================

      _addressController.text =
          user.address?.toString() ?? '';

      if (!mounted) return;

      setState(() {
        _user = user;
        _currentUserId = userId;
        _isLoading = false;
      });

      debugPrint(
        'USER DATE OF BIRTH: ${_dateOfBirthController.text}',
      );

      debugPrint(
        'USER GENDER: $_selectedGender',
      );

      debugPrint(
        'USER ADDRESS: ${_addressController.text}',
      );
    } catch (e) {
      debugPrint(
        'LOAD EDIT PROFILE ERROR: $e',
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
  // NORMALIZE DATE
  // ============================================================

  String _normalizeDateOfBirth(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is DateTime) {
      return _formatDate(value);
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    // Ví dụ:
    // 2000-04-12T00:00:00
    // 2000-04-12T00:00:00.000Z
    // => 2000-04-12
    if (text.length >= 10) {
      final firstTen = text.substring(0, 10);

      final parsed = DateTime.tryParse(firstTen);

      if (parsed != null) {
        return _formatDate(parsed);
      }
    }

    final parsed = DateTime.tryParse(text);

    if (parsed != null) {
      return _formatDate(parsed);
    }

    return text;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // DISPLAY DATE
  // ============================================================

  String _displayDate(String value) {
    if (value.isEmpty) {
      return 'Chọn ngày sinh';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    final year =
    date.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // PICK DATE OF BIRTH
  // ============================================================

  Future<void> _pickDateOfBirth() async {
    DateTime initialDate = DateTime(
      2000,
      1,
      1,
    );

    if (_dateOfBirthController.text.isNotEmpty) {
      final parsedDate = DateTime.tryParse(
        _dateOfBirthController.text,
      );

      if (parsedDate != null) {
        initialDate = parsedDate;
      }
    }

    final now = DateTime.now();

    DateTime firstDate = DateTime(
      1900,
      1,
      1,
    );

    DateTime lastDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // Đảm bảo initialDate nằm trong khoảng cho phép
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('vi', 'VN'),
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      fieldLabelText: 'Ngày sinh',
      fieldHintText: 'dd/mm/yyyy',
      builder: (
          BuildContext context,
          Widget? child,
          ) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B365D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF222222),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _dateOfBirthController.text =
          _formatDate(pickedDate);
    });
  }

  // ============================================================
  // PICK AVATAR
  // ============================================================

  Future<void> _pickAvatar() async {
    try {
      final XFile? image =
      await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _selectedAvatar = File(image.path);
      });
    } catch (e) {
      debugPrint(
        'PICK AVATAR ERROR: $e',
      );

      _showMessage(
        'Không thể chọn ảnh.',
        isError: true,
      );
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (_currentUserId == null ||
        _currentUserId!.trim().isEmpty) {
      _showMessage(
        'Không xác định được tài khoản.',
        isError: true,
      );

      return;
    }

    final fullName =
    _fullNameController.text.trim();

    final email =
    _emailController.text.trim();

    final phone =
    _phoneController.text.trim();

    final dateOfBirth =
    _dateOfBirthController.text.trim();

    final address =
    _addressController.text.trim();

    final gender =
        _selectedGender?.trim() ?? '';

    // ============================================================
    // VALIDATE
    // ============================================================

    if (fullName.isEmpty) {
      _showMessage(
        'Vui lòng nhập họ và tên.',
        isError: true,
      );

      return;
    }

    if (email.isEmpty) {
      _showMessage(
        'Vui lòng nhập email.',
        isError: true,
      );

      return;
    }

    // ============================================================
    // EMAIL
    // ============================================================

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage(
        'Email không hợp lệ.',
        isError: true,
      );

      return;
    }

    // ============================================================
    // PHONE
    // ============================================================

    if (phone.isNotEmpty) {
      final phoneRegex = RegExp(
        r'^[0-9]{9,11}$',
      );

      if (!phoneRegex.hasMatch(phone)) {
        _showMessage(
          'Số điện thoại không hợp lệ.',
          isError: true,
        );

        return;
      }
    }

    // ============================================================
    // DATE
    // ============================================================

    if (dateOfBirth.isNotEmpty) {
      final parsedDate =
      DateTime.tryParse(dateOfBirth);

      if (parsedDate == null) {
        _showMessage(
          'Ngày sinh không hợp lệ.',
          isError: true,
        );

        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // ==========================================================
      // 1. UPDATE PROFILE
      //
      // Giống Web:
      //
      // PATCH /users/{id}/profile
      //
      // fullName
      // email
      // phone
      // gender
      // dateOfBirth
      // address
      // ==========================================================

      final Map<String, dynamic> data = {
        'fullName': fullName,
        'email': email,
        'phone': phone.isEmpty ? null : phone,
        'gender': gender.isEmpty ? null : gender,
        'dateOfBirth':
        dateOfBirth.isEmpty ? null : dateOfBirth,
        'address':
        address.isEmpty ? null : address,
      };

      debugPrint(
        '========================================',
      );

      debugPrint(
        'UPDATE PROFILE USER ID: $_currentUserId',
      );

      debugPrint(
        'UPDATE PROFILE DATA: $data',
      );

      debugPrint(
        '========================================',
      );

      await _userService.updateProfile(
        _currentUserId!,
        data,
      );

      // ==========================================================
      // 2. UPLOAD AVATAR NẾU CÓ
      // ==========================================================

      if (_selectedAvatar != null) {
        debugPrint(
          'UPLOAD AVATAR: ${_selectedAvatar!.path}',
        );

        await _userService.uploadAvatar(
          _currentUserId!,
          _selectedAvatar!,
        );
      }

      // ==========================================================
      // 3. LOAD LẠI USER TỪ SERVER
      //
      // Không tự new UserModel ở đây.
      // Lấy lại dữ liệu thật từ API.
      // ==========================================================

      final refreshedUser =
      await _userService.getUserById(
        _currentUserId!,
      );

      // ==========================================================
      // 4. SAVE LOCAL
      // ==========================================================

      final prefs =
      await SharedPreferences.getInstance();

      await prefs.setString(
        'userId',
        refreshedUser.id,
      );

      await prefs.setString(
        'fullName',
        refreshedUser.fullName,
      );

      await prefs.setString(
        'email',
        refreshedUser.email,
      );

      if (refreshedUser.phone != null &&
          refreshedUser.phone!.isNotEmpty) {
        await prefs.setString(
          'phone',
          refreshedUser.phone!,
        );
      } else {
        await prefs.remove('phone');
      }

      // Lưu thêm các thông tin mới
      if (refreshedUser.address != null &&
          refreshedUser.address!
              .toString()
              .isNotEmpty) {
        await prefs.setString(
          'address',
          refreshedUser.address!.toString(),
        );
      } else {
        await prefs.remove('address');
      }

      if (refreshedUser.gender != null &&
          refreshedUser.gender!
              .toString()
              .isNotEmpty) {
        await prefs.setString(
          'gender',
          refreshedUser.gender!.toString(),
        );
      } else {
        await prefs.remove('gender');
      }

      final savedDateOfBirth =
      _normalizeDateOfBirth(
        refreshedUser.dateOfBirth,
      );

      if (savedDateOfBirth.isNotEmpty) {
        await prefs.setString(
          'dateOfBirth',
          savedDateOfBirth,
        );
      } else {
        await prefs.remove('dateOfBirth');
      }

      // ==========================================================
      // 5. UPDATE UI
      // ==========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _user = refreshedUser;
        _selectedAvatar = null;
        _isSaving = false;
      });

      // ==========================================================
      // 6. THÔNG BÁO
      // ==========================================================

      _showMessage(
        'Đã lưu thay đổi thông tin cá nhân.',
      );

      // Chờ một chút để người dùng thấy thông báo
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      // ==========================================================
      // 7. QUAY VỀ PROFILE
      // ==========================================================

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      debugPrint(
        'UPDATE PROFILE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      final message =
      e.toString();

      if (message.contains('409')) {
        _showMessage(
          'Email hoặc số điện thoại đã được sử dụng.',
          isError: true,
        );

        return;
      }

      if (message.contains('400')) {
        _showMessage(
          'Thông tin nhập vào không hợp lệ.',
          isError: true,
        );

        return;
      }

      if (message.contains('401')) {
        _showMessage(
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          isError: true,
        );

        return;
      }

      if (message.contains('403')) {
        _showMessage(
          'Bạn không có quyền chỉnh sửa thông tin này.',
          isError: true,
        );

        return;
      }

      _showMessage(
        'Không thể cập nhật thông tin. Vui lòng thử lại.',
        isError: true,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF1B365D),
        behavior:
        SnackBarBehavior.floating,
        margin:
        const EdgeInsets.all(16),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor:
        Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1B365D),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Chỉnh sửa trang cá nhân',
          style: TextStyle(
            color: Color(0xFF1B365D),
            fontSize: 19,
            fontWeight:
            FontWeight.w700,
          ),
        ),

        centerTitle: false,
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color:
          Color(0xFF1B365D),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_user == null) {
      return _buildError();
    }

    return SafeArea(
      child:
      SingleChildScrollView(
        padding:
        const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          40,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildAvatarSection(),

            const SizedBox(
              height: 24,
            ),

            _buildSectionTitle(
              'Thông tin cơ bản',
              'Cập nhật thông tin cá nhân của bạn',
            ),

            const SizedBox(
              height: 14,
            ),

            _buildInputCard(),

            const SizedBox(
              height: 24,
            ),

            _buildSectionTitle(
              'Thông tin tài khoản',
              'Một số thông tin chỉ được xem',
            ),

            const SizedBox(
              height: 14,
            ),

            _buildAccountInfoCard(),

            const SizedBox(
              height: 30,
            ),

            _buildSaveButton(),
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
        const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration:
              BoxDecoration(
                color: Colors.red
                    .withOpacity(0.08),
                shape:
                BoxShape.circle,
              ),
              child:
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 35,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              _errorMessage ??
                  'Không thể tải dữ liệu.',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 15,
                color:
                Color(0xFF555555),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
              _loadUserProfile,
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF1B365D,
                ),
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text(
                'Thử lại',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatarSection() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.04),
            blurRadius: 12,
            offset:
            const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior:
            Clip.none,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,
                  border:
                  Border.all(
                    color:
                    const Color(
                      0xFFD4AF37,
                    ),
                    width: 3,
                  ),
                ),
                child:
                ClipOval(
                  child:
                  _selectedAvatar !=
                      null
                      ? Image.file(
                    _selectedAvatar!,
                    fit: BoxFit
                        .cover,
                  )
                      : (_user?.avatarUrl !=
                      null &&
                      _user!
                          .avatarUrl!
                          .isNotEmpty)
                      ? Image.network(
                    _user!
                        .avatarUrl!,
                    fit: BoxFit
                        .cover,
                    errorBuilder:
                        (
                        _,
                        __,
                        ___,
                        ) {
                      return _defaultAvatar();
                    },
                  )
                      : _defaultAvatar(),
                ),
              ),

              Positioned(
                right: -2,
                bottom: 2,
                child:
                GestureDetector(
                  onTap:
                  _pickAvatar,
                  child:
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                    const BoxDecoration(
                      color:
                      Color(
                        0xFF1B365D,
                      ),
                      shape:
                      BoxShape.circle,
                    ),
                    child:
                    const Icon(
                      Icons
                          .camera_alt_outlined,
                      color:
                      Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Ảnh đại diện',
            style:
            TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF1B365D),
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Nhấn vào biểu tượng máy ảnh để thay đổi',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontSize: 12,
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEFAULT AVATAR
  // ============================================================

  Widget _defaultAvatar() {
    return Container(
      color:
      const Color(0xFFE9EEF5),
      child:
      const Icon(
        Icons.person,
        size: 58,
        color:
        Color(0xFF1B365D),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
      String title,
      String subtitle,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
          const TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.w700,
            color:
            Color(0xFF1B365D),
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          subtitle,
          style:
          TextStyle(
            fontSize: 12,
            color:
            Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT CARD
  // ============================================================

  Widget _buildInputCard() {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.035),
            blurRadius: 10,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // HỌ TÊN
          // ======================================================

          _buildTextField(
            controller:
            _fullNameController,
            label:
            'Họ và tên',
            hint:
            'Nhập họ và tên',
            icon:
            Icons.person_outline_rounded,
            textInputAction:
            TextInputAction.next,
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // EMAIL
          // ======================================================

          _buildTextField(
            controller:
            _emailController,
            label:
            'Email',
            hint:
            'Nhập email',
            icon:
            Icons.mail_outline_rounded,
            keyboardType:
            TextInputType.emailAddress,
            textInputAction:
            TextInputAction.next,
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // PHONE
          // ======================================================

          _buildTextField(
            controller:
            _phoneController,
            label:
            'Số điện thoại',
            hint:
            'Nhập số điện thoại',
            icon:
            Icons.phone_outlined,
            keyboardType:
            TextInputType.phone,
            textInputAction:
            TextInputAction.next,
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // NGÀY SINH
          // ======================================================

          _buildDateOfBirthField(),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // GIỚI TÍNH
          // ======================================================

          _buildGenderField(),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // ĐỊA CHỈ
          // ======================================================

          _buildTextField(
            controller:
            _addressController,
            label:
            'Địa chỉ',
            hint:
            'Nhập địa chỉ',
            icon:
            Icons.location_on_outlined,
            keyboardType:
            TextInputType.streetAddress,
            textInputAction:
            TextInputAction.done,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE OF BIRTH FIELD
  // ============================================================

  Widget _buildDateOfBirthField() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngày sinh',
          style:
          TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
            color:
            Color(0xFF333333),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        InkWell(
          onTap:
          _pickDateOfBirth,
          borderRadius:
          BorderRadius.circular(12),
          child:
          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFF7F9FC,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              border:
              Border.all(
                color:
                Colors.grey.shade200,
              ),
            ),
            child:
            Row(
              children: [
                const Icon(
                  Icons
                      .calendar_month_outlined,
                  color:
                  Color(0xFF1B365D),
                  size: 21,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                  Text(
                    _displayDate(
                      _dateOfBirthController
                          .text,
                    ),
                    style:
                    TextStyle(
                      fontSize: 14,
                      color: _dateOfBirthController
                          .text
                          .isEmpty
                          ? Colors.grey
                          .shade500
                          : const Color(
                        0xFF333333,
                      ),
                    ),
                  ),
                ),

                const Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  color:
                  Color(0xFF777777),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GENDER FIELD
  // ============================================================

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính',
          style:
          TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
            color:
            Color(0xFF333333),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        DropdownButtonFormField<String>(
          value:
          _selectedGender,
          isExpanded:
          true,

          decoration:
          InputDecoration(
            prefixIcon:
            const Icon(
              Icons
                  .wc_outlined,
              color:
              Color(0xFF1B365D),
              size: 21,
            ),

            filled: true,

            fillColor:
            const Color(
              0xFFF7F9FC,
            ),

            contentPadding:
            const EdgeInsets
                .symmetric(
              horizontal: 14,
              vertical: 5,
            ),

            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              BorderSide.none,
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              BorderSide(
                color:
                Colors.grey.shade200,
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xFF1B365D),
                width: 1.3,
              ),
            ),

            hintText:
            'Chọn giới tính',
          ),

          items: [
            ..._genderOptions.map(
                  (gender) {
                return DropdownMenuItem<
                    String>(
                  value:
                  gender,
                  child:
                  Text(
                    gender,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      color:
                      Color(
                        0xFF333333,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],

          onChanged:
              (value) {
            setState(() {
              _selectedGender =
                  value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
          const TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
            color:
            Color(0xFF333333),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        TextField(
          controller:
          controller,

          keyboardType:
          keyboardType ??
              TextInputType.text,

          textInputAction:
          textInputAction ??
              TextInputAction.next,

          textCapitalization:
          TextCapitalization.sentences,

          maxLines:
          maxLines,

          decoration:
          InputDecoration(
            hintText:
            hint,

            prefixIcon:
            Padding(
              padding:
              EdgeInsets.only(
                top: maxLines > 1
                    ? 4
                    : 0,
              ),
              child:
              Icon(
                icon,
                color:
                const Color(
                  0xFF1B365D,
                ),
                size: 21,
              ),
            ),

            alignLabelWithHint:
            maxLines > 1,

            filled: true,

            fillColor:
            const Color(
              0xFFF7F9FC,
            ),

            contentPadding:
            const EdgeInsets
                .symmetric(
              horizontal: 14,
              vertical: 15,
            ),

            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              BorderSide.none,
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              BorderSide(
                color:
                Colors.grey.shade200,
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xFF1B365D),
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACCOUNT INFO
  // ============================================================

  Widget _buildAccountInfoCard() {
    return Container(
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.035),
            blurRadius: 10,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child:
      Column(
        children: [
          _buildReadOnlyRow(
            icon:
            Icons.badge_outlined,
            label:
            'Loại tài khoản',
            value:
            _getRoleName(
              _user!.role,
            ),
          ),

          _buildDivider(),

          _buildReadOnlyRow(
            icon:
            Icons
                .verified_user_outlined,
            label:
            'Trạng thái',
            value:
            _user!.isActive
                ? 'Đang hoạt động'
                : 'Đã khóa',
            valueColor:
            _user!.isActive
                ? Colors.green
                .shade700
                : Colors.red
                .shade700,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // READ ONLY ROW
  // ============================================================

  Widget _buildReadOnlyRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      child:
      Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFF1B365D,
              ).withOpacity(0.08),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child:
            Icon(
              icon,
              color:
              const Color(
                0xFF1B365D,
              ),
              size: 20,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
            Text(
              label,
              style:
              const TextStyle(
                fontSize: 14,
                color:
                Color(0xFF555555),
              ),
            ),
          ),

          Text(
            value,
            style:
            TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w600,
              color:
              valueColor ??
                  const Color(
                    0xFF333333,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color:
      Colors.grey.shade100,
      indent: 66,
      endIndent: 16,
    );
  }

  // ============================================================
  // ROLE
  // ============================================================

  String _getRoleName(
      String role,
      ) {
    switch (
    role.toLowerCase()) {
      case 'client':
        return 'Khách hàng';

      case 'lawyer':
        return 'Luật sư';

      case 'admin':
        return 'Quản trị viên';

      case 'staff':
        return 'Nhân viên';

      default:
        return role;
    }
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width:
      double.infinity,
      height: 52,
      child:
      ElevatedButton(
        onPressed:
        _isSaving
            ? null
            : _saveProfile,

        style:
        ElevatedButton.styleFrom(
          backgroundColor:
          const Color(
            0xFF1B365D,
          ),

          foregroundColor:
          Colors.white,

          disabledBackgroundColor:
          Colors.grey.shade400,

          elevation: 0,

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
        ),

        child: _isSaving
            ? const SizedBox(
          width: 23,
          height: 23,
          child:
          CircularProgressIndicator(
            strokeWidth: 2.5,
            color:
            Colors.white,
          ),
        )
            : const Row(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Icon(
              Icons
                  .save_outlined,
              size: 20,
            ),
            SizedBox(
              width: 8,
            ),
            Text(
              'Lưu thay đổi',
              style:
              TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight
                    .w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}