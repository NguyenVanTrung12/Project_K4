import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/models/notification_model.dart';
import 'package:themis_trust_mobile/screens/client/client_login_page/client_login_screen.dart';
import 'package:themis_trust_mobile/services/notification_service.dart';
import 'package:themis_trust_mobile/services/auth_navigation_service.dart';

// =============================================================
// COLORS
// =============================================================

const Color clientNotificationNavy = Color(0xFF123963);
const Color clientNotificationDarkNavy = Color(0xFF0D2E52);
const Color clientNotificationGold = Color(0xFFC68A2B);
const Color clientNotificationText = Color(0xFF173A63);
const Color clientNotificationMuted = Color(0xFF7187A0);
const Color clientNotificationBorder = Color(0xFFE5ECF3);

// =============================================================
// SCREEN
// =============================================================

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  State<ClientNotificationsScreen> createState() =>
      ClientNotificationsScreenState();
}

class ClientNotificationsScreenState extends State<ClientNotificationsScreen> {
  // =============================================================
  // SERVICES
  // =============================================================

  final NotificationService _notificationService = NotificationService();

  // =============================================================
  // DATA
  // =============================================================

  List<NotificationModel> _notifications = [];

  String? _currentUserId;

  bool _isLoading = true;
  bool _isMarkingAll = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> refreshAfterTabChange() async {
    if (!mounted) return;

    await _loadNotifications();
  }

  // =============================================================
  // GET CURRENT USER ID
  // =============================================================

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('userId');

    debugPrint('====================================');
    debugPrint('NOTIFICATION SESSION');
    debugPrint('USER ID: $userId');
    debugPrint(
      'TOKEN: ${prefs.getString('token') != null ? "CÓ TOKEN" : "KHÔNG CÓ TOKEN"}',
    );
    debugPrint('====================================');

    if (userId == null || userId.trim().isEmpty) {
      return null;
    }

    return userId.trim();
  }

  // =============================================================
  // LOAD NOTIFICATIONS
  // =============================================================

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getString('userId');
      final token = prefs.getString('token');

      debugPrint('====================================');
      debugPrint('LOAD NOTIFICATIONS');
      debugPrint('USER ID: $userId');
      debugPrint(
        'TOKEN: ${token != null && token.isNotEmpty ? "CÓ TOKEN" : "KHÔNG CÓ TOKEN"}',
      );
      debugPrint('====================================');

      // ============================================================
      // CHƯA ĐĂNG NHẬP
      // ============================================================

      if (token == null ||
          token.trim().isEmpty ||
          userId == null ||
          userId.trim().isEmpty) {
        debugPrint('NOTIFICATION: Chưa đăng nhập');

        if (!mounted) return;

        setState(() {
          _currentUserId = null;
          _notifications = [];
          _isLoading = false;
          _errorMessage = null;
        });

        return;
      }

      // ============================================================
      // ĐÃ ĐĂNG NHẬP
      // ============================================================

      final currentUserId = userId.trim();

      debugPrint('NOTIFICATION: Đang lấy thông báo cho user $currentUserId');

      final result = await _notificationService.getMine();

      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;

      setState(() {
        _currentUserId = currentUserId;
        _notifications = result;
        _isLoading = false;
        _errorMessage = null;
      });

      debugPrint('NOTIFICATION: Tải thành công ${result.length} thông báo');
    } catch (e, stackTrace) {
      debugPrint('NOTIFICATION ERROR: $e');
      debugPrint('NOTIFICATION STACK: $stackTrace');

      if (!mounted) return;

      setState(() {
        _notifications = [];
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  // =============================================================
  // ERROR MESSAGE
  // =============================================================

  String _getErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'Không thể kết nối đến máy chủ';
    }

    if (message.contains('401')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại';
    }

    if (message.contains('403')) {
      return 'Bạn không có quyền xem thông báo';
    }

    if (message.contains('404')) {
      return 'Không tìm thấy dữ liệu thông báo';
    }

    return 'Không thể tải thông báo. Vui lòng thử lại';
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // BODY
  // =============================================================

  Widget _buildBody() {
    // -----------------------------------------------------------
    // LOADING
    // -----------------------------------------------------------

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: clientNotificationNavy),
      );
    }

    // -----------------------------------------------------------
    // CHƯA ĐĂNG NHẬP
    // -----------------------------------------------------------

    if (_currentUserId == null) {
      return _buildLoginRequiredState();
    }

    // -----------------------------------------------------------
    // ERROR
    // -----------------------------------------------------------

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // -----------------------------------------------------------
    // EMPTY
    // -----------------------------------------------------------

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    // -----------------------------------------------------------
    // LIST
    // -----------------------------------------------------------

    return RefreshIndicator(
      color: clientNotificationNavy,
      onRefresh: _loadNotifications,
      child: _buildNotificationList(),
    );
  }

  // =============================================================
  // HEADER
  // =============================================================

  Widget _buildHeader() {
    final hasUnread = _notifications.any(
          (notification) => !notification.isRead,
    );

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------
          // TITLE
          // -------------------------------------------------------

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông báo',
                  style: TextStyle(
                    color: clientNotificationDarkNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cập nhật nhanh chóng các hoạt động mới nhất',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: clientNotificationMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // -------------------------------------------------------
          // MARK ALL AS READ
          // -------------------------------------------------------
          GestureDetector(
            onTap: hasUnread && !_isMarkingAll ? _markAllAsRead : null,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE0E8F1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isMarkingAll)
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.7,
                        color: clientNotificationNavy,
                      ),
                    )
                  else
                    const Icon(
                      Icons.done_all_rounded,
                      color: clientNotificationNavy,
                      size: 15,
                    ),
                  const SizedBox(width: 5),
                  const Text(
                    'Đánh dấu tất cả đã đọc',
                    style: TextStyle(
                      color: clientNotificationText,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // NOTIFICATION LIST
  // =============================================================

  Widget _buildNotificationList() {
    final List<String> groups = ['Hôm nay', 'Hôm qua', 'Trước đó'];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 20),
      children: [
        for (final group in groups) ...[
          if (_notifications.any(
                (notification) => _getDateGroup(notification.createdAt) == group,
          ))
            _buildGroupTitle(group),

          ..._notifications
              .where(
                (notification) =>
            _getDateGroup(notification.createdAt) == group,
          )
              .map((notification) {
            return ClientNotificationCard(
              notification: notification,
              onTap: () {
                _openNotification(notification);
              },
            );
          }),
        ],
      ],
    );
  }

  // =============================================================
  // DATE GROUP
  // =============================================================

  String _getDateGroup(DateTime dateTime) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final date = DateTime(
      dateTime.toLocal().year,
      dateTime.toLocal().month,
      dateTime.toLocal().day,
    );

    final difference = today.difference(date).inDays;

    if (difference == 0) {
      return 'Hôm nay';
    }

    if (difference == 1) {
      return 'Hôm qua';
    }

    return 'Trước đó';
  }

  // =============================================================
  // GROUP TITLE
  // =============================================================

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: clientNotificationText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // =============================================================
  // MARK ALL AS READ
  // =============================================================

  Future<void> _markAllAsRead() async {
    final userId = _currentUserId;

    if (userId == null || userId.isEmpty) {
      return;
    }

    if (_isMarkingAll) {
      return;
    }

    setState(() {
      _isMarkingAll = true;
    });

    try {
      await _notificationService.markAllAsRead();

      if (!mounted) return;

      setState(() {
        _isMarkingAll = false;
      });

      await _loadNotifications();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isMarkingAll = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(e)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // =============================================================
  // OPEN NOTIFICATION
  // =============================================================

  Future<void> _openNotification(NotificationModel notification) async {
    // -----------------------------------------------------------
    // Nếu chưa đọc -> gọi API mark read
    // -----------------------------------------------------------

    if (!notification.isRead) {
      try {
        await _notificationService.markAsRead(notification.id);

        // Reload để lấy trạng thái mới nhất từ server.
        await _loadNotifications();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể đánh dấu thông báo đã đọc'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }

    if (!mounted) return;

    // -----------------------------------------------------------
    // XỬ LÝ ĐIỀU HƯỚNG THEO TYPE
    // -----------------------------------------------------------

    _handleNotificationNavigation(notification);
  }

  // =============================================================
  // NAVIGATION BY TYPE
  // =============================================================

  void _handleNotificationNavigation(NotificationModel notification) {
    switch (notification.type.toLowerCase()) {
    // =========================================================
    // APPOINTMENT
    // =========================================================
    //
    // Backend sử dụng:
    // type = "appointment"
    //
    // Ví dụ:
    // "Đặt lịch thành công"
    // "Lịch đang chờ luật sư xác nhận."
    //
    // Hiện tại mở bottom sheet giống các notification khác.
    // =========================================================

      case 'appointment':
        _showNotificationMessage(notification);
        break;

    // =========================================================
    // MESSAGE
    // =========================================================

      case 'message':
        _showNotificationMessage(notification);
        break;

    // =========================================================
    // CALENDAR
    // =========================================================

      case 'calendar':
        _showNotificationMessage(notification);
        break;

    // =========================================================
    // DOCUMENT
    // =========================================================

      case 'document':
        _showNotificationMessage(notification);
        break;

    // =========================================================
    // REVIEW
    // =========================================================

      case 'review':
        _showNotificationMessage(notification);
        break;

    // =========================================================
    // PAYMENT
    // =========================================================

      case 'payment':
        _showNotificationMessage(notification);
        break;

    // =========================================================
    // SYSTEM
    // =========================================================

      case 'system':
        _showNotificationMessage(notification);
        break;

    // =========================================================
    // USER
    // =========================================================

      case 'user':
        _showNotificationMessage(notification);
        break;

    // =========================================================
    // THANKS
    // =========================================================

      case 'thanks':
        _showNotificationMessage(notification);
        break;

    // =========================================================
    // DEFAULT
    // =========================================================

      default:
        _showNotificationMessage(notification);
        break;
    }
  }

  // =============================================================
  // SHOW NOTIFICATION DETAIL
  // =============================================================

  void _showNotificationMessage(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------
              // HANDLE
              // ---------------------------------------------------

              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E0E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ---------------------------------------------------
              // TITLE
              // ---------------------------------------------------
              Text(
                notification.title,
                style: const TextStyle(
                  color: clientNotificationDarkNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              // ---------------------------------------------------
              // BODY
              // ---------------------------------------------------
              if (notification.body != null &&
                  notification.body!.trim().isNotEmpty)
                Text(
                  notification.body!,
                  style: const TextStyle(
                    color: clientNotificationMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

              const SizedBox(height: 12),

              // ---------------------------------------------------
              // TIME
              // ---------------------------------------------------
              Text(
                _formatDateTime(notification.createdAt),
                style: const TextStyle(
                  color: clientNotificationMuted,
                  fontSize: 10,
                ),
              ),

              // ---------------------------------------------------
              // REF ID
              // ---------------------------------------------------
              if (notification.refId != null &&
                  notification.refId!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Mã tham chiếu: ${notification.refId}',
                  style: const TextStyle(
                    color: clientNotificationMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // =============================================================
  // FORMAT DATE TIME
  // =============================================================

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    final hour = local.hour.toString().padLeft(2, '0');

    final minute = local.minute.toString().padLeft(2, '0');

    final day = local.day.toString().padLeft(2, '0');

    final month = local.month.toString().padLeft(2, '0');

    final year = local.year.toString();

    return '$hour:$minute - $day/$month/$year';
  }

  // =============================================================
  // EMPTY STATE
  // =============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: clientNotificationNavy,
      onRefresh: _loadNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.30),

          const Icon(
            Icons.notifications_none_rounded,
            size: 60,
            color: Color(0xFFB7C5D4),
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'Chưa có thông báo',
              style: TextStyle(
                color: clientNotificationText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 6),

          const Center(
            child: Text(
              'Các thông báo mới sẽ xuất hiện tại đây',
              style: TextStyle(color: clientNotificationMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // LOGIN REQUIRED STATE
  // =============================================================
  Future<void> _openLogin() async {
    await AuthNavigationService.loginAndRedirect(context);
    await _loadNotifications();
  }

  Widget _buildLoginRequiredState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.24),

        // ==========================================================
        // ICON
        // ==========================================================
        const Icon(
          Icons.lock_outline_rounded,
          size: 58,
          color: Color(0xFFB7C5D4),
        ),

        const SizedBox(height: 16),

        // ==========================================================
        // TITLE
        // ==========================================================
        const Center(
          child: Text(
            'Bạn cần đăng nhập để xem thông báo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: clientNotificationText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ==========================================================
        // DESCRIPTION
        // ==========================================================
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 35),
          child: Text(
            'Vui lòng đăng nhập để nhận và xem các thông báo mới nhất.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: clientNotificationMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ==========================================================
        // LOGIN BUTTON
        // ==========================================================
        Center(
          child: SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: _openLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: clientNotificationNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login_rounded, size: 17),
                  SizedBox(width: 7),
                  Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // ERROR STATE
  // =============================================================

  Widget _buildErrorState() {
    return RefreshIndicator(
      color: clientNotificationNavy,
      onRefresh: _loadNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),

          const Icon(
            Icons.cloud_off_rounded,
            size: 55,
            color: Color(0xFFB7C5D4),
          ),

          const SizedBox(height: 15),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                _errorMessage ?? 'Không thể tải thông báo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: clientNotificationText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Center(
            child: ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: clientNotificationNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// NOTIFICATION CARD
// =================================================================

class ClientNotificationCard extends StatelessWidget {
  const ClientNotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _getStyle(notification.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(9, 9, 8, 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9EFF5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.018),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------
                // ICON
                // -------------------------------------------------

                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: style.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: style.iconColor, size: 21),
                ),

                const SizedBox(width: 10),

                // -------------------------------------------------
                // CONTENT
                // -------------------------------------------------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: clientNotificationText,
                                fontSize: 10.5,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            _formatNotificationTime(notification.createdAt),
                            style: const TextStyle(
                              color: clientNotificationMuted,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      Text(
                        notification.body ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: clientNotificationMuted,
                          fontSize: 8.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 5),

                // -------------------------------------------------
                // ARROW
                // -------------------------------------------------
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8195AA),
                    size: 17,
                  ),
                ),

                // -------------------------------------------------
                // UNREAD DOT
                // -------------------------------------------------
                if (!notification.isRead)
                  const Padding(
                    padding: EdgeInsets.only(top: 28, left: 1),
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFE8293A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // TIME
  // =============================================================

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();

    // Đưa cả hai về đầu ngày để tính số ngày chính xác
    final today = DateTime(now.year, now.month, now.day);

    final notificationDate = DateTime(local.year, local.month, local.day);

    final difference = today.difference(notificationDate).inDays;

    // =========================================================
    // HÔM NAY → HIỂN THỊ GIỜ
    // Ví dụ: 15:30
    // =========================================================

    if (difference == 0) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    }

    // =========================================================
    // HÔM QUA
    // =========================================================

    if (difference == 1) {
      return 'Hôm qua';
    }

    // =========================================================
    // 2 - 6 NGÀY TRƯỚC
    // =========================================================

    if (difference >= 2 && difference < 7) {
      return '$difference ngày trước';
    }

    // =========================================================
    // TỪ 7 NGÀY TRỞ LÊN
    // =========================================================

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    // Nếu khác năm thì hiển thị cả năm
    if (local.year != now.year) {
      return '$day/$month/${local.year}';
    }

    return '$day/$month';
  }

  // =============================================================
  // STYLE
  // =============================================================

  ClientNotificationStyle _getStyle(String type) {
    switch (type.toLowerCase()) {
    // =========================================================
    // APPOINTMENT
    // =========================================================
    //
    // Notification từ backend:
    //
    // type = "appointment"
    //
    // Ví dụ:
    // "Đặt lịch thành công"
    //
    // "Bạn đã đặt lịch tư vấn ngày 25/09/2026 10:00.
    //  Lịch đang chờ luật sư xác nhận."
    // =========================================================

      case 'appointment':
        return const ClientNotificationStyle(
          icon: Icons.event_available_outlined,
          iconColor: Color(0xFFE58A12),
          backgroundColor: Color(0xFFFFF2DF),
        );

    // =========================================================
    // MESSAGE
    // =========================================================

      case 'message':
        return const ClientNotificationStyle(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: Color(0xFF0DA46D),
          backgroundColor: Color(0xFFE6F8F1),
        );

    // =========================================================
    // CALENDAR
    // =========================================================

      case 'calendar':
        return const ClientNotificationStyle(
          icon: Icons.calendar_month_outlined,
          iconColor: Color(0xFFE58A12),
          backgroundColor: Color(0xFFFFF2DF),
        );

    // =========================================================
    // DOCUMENT
    // =========================================================

      case 'document':
        return const ClientNotificationStyle(
          icon: Icons.description_outlined,
          iconColor: Color(0xFF3183DD),
          backgroundColor: Color(0xFFE8F1FF),
        );

    // =========================================================
    // REVIEW
    // =========================================================

      case 'review':
        return const ClientNotificationStyle(
          icon: Icons.star_border_rounded,
          iconColor: Color(0xFF8B5DE8),
          backgroundColor: Color(0xFFF1E9FF),
        );

    // =========================================================
    // PAYMENT
    // =========================================================

      case 'payment':
        return const ClientNotificationStyle(
          icon: Icons.credit_card_outlined,
          iconColor: Color(0xFFFF3D70),
          backgroundColor: Color(0xFFFFE9EF),
        );

    // =========================================================
    // SYSTEM
    // =========================================================

      case 'system':
        return const ClientNotificationStyle(
          icon: Icons.campaign_outlined,
          iconColor: Color(0xFF4087DC),
          backgroundColor: Color(0xFFE7F1FF),
        );

    // =========================================================
    // USER
    // =========================================================

      case 'user':
        return const ClientNotificationStyle(
          icon: Icons.person_add_alt_1_outlined,
          iconColor: Color(0xFF12A974),
          backgroundColor: Color(0xFFE7F8F0),
        );

    // =========================================================
    // THANKS
    // =========================================================

      case 'thanks':
        return const ClientNotificationStyle(
          icon: Icons.favorite_border_rounded,
          iconColor: Color(0xFFFF4F72),
          backgroundColor: Color(0xFFFFE9EF),
        );

    // =========================================================
    // DEFAULT
    // =========================================================

      default:
        return const ClientNotificationStyle(
          icon: Icons.notifications_none_rounded,
          iconColor: clientNotificationNavy,
          backgroundColor: Color(0xFFEAF1F8),
        );
    }
  }
}

// =================================================================
// NOTIFICATION STYLE
// =================================================================

class ClientNotificationStyle {
  const ClientNotificationStyle({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;

  final Color iconColor;

  final Color backgroundColor;
}
