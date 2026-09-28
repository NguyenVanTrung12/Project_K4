import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/services/message_service.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_message_page/lawyer_chat_screen.dart';

class LawyerMessagesScreen extends StatefulWidget {
  const LawyerMessagesScreen({super.key});

  @override
  State<LawyerMessagesScreen> createState() => _LawyerMessagesScreenState();
}

class _LawyerMessagesScreenState extends State<LawyerMessagesScreen> {
  // =============================================================
  // COLORS
  // =============================================================

  static const Color _navy = Color(0xFF123963);

  static const Color _darkNavy = Color(0xFF0D2E52);

  static const Color _gold = Color(0xFFC68A2B);

  static const Color _lightGold = Color(0xFFFFF5E5);

  static const Color _text = Color(0xFF173A63);

  static const Color _muted = Color(0xFF7B91AA);

  static const Color _border = Color(0xFFE3EAF2);

  static const Color _background = Color(0xFFF8FAFD);

  // =============================================================
  // SERVICES
  // =============================================================

  final MessageService _messageService = MessageService();

  // =============================================================
  // STATE
  // =============================================================

  int _selectedTab = 0;

  final TextEditingController _searchController = TextEditingController();

  List<ConversationModel> _conversations = [];

  // Số tin chưa đọc của từng conversation
  final Map<String, int> _unreadCounts = {};

  bool _isLoading = true;

  String? _errorMessage;

  String? _lawyerId;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  // =============================================================
  // LOAD DATA
  // =============================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // ---------------------------------------------------------
      // Lấy lawyerId hiện tại
      // ---------------------------------------------------------

      final prefs = await SharedPreferences.getInstance();

      final lawyerId = prefs.getString('userId');

      _lawyerId = lawyerId;

      // ---------------------------------------------------------
      // Gọi API lấy danh sách conversation
      // ---------------------------------------------------------

      final conversations = await _messageService.getConversations();

      // ---------------------------------------------------------
      // Đếm unread
      // ---------------------------------------------------------

      final Map<String, int> unreadCounts = {};

      for (final conversation in conversations) {
        try {
          final messages = await _messageService.getByConversation(
            conversation.id,
          );

          int unreadCount = 0;

          for (final message in messages) {
            final senderId = message.senderId.toString();

            final readAt = message.readAt;

            // ---------------------------------------------------
            // Tin chưa đọc:
            //
            // 1. ReadAt == null
            // 2. Người gửi không phải lawyer hiện tại
            //
            // Không hiển thị ai gửi cuối.
            // Chỉ dùng SenderId để tính unread.
            // ---------------------------------------------------

            if (readAt == null && senderId != lawyerId) {
              unreadCount++;
            }
          }

          unreadCounts[conversation.id] = unreadCount;
        } catch (e) {
          debugPrint(
            'Không thể đếm unread conversation '
                '${conversation.id}: $e',
          );

          unreadCounts[conversation.id] = 0;
        }
      }

      if (!mounted) return;

      setState(() {
        _conversations = conversations;

        _unreadCounts.clear();
        _unreadCounts.addAll(unreadCounts);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });

      debugPrint('Load lawyer conversations error: $e');
    }
  }

  // =============================================================
  // REFRESH
  // =============================================================

  Future<void> _refresh() async {
    await _loadData();
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      body: SafeArea(
        top: true,
        bottom: false,

        child: Column(
          children: [
            // ===================================================
            // HEADER
            // ===================================================

            _buildHeader(),

            Expanded(
              child: Column(
                children: [
                  // =================================================
                  // SEARCH
                  // =================================================

                  _buildSearchBox(),

                  // =================================================
                  // TABS
                  // =================================================
                  _buildMessageTabs(),

                  // =================================================
                  // LIST
                  // =================================================
                  Expanded(child: _buildMessageList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // HEADER
  // =============================================================

  Widget _buildHeader() {
    final unreadTotal = _getTotalUnreadCount();

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),

      decoration: const BoxDecoration(
        color: Colors.white,

        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF3), width: 1)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // =====================================================
          // TITLE
          // =====================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: const [
                Text(
                  'Tin nhắn',

                  style: TextStyle(
                    color: _darkNavy,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),

                SizedBox(height: 7),

                Text(
                  'Trao đổi dễ dàng, hỗ trợ khách hàng nhanh chóng',

                  style: TextStyle(
                    color: Color(0xFF667F9B),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // =====================================================
          // TOTAL UNREAD
          // =====================================================
          // if (unreadTotal > 0)
          //   Container(
          //     constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          //
          //     padding: const EdgeInsets.symmetric(horizontal: 8),
          //
          //     alignment: Alignment.center,
          //
          //     decoration: const BoxDecoration(
          //       color: Color(0xFFE52D35),
          //       shape: BoxShape.circle,
          //     ),
          //
          //     child: Text(
          //       unreadTotal > 99 ? '99+' : unreadTotal.toString(),
          //
          //       style: const TextStyle(
          //         color: Colors.white,
          //         fontSize: 10,
          //         fontWeight: FontWeight.w700,
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  // =============================================================
  // SEARCH BOX
  // =============================================================

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 8),

      child: Container(
        height: 52,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: const Color(0xFFDCE5EF)),
        ),

        child: TextField(
          controller: _searchController,

          onChanged: (_) {
            setState(() {});
          },

          style: const TextStyle(color: _text, fontSize: 13),

          decoration: const InputDecoration(
            border: InputBorder.none,

            prefixIcon: Icon(Icons.search_rounded, color: _navy, size: 23),

            hintText: 'Tìm kiếm khách hàng...',

            hintStyle: TextStyle(color: Color(0xFF94A7BA), fontSize: 13),

            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // TABS
  // =============================================================

  Widget _buildMessageTabs() {
    final unreadTotal = _getTotalUnreadCount();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),

      child: Row(
        children: [
          // =====================================================
          // TẤT CẢ
          // =====================================================

          Expanded(child: _buildMessageTab(title: 'Tất cả', index: 0)),

          // =====================================================
          // CHƯA ĐỌC
          // =====================================================
          Expanded(
            child: _buildMessageTab(
              title: 'Chưa đọc',
              index: 1,
              unreadCount: unreadTotal,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TAB ITEM
  // =============================================================

  Widget _buildMessageTab({
    required String title,
    required int index,
    int unreadCount = 0,
  }) {
    final selected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },

      child: SizedBox(
        height: 45,

        child: Stack(
          clipBehavior: Clip.none,

          alignment: Alignment.center,

          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),

              decoration: BoxDecoration(
                color: selected ? _lightGold : Colors.transparent,

                borderRadius: BorderRadius.circular(16),
              ),

              alignment: Alignment.center,

              child: Text(
                title,

                style: TextStyle(
                  color: selected ? _gold : _text,

                  fontSize: 13,

                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),

            // ===================================================
            // UNREAD BADGE
            // ===================================================
            if (index == 1 && unreadCount > 0)
              Positioned(
                top: 0,
                right: 20,

                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 21,
                    minHeight: 21,
                  ),

                  padding: const EdgeInsets.symmetric(horizontal: 5),

                  alignment: Alignment.center,

                  decoration: const BoxDecoration(
                    color: Color(0xFFE52D35),
                    shape: BoxShape.circle,
                  ),

                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // MESSAGE LIST
  // =============================================================

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _navy));
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final conversations = _getFilteredConversations();

    if (conversations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _navy,

      onRefresh: _refresh,

      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),

        physics: const AlwaysScrollableScrollPhysics(),

        itemCount: conversations.length,

        separatorBuilder: (_, __) {
          return const SizedBox(height: 3);
        },

        itemBuilder: (context, index) {
          final conversation = conversations[index];

          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  // =============================================================
  // FILTER CONVERSATIONS
  // =============================================================

  List<ConversationModel> _getFilteredConversations() {
    final keyword = _searchController.text.trim().toLowerCase();

    final result = _conversations.where((conversation) {
      // =======================================================
      // SEARCH
      // =======================================================

      if (keyword.isNotEmpty) {
        final name = conversation.clientName.toLowerCase();

        final preview = (conversation.lastMessagePreview ?? '').toLowerCase();

        if (!name.contains(keyword) && !preview.contains(keyword)) {
          return false;
        }
      }

      // =======================================================
      // CHƯA ĐỌC
      // =======================================================

      if (_selectedTab == 1) {
        final unread = _unreadCounts[conversation.id] ?? 0;

        return unread > 0;
      }

      // =======================================================
      // TẤT CẢ
      // =======================================================

      return true;
    }).toList();

    // ===========================================================
    // SẮP XẾP THEO THỜI GIAN TIN NHẮN CUỐI
    // ===========================================================

    result.sort((a, b) {
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

    return result;
  }

  // =============================================================
  // CONVERSATION TILE
  // =============================================================

  Widget _buildConversationTile(ConversationModel conversation) {
    final unreadCount = _unreadCounts[conversation.id] ?? 0;

    final bool hasUnread = unreadCount > 0;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () {
          _openConversation(conversation);
        },

        borderRadius: BorderRadius.circular(17),

        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),

          decoration: BoxDecoration(
            color: hasUnread ? const Color(0xFFFFF9EF) : Colors.white,

            borderRadius: BorderRadius.circular(17),

            border: Border.all(
              color: hasUnread ? const Color(0xFFF1D8AD) : _border,
            ),
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              // =================================================
              // AVATAR
              // =================================================

              _buildAvatar(conversation.clientName ?? 'Khách hàng'),
              const SizedBox(width: 12),

              // =================================================
              // CONTENT
              // =================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // =============================================
                    // NAME + TIME
                    // =============================================

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.clientName,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: _text,

                              fontSize: 14,

                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          _formatMessageTime(conversation.lastMessageAt),

                          style: TextStyle(
                            color: hasUnread ? _navy : _muted,

                            fontSize: 10,

                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // =============================================
                    // LAST MESSAGE + UNREAD
                    // =============================================
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (conversation.lastMessagePreview ?? '').isEmpty
                                ? 'Chưa có tin nhắn'
                                : conversation.lastMessagePreview!,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: hasUnread
                                  ? const Color(0xFF526E8A)
                                  : const Color(0xFF8094A9),

                              fontSize: 12,

                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),

                        // =========================================
                        // UNREAD COUNT
                        // =========================================
                        if (hasUnread) ...[
                          const SizedBox(width: 8),

                          _buildUnreadBadge(unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // AVATAR
  // =============================================================

  Widget _buildAvatar(String name) {
    final trimmed = name.trim();

    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();

    return Container(
      width: 58,
      height: 58,

      decoration: const BoxDecoration(
        color: Color(0xFFE8EEF4),
        shape: BoxShape.circle,
      ),

      alignment: Alignment.center,

      child: Text(
        initial,

        style: const TextStyle(
          color: _navy,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // =============================================================
  // UNREAD BADGE
  // =============================================================

  Widget _buildUnreadBadge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 25, minHeight: 25),

      padding: const EdgeInsets.symmetric(horizontal: 6),

      alignment: Alignment.center,

      decoration: const BoxDecoration(
        color: Color(0xFFE52D35),
        shape: BoxShape.circle,
      ),

      child: Text(
        count > 99 ? '99+' : count.toString(),

        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // =============================================================
  // FORMAT TIME
  // =============================================================

  String _formatMessageTime(DateTime? date) {
    if (date == null) {
      return '';
    }

    final now = DateTime.now();

    // ===========================================================
    // HÔM NAY
    // ===========================================================

    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      final hour = date.hour.toString().padLeft(2, '0');

      final minute = date.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    }

    // ===========================================================
    // HÔM QUA
    // ===========================================================

    final yesterday = now.subtract(const Duration(days: 1));

    final isYesterday =
        date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day;

    if (isYesterday) {
      return 'Hôm qua';
    }

    // ===========================================================
    // CÙNG NĂM
    // ===========================================================

    if (date.year == now.year) {
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}';
    }

    // ===========================================================
    // KHÁC NĂM
    // ===========================================================

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // =============================================================
  // TOTAL UNREAD
  // =============================================================

  int _getTotalUnreadCount() {
    int total = 0;

    for (final count in _unreadCounts.values) {
      total += count;
    }

    return total;
  }

  // =============================================================
  // OPEN CONVERSATION
  // =============================================================

  Future<void> _openConversation(ConversationModel conversation) async {
    try {
      // =========================================================
      // ĐÁNH DẤU ĐÃ ĐỌC TRÊN SERVER
      // =========================================================

      await _messageService.markConversationAsRead(conversation.id);

      // =========================================================
      // CẬP NHẬT UI NGAY LẬP TỨC
      // =========================================================

      if (mounted) {
        setState(() {
          _unreadCounts[conversation.id] = 0;
        });
      }

      // =========================================================
      // MỞ MÀN CHAT
      // =========================================================

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LawyerChatScreen(
            client: LawyerChatClientData(
              id: conversation.clientId,
              name: conversation.clientName,
              avatarUrl: '',
            ),
            conversationId: conversation.id,
          ),
        ),
      );

      // =========================================================
      // SAU KHI QUAY LẠI
      //
      // Lấy lại dữ liệu từ server để đồng bộ.
      // =========================================================

      if (!mounted) return;

      await _loadData();
    } catch (e) {
      debugPrint('Mark conversation as read error: $e');

      // Nếu API mark read lỗi thì vẫn cho phép
      // lawyer mở cuộc trò chuyện bình thường.

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LawyerChatScreen(
            client: LawyerChatClientData(
              id: conversation.clientId,
              name: conversation.clientName,
              avatarUrl: '',
            ),
            conversationId: conversation.id,
          ),
        ),
      );

      if (!mounted) return;

      await _loadData();
    }
  }

  // =============================================================
  // EMPTY STATE
  // =============================================================

  Widget _buildEmptyState() {
    final text = _selectedTab == 1
        ? 'Không có tin nhắn chưa đọc'
        : 'Chưa có cuộc trò chuyện';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 75,
              height: 75,

              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FC),
                shape: BoxShape.circle,
              ),

              child: const Icon(Icons.forum_outlined, color: _navy, size: 36),
            ),

            const SizedBox(height: 15),

            Text(
              text,

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Các cuộc trò chuyện với khách hàng sẽ hiển thị tại đây.',

              textAlign: TextAlign.center,

              style: TextStyle(color: _muted, fontSize: 12),
            ),
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
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration: const BoxDecoration(
                color: Color(0xFFFFEEEE),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFE05252),
                size: 36,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              _errorMessage ?? 'Không thể tải danh sách tin nhắn',

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: _text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: _loadData,

              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,

                foregroundColor: Colors.white,

                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
