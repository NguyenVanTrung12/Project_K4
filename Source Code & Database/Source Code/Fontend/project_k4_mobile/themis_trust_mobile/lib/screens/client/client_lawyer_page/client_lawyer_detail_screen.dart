import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/models/lawyer_model.dart';
import 'package:themis_trust_mobile/screens/client/client_consultation_page/client_consultation_screen.dart';
import 'package:themis_trust_mobile/screens/client/client_login_page/client_login_screen.dart';
import 'package:themis_trust_mobile/screens/client/client_message_page/client_chat_screen.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_consultation_page/lawyer_consultation_calendar.dart';
import 'package:themis_trust_mobile/services/conversation_service.dart';
import 'package:themis_trust_mobile/services/lawyer_service.dart';

class ClientLawyerDetailScreen extends StatefulWidget {
  const ClientLawyerDetailScreen({super.key, required this.lawyerId});

  /// ID của luật sư được truyền từ màn hình trước
  final String lawyerId;

  @override
  State<ClientLawyerDetailScreen> createState() =>
      _ClientLawyerDetailScreenState();
}

class _ClientLawyerDetailScreenState extends State<ClientLawyerDetailScreen> {
  // =============================================================
  // SERVICE
  // =============================================================
  final LawyerService _lawyerService = LawyerService();

  // =============================================================
  // STATE
  // =============================================================
  LawyerModel? _lawyer;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0;
  final List<String> _tabs = [
    'Tổng quan',
    'Học vấn',
    'Chứng chỉ',
    'Chuyên môn',
  ];

  final ConversationService _conversationService = ConversationService();

  // =============================================================
  // INIT
  // =============================================================
  @override
  void initState() {
    super.initState();
    _loadLawyer();
  }

  // =============================================================
  // GET LAWYER BY ID
  // =============================================================
  Future<void> _loadLawyer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final lawyer = await _lawyerService.getLawyerById(widget.lawyerId);
      if (!mounted) return;
      setState(() {
        _lawyer = lawyer;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải thông tin luật sư.';
      });
      debugPrint('GET LAWYER DETAIL ERROR: $e');
    }
  }

  // =============================================================
  // BUILD
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _lawyer != null ? _buildBottomAction() : null,
    );
  }

  // =============================================================
  // BODY
  // =============================================================
  Widget _buildBody() {
    // -------------------------------------------------------------
    // LOADING //
    //  -------------------------------------------------------------
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC48A2B)),
      );
    }
    // -------------------------------------------------------------
    // ERROR
    // -------------------------------------------------------------
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    // -------------------------------------------------------------
    // DATA
    // -------------------------------------------------------------
    if (_lawyer == null) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      color: const Color(0xFFC48A2B),
      onRefresh: _loadLawyer,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            // -----------------------------------------------------
            // HEADER
            // -----------------------------------------------------
            _buildLawyerHeader(),
            // -----------------------------------------------------
            // STATISTICS
            // -----------------------------------------------------
            _buildStatistics(),
            // -----------------------------------------------------
            // ACTION BUTTONS
            // -----------------------------------------------------
            _buildActionButtons(),
            // -----------------------------------------------------
            // INTRODUCTION
            // -----------------------------------------------------
            _buildIntroduction(),
            // -----------------------------------------------------
            // TABS
            // -----------------------------------------------------
            _buildTabs(),
            // -----------------------------------------------------
            // TAB CONTENT
            // -----------------------------------------------------
            _buildSelectedTabContent(),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // ERROR STATE
  // =============================================================
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: Color(0xFF9AAABC),
            ),
            const SizedBox(height: 15),
            const Text(
              'Không thể tải thông tin luật sư',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF123E72),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7188A3), fontSize: 12),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadLawyer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC48A2B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // EMPTY STATE
  // =============================================================
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Không tìm thấy thông tin luật sư.',
        style: TextStyle(color: Color(0xFF7188A3), fontSize: 13),
      ),
    );
  }

  // =============================================================
  // TOP BAR
  // =============================================================
  Widget _buildTopBar() {
    return Container(
      height: 54,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF123E72),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Thông tin luật sư',
              style: TextStyle(
                color: Color(0xFF123E72),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.share_outlined,
              color: Color(0xFF123E72),
              size: 21,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: Color(0xFF123E72),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // LAWYER HEADER
  // =============================================================
  Widget _buildLawyerHeader() {
    final lawyer = _lawyer!;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------
          // AVATAR
          // -------------------------------------------------------
          _buildAvatar(), const SizedBox(width: 13),
          // -------------------------------------------------------
          // INFORMATION
          // -------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LUẬT SƯ',
                  style: TextStyle(
                    color: Color(0xFFC58B2D),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lawyer.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF123E72),
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lawyer.title.isNotEmpty ? lawyer.title : 'Luật sư',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF55708F),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                _buildInfoLine(
                  Icons.work_outline_rounded,
                  '${lawyer.yearsExp} năm kinh nghiệm',
                ),
                const SizedBox(height: 4),
                _buildInfoLine(
                  Icons.workspace_premium_outlined,
                  lawyer.barLicenseNo != null && lawyer.barLicenseNo!.isNotEmpty
                      ? 'Số CCHN: ${lawyer.barLicenseNo}'
                      : 'Đã cập nhật thông tin hành nghề',
                ),
                const SizedBox(height: 4),
                _buildInfoLine(Icons.mail_outline_rounded, lawyer.email),
                if (lawyer.phone != null && lawyer.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildInfoLine(Icons.phone_outlined, lawyer.phone!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // AVATAR
  // =============================================================
  Widget _buildAvatar() {
    final lawyer = _lawyer!;

    final String avatarUrl = _buildAvatarUrl(lawyer.avatarUrl);

    debugPrint(
      '[LAWYER DETAIL AVATAR] '
          '${lawyer.fullName} -> "$avatarUrl"',
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: avatarUrl.isNotEmpty
              ? Image.network(
            avatarUrl,
            width: 118,
            height: 130,
            fit: BoxFit.cover,

            // -------------------------------------------------
            // LOADING
            // -------------------------------------------------
            loadingBuilder:
                (
                BuildContext context,
                Widget child,
                ImageChunkEvent? loadingProgress,
                ) {
              if (loadingProgress == null) {
                return child;
              }

              return Container(
                width: 118,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFFC48A2B),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            },

            // -------------------------------------------------
            // ERROR
            // -------------------------------------------------
            errorBuilder:
                (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
                ) {
              debugPrint(
                '[LAWYER DETAIL AVATAR ERROR] '
                    '${lawyer.fullName}: $error',
              );

              return _buildDefaultAvatar();
            },
          )
              : _buildDefaultAvatar(),
        ),

        // -----------------------------------------------------------
        // ONLINE STATUS
        // -----------------------------------------------------------
        if (lawyer.isAvailable)
          Positioned(
            left: 7,
            bottom: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Color(0xFF14A879), size: 7),
                  SizedBox(width: 4),
                  Text(
                    'Đang hoạt động',
                    style: TextStyle(
                      color: Color(0xFF14986E),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // =============================================================
  // BUILD AVATAR URL
  // =============================================================
  String _buildAvatarUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }

    final String value = url.trim();

    // API đã trả URL đầy đủ
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    // API trả đường dẫn tương đối
    if (value.startsWith('/')) {
      return 'http://10.0.2.2:5000$value';
    }

    // API trả đường dẫn tương đối nhưng không có /
    return 'http://10.0.2.2:5000/$value';
  }

  // =============================================================
  // DEFAULT AVATAR
  // =============================================================
  Widget _buildDefaultAvatar() {
    return Container(
      width: 118,
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFE6EDF4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 60,
        color: Color(0xFF7890A8),
      ),
    );
  }

  // =============================================================
  // INFO LINE
  // =============================================================
  Widget _buildInfoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF234D78), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF496783), fontSize: 9.5),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // STATISTICS
  // =============================================================
  Widget _buildStatistics() {
    final lawyer = _lawyer!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2EAF2)),
      ),
      child: Row(
        children: [
          _buildStatisticItem(
            icon: Icons.workspace_premium_outlined,
            value: '${lawyer.yearsExp}',
            label: 'Năm kinh nghiệm',
          ),
          _buildVerticalDivider(),
          _buildStatisticItem(
            icon: Icons.gavel_outlined,
            value: '${lawyer.casesWon}',
            label: 'Vụ việc đã thắng',
          ),
          _buildVerticalDivider(),
          _buildStatisticItem(
            icon: Icons.star_outline_rounded,
            value: lawyer.ratingAvg.toStringAsFixed(1),
            label: 'Đánh giá',
          ),
          _buildVerticalDivider(),
          _buildStatisticItem(
            icon: Icons.circle,
            value: lawyer.isAvailable ? 'Online' : 'Offline',
            label: 'Trạng thái',
          ),
        ],
      ),
    );
  }

  // =============================================================
  // STATISTIC ITEM
  // =============================================================
  Widget _buildStatisticItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFC48A2B), size: 18),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF163E6B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7890A8),
                fontSize: 6.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================= // DIVIDER // =============================================================
  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 42, color: const Color(0xFFE4EBF2));
  }

  // ============================================================= // ACTION BUTTONS // =============================================================
  Widget _buildActionButtons() {
    final lawyer = _lawyer!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 11),
      child: Row(
        children: [
          // ------------------------------------------------------- // BOOK CONSULTATION // -------------------------------------------------------
          Expanded(
            child: SizedBox(
              height: 39,
              child: ElevatedButton(
                onPressed: lawyer.isAvailable ? _onBookConsultation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC48A2B),
                  disabledBackgroundColor: const Color(0xFFD8DDE3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'Đặt lịch tư vấn',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          // ------------------------------------------------------- // CONTACT // -------------------------------------------------------
          Expanded(
            child: SizedBox(
              height: 39,
              child: OutlinedButton(
                onPressed: () => _onContact(
                  lawyerId: lawyer.id.toString(),
                  lawyerName: lawyer.fullName,
                  lawyerAvatar: lawyer.avatarUrl,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF789CC0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      color: Color(0xFF234D78),
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Liên hệ ngay',
                      style: TextStyle(
                        color: Color(0xFF234D78),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================= // INTRODUCTION // =============================================================
  Widget _buildIntroduction() {
    final lawyer = _lawyer!;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Giới thiệu',
                  style: TextStyle(
                    color: Color(0xFF123E72),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (lawyer.bio != null && lawyer.bio!.isNotEmpty)
                const Text(
                  'Thông tin',
                  style: TextStyle(
                    color: Color(0xFF17609D),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            lawyer.bio != null && lawyer.bio!.isNotEmpty
                ? lawyer.bio!
                : 'Luật sư chưa cập nhật thông tin giới thiệu.',
            style: const TextStyle(
              color: Color(0xFF607B98),
              fontSize: 9.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 9),
          // ------------------------------------------------------- // BAR LICENSE // -------------------------------------------------------
          if (lawyer.barLicenseNo != null && lawyer.barLicenseNo!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF6),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFEAE5DA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    color: Color(0xFFC48A2B),
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Chứng chỉ hành nghề: ${lawyer.barLicenseNo}',
                      style: const TextStyle(
                        color: Color(0xFF6C7180),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
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

  // ============================================================= // TABS // =============================================================
  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _tabs.length,
          itemBuilder: (context, index) {
            final bool selected = _selectedTab == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFFF9EE) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? const Color(0xFFC48A2B)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTabIcon(index),
                      color: selected
                          ? const Color(0xFFC48A2B)
                          : const Color(0xFF244A72),
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _tabs[index],
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFFC48A2B)
                            : const Color(0xFF244A72),
                        fontSize: 8.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================= // TAB ICON // =============================================================
  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.info_outline_rounded;
      case 1:
        return Icons.school_outlined;
      case 2:
        return Icons.workspace_premium_outlined;
      case 3:
        return Icons.balance_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // ============================================================= // SELECTED TAB CONTENT // =============================================================
  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewContent();
      case 1:
        return _buildEducationContent();
      case 2:
        return _buildCertificateContent();
      case 3:
        return _buildSpecializationContent();
      default:
        return const SizedBox();
    }
  }

  // ============================================================= // OVERVIEW // =============================================================
  Widget _buildOverviewContent() {
    final lawyer = _lawyer!;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Thông tin hành nghề'),
          const SizedBox(height: 11),
          _buildDetailRow(
            Icons.person_outline_rounded,
            'Họ và tên',
            lawyer.fullName,
          ),
          _buildDetailRow(
            Icons.work_outline_rounded,
            'Chức danh',
            lawyer.title.isNotEmpty ? lawyer.title : 'Chưa cập nhật',
          ),
          _buildDetailRow(
            Icons.timelapse_outlined,
            'Kinh nghiệm',
            '${lawyer.yearsExp} năm',
          ),
          _buildDetailRow(
            Icons.star_outline_rounded,
            'Đánh giá',
            lawyer.ratingAvg.toStringAsFixed(1),
          ),
          _buildDetailRow(
            Icons.gavel_outlined,
            'Vụ việc đã thắng',
            '${lawyer.casesWon}',
          ),
          _buildDetailRow(
            Icons.circle_outlined,
            'Trạng thái',
            lawyer.isAvailable ? 'Đang nhận tư vấn' : 'Hiện không nhận tư vấn',
          ),
        ],
      ),
    );
  }

  // ============================================================= // DETAIL ROW // =============================================================
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5ECF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC48A2B), size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF7890A8), fontSize: 8),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF365B80),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================= // EDUCATION // =============================================================
  Widget _buildEducationContent() {
    return _buildEmptyInformationSection(
      title: 'Học vấn',
      icon: Icons.school_outlined,
      message: 'API hiện tại chưa cung cấp thông tin học vấn của luật sư.',
    );
  }

  // ============================================================= // CERTIFICATE // =============================================================
  Widget _buildCertificateContent() {
    final lawyer = _lawyer!;
    if (lawyer.barLicenseNo != null && lawyer.barLicenseNo!.isNotEmpty) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Chứng chỉ'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5ECF3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    color: Color(0xFFC48A2B),
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chứng chỉ hành nghề Luật sư',
                          style: TextStyle(
                            color: Color(0xFF123E72),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Số: ${lawyer.barLicenseNo}',
                          style: const TextStyle(
                            color: Color(0xFF607B98),
                            fontSize: 9,
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
      );
    }
    return _buildEmptyInformationSection(
      title: 'Chứng chỉ',
      icon: Icons.workspace_premium_outlined,
      message: 'Luật sư chưa cập nhật thông tin chứng chỉ.',
    );
  }

  // ============================================================= // SPECIALIZATION // =============================================================
  Widget _buildSpecializationContent() {
    final lawyer = _lawyer!;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Chuyên môn'),
          const SizedBox(height: 11),
          if (lawyer.practiceAreas.isEmpty)
            const Text(
              'Luật sư chưa cập nhật lĩnh vực hành nghề.',
              style: TextStyle(color: Color(0xFF7188A3), fontSize: 9.5),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: lawyer.practiceAreas.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF316895),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ============================================================= // EMPTY INFORMATION // =============================================================
  Widget _buildEmptyInformationSection({
    required String title,
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5ECF3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: const Color(0xFFC48A2B), size: 30),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7188A3),
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================= // SECTION HEADER // =============================================================
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF123E72),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ============================================================= // BOTTOM ACTION // =============================================================
  Widget _buildBottomAction() {
    final lawyer = _lawyer!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 43,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: lawyer.isAvailable ? _onBookConsultation : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC48A2B),
              disabledBackgroundColor: const Color(0xFFD8DDE3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_outlined, size: 17),
                const SizedBox(width: 7),
                Text(
                  lawyer.isAvailable
                      ? 'Đặt lịch tư vấn'
                      : 'Luật sư hiện không nhận tư vấn',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================= // BOOK CONSULTATION // =============================================================
  Future<void> _onBookConsultation() async {
    if (_lawyer == null) return;
    // =========================================================
    // 1. KIỂM TRA TOKEN
    // =========================================================
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final isLoggedIn = token != null && token.trim().isNotEmpty;
    // =========================================================
    // 2. ĐÃ ĐĂNG NHẬP // → MỞ TRANG ĐẶT LỊCH NGAY
    // =========================================================
    if (isLoggedIn) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientConsultationScreen(lawyerId: _lawyer!.id),
        ),
      );
      return;
    }
    // =========================================================
    // 3. CHƯA ĐĂNG NHẬP
    // → HIỆN DIALOG
    // =========================================================
    if (!mounted) return;
    await _showLoginRequiredDialog();
  }

  // =============================================================
  // CONTACT
  // =============================================================
  Future<void> _onContact({
    required String lawyerId,
    required String lawyerName,
    String? lawyerAvatar,
  }) async {
    // ==========================================================
    // KIỂM TRA ĐĂNG NHẬP
    // ==========================================================

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    final isLoggedIn = token != null && token.trim().isNotEmpty;

    if (!isLoggedIn) {
      if (!mounted) return;

      await _showLoginRequiredDialog();

      return;
    }

    // ==========================================================
    // TÌM CONVERSATION ĐÃ CÓ VỚI LUẬT SƯ
    // ==========================================================

    String? conversationId;

    try {
      final conversations = await _conversationService.getMyConversations();

      // Tìm tất cả conversation của lawyer này
      final lawyerConversations = conversations
          .where(
            (conversation) =>
        conversation.lawyerId.toString() == lawyerId.toString(),
      )
          .toList();

      // ========================================================
      // NẾU ĐÃ CÓ
      // → DÙNG CONVERSATION CŨ
      // ========================================================

      if (lawyerConversations.isNotEmpty) {
        // Nếu có nhiều conversation trùng lawyer,
        // lấy conversation có thời gian tin nhắn mới nhất.

        lawyerConversations.sort((a, b) {
          final dateA = a.lastMessageAt;
          final dateB = b.lastMessageAt;

          if (dateA == null && dateB == null) {
            return 0;
          }

          if (dateA == null) {
            return 1;
          }

          if (dateB == null) {
            return -1;
          }

          return dateB.compareTo(dateA);
        });

        conversationId = lawyerConversations.first.id;
      }
    } catch (e) {
      debugPrint('FIND EXISTING CONVERSATION ERROR: $e');
    }

    // ==========================================================
    // MỞ CHAT
    // ==========================================================

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientChatScreen(
          conversationId: conversationId,

          lawyer: ClientChatLawyerData(
            id: lawyerId,
            name: lawyerName,
            status: (_lawyer?.isAvailable ?? false)
                ? 'Đang hoạt động'
                : 'Không hoạt động',
            avatarUrl: lawyerAvatar ?? '',
          ),
        ),
      ),
    );
  }

  Future<void> _showLoginRequiredDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          // =====================================================
          // TITLE
          // =====================================================
          title: const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFC48A2B),
                size: 22,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Yêu cầu đăng nhập',
                  style: TextStyle(
                    color: Color(0xFF173B66),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // =====================================================
          // CONTENT
          // =====================================================
          content: const Text(
            'Bạn cần đăng nhập để có thể đặt lịch tư vấn với luật sư.',
            style: TextStyle(
              color: Color(0xFF7186A0),
              fontSize: 13,
              height: 1.4,
            ),
          ),

          // =====================================================
          // ACTIONS
          // =====================================================
          actions: [
            // ---------------------------------------------------
            // ĐỂ SAU
            // ---------------------------------------------------

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Để sau',
                style: TextStyle(color: Color(0xFF7186A0)),
              ),
            ),

            // ---------------------------------------------------
            // ĐĂNG NHẬP
            // ---------------------------------------------------
            ElevatedButton(
              onPressed: () async {
                // ===============================================
                // ĐÓNG DIALOG
                // ===============================================

                Navigator.pop(dialogContext);

                // ===============================================
                // MỞ LOGIN
                // ===============================================

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClientLoginScreen()),
                );

                // ===============================================
                // NGƯỜI DÙNG CHƯA ĐĂNG NHẬP THÀNH CÔNG
                // ===============================================

                if (result == null || !mounted) {
                  return;
                }

                // ===============================================
                // LOGIN THÀNH CÔNG
                // ===============================================

                final userData = Map<String, dynamic>.from(result);

                debugPrint('LOGIN RETURN USER: $userData');

                // ===============================================
                // QUAN TRỌNG:
                //
                // ClientLoginScreen đã lưu token vào
                // SharedPreferences.
                //
                // Bây giờ mở thẳng trang đặt lịch.
                // ===============================================

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ClientConsultationScreen(lawyerId: _lawyer!.id),
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC48A2B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              child: const Text('Đăng nhập'),
            ),
          ],
        );
      },
    );
  }
}
