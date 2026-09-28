import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/models/practice_area_model.dart';
import 'package:themis_trust_mobile/models/user_model.dart';
import 'package:themis_trust_mobile/screens/client/client_login_page/client_login_screen.dart';
import 'package:themis_trust_mobile/services/appointment_service.dart';
import 'package:themis_trust_mobile/services/practice_area_service.dart';

import '../../../models/appointment_model.dart';

class ClientConsultationScreen extends StatefulWidget {
  const ClientConsultationScreen({super.key, required this.lawyerId});

  final String lawyerId;

  @override
  State<ClientConsultationScreen> createState() =>
      _ClientConsultationScreenState();
}

class _ClientConsultationScreenState extends State<ClientConsultationScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF173B66);
  static const Color darkNavy = Color(0xFF102F55);
  static const Color gold = Color(0xFFC88A2D);
  static const Color lightGold = Color(0xFFFFF3DF);
  static const Color muted = Color(0xFF7186A0);
  static const Color border = Color(0xFFDDE6EF);
  static const Color background = Color(0xFFF7F9FC);
  static const Color lightBlue = Color(0xFFF3F6FA);

  // ============================================================
  // CONTROLLERS
  // ============================================================
  final PracticeAreaService _practiceAreaService = PracticeAreaService();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _contentController = TextEditingController();

  final AppointmentService _appointmentService = AppointmentService();
  // ============================================================
  // API / LAWYER DATA
  // ============================================================
  UserModel? currentUser;
  static const String _baseUrl = 'http://10.0.2.2:5000/api';

  Map<String, dynamic>? _lawyer;
  String _currentUserId = '';
  bool _isLoggedIn = false;
  bool _isLoadingCustomer = true;
  bool _isLoadingLawyer = true;

  String get lawyerName =>
      (_lawyer?['fullName'] ??
          _lawyer?['name'] ??
          _lawyer?['userName'] ??
          'Luật sư')
          .toString();

  String get lawyerSpecialization =>
      (_lawyer?['specialization'] ??
          _lawyer?['specializations'] ??
          _lawyer?['practiceAreas'] ??
          _lawyer?['expertise'] ??
          '')
          .toString();

  String get lawyerRating =>
      (_lawyer?['rating'] ?? _lawyer?['averageRating'] ?? '0').toString();

  String get lawyerReviews =>
      (_lawyer?['reviewCount'] ??
          _lawyer?['reviewsCount'] ??
          _lawyer?['totalReviews'] ??
          '0')
          .toString() +
          ' đánh giá';

  String get lawyerExperience =>
      (_lawyer?['experience'] ??
          _lawyer?['yearsOfExperience'] ??
          _lawyer?['experienceYears'] ??
          '')
          .toString();

  String get lawyerCustomers =>
      (_lawyer?['customers'] ??
          _lawyer?['customerCount'] ??
          _lawyer?['totalClients'] ??
          '0')
          .toString();

  String get lawyerAvatar {
    final value =
    (_lawyer?['avatarUrl'] ??
        _lawyer?['avatar'] ??
        _lawyer?['profileImage'] ??
        '')
        .toString()
        .trim();

    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return 'http://10.0.2.2:5000$value';
    }
    return 'http://10.0.2.2:5000/$value';
  }

  // ============================================================
  // CONSULTATION BOOKING STATE
  // ============================================================

  String selectedConsultationType = 'direct';

  DateTime selectedDate = DateTime.now();

  String selectedTime = '';

  int? selectedPracticeAreaId;

  DateTime displayedWeekStart = DateTime.now();

  final List<String> times = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '13:30',
    '14:30',
    '15:30',
    '16:30',
  ];

  // ============================================================
  // CATEGORY / PRACTICE AREA
  // ============================================================

  List<PracticeAreaModel> _consultationCategories = [];

  bool _isLoadingCategories = true;

  // ============================================================
  // STATE
  // ============================================================

  bool _isBooking = false;

  // Các khung giờ thực tế mà backend /api/appointments/availability trả về.
  // Giao diện times vẫn giữ nguyên để không thay đổi UI hiện tại.
  Set<String> _availableTimesFromApi = {};
  bool _availabilityLoaded = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    selectedDate = DateTime(now.year, now.month, now.day);

    displayedWeekStart = selectedDate;

    _updateSelectedTime();

    _loadInitialData();
    _loadAvailability();

    // Lấy danh sách lĩnh vực tư vấn
    // _loadConsultationCategories();
  }

  // ============================================================
  // LOAD CONSULTATION CATEGORIES
  // ============================================================

  Future<void> _loadConsultationCategories() async {
    try {
      final categories = await _practiceAreaService.getPracticeAreas();

      if (!mounted) return;

      setState(() {
        _consultationCategories = categories;

        if (categories.isNotEmpty && selectedPracticeAreaId == null) {
          selectedPracticeAreaId = categories.first.id;
        }

        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('LOAD PRACTICE AREA ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  String _getWeekdayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';

      case DateTime.tuesday:
        return 'T3';

      case DateTime.wednesday:
        return 'T4';

      case DateTime.thursday:
        return 'T5';

      case DateTime.friday:
        return 'T6';

      case DateTime.saturday:
        return 'T7';

      case DateTime.sunday:
        return 'CN';

      default:
        return '';
    }
  }

  String _getMonthTitle(DateTime date) {
    return 'Tháng ${date.month}, ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }

  bool _isPastDate(DateTime date) {
    final today = DateTime.now();

    final currentDay = DateTime(today.year, today.month, today.day);

    final compareDay = DateTime(date.year, date.month, date.day);

    return compareDay.isBefore(currentDay);
  }

  String _formatDateForApi(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatDateDisplay(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }

  // ============================================================
  // TIME HELPERS
  // ============================================================

  bool _isTimeAvailable(String time) {
    // Khi chưa nhận được dữ liệu từ backend, giữ nguyên hành vi hiển thị
    // cũ theo thời gian hiện tại.
    final serverAvailable =
        !_availabilityLoaded || _availableTimesFromApi.contains(time);

    if (!serverAvailable) {
      return false;
    }

    if (!_isToday(selectedDate)) {
      return true;
    }

    final parts = time.split(':');

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();

    final slotTime = DateTime(now.year, now.month, now.day, hour, minute);

    return slotTime.isAfter(now);
  }

  void _updateSelectedTime() {
    final availableTimes = times.where(_isTimeAvailable).toList();

    if (availableTimes.isEmpty) {
      selectedTime = '';
      return;
    }

    if (!availableTimes.contains(selectedTime)) {
      selectedTime = availableTimes.first;
    }
  }

  Future<void> _loadAvailability() async {
    try {
      final dateString = _formatDateForApi(selectedDate);

      debugPrint(
        '[AVAILABILITY] lawyerId=${widget.lawyerId}, date=$dateString',
      );

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/appointments/availability'
              '?lawyerId=${Uri.encodeQueryComponent(widget.lawyerId)}'
              '&date=${Uri.encodeQueryComponent(dateString)}',
        ),
      );

      debugPrint(
        '[AVAILABILITY] GET -> ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Không thể tải khung giờ (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);

      final List<dynamic> data = decoded is List ? decoded : <dynamic>[];

      if (!mounted) return;

      setState(() {
        _availableTimesFromApi = data
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toSet();

        _availabilityLoaded = true;
        _updateSelectedTime();
      });
    } catch (e) {
      debugPrint('[AVAILABILITY] ERROR: $e');

      if (!mounted) return;

      // Nếu availability lỗi, không làm hỏng giao diện hiện tại.
      // Booking vẫn sẽ được backend kiểm tra conflict.
      setState(() {
        _availabilityLoaded = false;
        _availableTimesFromApi = {};
        _updateSelectedTime();
      });
    }
  }

  DateTime? _buildScheduledAt() {
    if (selectedTime.isEmpty) return null;

    final parts = selectedTime.split(':');

    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      minute,
    );
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadCurrentCustomer(), _loadLawyer()]);
  }

  Future<void> _loadCurrentCustomer() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      // Không có token
      if (token == null || token.trim().isEmpty) {
        debugPrint('[CONSULTATION] Không có token.');

        await _clearSession();

        if (!mounted) return;

        setState(() {
          _isLoadingCustomer = false;
        });

        return;
      }

      // Decode JWT
      final parts = token.split('.');

      if (parts.length != 3) {
        debugPrint('[CONSULTATION] Token không hợp lệ.');

        await _clearSession();

        if (!mounted) return;

        setState(() {
          _isLoadingCustomer = false;
        });

        return;
      }

      final normalized = base64Url.normalize(parts[1]);

      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));

      if (decoded is! Map) {
        debugPrint('[CONSULTATION] JWT payload không hợp lệ.');

        await _clearSession();

        if (!mounted) return;

        setState(() {
          _isLoadingCustomer = false;
        });

        return;
      }

      final payload = Map<String, dynamic>.from(decoded);

      // ==============================
      // KIỂM TRA TOKEN HẾT HẠN
      // ==============================

      final expValue = payload['exp'];

      if (expValue != null) {
        final exp = int.tryParse(expValue.toString());

        if (exp != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          if (now >= exp) {
            debugPrint('[CONSULTATION] Token đã hết hạn.');

            await _clearSession();

            if (!mounted) return;

            setState(() {
              _isLoadingCustomer = false;
            });

            return;
          }
        }
      }

      // ==============================
      // LẤY USER ID
      // ==============================

      final userId = _firstNonEmpty([
        payload['nameid'],
        payload['sub'],
        payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'],
      ]);

      if (userId.isEmpty) {
        debugPrint('[CONSULTATION] Token không có userId.');

        await _clearSession();

        if (!mounted) return;

        setState(() {
          _isLoadingCustomer = false;
        });

        return;
      }

      // ==============================
      // LẤY THÔNG TIN USER
      // ==============================

      final tokenName = _firstNonEmpty([
        payload['fullName'],
        payload['name'],
        payload['unique_name'],
        payload['preferred_username'],
        payload['given_name'],
      ]);

      final tokenEmail = _firstNonEmpty([
        payload['email'],
        payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'],
      ]);

      final tokenPhone = _firstNonEmpty([
        payload['phone'],
        payload['phoneNumber'],
        payload['mobile'],
        payload['mobilePhone'],
      ]);

      // ==============================
      // LẤY SESSION ĐÃ LƯU
      // ==============================

      final savedName = _readSavedUserValue(prefs, const [
        'userName',
        'fullName',
        'name',
        'clientName',
      ]);

      final savedPhone = _readSavedUserValue(prefs, const [
        'userPhone',
        'phone',
        'phoneNumber',
        'mobile',
        'mobilePhone',
      ]);

      final savedEmail = _readSavedUserValue(prefs, const [
        'userEmail',
        'email',
      ]);

      final name = savedName.isNotEmpty ? savedName : tokenName;

      final phone = savedPhone.isNotEmpty ? savedPhone : tokenPhone;

      final email = savedEmail.isNotEmpty ? savedEmail : tokenEmail;

      if (!mounted) return;

      setState(() {
        _isLoggedIn = true;
        _isLoadingCustomer = false;
        _currentUserId = userId;

        _nameController.text = name;
        _phoneController.text = phone;
        _emailController.text = email;
      });

      debugPrint(
        '[CONSULTATION] Đã đăng nhập: '
            'userId=$_currentUserId, '
            'phone=$phone',
      );
    } catch (e) {
      debugPrint('[CONSULTATION] Lỗi kiểm tra session: $e');

      await _clearSession();

      if (!mounted) return;

      setState(() {
        _isLoadingCustomer = false;
      });
    }
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _readSavedUserValue(SharedPreferences prefs, List<String> keys) {
    for (final key in keys) {
      final value = prefs.getString(key);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('expiresAt');

    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhone');
    await prefs.remove('userRole');
    await prefs.remove('avatarUrl');

    if (!mounted) return;

    setState(() {
      _isLoggedIn = false;
      _currentUserId = '';

      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
    });
  }

  Future<void> _loadLawyer() async {
    try {
      debugPrint('[CONSULTATION] Loading lawyerId=${widget.lawyerId}');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/Lawyers/${widget.lawyerId}'),
        headers: headers,
      );

      debugPrint('[CONSULTATION] GET lawyer -> ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Không thể tải luật sư (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? (decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded)
          : <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _lawyer = data;
        _isLoadingLawyer = false;
      });
    } catch (e) {
      debugPrint('[CONSULTATION] Load lawyer error: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingLawyer = false;
      });

      _showMessage('Không thể tải thông tin luật sư.');
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _contentController.dispose();

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
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Container(
              width: double.infinity,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: border, width: 1)),
              ),
              child: Row(
                children: [
                  // NÚT QUAY LẠI
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      padding: EdgeInsets.zero,
                      splashRadius: 22,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: darkNavy,
                        size: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // TIÊU ĐỀ
                  const Expanded(
                    child: Text(
                      'Đặt lịch tư vấn',
                      style: TextStyle(
                        color: darkNavy,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
                child: Column(
                  children: [
                    _isLoadingLawyer
                        ? _buildLawyerLoadingCard()
                        : _buildLawyerCard(),

                    const SizedBox(height: 9),

                    _buildConsultationType(),

                    const SizedBox(height: 9),

                    _buildDateSelector(),

                    const SizedBox(height: 9),

                    _buildTimeSelector(),

                    const SizedBox(height: 9),

                    _buildUserInformation(),

                    const SizedBox(height: 9),

                    _buildConsultationContent(),


                    const SizedBox(height: 10),

                    _buildBookButton(),

                    const SizedBox(height: 10),

                    _buildSecurityText(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LAWYER CARD
  // ============================================================

  Widget _buildLawyerLoadingCard() {
    return Container(
      width: double.infinity,
      height: 94,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đang tải thông tin luật sư...',
              style: TextStyle(
                color: darkNavy,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          // ==================================================
          // AVATAR
          // ==================================================

          _buildLawyerAvatar(),

          const SizedBox(width: 10),

          // ==================================================
          // LAWYER INFO
          // ==================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Luật sư $lawyerName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkNavy,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    const Icon(Icons.verified_rounded, color: gold, size: 14),
                  ],
                ),

                const SizedBox(height: 3),

                Text(
                  'Chuyên về: $lawyerSpecialization',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 7.5,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    _buildLawyerStat(
                      icon: Icons.star_rounded,
                      value: lawyerRating,
                      label: '($lawyerReviews)',
                      iconColor: gold,
                    ),

                    _buildVerticalDivider(),

                    _buildLawyerStat(
                      icon: Icons.business_center_rounded,
                      value: lawyerExperience,
                      label: 'Kinh nghiệm',
                    ),

                    _buildVerticalDivider(),

                    _buildLawyerStat(
                      icon: Icons.groups_rounded,
                      value: lawyerCustomers,
                      label: 'Khách hàng',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LAWYER AVATAR
  // ============================================================

  Widget _buildLawyerAvatar() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E8EC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: lawyerAvatar.isNotEmpty
            ? Image.network(
          lawyerAvatar,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _defaultLawyerAvatar();
          },
        )
            : _defaultLawyerAvatar(),
      ),
    );
  }

  Widget _defaultLawyerAvatar() {
    return Container(
      color: const Color(0xFFE0E4E8),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF8290A0),
        size: 45,
      ),
    );
  }

  // ============================================================
  // LAWYER STAT
  // ============================================================

  Widget _buildLawyerStat({
    required IconData icon,
    required String value,
    required String label,
    Color iconColor = navy,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 15),

          const SizedBox(width: 3),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 6.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VERTICAL DIVIDER
  // ============================================================

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 27,
      color: border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ============================================================
  // CONSULTATION TYPE
  // ============================================================

  Widget _buildConsultationType() {
    return Row(
      children: [
        Expanded(
          child: _buildConsultationTypeCard(
            type: 'direct',
            icon: Icons.account_balance_rounded,
            title: 'Tư vấn trực tiếp',
            subtitle: 'Tại văn phòng',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildConsultationTypeCard(
            type: 'online',
            icon: Icons.videocam_rounded,
            title: 'Tư vấn trực tuyến',
            subtitle: 'Qua video call',
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationTypeCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool selected = selectedConsultationType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedConsultationType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3E2) : const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? const Color(0xFFEBC78F) : border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? gold : navy, size: 24),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkNavy,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
                    style: const TextStyle(color: muted, fontSize: 7),
                  ),
                ],
              ),
            ),

            if (selected)
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE SELECTOR
  // ============================================================

  Widget _buildDateSelector() {
    final List<DateTime> weekDays = List.generate(
      7,
          (index) => DateTime(
        displayedWeekStart.year,
        displayedWeekStart.month,
        displayedWeekStart.day + index,
      ),
    );

    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: gold, size: 18),

            const SizedBox(width: 7),

            const Expanded(
              child: Text(
                'Chọn ngày tư vấn',
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                final newStart = displayedWeekStart.subtract(
                  const Duration(days: 7),
                );

                // Không cho quay về trước hôm nay
                if (_isPastDate(newStart)) {
                  return;
                }

                setState(() {
                  displayedWeekStart = newStart;

                  if (_isPastDate(selectedDate)) {
                    selectedDate = DateTime(today.year, today.month, today.day);
                  }

                  _updateSelectedTime();
                });
              },
              child: const Icon(
                Icons.chevron_left_rounded,
                color: navy,
                size: 20,
              ),
            ),

            const SizedBox(width: 5),

            Text(
              _getMonthTitle(displayedWeekStart),
              style: const TextStyle(
                color: navy,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 5),

            GestureDetector(
              onTap: () {
                setState(() {
                  displayedWeekStart = displayedWeekStart.add(
                    const Duration(days: 7),
                  );
                });
              },
              child: const Icon(
                Icons.chevron_right_rounded,
                color: navy,
                size: 20,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        Row(
          children: weekDays.map((date) {
            final bool selected = _isSameDay(selectedDate, date);

            final bool past = _isPastDate(date);

            final bool todayDate = _isToday(date);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: past
                      ? null
                      : () {
                    setState(() {
                      selectedDate = date;
                      selectedTime = '';
                      _availabilityLoaded = false;
                      _availableTimesFromApi = {};
                      _updateSelectedTime();
                    });

                    _loadAvailability();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 50,
                    decoration: BoxDecoration(
                      color: selected
                          ? gold
                          : past
                          ? const Color(0xFFE9EDF2)
                          : lightBlue,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? gold
                            : past
                            ? const Color(0xFFD5DCE4)
                            : border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getWeekdayName(date),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : past
                                ? const Color(0xFFA5AFBA)
                                : muted,
                            fontSize: 7,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : past
                                ? const Color(0xFFA5AFBA)
                                : navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        if (todayDate && !selected)
                          const Text(
                            'Hôm nay',
                            style: TextStyle(
                              color: gold,
                              fontSize: 5.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================
  // TIME SELECTOR
  // ============================================================

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded, color: gold, size: 18),

            const SizedBox(width: 7),

            const Text(
              'Chọn khung giờ',
              style: TextStyle(
                color: darkNavy,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),

            const Spacer(),

            if (_isToday(selectedDate))
              Text(
                'Hiện tại ${TimeOfDay.now().format(context)}',
                style: const TextStyle(color: muted, fontSize: 7),
              ),
          ],
        ),

        const SizedBox(height: 7),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: times.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 2.65,
          ),
          itemBuilder: (context, index) {
            final time = times[index];

            final bool available = _isTimeAvailable(time);

            final bool selected = selectedTime == time && available;

            return GestureDetector(
              onTap: !available
                  ? null
                  : () {
                setState(() {
                  selectedTime = time;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: !available
                      ? const Color(0xFFE9EDF2)
                      : selected
                      ? gold
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: !available
                        ? const Color(0xFFD5DCE4)
                        : selected
                        ? gold
                        : border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  time,
                  style: TextStyle(
                    color: !available
                        ? const Color(0xFFA5AFBA)
                        : selected
                        ? Colors.white
                        : navy,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),

        if (_isToday(selectedDate) &&
            times.every((time) => !_isTimeAvailable(time)))
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Hôm nay đã hết khung giờ. Vui lòng chọn ngày khác.',
              style: TextStyle(color: Color(0xFFE53935), fontSize: 7),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // USER INFORMATION
  // ============================================================

  Widget _buildUserInformation() {
    return _buildSection(
      icon: Icons.person_rounded,
      title: 'Thông tin của bạn',
      children: [
        if (_isLoadingCustomer)
          const Padding(
            padding: EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                SizedBox(width: 6),
                Text(
                  'Đang tải thông tin khách hàng...',
                  style: TextStyle(color: muted, fontSize: 7.5),
                ),
              ],
            ),
          )
        else if (_isLoggedIn)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF2E8B57),
                  size: 13,
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'Thông tin được lấy từ tài khoản đang đăng nhập.',
                    style: TextStyle(color: Color(0xFF2E8B57), fontSize: 7.5),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: gold, size: 13),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'Vui lòng đăng nhập để tự động điền thông tin.',
                    style: TextStyle(color: muted, fontSize: 7.5),
                  ),
                ),
              ],
            ),
          ),

        Row(
          children: [
            Expanded(
              child: _buildSmallTextField(
                label: 'Họ và tên',
                required: true,
                hint: 'Nhập họ và tên của bạn',
                controller: _nameController,
                icon: Icons.person_outline,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildSmallTextField(
                label: 'Số điện thoại',
                required: true,
                hint: 'Nhập số điện thoại',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: _buildSmallTextField(
                label: 'Email',
                hint: 'Nhập email (nếu có)',
                controller: _emailController,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
            ),

            const SizedBox(width: 10),

            // Expanded(child: _buildFieldDropdown()),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: gold, size: 18),

              const SizedBox(width: 7),

              Text(
                title,
                style: const TextStyle(
                  color: darkNavy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // SMALL TEXT FIELD
  // ============================================================

  Widget _buildSmallTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label, required),

          const SizedBox(height: 3),

          Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: border),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(color: navy, fontSize: 8.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF98A7B8),
                  fontSize: 8,
                ),
                prefixIcon: Icon(icon, color: muted, size: 14),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 31,
                  minHeight: 30,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIELD DROPDOWN
  // ============================================================

  // Widget _buildFieldDropdown() {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 7),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _buildLabel('Lĩnh vực tư vấn', true),
  //
  //         const SizedBox(height: 3),
  //
  //         Container(
  //           height: 34,
  //           padding: const EdgeInsets.symmetric(horizontal: 7),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(7),
  //             border: Border.all(color: border),
  //           ),
  //           child: _isLoadingCategories
  //               ? const Center(
  //             child: SizedBox(
  //               width: 13,
  //               height: 13,
  //               child: CircularProgressIndicator(strokeWidth: 1.5),
  //             ),
  //           )
  //               : DropdownButtonHideUnderline(
  //             child: DropdownButtonFormField<int>(
  //               value: selectedPracticeAreaId,
  //
  //               decoration: const InputDecoration(
  //                 labelText: 'Lĩnh vực pháp lý',
  //                 border: OutlineInputBorder(),
  //               ),
  //
  //               items: _consultationCategories.map((category) {
  //                 return DropdownMenuItem<int>(
  //                   value: category.id,
  //                   child: Text(category.name),
  //                 );
  //               }).toList(),
  //
  //               onChanged: (value) {
  //                 setState(() {
  //                   selectedPracticeAreaId = value;
  //                 });
  //               },
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String label, bool required) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: navy,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CONSULTATION CONTENT
  // ============================================================

  Widget _buildConsultationContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded, color: gold, size: 18),

              const SizedBox(width: 7),

              const Text(
                'Nội dung cần tư vấn',
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Container(
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: border),
            ),
            child: TextField(
              controller: _contentController,
              maxLines: null,
              maxLength: 500,
              style: const TextStyle(color: navy, fontSize: 8.5),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: 'Vui lòng nhập nội dung chi tiết để chúng tôi hỗ trợ tốt hơn...',
                hintStyle: TextStyle(color: Color(0xFF9AA9BA), fontSize: 7.5),
                contentPadding: EdgeInsets.all(9),
              ),
            ),
          ),

          const SizedBox(height: 2),

          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _contentController,
              builder: (context, value, child) {
                return Text(
                  '${value.text.length}/500',
                  style: const TextStyle(color: muted, fontSize: 6.5),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOK BUTTON
  // ============================================================

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: _isBooking ? null : _bookConsultation,
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          disabledBackgroundColor: gold.withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isBooking
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 18,
            ),

            SizedBox(width: 8),

            Text(
              'Đặt lịch ngay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(width: 9),

            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECURITY
  // ============================================================

  Widget _buildSecurityText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_rounded, color: navy, size: 12),

        const SizedBox(width: 5),

        const Text(
          'Thông tin của bạn được bảo mật tuyệt đối.',
          style: TextStyle(color: navy, fontSize: 7),
        ),
      ],
    );
  }

  // ============================================================
  // PICK ATTACHMENT
  // ============================================================

  void _pickAttachment() {
    _showMessage('Chọn tệp đính kèm');

    // ==========================================================
    // SAU NÀY CÓ THỂ DÙNG:
    //
    // file_picker
    //
    // final result =
    //     await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: [
    //     'pdf',
    //     'doc',
    //     'docx',
    //     'jpg',
    //     'jpeg',
    //     'png',
    //   ],
    // );
    //
    // Sau đó upload file lên API.
    // ==========================================================
  }

  // ============================================================
  // BOOK CONSULTATION
  // ============================================================

  Future<void> _bookConsultation() async {
    // ==========================================================
    // 1. KIỂM TRA TOKEN
    // ==========================================================

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.trim().isEmpty) {
      await _showLoginRequiredDialog();
      return;
    }

    if (_currentUserId.trim().isEmpty) {
      _showBookingError(
        'Không xác định được tài khoản khách hàng. Vui lòng đăng nhập lại.',
      );
      return;
    }

    // ==========================================================
    // 2. KIỂM TRA THÔNG TIN KHÁCH HÀNG
    // ==========================================================

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final content = _contentController.text.trim();

    if (name.isEmpty) {
      _showBookingError('Vui lòng nhập họ và tên.');
      return;
    }

    if (phone.isEmpty) {
      _showBookingError('Vui lòng nhập số điện thoại.');
      return;
    }

    if (email.isEmpty) {
      _showBookingError('Vui lòng nhập email.');
      return;
    }

    // ==========================================================
    // 3. KIỂM TRA LĨNH VỰC
    // ==========================================================
    // Giữ nguyên UI và validation của màn hình hiện tại.
    // Backend Appointment không nhận practiceAreaId, vì vậy giá trị
    // này chỉ phục vụ phần giao diện và không gửi vào POST /appointments.

    // if (selectedPracticeAreaId == null) {
    //   _showBookingError('Vui lòng chọn lĩnh vực pháp lý.');
    //   return;
    // }

    // ==========================================================
    // 4. KIỂM TRA NGÀY / GIỜ / NỘI DUNG
    // ==========================================================

    if (selectedTime.isEmpty) {
      _showBookingError('Vui lòng chọn khung giờ tư vấn.');
      return;
    }

    final scheduledAt = _buildScheduledAt();

    if (scheduledAt == null) {
      _showBookingError('Khung giờ tư vấn không hợp lệ.');
      return;
    }

    if (scheduledAt.isBefore(DateTime.now())) {
      _showBookingError('Khung giờ này đã qua. Vui lòng chọn giờ khác.');
      await _loadAvailability();
      return;
    }

    if (content.isEmpty) {
      _showBookingError('Vui lòng nhập nội dung cần tư vấn.');
      return;
    }

    // ==========================================================
    // 5. CHỐNG BẤM NHIỀU LẦN
    // ==========================================================

    if (_isBooking) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final result = await _appointmentService.createAppointment(
        clientId: _currentUserId,
        lawyerId: widget.lawyerId,
        scheduledAt: scheduledAt,
        durationMin: 30,
        description: content,
      );

      // 200 → thành công
      await _showBookingSuccess(result);
    } catch (e) {
      // Có thể backend đã lưu Appointment
      final savedAppointment = await _findRecentlyCreatedAppointment(
        clientId: _currentUserId,
        lawyerId: widget.lawyerId,
        scheduledAt: scheduledAt,
      );

      if (savedAppointment != null) {
        // Coi như đặt lịch thành công
        await _showBookingSuccess(savedAppointment);
        return;
      }

      // Không tìm thấy → thực sự thất bại
      _showBookingError(_parseBookingError(e));
    }
  }

  String _parseBookingError(Object error) {
    final message = error.toString();

    debugPrint('[BOOK CONSULTATION ERROR] $message');

    if (message.contains('401')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (message.contains('403')) {
      return 'Tài khoản hiện không có quyền đặt lịch.';
    }

    if (message.contains('404')) {
      return 'Không tìm thấy API đặt lịch.';
    }

    if (message.contains('400')) {
      if (message.toLowerCase().contains('đã có lịch') ||
          message.toLowerCase().contains('khung giờ') ||
          message.toLowerCase().contains('conflict')) {
        return 'Khung giờ này vừa được đặt. Vui lòng chọn khung giờ khác.';
      }

      return 'Thông tin đặt lịch không hợp lệ.';
    }

    if (message.contains('409')) {
      return 'Khung giờ này vừa được đặt. Vui lòng chọn khung giờ khác.';
    }

    if (message.contains('500')) {
      return 'Máy chủ đang gặp lỗi. Vui lòng thử lại sau.';
    }

    return 'Đặt lịch không thành công. Vui lòng thử lại.';
  }
  Future<AppointmentModel?> _findRecentlyCreatedAppointment({
    required String clientId,
    required String lawyerId,
    required DateTime scheduledAt,
  }) async {
    try {
      final appointments =
      await _appointmentService.getAppointments();

      for (final appointment in appointments) {
        final sameClient = appointment.clientId == clientId;
        final sameLawyer = appointment.lawyerId == lawyerId;

        final difference =
        appointment.scheduledAt.difference(scheduledAt).inSeconds.abs();

        final sameTime = difference <= 5;

        if (sameClient && sameLawyer && sameTime) {
          return appointment;
        }
      }

      return null;
    } catch (e) {
      debugPrint(
        '[BOOK CONSULTATION] '
            'Không thể kiểm tra appointment sau HTTP 500: $e',
      );

      return null;
    }
  }
  Future<void> _showBookingSuccess(AppointmentModel result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E8B57),
                size: 26,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đặt lịch thành công',
                  style: TextStyle(
                    color: darkNavy,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Lịch tư vấn của bạn đã được tạo thành công.\n\n'
                'Mã lịch hẹn:\n${result.id}\n\n'
                'Thời gian:\n'
                '${_formatDateDisplay(result.scheduledAt)} '
                '${TimeOfDay.fromDateTime(result.scheduledAt).format(context)}\n\n'
                'Trạng thái: Chờ xác nhận',
            style: const TextStyle(
              color: muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Đóng',
                style: TextStyle(color: navy),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.pop(context, result);
  }

  void _showBookingError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _showLoginRequiredDialog() async {
    if (!mounted) return;

    final shouldLogin = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: gold,
                size: 22,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yêu cầu đăng nhập',
                  style: TextStyle(
                    color: darkNavy,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Bạn cần đăng nhập để có thể đặt lịch tư vấn với luật sư.',
            style: TextStyle(
              color: muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Để sau',
                style: TextStyle(color: muted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Đăng nhập'),
            ),
          ],
        );
      },
    );

    if (shouldLogin != true || !mounted) {
      return;
    }

    // ============================================================
    // MỞ TRANG LOGIN VÀ CHỜ KẾT QUẢ
    // ============================================================

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientLoginScreen(),
      ),
    );

    if (!mounted) return;

    // ============================================================
    // LOGIN THÀNH CÔNG
    // ============================================================

    if (result != null) {
      setState(() {
        currentUser = result;
      });

      await _syncCustomerAfterLogin(result);
    }
  }

  Future<void> _syncCustomerAfterLogin(
      dynamic loginResult,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ==========================================================
      // ƯU TIÊN LẤY DỮ LIỆU TỪ RESULT LOGIN
      // ==========================================================

      String userId = '';
      String userName = '';
      String userEmail = '';
      String userPhone = '';

      if (loginResult is Map) {
        userId = _firstNonEmpty([
          loginResult['userId'],
          loginResult['id'],
        ]);

        userName = _firstNonEmpty([
          loginResult['userName'],
          loginResult['fullName'],
          loginResult['name'],
        ]);

        userEmail = _firstNonEmpty([
          loginResult['userEmail'],
          loginResult['email'],
        ]);

        userPhone = _firstNonEmpty([
          loginResult['userPhone'],
          loginResult['phone'],
        ]);
      }

      // ==========================================================
      // FALLBACK: ĐỌC LẠI SESSION ĐÃ LƯU
      // ==========================================================

      if (userId.isEmpty) {
        userId = _firstNonEmpty([
          prefs.getString('userId'),
        ]);
      }

      if (userName.isEmpty) {
        userName = _firstNonEmpty([
          prefs.getString('userName'),
          prefs.getString('fullName'),
        ]);
      }

      if (userEmail.isEmpty) {
        userEmail = _firstNonEmpty([
          prefs.getString('userEmail'),
          prefs.getString('email'),
        ]);
      }

      if (userPhone.isEmpty) {
        userPhone = _firstNonEmpty([
          prefs.getString('userPhone'),
          prefs.getString('phone'),
        ]);
      }

      // ==========================================================
      // CẬP NHẬT STATE NGAY LẬP TỨC
      // ==========================================================

      if (!mounted) return;

      setState(() {
        _isLoggedIn = true;
        _isLoadingCustomer = false;

        _currentUserId = userId;

        _nameController.text = userName;
        _phoneController.text = userPhone;
        _emailController.text = userEmail;
      });

      debugPrint(
        '[CONSULTATION] Đã đồng bộ client sau login: '
            'userId=$_currentUserId, '
            'name=$userName, '
            'phone=$userPhone, '
            'email=$userEmail',
      );
    } catch (e) {
      debugPrint(
        '[CONSULTATION] Lỗi đồng bộ client sau login: $e',
      );

      // Nếu result login thành công nhưng state chưa đồng bộ,
      // đọc lại session một lần.
      await _loadCurrentCustomer();
    }
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

