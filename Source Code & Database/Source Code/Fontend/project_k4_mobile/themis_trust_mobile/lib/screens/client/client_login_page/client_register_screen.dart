import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/services/api_service.dart';


class ClientRegisterScreen extends StatefulWidget {
  const ClientRegisterScreen({
    super.key,
  });

  @override
  State<ClientRegisterScreen> createState() =>
      _ClientRegisterScreenState();
}

class _ClientRegisterScreenState
    extends State<ClientRegisterScreen> {

  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF173B66);
  static const Color darkNavy = Color(0xFF102F55);
  static const Color gold = Color(0xFFC98B2E);
  static const Color muted = Color(0xFF7186A0);
  static const Color border = Color(0xFFDCE5EF);
  static const Color background = Color(0xFFF7F9FC);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final ApiService _api = ApiService();

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: _buildRegisterCard(),
              ),

              // ==================================================
              // CLOSE BUTTON
              // Góc trên bên phải form
              // ==================================================

              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _goBack,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE3EAF2),
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF123963),
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REGISTER CARD
  // ============================================================

  Widget _buildRegisterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        0,
        12,
        0,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE7ECF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [

          // ======================================================
          // HEADER
          // ======================================================

          _buildRegisterHeader(),

          const SizedBox(height: 20),

          // ======================================================
          // FORM
          // ======================================================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Column(
              children: [

                // ==================================================
                // HỌ VÀ TÊN
                // ==================================================

                _buildInputField(
                  controller: _nameController,
                  hint: 'Họ và tên',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                ),

                const SizedBox(height: 9),

                // ==================================================
                // EMAIL
                // ==================================================

                _buildInputField(
                  controller: _emailController,
                  hint: 'Email',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 9),

                // ==================================================
                // SỐ ĐIỆN THOẠI
                // ==================================================

                _buildInputField(
                  controller: _phoneController,
                  hint: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 9),

                // ==================================================
                // MẬT KHẨU
                // ==================================================

                _buildPasswordField(
                  controller: _passwordController,
                  hint: 'Mật khẩu',
                  obscureText: _obscurePassword,
                  onToggle: () {
                    setState(() {
                      _obscurePassword =
                      !_obscurePassword;
                    });
                  },
                ),

                const SizedBox(height: 9),

                // ==================================================
                // XÁC NHẬN MẬT KHẨU
                // ==================================================

                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hint: 'Xác nhận mật khẩu',
                  obscureText: _obscureConfirmPassword,
                  onToggle: () {
                    setState(() {
                      _obscureConfirmPassword =
                      !_obscureConfirmPassword;
                    });
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // REGISTER BUTTON
                // ==================================================

                _buildRegisterButton(),

                const SizedBox(height: 14),

                // ==================================================
                // SECURITY CARD
                // ==================================================

                _buildSecurityCard(),

                const SizedBox(height: 17),

                // ==================================================
                // LOGIN
                // ==================================================

                _buildLoginText(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTER HEADER
  // ============================================================

  Widget _buildRegisterHeader() {
    return Column(
      children: [

        const Text(
          'Tạo tài khoản',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: darkNavy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 6),

        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 25,
          ),
          child: Text(
            'Đăng ký tài khoản để bắt đầu hành trình\n'
                'tìm kiếm giải pháp pháp lý cùng Themis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 9.5,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 39,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: border,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: navy,
          fontSize: 10,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,

          hintText: hint,

          hintStyle: const TextStyle(
            color: Color(0xFF8B9BB0),
            fontSize: 9.5,
          ),

          // ======================================================
          // ICON
          // ======================================================

          prefixIcon: Container(
            width: 31,
            height: 31,
            margin: const EdgeInsets.only(
              left: 5,
              right: 5,
              top: 3,
              bottom: 3,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5FA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: navy,
              size: 16,
            ),
          ),

          prefixIconConstraints:
          const BoxConstraints(
            minWidth: 42,
            minHeight: 35,
          ),

          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 11,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      height: 39,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: border,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: navy,
          fontSize: 10,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,

          hintText: hint,

          hintStyle: const TextStyle(
            color: Color(0xFF8B9BB0),
            fontSize: 9.5,
          ),

          // ======================================================
          // LOCK ICON
          // ======================================================

          prefixIcon: Container(
            width: 31,
            height: 31,
            margin: const EdgeInsets.only(
              left: 5,
              right: 5,
              top: 3,
              bottom: 3,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: navy,
              size: 16,
            ),
          ),

          prefixIconConstraints:
          const BoxConstraints(
            minWidth: 42,
            minHeight: 35,
          ),

          // ======================================================
          // SHOW PASSWORD
          // ======================================================

          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: navy,
              size: 16,
            ),
          ),

          suffixIconConstraints:
          const BoxConstraints(
            minWidth: 40,
            minHeight: 35,
          ),

          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 11,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REGISTER BUTTON
  // ============================================================

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 41,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          gold.withOpacity(0.65),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [

            Text(
              'Đăng ký',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(width: 8),

            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECURITY CARD
  // ============================================================

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [

          // ======================================================
          // SHIELD
          // ======================================================

          Container(
            width: 27,
            height: 27,
            decoration: const BoxDecoration(
              color: Color(0xFFE3EDF7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: navy,
              size: 17,
            ),
          ),

          const SizedBox(width: 8),

          // ======================================================
          // TEXT
          // ======================================================

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  'Thông tin của bạn được bảo mật tuyệt đối',
                  style: TextStyle(
                    color: navy,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  'Themis cam kết bảo vệ dữ liệu cá nhân của bạn',
                  style: TextStyle(
                    color: muted,
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // ARROW
          // ======================================================

          const Icon(
            Icons.chevron_right_rounded,
            color: muted,
            size: 19,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGIN TEXT
  // ============================================================

  Widget _buildLoginText() {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.center,
      children: [

        const Text(
          'Đã có tài khoản? ',
          style: TextStyle(
            color: muted,
            fontSize: 9.5,
          ),
        ),

        GestureDetector(
          onTap: _goToLogin,
          child: const Text(
            'Đăng nhập ngay',
            style: TextStyle(
              color: Color(0xFF287BD6),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REGISTER API
  // ============================================================

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword =
        _confirmPasswordController.text;

    // ==========================================================
    // VALIDATE
    // ==========================================================

    if (name.isEmpty) {
      _showMessage('Vui lòng nhập họ và tên.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('Vui lòng nhập email.');
      return;
    }

    // Kiểm tra email cơ bản
    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage('Email không hợp lệ.');
      return;
    }

    if (phone.isEmpty) {
      _showMessage('Vui lòng nhập số điện thoại.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Vui lòng nhập mật khẩu.');
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Mật khẩu phải có ít nhất 6 ký tự.',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage(
        'Vui lòng xác nhận mật khẩu.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Mật khẩu xác nhận không khớp.',
      );
      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    setState(() {
      _isLoading = true;
    });

    try {
      // ========================================================
      // CALL API
      // ========================================================

      await _api.post(
        '/Users',
        body: {
          'fullName': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': 'client',
        },
      );

      if (!mounted) return;

      // ========================================================
      // THÀNH CÔNG
      // ========================================================

      setState(() {
        _isLoading = false;
      });

      await _showSuccessDialog();

      if (!mounted) return;

      // ========================================================
      // QUAY VỀ LOGIN
      // ========================================================

      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // ========================================================
      // XỬ LÝ LỖI
      // ========================================================

      final errorText = e.toString();

      if (errorText
          .toLowerCase()
          .contains('email')) {
        _showMessage(
          'Email đã được sử dụng hoặc không hợp lệ.',
        );
      } else {
        _showMessage(
          'Đăng ký thất bại. Vui lòng thử lại.',
        );
      }
    }
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ==================================================
                // SUCCESS ICON
                // ==================================================

                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9F7EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF28A866),
                    size: 34,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Đăng ký thành công',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: darkNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Tài khoản của bạn đã được tạo thành công.\n'
                      'Vui lòng đăng nhập để tiếp tục.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // GO TO LOGIN
  // ============================================================

  void _goToLogin() {
    Navigator.pop(context);
  }

  // ============================================================
  // GO BACK
  // ============================================================

  void _goBack() {
    Navigator.pop(context);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        duration: const Duration(
          seconds: 2,
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}