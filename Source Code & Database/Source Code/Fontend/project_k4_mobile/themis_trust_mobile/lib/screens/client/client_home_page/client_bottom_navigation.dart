import 'dart:async';

import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/services/notification_service.dart';


class ClientHomeBottomNavigationWidget extends StatefulWidget {
  const ClientHomeBottomNavigationWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,

    // Số tin nhắn chưa đọc truyền từ màn hình cha
    this.unreadMessageCount = 0,
  });

  // ================================================================
  // PROPERTIES
  // ================================================================

  final int selectedIndex;

  final ValueChanged<int> onItemSelected;

  /// Số tin nhắn chưa đọc
  final int unreadMessageCount;

  @override
  State<ClientHomeBottomNavigationWidget> createState() =>
      _ClientHomeBottomNavigationWidgetState();
}

class _ClientHomeBottomNavigationWidgetState
    extends State<ClientHomeBottomNavigationWidget> {

  // ================================================================
  // SERVICES
  // ================================================================

  final NotificationService _notificationService =
  NotificationService();

  // ================================================================
  // UNREAD COUNTS
  // ================================================================

  int _unreadNotificationCount = 0;

  int _unreadMessageCount = 0;

  Timer? _refreshTimer;

  // ================================================================
  // INIT
  // ================================================================

  @override
  void initState() {
    super.initState();

    _unreadMessageCount = widget.unreadMessageCount;

    _loadUnreadNotificationCount();

    // Kiểm tra lại mỗi 10 giây.
    //
    // Như vậy nếu server có notification mới,
    // badge sẽ tự cập nhật.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) {
        _loadUnreadNotificationCount();
      },
    );
  }

  // ================================================================
  // UPDATE PROPERTIES
  // ================================================================

  @override
  void didUpdateWidget(
      covariant ClientHomeBottomNavigationWidget oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.unreadMessageCount !=
        widget.unreadMessageCount) {
      setState(() {
        _unreadMessageCount =
            widget.unreadMessageCount;
      });
    }
  }

  // ================================================================
  // LOAD UNREAD NOTIFICATIONS
  // ================================================================

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count =
      await _notificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _unreadNotificationCount = count;
      });
    } catch (e) {
      debugPrint(
        'Lỗi lấy số thông báo chưa đọc: $e',
      );
    }
  }

  // ================================================================
  // CLICK ITEM
  // ================================================================

  Future<void> _handleItemSelected(int index) async {

    // ============================================================
    // THÔNG BÁO
    // ============================================================

    if (index == 3) {

      // Xóa badge ngay lập tức
      setState(() {
        _unreadNotificationCount = 0;
      });

      // Đánh dấu toàn bộ notification đã đọc
      try {
        await _notificationService.markAllAsRead();
      } catch (e) {
        debugPrint(
          'Lỗi đánh dấu thông báo đã đọc: $e',
        );
      }
    }

    // ============================================================
    // TIN NHẮN
    // ============================================================

    if (index == 2) {

      // Xóa badge ngay lập tức
      setState(() {
        _unreadMessageCount = 0;
      });

      // Phần mark message đã đọc
      // sẽ xử lý ở màn hình Tin nhắn/API tin nhắn.
    }

    // ============================================================
    // GỌI CALLBACK CHUYỂN TRANG
    // ============================================================

    widget.onItemSelected(index);
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,

      child: Container(
        height: 68,

        decoration: const BoxDecoration(
          color: Colors.white,

          border: Border(
            top: BorderSide(
              color: Color(0xFFE5ECF3),
              width: 1,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),

        child: Row(
          children: List.generate(
            _items.length,
                (index) {

              final item = _items[index];

              final bool isSelected =
                  widget.selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,

                  onTap: () {
                    _handleItemSelected(index);
                  },

                  child: Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,

                      children: [

                        // =================================================
                        // ICON + BADGE
                        // =================================================

                        Stack(
                          clipBehavior: Clip.none,

                          children: [

                            Icon(
                              isSelected
                                  ? item.activeIcon
                                  : item.icon,

                              size: 22,

                              color: isSelected
                                  ? const Color(0xFFC79132)
                                  : const Color(0xFF8295A8),
                            ),

                            // =================================================
                            // BADGE THÔNG BÁO
                            // =================================================

                            if (index == 3 &&
                                _unreadNotificationCount > 0)
                              _buildBadge(
                                _unreadNotificationCount,
                              ),

                            // =================================================
                            // BADGE TIN NHẮN
                            // =================================================

                            if (index == 2 &&
                                _unreadMessageCount > 0)
                              _buildBadge(
                                _unreadMessageCount,
                              ),
                          ],
                        ),

                        const SizedBox(height: 3),

                        // =================================================
                        // TITLE
                        // =================================================

                        Text(
                          item.title,

                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFC79132)
                                : const Color(0xFF8295A8),

                            fontSize: 10,

                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 3),

                        // =================================================
                        // UNDERLINE
                        // =================================================

                        AnimatedContainer(
                          duration:
                          const Duration(
                            milliseconds: 200,
                          ),

                          width:
                          isSelected ? 28 : 0,

                          height: 2,

                          decoration:
                          BoxDecoration(
                            color:
                            const Color(0xFFC79132),

                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================================================================
  // BADGE
  // ================================================================

  Widget _buildBadge(int count) {

    final displayCount =
    count > 99 ? '99+' : count.toString();

    return Positioned(
      right: -10,
      top: -8,

      child: Container(
        constraints: const BoxConstraints(
          minWidth: 17,
          minHeight: 17,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 1,
        ),

        decoration: BoxDecoration(
          color: const Color(0xFFE53935),

          shape: BoxShape.rectangle,

          borderRadius:
          BorderRadius.circular(20),

          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
        ),

        alignment: Alignment.center,

        child: Text(
          displayCount,

          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// NAVIGATION ITEMS
// ==================================================================

class _BottomNavigationItem {
  const _BottomNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
  });

  final IconData icon;
  final IconData activeIcon;
  final String title;
}

// ==================================================================
// ITEMS
// ==================================================================

const List<_BottomNavigationItem> _items = [
  _BottomNavigationItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    title: 'Trang chủ',
  ),

  _BottomNavigationItem(
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_rounded,
    title: 'Luật sư',
  ),

  _BottomNavigationItem(
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
    title: 'Tin nhắn',
  ),

  _BottomNavigationItem(
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications,
    title: 'Thông báo',
  ),

  _BottomNavigationItem(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    title: 'Tài khoản',
  ),
];