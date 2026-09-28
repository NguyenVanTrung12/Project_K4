import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/models/notification_model.dart';
import 'package:themis_trust_mobile/services/notification_service.dart';


class LawyerNotificationScreen extends StatefulWidget {
  const LawyerNotificationScreen({
    super.key,
  });

  @override
  State<LawyerNotificationScreen> createState() =>
      _LawyerNotificationScreenState();
}

class _LawyerNotificationScreenState
    extends State<LawyerNotificationScreen> {
  // =============================================================
  // SERVICES
  // =============================================================

  final NotificationService _notificationService =
  NotificationService();

  // =============================================================
  // COLORS
  // =============================================================

  static const Color navy = Color(0xFF0D3558);
  static const Color darkNavy = Color(0xFF092E50);
  static const Color gold = Color(0xFFC78A2C);

  static const Color background = Color(0xFFF7F9FC);
  static const Color border = Color(0xFFE2E9F0);
  static const Color muted = Color(0xFF71839A);

  // =============================================================
  // STATE
  // =============================================================

  List<NotificationModel> _notifications = [];

  bool _isLoading = true;
  bool _isMarkingAll = false;

  String? _errorMessage;

  int _selectedTab = 0;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();
    _loadNotifications();
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
      final notifications =
      await _notificationService.getMine();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      debugPrint(
        'Load lawyer notifications error: $e',
      );
    }
  }

  // =============================================================
  // REFRESH
  // =============================================================

  Future<void> _refreshNotifications() async {
    try {
      final notifications =
      await _notificationService.getMine();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint(
        'Refresh notifications error: $e',
      );
    }
  }

  // =============================================================
  // UNREAD COUNT
  // =============================================================

  int get _unreadCount {
    return _notifications
        .where((notification) => !notification.isRead)
        .length;
  }

  // =============================================================
  // FILTER
  // =============================================================

  List<NotificationModel> get _filteredNotifications {
    if (_selectedTab == 1) {
      return _notifications
          .where((notification) => !notification.isRead)
          .toList();
    }

    return _notifications;
  }

  // =============================================================
  // MARK AS READ
  // =============================================================

  Future<void> _markAsRead(
      NotificationModel notification,
      ) async {
    if (notification.isRead) {
      return;
    }

    try {
      await _notificationService.markAsRead(
        notification.id,
      );

      if (!mounted) return;

      // Không tự tạo NotificationModel mới.
      // Tải lại dữ liệu từ API để đảm bảo đúng trạng thái server.
      final notifications =
      await _notificationService.getMine();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      debugPrint(
        'Mark notification as read error: $e',
      );
    }
  }

  // =============================================================
  // MARK ALL AS READ
  // =============================================================

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0 || _isMarkingAll) {
      return;
    }

    setState(() {
      _isMarkingAll = true;
    });

    try {
      await _notificationService.markAllAsRead();

      final notifications =
      await _notificationService.getMine();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isMarkingAll = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã đánh dấu tất cả thông báo là đã đọc',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isMarkingAll = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể đánh dấu tất cả thông báo',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      debugPrint(
        'Mark all notifications as read error: $e',
      );
    }
  }

  // =============================================================
  // CLICK NOTIFICATION
  // =============================================================

  Future<void> _onNotificationTap(
      NotificationModel notification,
      ) async {
    await _markAsRead(notification);

    if (!mounted) return;

    // ===========================================================
    // Nếu sau này cần điều hướng theo refId/type,
    // có thể xử lý tại đây.
    //
    // Ví dụ:
    //
    // if (notification.type == 'message') {
    //   ...
    // }
    //
    // if (notification.refId != null) {
    //   ...
    // }
    // ===========================================================
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unreadCount;

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        // leading: IconButton(
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        //   icon: const Icon(
        //     Icons.arrow_back_ios_new_rounded,
        //     color: navy,
        //     size: 20,
        //   ),
        // ),

        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: navy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: false,

        actions: [
          if (unreadCount > 0)
            _isMarkingAll
                ? const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Center(
                child: SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: gold,
                  ),
                ),
              ),
            )
                : TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  color: gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),

      body: RefreshIndicator(
        color: navy,
        onRefresh: _refreshNotifications,

        child: Column(
          children: [
            // =====================================================
            // HEADER SUMMARY
            // =====================================================

            // _buildHeaderSummary(unreadCount),

            // =====================================================
            // TABS
            // =====================================================

            _buildTabs(unreadCount),

            const SizedBox(height: 4),

            // =====================================================
            // CONTENT
            // =====================================================

            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // HEADER SUMMARY
  // =============================================================

  // Widget _buildHeaderSummary(int unreadCount) {
  //   return Container(
  //     width: double.infinity,
  //     margin: const EdgeInsets.fromLTRB(
  //       14,
  //       10,
  //       14,
  //       8,
  //     ),
  //
  //     padding: const EdgeInsets.all(16),
  //
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           darkNavy,
  //           navy,
  //         ],
  //       ),
  //
  //       borderRadius: BorderRadius.circular(16),
  //
  //       boxShadow: [
  //         BoxShadow(
  //           color: navy.withOpacity(0.14),
  //           blurRadius: 12,
  //           offset: const Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //
  //     child: Row(
  //       children: [
  //         // ICON
  //         Container(
  //           width: 48,
  //           height: 48,
  //
  //           decoration: BoxDecoration(
  //             color: Colors.white.withOpacity(0.12),
  //             shape: BoxShape.circle,
  //           ),
  //
  //           child: const Icon(
  //             Icons.notifications_none_rounded,
  //             color: Colors.white,
  //             size: 27,
  //           ),
  //         ),
  //
  //         const SizedBox(width: 13),
  //
  //         // TEXT
  //         // Expanded(
  //         //   child: Column(
  //         //     crossAxisAlignment:
  //         //     CrossAxisAlignment.start,
  //         //
  //         //     children: [
  //         //       const Text(
  //         //         'Thông báo của bạn',
  //         //         style: TextStyle(
  //         //           color: Colors.white,
  //         //           fontSize: 16,
  //         //           fontWeight: FontWeight.w700,
  //         //         ),
  //         //       ),
  //         //
  //         //       const SizedBox(height: 4),
  //         //
  //         //       Text(
  //         //         unreadCount > 0
  //         //             ? 'Bạn có $unreadCount thông báo chưa đọc'
  //         //             : 'Bạn đã đọc tất cả thông báo',
  //         //         style: TextStyle(
  //         //           color:
  //         //           Colors.white.withOpacity(0.78),
  //         //           fontSize: 12.5,
  //         //           height: 1.3,
  //         //         ),
  //         //       ),
  //         //     ],
  //         //   ),
  //         // ),
  //
  //         // BADGE
  //         if (unreadCount > 0)
  //           Container(
  //             constraints: const BoxConstraints(
  //               minWidth: 32,
  //               minHeight: 32,
  //             ),
  //
  //             padding:
  //             const EdgeInsets.symmetric(
  //               horizontal: 8,
  //             ),
  //
  //             decoration: BoxDecoration(
  //               color: gold,
  //               borderRadius:
  //               BorderRadius.circular(16),
  //             ),
  //
  //             alignment: Alignment.center,
  //
  //             child: Text(
  //               unreadCount > 99
  //                   ? '99+'
  //                   : unreadCount.toString(),
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 12,
  //                 fontWeight: FontWeight.w700,
  //               ),
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  // =============================================================
  // TABS
  // =============================================================

  Widget _buildTabs(int unreadCount) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 14,
      ),

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: border,
        ),
      ),

      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              index: 0,
              title: 'Tất cả',
              count: _notifications.length,
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _buildTab(
              index: 1,
              title: 'Chưa đọc',
              count: unreadCount,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TAB ITEM
  // =============================================================

  Widget _buildTab({
    required int index,
    required String title,
    required int count,
  }) {
    final selected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },

      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),

        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 8,
        ),

        decoration: BoxDecoration(
          color: selected
              ? navy
              : Colors.transparent,

          borderRadius: BorderRadius.circular(9),
        ),

        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : muted,
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),

            if (count > 0) ...[
              const SizedBox(width: 6),

              Container(
                constraints:
                const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 5,
                ),

                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      .withOpacity(0.18)
                      : const Color(0xFFEAF0F6),

                  borderRadius:
                  BorderRadius.circular(10),
                ),

                alignment: Alignment.center,

                child: Text(
                  count > 99
                      ? '99+'
                      : count.toString(),
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =============================================================
  // CONTENT
  // =============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: navy,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final notifications =
        _filteredNotifications;

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics:
      const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        14,
        8,
        14,
        24,
      ),

      itemCount: notifications.length,

      itemBuilder: (context, index) {
        final notification =
        notifications[index];

        return _buildNotificationCard(
          notification,
        );
      },
    );
  }

  // =============================================================
  // NOTIFICATION CARD
  // =============================================================

  Widget _buildNotificationCard(
      NotificationModel notification,
      ) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: () {
        _onNotificationTap(notification);
      },

      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),

        margin: const EdgeInsets.only(
          bottom: 10,
        ),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: isUnread
              ? const Color(0xFFF4F8FC)
              : Colors.white,

          borderRadius:
          BorderRadius.circular(15),

          border: Border.all(
            color: isUnread
                ? const Color(0xFFD3E0EC)
                : border,
          ),

          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(
                isUnread ? 0.055 : 0.025,
              ),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            // ===================================================
            // ICON
            // ===================================================

            _buildNotificationIcon(
              notification.type,
            ),

            const SizedBox(width: 12),

            // ===================================================
            // CONTENT
            // ===================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,

                          style: TextStyle(
                            color: navy,
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),

                      if (isUnread)
                        Container(
                          margin:
                          const EdgeInsets.only(
                            left: 8,
                            top: 4,
                          ),

                          width: 8,
                          height: 8,

                          decoration:
                          const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  if (notification.body !=
                      null &&
                      notification.body!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Text(
                      notification.body!,
                      maxLines: 3,
                      overflow:
                      TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: muted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: muted
                            .withOpacity(0.75),
                        size: 14,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        _formatNotificationTime(
                          notification.createdAt,
                        ),
                        style: TextStyle(
                          color: muted
                              .withOpacity(0.85),
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // NOTIFICATION ICON
  // =============================================================

  Widget _buildNotificationIcon(
      String type,
      ) {
    final normalized =
    type.trim().toLowerCase();

    IconData icon;
    Color iconColor;
    Color backgroundColor;

    switch (normalized) {
      case 'message':
      case 'messages':
      case 'chat':
        icon =
            Icons.chat_bubble_outline_rounded;
        iconColor = const Color(0xFF1769AA);
        backgroundColor =
        const Color(0xFFEAF4FF);
        break;

      case 'appointment':
      case 'appointments':
      case 'consultation':
        icon =
            Icons.calendar_month_outlined;
        iconColor = const Color(0xFF8B641D);
        backgroundColor =
        const Color(0xFFFFF5E4);
        break;

      case 'review':
      case 'reviews':
        icon =
            Icons.star_border_rounded;
        iconColor = const Color(0xFFB47A16);
        backgroundColor =
        const Color(0xFFFFF5DD);
        break;

      case 'case':
      case 'cases':
        icon =
            Icons.folder_open_outlined;
        iconColor = const Color(0xFF68529A);
        backgroundColor =
        const Color(0xFFF1EDFC);
        break;

      case 'system':
        icon =
            Icons.info_outline_rounded;
        iconColor = const Color(0xFF27738C);
        backgroundColor =
        const Color(0xFFE9F7FA);
        break;

      default:
        icon =
            Icons.notifications_none_rounded;
        iconColor = navy;
        backgroundColor =
        const Color(0xFFEAF0F6);
    }

    return Container(
      width: 44,
      height: 44,

      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),

      child: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
    );
  }

  // =============================================================
  // EMPTY STATE
  // =============================================================

  Widget _buildEmptyState() {
    final isUnreadTab = _selectedTab == 1;

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),

      children: [
        const SizedBox(height: 80),

        Container(
          width: 76,
          height: 76,

          decoration: const BoxDecoration(
            color: Color(0xFFEAF0F6),
            shape: BoxShape.circle,
          ),

          child: const Icon(
            Icons.notifications_none_rounded,
            color: navy,
            size: 38,
          ),
        ),

        const SizedBox(height: 18),

        Text(
          isUnreadTab
              ? 'Không có thông báo chưa đọc'
              : 'Chưa có thông báo',
          textAlign: TextAlign.center,

          style: const TextStyle(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          isUnreadTab
              ? 'Bạn đã đọc tất cả thông báo.'
              : 'Các thông báo mới sẽ xuất hiện tại đây.',
          textAlign: TextAlign.center,

          style: const TextStyle(
            color: muted,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // =============================================================
  // ERROR STATE
  // =============================================================

  Widget _buildErrorState() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),

      children: [
        const SizedBox(height: 70),

        const Icon(
          Icons.error_outline_rounded,
          color: Colors.redAccent,
          size: 48,
        ),

        const SizedBox(height: 14),

        const Text(
          'Không thể tải thông báo',
          textAlign: TextAlign.center,

          style: TextStyle(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          'Đã xảy ra lỗi khi kết nối với máy chủ.',
          textAlign: TextAlign.center,

          style: TextStyle(
            color: muted,
            fontSize: 12.5,
          ),
        ),

        const SizedBox(height: 15),

        Center(
          child: ElevatedButton(
            onPressed: _loadNotifications,

            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,

              elevation: 0,

              padding:
              const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 11,
              ),

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(10),
              ),
            ),

            child: const Text(
              'Thử lại',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // TIME FORMAT
  // =============================================================

  String _formatNotificationTime(
      DateTime dateTime,
      ) {
    final now = DateTime.now();
    final difference =
    now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    }

    if (difference.inDays == 1) {
      return 'Hôm qua ${_formatTime(dateTime)}';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour =
    dateTime.hour.toString().padLeft(2, '0');

    final minute =
    dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}