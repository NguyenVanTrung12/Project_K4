import 'dart:async';
import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/models/message_model.dart';
import 'package:themis_trust_mobile/services/message_service.dart';

class ClientChatScreen extends StatefulWidget {
  const ClientChatScreen({
    super.key,
    this.conversationId,
    this.lawyer,
  });

  final String? conversationId;
  final ClientChatLawyerData? lawyer;

  @override
  State<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends State<ClientChatScreen> {
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
  // CONTROLLERS
  // =============================================================

  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  final MessageService _messageService =
  MessageService();

  // =============================================================
  // DATA
  // =============================================================

  late ClientChatLawyerData _lawyer;

  String? _conversationId;

  List<MessageModel> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  Timer? _messageRefreshTimer;

  bool _isRefreshingMessages = false;
  String? _errorMessage;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _lawyer = widget.lawyer ??
        const ClientChatLawyerData(
          id: '',
          name: 'Luật sư',
          status: 'Luật sư',
          avatarUrl: '',
        );

    _conversationId = widget.conversationId;

    // Tải lịch sử tin nhắn lần đầu
    _loadMessages();

    // Bắt đầu tự động kiểm tra tin nhắn mới
    _startMessageRefresh();
  }

  void _startMessageRefresh() {
    _messageRefreshTimer?.cancel();

    _messageRefreshTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) async {
        await _refreshMessagesSilently();
      },
    );
  }

  Future<void> _refreshMessagesSilently() async {
    if (!mounted) return;

    // Không có conversation thì chưa có gì để kiểm tra
    if (_conversationId == null ||
        _conversationId!.trim().isEmpty) {
      return;
    }

    // Tránh gọi API chồng lên nhau
    if (_isRefreshingMessages) {
      return;
    }

    _isRefreshingMessages = true;

    try {
      final List<MessageModel> newMessages =
      await _messageService.getByConversation(
        _conversationId!,
      );

      if (!mounted) return;

      // Không có thay đổi
      if (newMessages.length == _messages.length) {
        return;
      }

      // Có tin nhắn mới
      setState(() {
        _messages = newMessages;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint(
        'CLIENT CHAT - AUTO REFRESH ERROR: $e',
      );
    } finally {
      _isRefreshingMessages = false;
    }
  }
  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _messageRefreshTimer?.cancel();

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
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildChatHeader(),

            // Chat
            Expanded(
              child: _buildChatBody(),
            ),

            // Nhập tin nhắn
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // HEADER
  // =============================================================

  Widget _buildChatHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFDDE6EF),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF173B66),
            ),
          ),

          const SizedBox(width: 4),

          _buildLawyerAvatar(),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _lawyer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF173B66),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      color: Color(0xFF35A66F),
                      size: 7,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      _lawyer.status,
                      style: const TextStyle(
                        color: Color(0xFF7186A0),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: _showChatMenu,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF173B66),
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
    // -------------------------------------------------------------
    // LOADING
    // -------------------------------------------------------------

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _gold,
        ),
      );
    }

    // -------------------------------------------------------------
    // ERROR
    // -------------------------------------------------------------

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFD85A5A),
                size: 40,
              ),

              const SizedBox(height: 15),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: _loadMessages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  elevation: 0,
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // -------------------------------------------------------------
    // CHƯA CÓ TIN NHẮN
    // -------------------------------------------------------------

    if (_messages.isEmpty) {
      return Container(
        width: double.infinity,
        color: const Color(0xFFFBFCFE),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: Text(
              'Hãy bắt đầu cuộc trò chuyện',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7186A0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    // -------------------------------------------------------------
    // CÓ TIN NHẮN
    // -------------------------------------------------------------

    return Container(
      width: double.infinity,
      color: const Color(0xFFFBFCFE),
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          14,
          13,
          14,
          20,
        ),
        itemCount: _messages.length + 1,
        itemBuilder: (context, index) {
          // Ngày
          if (index == 0) {
            return _buildDateDivider();
          }

          final message = _messages[index - 1];

          return Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
            child: _buildMessageBubble(message),
          );
        },
      ),
    );
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
      final String? conversationId =
          _conversationId;

      // Chưa có conversation
      // Không phải lỗi.
      if (conversationId == null ||
          conversationId.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          _messages = [];
          _isLoading = false;
        });

        return;
      }

      final List<MessageModel> messages =
      await _messageService.getByConversation(
        conversationId,
      );

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint(
        'CLIENT CHAT - LOAD MESSAGE ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _messages = [];
        _isLoading = false;
        _errorMessage =
        'Không thể tải tin nhắn.\n'
            'Vui lòng thử lại.';
      });
    }
  }

  // =============================================================
  // DATE DIVIDER
  // =============================================================

  Widget _buildDateDivider() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE7ECF2),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
            ),
            child: Text(
              'Hôm nay',
              style: TextStyle(
                color: Color(0xFF71849A),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE7ECF2),
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
    // Nếu senderId trùng lawyer.id
    // → tin của luật sư.
    //
    // Nếu không trùng
    // → tin của client.

    final bool isMe =
        message.senderId.toString() !=
            _lawyer.id.toString();

    final String content =
        message.content?.trim() ?? '';

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
          MediaQuery.of(context).size.width *
              0.75,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF234D78)
              : const Color(0xFFF0F4F8),
          borderRadius:
          BorderRadius.only(
            topLeft:
            const Radius.circular(14),
            topRight:
            const Radius.circular(14),
            bottomLeft:
            Radius.circular(
              isMe ? 14 : 4,
            ),
            bottomRight:
            Radius.circular(
              isMe ? 4 : 14,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------
            // CONTENT
            // -----------------------------------------------------

            if (content.isNotEmpty)
              Text(
                content,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : const Color(
                    0xFF173B66,
                  ),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

            // -----------------------------------------------------
            // ATTACHMENT
            // -----------------------------------------------------

            if (message.attachmentUrl != null &&
                message
                    .attachmentUrl!
                    .trim()
                    .isNotEmpty)
              Padding(
                padding:
                EdgeInsets.only(
                  top:
                  content.isNotEmpty
                      ? 8
                      : 0,
                ),
                child: _buildAttachment(
                  message
                      .attachmentUrl!,
                  isMe,
                ),
              ),

            // -----------------------------------------------------
            // TIME
            // -----------------------------------------------------

            const SizedBox(height: 4),

            Text(
              _formatMessageTime(
                message.sentAt,
              ),
              style: TextStyle(
                color: isMe
                    ? Colors.white70
                    : const Color(
                  0xFF8A9AAF,
                ),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // ATTACHMENT
  // =============================================================

  Widget _buildAttachment(
      String url,
      bool isMe,
      ) {
    return GestureDetector(
      onTap: () {
        _showComingSoon(
          'Xem tệp đính kèm',
        );
      },
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withOpacity(
            0.12,
          )
              : Colors.white,
          borderRadius:
          BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file_rounded,
              size: 18,
              color: isMe
                  ? Colors.white
                  : _navy,
            ),

            const SizedBox(width: 6),

            Flexible(
              child: Text(
                'Tệp đính kèm',
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : _navy,
                  fontSize: 11,
                ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE3EAF2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 8,
            offset: const Offset(
              0,
              -2,
            ),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            // -----------------------------------------------------
            // ATTACHMENT
            // -----------------------------------------------------

            IconButton(
              onPressed:
              _selectAttachment,
              padding:
              const EdgeInsets.all(8),
              constraints:
              const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),
              icon: const Icon(
                Icons.attach_file_rounded,
                color: _navy,
                size: 24,
              ),
            ),

            // -----------------------------------------------------
            // TEXT FIELD
            // -----------------------------------------------------

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
                  border: Border.all(
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

            // -----------------------------------------------------
            // EMOJI
            // -----------------------------------------------------

            IconButton(
              onPressed:
              _showEmojiPicker,
              padding:
              const EdgeInsets.all(8),
              constraints:
              const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),
              icon: const Icon(
                Icons
                    .sentiment_satisfied_alt_outlined,
                color:
                Color(0xFF6C829A),
                size: 24,
              ),
            ),

            // -----------------------------------------------------
            // SEND
            // -----------------------------------------------------

            GestureDetector(
              onTap: _isSending
                  ? null
                  : _sendMessage,
              child: Container(
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
  // SEND MESSAGE
  // =============================================================

  Future<void> _sendMessage() async {
    final String text =
    _messageController.text.trim();

    if (text.isEmpty || _isSending) {
      return;
    }

    if (_lawyer.id.toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không xác định được luật sư.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // ==========================================================
      // 1. LẤY CONVERSATION HIỆN TẠI
      // ==========================================================

      String? conversationId =
          _conversationId;

      // ==========================================================
      // 2. CHƯA CÓ CONVERSATION
      //    → TỰ ĐỘNG TẠO
      // ==========================================================

      if (conversationId == null ||
          conversationId.trim().isEmpty) {
        conversationId =
        await _messageService.createConversation(
          lawyerId: _lawyer.id.toString(),
        );

        if (!mounted) return;

        setState(() {
          _conversationId = conversationId;
        });
      }

      // ==========================================================
      // 3. GỬI MESSAGE THẬT LÊN BACKEND
      // ==========================================================

      final MessageModel message =
      await _messageService.sendMessage(
        conversationId: conversationId,
        content: text,
      );

      // ==========================================================
      // 4. THÊM MESSAGE BACKEND TRẢ VỀ VÀO UI
      // ==========================================================

      if (!mounted) return;

      setState(() {
        _messages.add(message);
      });

      // ==========================================================
      // 5. CLEAR INPUT
      // ==========================================================

      _messageController.clear();

      // ==========================================================
      // 6. CUỘN XUỐNG CUỐI
      // ==========================================================

      _scrollToBottom();
    } catch (e) {
      debugPrint(
        'CLIENT CHAT - SEND MESSAGE ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể gửi tin nhắn.\n$e',
          ),
          duration:
          const Duration(seconds: 3),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });
    }
  }

  // =============================================================
  // SCROLL
  // =============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!_scrollController
          .hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController
            .position.maxScrollExtent,
        duration:
        const Duration(
          milliseconds: 300,
        ),
        curve: Curves.easeOut,
      );
    });
  }

  // =============================================================
  // AVATAR
  // =============================================================

  Widget _buildLawyerAvatar() {
    final String avatar =
    _lawyer.avatarUrl.trim();

    if (avatar.isEmpty) {
      return _buildDefaultAvatar(
        42,
      );
    }

    return ClipOval(
      child: Image.network(
        avatar,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder:
            (
            context,
            error,
            stackTrace,
            ) {
          return _buildDefaultAvatar(
            42,
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar(
      double size,
      ) {
    return Container(
      width: size,
      height: size,
      decoration:
      const BoxDecoration(
        color: Color(0xFFE7EDF4),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: const Color(
          0xFF7890A8,
        ),
        size: size * 0.55,
      ),
    );
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
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration:
                  BoxDecoration(
                    color: Colors
                        .grey
                        .shade300,
                    borderRadius:
                    BorderRadius
                        .circular(
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
                    style: TextStyle(
                      color: _darkNavy,
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
                  icon: Icons
                      .photo_outlined,
                  title: 'Hình ảnh',
                ),

                _buildAttachmentOption(
                  icon: Icons
                      .description_outlined,
                  title: 'Tài liệu',
                ),

                _buildAttachmentOption(
                  icon: Icons
                      .camera_alt_outlined,
                  title: 'Chụp ảnh',
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
          const Color(0xFFEAF2FC),
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
        style: const TextStyle(
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

    showModalBottomSheet(
      context: context,
      backgroundColor:
      Colors.white,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(20),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children:
              emojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    final String
                    current =
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
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // MESSAGE TIME
  // =============================================================

  String _formatMessageTime(
      DateTime dateTime,
      ) {
    final DateTime localTime =
    dateTime.toLocal();

    final String hour =
    localTime.hour
        .toString()
        .padLeft(2, '0');

    final String minute =
    localTime.minute
        .toString()
        .padLeft(2, '0');

    return '$hour:$minute';
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
          top: Radius.circular(20),
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
                  icon: Icons
                      .search_rounded,
                  title:
                  'Tìm kiếm tin nhắn',
                ),

                _buildMenuItem(
                  icon: Icons
                      .notifications_off_outlined,
                  title:
                  'Tắt thông báo',
                ),

                _buildMenuItem(
                  icon: Icons
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
  // COMING SOON
  // =============================================================

  void _showComingSoon(
      String feature,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$feature sẽ được kết nối API sau.',
        ),
        duration:
        const Duration(seconds: 1),
      ),
    );
  }
}

// =================================================================
// LAWYER DATA
// =================================================================

class ClientChatLawyerData {
  const ClientChatLawyerData({
    required this.id,
    required this.name,
    required this.status,
    required this.avatarUrl,
  });

  final dynamic id;
  final String name;
  final String status;
  final String avatarUrl;
}