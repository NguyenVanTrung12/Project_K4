import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/models/message_model.dart';
import 'package:themis_trust_mobile/services/message_service.dart';

class LawyerChatScreen extends StatefulWidget {
  const LawyerChatScreen({
    super.key,
    required this.client,
    this.conversationId,
  });

  final LawyerChatClientData client;

  /// Có thể truyền trực tiếp conversationId từ màn hình danh sách tin nhắn.
  /// Nếu không truyền, màn hình sẽ tự tìm conversation theo clientId.
  final String? conversationId;

  @override
  State<LawyerChatScreen> createState() => _LawyerChatScreenState();
}

class _LawyerChatScreenState extends State<LawyerChatScreen> {
  // =============================================================
  // COLORS
  // =============================================================

  static const Color _navy = Color(0xFF123963);
  static const Color _darkNavy = Color(0xFF0D2E52);
  static const Color _gold = Color(0xFFC68A2B);
  static const Color _text = Color(0xFF173A63);
  static const Color _muted = Color(0xFF7C91A8);
  static const Color _border = Color(0xFFE3EAF2);

  // =============================================================
  // SERVICES
  // =============================================================

  final MessageService _messageService = MessageService();

  // =============================================================
  // CONTROLLERS
  // =============================================================

  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  // =============================================================
  // DATA
  // =============================================================

  late LawyerChatClientData _client;

  List<MessageModel> _messages = [];

  String? _conversationId;
  String? _lawyerId;

  Timer? _messagePollingTimer;

  bool _isLoading = true;
  bool _isSending = false;
  bool _isFindingConversation = false;

  String? _errorMessage;

  // Dùng để tránh thêm trùng message
  String _lastLoadedSignature = '';

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _client = widget.client;

    _loadChat();

    // ===========================================================
    // REAL-TIME
    // ===========================================================
    //
    // API hiện tại chưa có SignalR listener ở Flutter screen này.
    // Vì vậy kiểm tra API mỗi 2 giây để nhận tin nhắn mới.
    //
    // Không cần restart app.
    // Không cần thoát màn hình.
    //
    // ===========================================================

    _messagePollingTimer = Timer.periodic(
      const Duration(seconds: 2),
          (_) {
        if (!_isLoading &&
            !_isSending &&
            _conversationId != null) {
          _refreshMessages(silent: true);
        }
      },
    );
  }

  // =============================================================
  // LOAD CHAT
  // =============================================================

  Future<void> _loadChat() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // ---------------------------------------------------------
      // Lấy ID lawyer đang đăng nhập
      // ---------------------------------------------------------

      final prefs =
      await SharedPreferences.getInstance();

      _lawyerId = prefs.getString('userId');

      if (_lawyerId == null ||
          _lawyerId!.trim().isEmpty) {
        throw Exception(
          'Không tìm thấy tài khoản luật sư đang đăng nhập.',
        );
      }

      // ---------------------------------------------------------
      // Nếu đã truyền conversationId
      // ---------------------------------------------------------

      if (widget.conversationId != null &&
          widget.conversationId!.trim().isNotEmpty) {
        _conversationId =
            widget.conversationId!.trim();
      }

      // ---------------------------------------------------------
      // Nếu chưa có conversationId
      // → tìm conversation theo clientId
      // ---------------------------------------------------------

      if (_conversationId == null) {
        await _findConversation();
      }

      if (_conversationId == null) {
        throw Exception(
          'Không tìm thấy cuộc trò chuyện với khách hàng này.',
        );
      }

      // ---------------------------------------------------------
      // Lấy toàn bộ tin nhắn
      // ---------------------------------------------------------

      await _refreshMessages(
        silent: false,
        scrollToBottom: true,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });

      debugPrint(
        'LawyerChatScreen - Load chat error: $e',
      );
    }
  }

  // =============================================================
  // FIND CONVERSATION
  // =============================================================

  Future<void> _findConversation() async {
    if (_isFindingConversation) return;

    _isFindingConversation = true;

    try {
      final conversations =
      await _messageService.getConversations();

      final targetClientId =
      _client.id.toString();

      for (final conversation in conversations) {
        final conversationClientId =
        conversation.clientId.toString();

        if (conversationClientId ==
            targetClientId) {
          _conversationId =
              conversation.id.toString();

          break;
        }
      }
    } finally {
      _isFindingConversation = false;
    }
  }

  // =============================================================
  // REFRESH MESSAGES
  // =============================================================

  Future<void> _refreshMessages({
    bool silent = false,
    bool scrollToBottom = false,
  }) async {
    if (_conversationId == null) return;

    try {
      final messages =
      await _messageService.getByConversation(
        _conversationId!,
      );

      if (!mounted) return;

      // ---------------------------------------------------------
      // Tạo signature để biết dữ liệu có thực sự thay đổi hay không
      // ---------------------------------------------------------

      final signature = messages
          .map(
            (message) =>
        '${message.id}|'
            '${message.content}|'
            '${message.sentAt?.millisecondsSinceEpoch}',
      )
          .join('||');

      final hasChanged =
          signature != _lastLoadedSignature;

      if (!hasChanged && silent) {
        return;
      }

      _lastLoadedSignature = signature;

      setState(() {
        _messages = messages;
      });

      // ---------------------------------------------------------
      // Cuộn xuống cuối khi có tin nhắn mới
      // ---------------------------------------------------------

      if (hasChanged || scrollToBottom) {
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint(
        'LawyerChatScreen - Refresh messages error: $e',
      );

      // Khi polling lỗi thì không làm mất giao diện hiện tại.
      // Chỉ hiện lỗi khi load lần đầu.
      if (!silent && mounted) {
        setState(() {
          _errorMessage = _cleanError(e);
        });
      }
    }
  }

  // =============================================================
  // SEND MESSAGE
  // =============================================================

  Future<void> _sendMessage() async {
    final text =
    _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    if (_conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không tìm thấy cuộc trò chuyện.',
          ),
        ),
      );
      return;
    }

    if (_isSending) {
      return;
    }

    try {
      setState(() {
        _isSending = true;
      });

      // ---------------------------------------------------------
      // Gọi API thật
      // ---------------------------------------------------------

      final sentMessage =
      await _messageService.sendMessage(
        conversationId: _conversationId!,
        content: text,
      );

      // ---------------------------------------------------------
      // Xóa input
      // ---------------------------------------------------------

      _messageController.clear();

      // ---------------------------------------------------------
      // Thêm tin nhắn vừa gửi ngay lập tức
      // ---------------------------------------------------------

      if (mounted) {
        setState(() {
          final exists = _messages.any(
                (item) =>
            item.id.toString() ==
                sentMessage.id.toString(),
          );

          if (!exists) {
            _messages = [
              ..._messages,
              sentMessage,
            ];
          }
        });
      }

      _lastLoadedSignature = _messages
          .map(
            (message) =>
        '${message.id}|'
            '${message.content}|'
            '${message.sentAt?.millisecondsSinceEpoch}',
      )
          .join('||');

      _scrollToBottom();

      // ---------------------------------------------------------
      // Gọi lại API một lần nữa để đồng bộ hoàn toàn
      // ---------------------------------------------------------

      await _refreshMessages(
        silent: true,
        scrollToBottom: true,
      );
    } catch (e) {
      debugPrint(
        'LawyerChatScreen - Send message error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể gửi tin nhắn: ${_cleanError(e)}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // =============================================================
  // SCROLL TO BOTTOM
  // =============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
          const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _messagePollingTimer?.cancel();

    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF8FAFD),

      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // ===================================================
            // HEADER
            // ===================================================

            _buildChatHeader(),

            // ===================================================
            // BODY
            // ===================================================

            Expanded(
              child: _buildChatBody(),
            ),

            // ===================================================
            // INPUT
            // ===================================================

            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // CHAT HEADER
  // =============================================================

  Widget _buildChatHeader() {
    return Container(
      width: double.infinity,
      height: 82,

      decoration:
      const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _border,
            width: 1,
          ),
        ),
      ),

      child: Row(
        children: [
          // ===================================================
          // BACK
          // ===================================================

          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _navy,
              size: 20,
            ),
          ),

          // ===================================================
          // AVATAR
          // ===================================================

          _buildClientAvatar(
            size: 52,
          ),

          const SizedBox(width: 11),

          // ===================================================
          // CLIENT NAME
          // Không còn trạng thái
          // ===================================================

          Expanded(
            child: Text(
              _client.name,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                color: _darkNavy,
                fontSize: 15,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),

          // ===================================================
          // MORE
          // ===================================================

          IconButton(
            onPressed: _showChatMenu,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: _navy,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // CHAT BODY
  // =============================================================

  Widget _buildChatBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _navy,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_messages.isEmpty) {
      return _buildEmptyChat();
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFFFBFCFE),

      child: ListView.builder(
        controller: _scrollController,

        physics:
        const BouncingScrollPhysics(),

        padding:
        const EdgeInsets.fromLTRB(
          14,
          13,
          14,
          20,
        ),

        itemCount:
        _messages.length + 1,

        itemBuilder:
            (context, index) {
          // ---------------------------------------------------
          // DATE
          // ---------------------------------------------------

          if (index == 0) {
            return _buildDateDivider();
          }

          final message =
          _messages[index - 1];

          return Padding(
            padding:
            const EdgeInsets.only(
              bottom: 10,
            ),

            child:
            _buildMessageBubble(
              message,
            ),
          );
        },
      ),
    );
  }

  // =============================================================
  // EMPTY CHAT
  // =============================================================

  Widget _buildEmptyChat() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBFCFE),

      child: Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            Container(
              width: 68,
              height: 68,

              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFEAF2FC,
                ),
                shape:
                BoxShape.circle,
              ),

              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: _navy,
                size: 31,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Chưa có tin nhắn',
              style: TextStyle(
                color: _darkNavy,
                fontSize: 15,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Hãy bắt đầu cuộc trò chuyện với ${_client.name}',
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
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
        padding:
        const EdgeInsets.all(24),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 42,
            ),

            const SizedBox(height: 12),

            const Text(
              'Không thể tải cuộc trò chuyện',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color: _darkNavy,
                fontSize: 15,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ??
                  'Đã xảy ra lỗi.',
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _loadChat,
              style:
              ElevatedButton.styleFrom(
                backgroundColor: _navy,
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

  // =============================================================
  // DATE DIVIDER
  // =============================================================

  Widget _buildDateDivider() {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 16,
      ),

      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color:
              const Color(
                0xFFE7ECF2,
              ),
            ),
          ),

          const Padding(
            padding:
            EdgeInsets.symmetric(
              horizontal: 14,
            ),

            child: Text(
              'Tin nhắn',
              style: TextStyle(
                color:
                Color(0xFF71849A),
                fontSize: 11,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            child: Container(
              height: 1,
              color:
              const Color(
                0xFFE7ECF2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // MESSAGE BUBBLE
  // =============================================================

  Widget _buildMessageBubble(
      MessageModel message,
      ) {
    final lawyerId =
    _lawyerId?.toString();

    final senderId =
    message.senderId.toString();

    final isMine =
        lawyerId != null &&
            senderId == lawyerId;

    // ===========================================================
    // LAWYER MESSAGE
    // ===========================================================

    if (isMine) {
      return Align(
        alignment:
        Alignment.centerRight,

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.end,

          children: [
            Container(
              constraints:
              BoxConstraints(
                maxWidth:
                MediaQuery.of(
                  context,
                ).size.width *
                    0.78,
              ),

              padding:
              const EdgeInsets.fromLTRB(
                14,
                11,
                11,
                7,
              ),

              decoration:
              const BoxDecoration(
                color: _navy,

                borderRadius:
                BorderRadius.only(
                  topLeft:
                  Radius.circular(16),
                  topRight:
                  Radius.circular(16),
                  bottomLeft:
                  Radius.circular(16),
                  bottomRight:
                  Radius.circular(4),
                ),
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,

                children: [
                  Align(
                    alignment:
                    Alignment.centerLeft,

                    child: Text(
                      message.content ??
                          '',

                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Row(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      Text(
                        _formatMessageTime(
                          message.sentAt,
                        ),

                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFFD8E3EF,
                          ),
                          fontSize: 9,
                        ),
                      ),

                      const SizedBox(
                        width: 4,
                      ),

                      Icon(
                        message.readAt !=
                            null
                            ? Icons
                            .done_all_rounded
                            : Icons
                            .done_rounded,

                        color:
                        const Color(
                          0xFFD8E3EF,
                        ),

                        size: 13,
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

    // ===========================================================
    // CLIENT MESSAGE
    // ===========================================================

    return Align(
      alignment:
      Alignment.centerLeft,

      child: Container(
        constraints:
        BoxConstraints(
          maxWidth:
          MediaQuery.of(
            context,
          ).size.width *
              0.78,
        ),

        padding:
        const EdgeInsets.fromLTRB(
          14,
          11,
          14,
          8,
        ),

        decoration:
        BoxDecoration(
          color: Colors.white,

          borderRadius:
          const BorderRadius.only(
            topLeft:
            Radius.circular(16),
            topRight:
            Radius.circular(16),
            bottomLeft:
            Radius.circular(4),
            bottomRight:
            Radius.circular(16),
          ),

          border: Border.all(
            color:
            const Color(
              0xFFE2EAF2,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color:
              Colors.black
                  .withOpacity(
                0.025,
              ),
              blurRadius: 5,
              offset:
              const Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Text(
              message.content ??
                  '',

              style:
              const TextStyle(
                color: _text,
                fontSize: 14,
                height: 1.45,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              _formatMessageTime(
                message.sentAt,
              ),

              style:
              const TextStyle(
                color: _muted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // MESSAGE INPUT
  // =============================================================

  Widget _buildMessageInput() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        10,
      ),

      decoration:
      BoxDecoration(
        color: Colors.white,

        border: const Border(
          top: BorderSide(
            color:
            Color(0xFFE3EAF2),
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withOpacity(
              0.04,
            ),
            blurRadius: 8,
            offset:
            const Offset(0, -2),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.end,

          children: [
            // =================================================
            // ATTACH
            // =================================================

            IconButton(
              onPressed:
              _selectAttachment,

              padding:
              const EdgeInsets.all(
                8,
              ),

              constraints:
              const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),

              icon:
              const Icon(
                Icons.attach_file_rounded,
                color: _navy,
                size: 24,
              ),
            ),

            // =================================================
            // TEXT FIELD
            // =================================================

            Expanded(
              child: Container(
                constraints:
                const BoxConstraints(
                  minHeight: 44,
                  maxHeight: 110,
                ),

                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF9FBFD,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),

                  border:
                  Border.all(
                    color:
                    const Color(
                      0xFFE1E8F0,
                    ),
                  ),
                ),

                child: TextField(
                  controller:
                  _messageController,

                  minLines: 1,
                  maxLines: 4,

                  textInputAction:
                  TextInputAction.newline,

                  style:
                  const TextStyle(
                    color: _text,
                    fontSize: 13,
                  ),

                  decoration:
                  const InputDecoration(
                    border:
                    InputBorder.none,

                    hintText:
                    'Nhập tin nhắn...',

                    hintStyle:
                    TextStyle(
                      color:
                      Color(
                        0xFF8DA0B4,
                      ),
                      fontSize: 13,
                    ),

                    contentPadding:
                    EdgeInsets.fromLTRB(
                      12,
                      11,
                      8,
                      10,
                    ),
                  ),
                ),
              ),
            ),

            // =================================================
            // EMOJI
            // =================================================

            IconButton(
              onPressed:
              _showEmojiPicker,

              padding:
              const EdgeInsets.all(
                8,
              ),

              constraints:
              const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),

              icon:
              const Icon(
                Icons
                    .sentiment_satisfied_alt_outlined,
                color:
                Color(0xFF6C829A),
                size: 24,
              ),
            ),

            // =================================================
            // SEND
            // =================================================

            GestureDetector(
              onTap:
              _isSending
                  ? null
                  : _sendMessage,

              child: AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 150,
                ),

                width: 46,
                height: 46,

                decoration:
                BoxDecoration(
                  color: _isSending
                      ? Colors.grey
                      : _gold,

                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),

                child: _isSending
                    ? const Padding(
                  padding:
                  EdgeInsets.all(
                    13,
                  ),
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.send_rounded,
                  color:
                  Colors.white,
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // CLIENT AVATAR
  // =============================================================

  Widget _buildClientAvatar({
    required double size,
  }) {
    final avatarUrl =
    _client.avatarUrl.trim();

    return SizedBox(
      width: size,
      height: size,

      child: ClipOval(
        child: avatarUrl.isNotEmpty
            ? Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,

          errorBuilder:
              (
              context,
              error,
              stackTrace,
              ) {
            return _buildDefaultAvatar(
              size,
            );
          },
        )
            : _buildDefaultAvatar(
          size,
        ),
      ),
    );
  }

  // =============================================================
  // DEFAULT AVATAR
  // =============================================================

  Widget _buildDefaultAvatar(
      double size,
      ) {
    return Container(
      width: size,
      height: size,

      decoration:
      const BoxDecoration(
        color:
        Color(0xFFE7EDF4),
        shape:
        BoxShape.circle,
      ),

      child: Icon(
        Icons.person_rounded,
        color:
        const Color(
          0xFF7890A8,
        ),
        size:
        size * 0.55,
      ),
    );
  }

  // =============================================================
  // FORMAT TIME
  // =============================================================

  String _formatMessageTime(
      DateTime? dateTime,
      ) {
    if (dateTime == null) {
      return '';
    }

    final local =
    dateTime.toLocal();

    final hour =
    local.hour
        .toString()
        .padLeft(2, '0');

    final minute =
    local.minute
        .toString()
        .padLeft(2, '0');

    return '$hour:$minute';
  }

  // =============================================================
  // ATTACHMENT
  // =============================================================

  void _selectAttachment() {
    showModalBottomSheet(
      context: context,

      backgroundColor:
      Colors.white,

      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top:
          Radius.circular(20),
        ),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(
              20,
            ),

            child: Column(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                Container(
                  width: 40,
                  height: 4,

                  decoration:
                  BoxDecoration(
                    color:
                    Colors.grey.shade300,
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                const Align(
                  alignment:
                  Alignment.centerLeft,

                  child: Text(
                    'Gửi tệp đính kèm',

                    style:
                    TextStyle(
                      color:
                      _darkNavy,
                      fontSize: 17,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                _buildAttachmentOption(
                  icon:
                  Icons.photo_outlined,
                  title:
                  'Hình ảnh',
                ),

                _buildAttachmentOption(
                  icon:
                  Icons.description_outlined,
                  title:
                  'Tài liệu',
                ),

                _buildAttachmentOption(
                  icon:
                  Icons.camera_alt_outlined,
                  title:
                  'Chụp ảnh',
                ),

                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // ATTACHMENT OPTION
  // =============================================================

  Widget _buildAttachmentOption({
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      contentPadding:
      EdgeInsets.zero,

      leading: Container(
        width: 42,
        height: 42,

        decoration:
        BoxDecoration(
          color:
          const Color(
            0xFFEAF2FC,
          ),

          borderRadius:
          BorderRadius.circular(
            10,
          ),
        ),

        child: Icon(
          icon,
          color: _navy,
          size: 21,
        ),
      ),

      title: Text(
        title,

        style:
        const TextStyle(
          color: _text,
          fontSize: 13,
          fontWeight:
          FontWeight.w500,
        ),
      ),

      onTap: () {
        Navigator.pop(context);

        _showComingSoon(
          'Tính năng $title',
        );
      },
    );
  }

  // =============================================================
  // EMOJI
  // =============================================================

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,

      backgroundColor:
      Colors.white,

      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top:
          Radius.circular(20),
        ),
      ),

      builder: (context) {
        const List<String> emojis = [
          '😀',
          '😂',
          '😊',
          '😍',
          '🥰',
          '😎',
          '👍',
          '👏',
          '🙏',
          '❤️',
          '🎉',
          '✨',
        ];

        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(
              20,
            ),

            child: Wrap(
              spacing: 20,
              runSpacing: 20,

              children:
              emojis.map(
                    (emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      final current =
                          _messageController
                              .text;

                      _messageController
                          .text =
                      '$current$emoji';

                      _messageController
                          .selection =
                          TextSelection
                              .fromPosition(
                            TextPosition(
                              offset:
                              _messageController
                                  .text
                                  .length,
                            ),
                          );
                    },

                    child: Text(
                      emoji,

                      style:
                      const TextStyle(
                        fontSize: 27,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // CHAT MENU
  // =============================================================

  void _showChatMenu() {
    showModalBottomSheet(
      context: context,

      backgroundColor:
      Colors.white,

      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top:
          Radius.circular(20),
        ),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(
              vertical: 12,
            ),

            child: Column(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                _buildMenuItem(
                  icon:
                  Icons.search_rounded,
                  title:
                  'Tìm kiếm tin nhắn',
                ),

                _buildMenuItem(
                  icon:
                  Icons
                      .notifications_off_outlined,
                  title:
                  'Tắt thông báo',
                ),

                _buildMenuItem(
                  icon:
                  Icons
                      .delete_outline_rounded,
                  title:
                  'Xóa cuộc trò chuyện',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // MENU ITEM
  // =============================================================

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: _navy,
      ),

      title: Text(
        title,

        style:
        const TextStyle(
          color: _text,
          fontSize: 13,
        ),
      ),

      onTap: () {
        Navigator.pop(context);

        _showComingSoon(
          title,
        );
      },
    );
  }

  // =============================================================
  // ERROR CLEAN
  // =============================================================

  String _cleanError(
      Object error,
      ) {
    final text =
    error.toString();

    if (text.startsWith(
      'Exception: ',
    )) {
      return text.substring(
        11,
      );
    }

    return text;
  }

  // =============================================================
  // COMING SOON
  // =============================================================

  void _showComingSoon(
      String feature,
      ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '$feature sẽ được kết nối API sau.',
        ),

        duration:
        const Duration(
          seconds: 1,
        ),
      ),
    );
  }
}

// =================================================================
// CLIENT DATA
// =================================================================

class LawyerChatClientData {
  const LawyerChatClientData({
    required this.id,
    required this.name,
    this.avatarUrl = '',
  });

  final dynamic id;
  final String name;
  final String avatarUrl;
}