import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/models/message_model.dart';
import 'package:themis_trust_mobile/screens/client/client_login_page/client_login_screen.dart';
import 'package:themis_trust_mobile/screens/client/client_message_page/client_chat_screen.dart';
import 'package:themis_trust_mobile/services/conversation_service.dart';
import 'package:themis_trust_mobile/services/lawyer_service.dart';
import 'package:themis_trust_mobile/services/message_service.dart';
import 'package:themis_trust_mobile/services/auth_navigation_service.dart';


class ClientMessagesScreen extends StatefulWidget {
  const ClientMessagesScreen({super.key});

  @override
  State<ClientMessagesScreen> createState() => ClientMessagesScreenState();
}

class ClientMessagesScreenState extends State<ClientMessagesScreen> {
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

  // Chưa đọc
  static const Color _unreadBackground = Color(0xFFFFF7EA);
  static const Color _unreadBorder = Color(0xFFF1D8AD);

  // Đã đọc
  static const Color _readBackground = Color(0xFFF4F9FD);
  static const Color _readBorder = Color(0xFFE1EAF3);

  // =============================================================
  // SERVICES
  // =============================================================
  final LawyerService _lawyerService = LawyerService();
  final ConversationService _conversationService = ConversationService();

  final MessageService _messageService = MessageService();

  // =============================================================
  // STATE
  // =============================================================

  int _selectedTab = 0;

  final TextEditingController _searchController = TextEditingController();

  List<ClientMessageItemData> _messages = [];

  bool _isLoading = true;

  String? _errorMessage;

  String? _currentUserId;

  Timer? _messagesRefreshTimer;

  bool _isRefreshingMessages = false;

  // =============================================================
  // DANH SÁCH CONVERSATION ĐÃ ĐỌC
  //
  // Nếu ID nằm trong Set này => đã đọc.
  // Nếu không nằm trong Set => chưa đọc.
  // =============================================================

  final Set<String> _readConversationIds = <String>{};

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _loadMessages();
  }
  void _startMessagesRefresh() {
    _messagesRefreshTimer?.cancel();

    _messagesRefreshTimer = Timer.periodic(
      const Duration(seconds: 2),
          (_) async {
        await _refreshMessagesSilently();
      },
    );
  }
  Future<void> _refreshMessagesSilently() async {
    if (!mounted) return;

    if (_isRefreshingMessages) {
      return;
    }

    _isRefreshingMessages = true;

    try {
      final conversations =
      await _conversationService.getMyConversations();

      if (!mounted) return;

      // Không bật loading
      // Chỉ tải lại dữ liệu nền
      final List<ClientMessageItemData> result = [];

      for (final conversation in conversations) {
        try {
          final messages =
          await _messageService.getByConversation(
            conversation.id,
          );

          MessageModel? latestMessage;

          if (messages.isNotEmpty) {
            final sortedMessages =
            List<MessageModel>.from(messages);

            sortedMessages.sort(
                  (a, b) =>
                  b.sentAt.compareTo(a.sentAt),
            );

            latestMessage = sortedMessages.first;
          }

          String lawyerName = 'Luật sư';
          String lawyerAvatar = '';

          try {
            final lawyer =
            await _lawyerService.getLawyerById(
              conversation.lawyerId,
            );

            lawyerName = lawyer.fullName;
            lawyerAvatar =
                lawyer.avatarUrl ?? '';
          } catch (_) {}

          final bool isRead =
          _readConversationIds.contains(
            conversation.id,
          );

          result.add(
            ClientMessageItemData(
              id: conversation.id,
              conversationId: conversation.id,
              clientId: conversation.clientId,
              lawyerId: conversation.lawyerId,
              name: lawyerName,
              message:
              latestMessage?.content ??
                  (latestMessage?.attachmentUrl != null
                      ? 'Đã gửi tệp đính kèm'
                      : 'Chưa có tin nhắn'),
              time: _formatMessageTime(
                latestMessage?.sentAt ??
                    conversation.lastMessageAt,
              ),
              avatarUrl: lawyerAvatar,
              unreadCount:
              isRead ? 0 : 1,
              isOnline: false,
              isSaved: false,
              latestMessage:
              latestMessage,
              isRead: isRead,
            ),
          );
        } catch (e) {
          debugPrint(
            'BACKGROUND MESSAGE ERROR: $e',
          );
        }
      }

      result.sort((a, b) {
        final dateA =
            a.latestMessage?.sentAt;

        final dateB =
            b.latestMessage?.sentAt;

        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        _messages = result;
      });
    } catch (e) {
      debugPrint(
        'BACKGROUND REFRESH ERROR: $e',
      );
    } finally {
      _isRefreshingMessages = false;
    }
  }
  // =============================================================
  // DISPOSE- loaị bỏ
  // =============================================================

  @override
  void dispose() {
    _messagesRefreshTimer?.cancel();

    _searchController.dispose();

    super.dispose();
  }

  // =============================================================
  // REFRESH KHI CHUYỂN TAB
  // =============================================================

  Future<void> refreshAfterTabChange() async {
    if (!mounted) return;

    await _loadMessages();
  }

  // =============================================================
  // LOAD CURRENT USER ID
  // =============================================================

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('userId');

    final token = prefs.getString('token');

    debugPrint('====================================');
    debugPrint('MESSAGE SESSION');
    debugPrint('USER ID: $userId');
    debugPrint(
      'TOKEN: ${token != null && token.isNotEmpty ? "CÓ TOKEN" : "KHÔNG CÓ TOKEN"}',
    );
    debugPrint('====================================');

    if (userId == null || userId.trim().isEmpty) {
      return null;
    }

    return userId.trim();
  }

  // =============================================================
  // LOAD MESSAGES
  // =============================================================

  Future<void> _loadMessages() async {
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
      debugPrint('LOAD CLIENT MESSAGES');
      debugPrint('USER ID: $userId');
      debugPrint(
        'TOKEN: ${token != null && token.isNotEmpty ? "CÓ TOKEN" : "KHÔNG CÓ TOKEN"}',
      );
      debugPrint('====================================');

      // ============================================================
      // CHƯA ĐĂNG NHẬP
      // ============================================================

      if (userId == null || userId.trim().isEmpty) {
        debugPrint('MESSAGES: Chưa đăng nhập');

        if (!mounted) return;

        setState(() {
          _currentUserId = null;
          _messages = [];
          _isLoading = false;
        });

        return;
      }

      // ============================================================
      // KHÔNG CÓ TOKEN
      // ============================================================

      if (token == null || token.isEmpty) {
        debugPrint('MESSAGES: Có userId nhưng không có token');

        if (!mounted) return;

        setState(() {
          _currentUserId = null;
          _messages = [];
          _isLoading = false;
          _errorMessage =
          'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại';
        });

        return;
      }

      // ============================================================
      // ĐÃ ĐĂNG NHẬP
      // ============================================================

      final currentUserId = userId.trim();

      _currentUserId = currentUserId;

      debugPrint('MESSAGES: Đang lấy conversation của $currentUserId');

      // ============================================================
      // LẤY CONVERSATION
      // ============================================================

      final conversations = await _conversationService.getMyConversations();

      debugPrint('MESSAGES: Có ${conversations.length} conversations');

      // ============================================================
      // LẤY MESSAGE
      // ============================================================

      final List<ClientMessageItemData> result = [];

      for (final conversation in conversations) {
        try {
          final messages = await _messageService.getByConversation(
            conversation.id,
          );

          MessageModel? latestMessage;

          if (messages.isNotEmpty) {
            final sortedMessages = List<MessageModel>.from(messages);

            sortedMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

            latestMessage = sortedMessages.first;
          }

          // ========================================================
          // KIỂM TRA ĐÃ ĐỌC
          // ========================================================

          final bool isRead = _readConversationIds.contains(conversation.id);

          // ========================================================
          // LẤY TÊN LUẬT SƯ
          // ========================================================

          String lawyerName = 'Luật sư';
          String lawyerAvatar = '';

          try {
            final lawyer = await _lawyerService.getLawyerById(
              conversation.lawyerId,
            );

            lawyerName = lawyer.fullName;

            lawyerAvatar = lawyer.avatarUrl ?? '';
          } catch (e) {
            debugPrint(
              'GET LAWYER NAME ERROR '
                  '${conversation.lawyerId}: $e',
            );
          }

          result.add(
            ClientMessageItemData(
              id: conversation.id,
              conversationId: conversation.id,
              clientId: conversation.clientId,
              lawyerId: conversation.lawyerId,

              // HIỂN THỊ TÊN THẬT
              name: lawyerName,

              message:
              latestMessage?.content ??
                  (latestMessage?.attachmentUrl != null
                      ? 'Đã gửi tệp đính kèm'
                      : 'Chưa có tin nhắn'),

              time: _formatMessageTime(
                latestMessage?.sentAt ?? conversation.lastMessageAt,
              ),

              avatarUrl: lawyerAvatar,

              unreadCount: isRead ? 0 : 1,

              isOnline: false,
              isSaved: false,

              latestMessage: latestMessage,

              isRead: isRead,
            ),
          );
        } catch (messageError) {
          debugPrint('LOAD MESSAGE ERROR ${conversation.id}: $messageError');

          final bool isRead = _readConversationIds.contains(conversation.id);

          result.add(
            ClientMessageItemData(
              id: conversation.id,
              conversationId: conversation.id,
              clientId: conversation.clientId,
              lawyerId: conversation.lawyerId,
              name: conversation.lawyerName,
              message: 'Không thể tải tin nhắn',
              time: _formatMessageTime(conversation.lastMessageAt),
              avatarUrl: '',
              unreadCount: isRead ? 0 : 1,
              isOnline: false,
              isSaved: false,
              latestMessage: null,
              isRead: isRead,
            ),
          );
        }
      }

      // ============================================================
      // SORT
      // ============================================================

      result.sort((a, b) {
        final dateA = a.latestMessage?.sentAt;
        final dateB = b.latestMessage?.sentAt;

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

      if (!mounted) return;

      setState(() {
        _currentUserId = currentUserId;
        _messages = result;
        _isLoading = false;
        _errorMessage = null;
      });

      debugPrint('MESSAGES: Tải thành công ${result.length} conversation');
    } catch (e, stackTrace) {
      debugPrint('LOAD CLIENT MESSAGES ERROR: $e');
      debugPrint('MESSAGES STACK: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _getMessageError(e);
      });
    }
  }

  // =============================================================
  // ERROR
  // =============================================================

  String _getMessageError(Object error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'Không thể kết nối đến máy chủ';
    }

    if (message.contains('401')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại';
    }

    if (message.contains('403')) {
      return 'Bạn không có quyền xem tin nhắn';
    }

    if (message.contains('404')) {
      return 'Không tìm thấy dữ liệu tin nhắn';
    }

    return 'Không thể tải danh sách tin nhắn. Vui lòng thử lại';
  }

  // =============================================================
  // FORMAT TIME
  // =============================================================

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final localTime = dateTime.toLocal();

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final messageDay = DateTime(localTime.year, localTime.month, localTime.day);

    final difference = today.difference(messageDay).inDays;

    final hour = localTime.hour.toString().padLeft(2, '0');

    final minute = localTime.minute.toString().padLeft(2, '0');

    if (difference == 0) {
      return '$hour:$minute';
    }

    if (difference == 1) {
      return 'Hôm qua';
    }

    if (difference > 1 && difference < 7) {
      const weekdays = [
        'Thứ 2',
        'Thứ 3',
        'Thứ 4',
        'Thứ 5',
        'Thứ 6',
        'Thứ 7',
        'Chủ nhật',
      ];

      return weekdays[localTime.weekday - 1];
    }

    return '${localTime.day.toString().padLeft(2, '0')}/'
        '${localTime.month.toString().padLeft(2, '0')}';
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

            Expanded(
              child: Column(
                children: [
                  _buildSearchBox(),
                  _buildMessageTabs(),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF3), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trò chuyện',
            style: TextStyle(
              color: _darkNavy,
              fontSize: 27,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Trao đổi dễ dàng, giải pháp pháp lý gần hơn',
            style: TextStyle(
              color: Color(0xFF667F9B),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SEARCH
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
            hintText: 'Tìm kiếm cuộc trò chuyện...',
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
    final unreadCount = _messages
        .where((message) => message.isRead == false)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: Row(
        children: [
          Expanded(child: _buildMessageTab(title: 'Tất cả', index: 0)),
          Expanded(
            child: _buildMessageTab(
              title: 'Chưa đọc',
              index: 1,
              showBadge: unreadCount > 0,
              badgeCount: unreadCount,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TAB
  // =============================================================

  Widget _buildMessageTab({
    required String title,
    required int index,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    final bool selected = _selectedTab == index;

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

            if (showBadge)
              Positioned(
                top: 0,
                right: 25,
                child: Container(
                  width: 21,
                  height: 21,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE52D35),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
    // -----------------------------------------------------------
    // NOT LOGGED IN
    // -----------------------------------------------------------

    if (!_isLoading && _currentUserId == null) {
      return _buildLoginRequiredState();
    }

    // -----------------------------------------------------------
    // LOADING
    // -----------------------------------------------------------

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }

    // -----------------------------------------------------------
    // ERROR
    // -----------------------------------------------------------

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // -----------------------------------------------------------
    // FILTER
    // -----------------------------------------------------------

    final filteredMessages = _getFilteredMessages();

    // -----------------------------------------------------------
    // EMPTY
    // -----------------------------------------------------------

    if (filteredMessages.isEmpty) {
      return _buildEmptyState();
    }

    // -----------------------------------------------------------
    // LIST
    // -----------------------------------------------------------

    return RefreshIndicator(
      color: _gold,
      onRefresh: _loadMessages,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: filteredMessages.length,
        separatorBuilder: (_, __) {
          return const SizedBox(height: 2);
        },
        itemBuilder: (context, index) {
          final message = filteredMessages[index];

          return ClientMessageListTile(
            message: message,
            isSelected: false,
            onTap: () {
              _openConversation(message);
            },
          );
        },
      ),
    );
  }

  // =============================================================
  // FILTER
  // =============================================================

  List<ClientMessageItemData> _getFilteredMessages() {
    final String keyword = _searchController.text.trim().toLowerCase();

    return _messages.where((message) {
      // ---------------------------------------------------------
      // SEARCH
      // ---------------------------------------------------------

      final bool matchesSearch =
          keyword.isEmpty ||
              message.name.toLowerCase().contains(keyword) ||
              message.message.toLowerCase().contains(keyword);

      if (!matchesSearch) {
        return false;
      }

      // ---------------------------------------------------------
      // UNREAD
      // ---------------------------------------------------------

      if (_selectedTab == 1) {
        return !message.isRead;
      }

      // ---------------------------------------------------------
      // SAVED
      // ---------------------------------------------------------

      if (_selectedTab == 2) {
        return message.isSaved;
      }

      return true;
    }).toList();
  }

  // =============================================================
  // OPEN LOGIN
  // =============================================================

  Future<void> _openLogin() async {
    await AuthNavigationService.loginAndRedirect(context);
    await _loadMessages();
  }

  // =============================================================
  // LOGIN REQUIRED
  // =============================================================

  Widget _buildLoginRequiredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: _navy,
                size: 36,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Bạn cần đăng nhập để xem tin nhắn',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Vui lòng đăng nhập để xem và trao đổi với luật sư.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: _openLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
              width: 75,
              height: 75,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFD85A5A),
                size: 35,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _errorMessage ?? 'Không thể tải tin nhắn',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadMessages,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
    String text = 'Chưa có tin nhắn';

    if (_selectedTab == 1) {
      text = 'Không có tin nhắn chưa đọc';
    }

    if (_selectedTab == 2) {
      text = 'Chưa có tin nhắn đã lưu';
    }

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
              'Các cuộc trò chuyện với luật sư sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // OPEN CONVERSATION
  // =============================================================

  Future<void> _openConversation(ClientMessageItemData message) async {
    // ==========================================
    // CLICK = ĐÃ ĐỌC
    // ==========================================

    if (message.isRead == false) {
      setState(() {
        message.isRead = true;
        message.unreadCount = 0;

        _readConversationIds.add(message.conversationId);
      });
    }

    // ==========================================
    // MỞ CHAT
    // ==========================================

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ClientChatScreen(
            conversationId: message.conversationId,
            lawyer: ClientChatLawyerData(
              id: message.lawyerId,
              name: message.name,
              status: 'Luật sư',
              avatarUrl: message.avatarUrl,
            ),
          );
        },
      ),
    );

    if (!mounted) return;

    await _loadMessages();
  }
}

// =================================================================
// MESSAGE DATA
// =================================================================

class ClientMessageItemData {
  ClientMessageItemData({
    required this.id,
    required this.conversationId,
    required this.clientId,
    required this.lawyerId,
    required this.name,
    required this.message,
    required this.time,
    required this.avatarUrl,
    required this.latestMessage,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isSaved = false,
    this.isRead = false,
  });

  final String id;
  final String conversationId;
  final String clientId;
  final String lawyerId;

  final String name;
  final String message;
  final String time;
  final String avatarUrl;

  final MessageModel? latestMessage;

  int unreadCount;

  bool isOnline;

  bool isSaved;

  bool isRead;
}

// =================================================================
// MESSAGE LIST TILE
// =================================================================

class ClientMessageListTile extends StatelessWidget {
  const ClientMessageListTile({
    super.key,
    required this.message,
    required this.isSelected,
    required this.onTap,
  });

  final ClientMessageItemData message;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isUnread = message.isRead == false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFFFF7EA) : const Color(0xFFF4F9FD),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFFF1D8AD)
                  : const Color(0xFFE1EAF3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF153B65),
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          message.time,
                          style: TextStyle(
                            color: isUnread
                                ? const Color(0xFF173D68)
                                : const Color(0xFF7D91A7),
                            fontSize: 10,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isUnread
                                  ? const Color(0xFF315A85)
                                  : const Color(0xFF8094A9),
                              fontSize: 12,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),

                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          _buildUnreadBadge(),
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

  Widget _buildAvatar() {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        children: [
          ClipOval(
            child: message.avatarUrl.isNotEmpty
                ? Image.network(
              message.avatarUrl,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAvatar();
              },
            )
                : _buildDefaultAvatar(),
          ),

          if (message.isOnline)
            Positioned(
              right: 0,
              bottom: 1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF12A875),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =============================================================
  // DEFAULT AVATAR
  // =============================================================

  Widget _buildDefaultAvatar() {
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        color: Color(0xFFE8EEF4),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF7A91A8),
        size: 30,
      ),
    );
  }

  // =============================================================
  // UNREAD BADGE
  // =============================================================

  Widget _buildUnreadBadge() {
    return Container(
      width: 25,
      height: 25,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE52D35),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.mark_email_unread_rounded,
        color: Colors.white,
        size: 13,
      ),
    );
  }
}
