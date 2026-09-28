import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/screens/client/client_login_page/client_register_screen.dart';
import 'package:themis_trust_mobile/services/api_service.dart';
import 'package:themis_trust_mobile/services/auth_service.dart';

class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> {
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

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _obscurePassword = true;
  bool _isLoading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

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
                child: _buildLoginCard(),
              ),

              // Nút X ở góc phải, gần form đăng nhập
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE3EAF2)),
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
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECF2)),
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
          // WELCOME
          // ======================================================

          _buildWelcomeHeader(),

          const SizedBox(height: 22),

          // ======================================================
          // FORM
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // ================================================
                // EMAIL
                // ================================================

                _buildInputField(
                  controller: _emailController,
                  hint: 'Email hoặc số điện thoại',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 9),

                // ================================================
                // PASSWORD
                // ================================================
                _buildPasswordField(),

                const SizedBox(height: 7),

                // ================================================
                // FORGOT PASSWORD
                // ================================================
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _forgotPassword,
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: Color(0xFF287BD6),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ================================================
                // LOGIN BUTTON
                // ================================================
                _buildLoginButton(),

                const SizedBox(height: 14),

                // ================================================
                // SECURITY CARD
                // ================================================
                _buildSecurityCard(),

                const SizedBox(height: 17),

                // ================================================
                // REGISTER
                // ================================================
                _buildRegisterText(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WELCOME HEADER
  // ============================================================

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        const Text(
          'Chào mừng bạn!',
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
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Text(
            'Đăng nhập để tiếp tục hành trình tìm kiếm\n'
                'giải pháp pháp lý cùng Themis.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 9.5, height: 1.45),
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
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: navy, fontSize: 10),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF8B9BB0), fontSize: 9.5),
          prefixIcon: Container(
            width: 31,
            height: 31,
            margin: const EdgeInsets.only(left: 5, right: 5, top: 3, bottom: 3),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5FA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: navy, size: 16),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 35,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _buildPasswordField() {
    return Container(
      height: 39,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: navy, fontSize: 10),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Mật khẩu',
          hintStyle: const TextStyle(color: Color(0xFF8B9BB0), fontSize: 9.5),

          // ----------------------------------------------
          // LOCK ICON
          // ----------------------------------------------
          prefixIcon: Container(
            width: 31,
            height: 31,
            margin: const EdgeInsets.only(left: 5, right: 5, top: 3, bottom: 3),
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

          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 35,
          ),

          // ----------------------------------------------
          // SHOW PASSWORD
          // ----------------------------------------------
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: navy,
              size: 16,
            ),
          ),

          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 35,
          ),

          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN BUTTON
  // ============================================================

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 41,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.white,
          disabledBackgroundColor: gold.withOpacity(0.65),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Đăng nhập',
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          // -----------------------------------------------
          // SHIELD
          // -----------------------------------------------

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

          // -----------------------------------------------
          // TEXT
          // -----------------------------------------------
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: TextStyle(color: muted, fontSize: 7),
                ),
              ],
            ),
          ),

          // -----------------------------------------------
          // ARROW
          // -----------------------------------------------
          const Icon(Icons.chevron_right_rounded, color: muted, size: 19),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Widget _buildRegisterText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chưa có tài khoản? ',
          style: TextStyle(color: muted, fontSize: 9.5),
        ),

        GestureDetector(
          onTap: _register,
          child: const Text(
            'Đăng ký ngay',
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
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ==========================================================
    // VALIDATE
    // ==========================================================

    if (email.isEmpty) {
      _showMessage('Vui lòng nhập email hoặc số điện thoại');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Vui lòng nhập mật khẩu');
      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();

      // ========================================================
      // LOGIN API
      // ========================================================

      final result = await authService.login(email: email, password: password);

      debugPrint('================================');
      debugPrint('LOGIN RESPONSE: $result');
      debugPrint('================================');

      // ========================================================
      // LẤY USER
      // ========================================================

      final user = result['user'];

      if (user == null) {
        throw Exception('API login không trả về thông tin user');
      }

      final userData = Map<String, dynamic>.from(user);

      // ========================================================
      // USER ID
      // ========================================================

      final userId = userData['id']?.toString();

      if (userId == null || userId.isEmpty) {
        throw Exception('API login không trả về id người dùng');
      }

      // ========================================================
      // USER INFO
      // ========================================================

      final fullName = userData['fullName']?.toString() ?? '';

      final userEmail = userData['email']?.toString() ?? email;

      final phone = userData['phone']?.toString() ?? '';

      final avatarUrl = userData['avatarUrl']?.toString() ?? '';

      // ========================================================
      // ROLE
      // ========================================================

      final role = userData['role']?.toString().trim().toLowerCase();

      // Không có role thì không cho đăng nhập tiếp
      if (role == null || role.isEmpty) {
        throw Exception('API login không trả về role');
      }

      // Chỉ chấp nhận 2 role của hệ thống
      if (role != 'client' && role != 'lawyer') {
        throw Exception('Role không hợp lệ: $role');
      }

      // ========================================================
      // TOKEN
      // ========================================================

      final token = result['token']?.toString() ?? '';

      final expiresAt = result['expiresAt']?.toString() ?? '';

      if (token.isEmpty) {
        throw Exception('API login không trả về token');
      }

      // ========================================================
      // SAVE SESSION
      // ========================================================

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('userId', userId);

      await prefs.setString('userName', fullName);

      await prefs.setString('userEmail', userEmail);

      await prefs.setString('userPhone', phone);

      await prefs.setString('userRole', role);

      await prefs.setString('avatarUrl', avatarUrl);

      await prefs.setString('token', token);

      if (expiresAt.isNotEmpty) {
        await prefs.setString('expiresAt', expiresAt);
      }

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint('================================');
      debugPrint('LOGIN SUCCESS');
      debugPrint('USER ID: $userId');
      debugPrint('USER NAME: $fullName');
      debugPrint('USER EMAIL: $userEmail');
      debugPrint('USER ROLE: $role');
      debugPrint('TOKEN: ${token.isNotEmpty ? "CÓ" : "KHÔNG"}');
      debugPrint('================================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // ========================================================
      // TRẢ ROLE VỀ CHO MÀN HÌNH GỌI LOGIN
      // ========================================================
      //
      // client -> màn hình gọi login sẽ đưa về Client Home
      //
      // lawyer -> màn hình gọi login sẽ đưa về Lawyer Home
      //
      // ========================================================

      Navigator.pop(context, role);
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('LOGIN ERROR: $e');
      debugPrint('LOGIN STACK: $stackTrace');
      debugPrint('================================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Sai thông tin đăng nhập');
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  void _forgotPassword() {
    _showMessage('Quên mật khẩu');

    // Sau này:
    //
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) =>
    //         const ForgotPasswordScreen(),
    //   ),
    // );
  }

  // ============================================================
  // REGISTER
  // ============================================================

  void _register() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClientRegisterScreen()),
    );

    // Sau này:
    //
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) =>
    //         const ClientRegisterScreen(),
    //   ),
    // );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
