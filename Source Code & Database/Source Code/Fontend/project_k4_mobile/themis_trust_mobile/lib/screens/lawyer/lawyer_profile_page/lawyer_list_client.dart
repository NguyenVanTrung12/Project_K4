import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/models/appointment_model.dart';
import 'package:themis_trust_mobile/models/client_model.dart';
import 'package:themis_trust_mobile/services/api_service.dart';


class LawyerListClientScreen extends StatefulWidget {
  const LawyerListClientScreen({super.key});

  @override
  State<LawyerListClientScreen> createState() =>
      _LawyerListClientScreenState();
}

class _LawyerListClientScreenState extends State<LawyerListClientScreen> {
  final ApiService _api = ApiService();

  static const Color _navy = Color(0xFF123963);
  static const Color _gold = Color(0xFFC68A2B);
  static const Color _text = Color(0xFF173A63);
  static const Color _muted = Color(0xFF71869D);
  static const Color _border = Color(0xFFDCE5EF);
  static const Color _background = Color(0xFFF7FAFD);

  List<ClientModel> _clients = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  // ============================================================
  // LẤY DANH SÁCH KHÁCH HÀNG CỦA LAWYER
  // ============================================================

  Future<void> _loadClients() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // API này tự lọc theo lawyer đang đăng nhập
      // trong AppointmentsController.
      final appointmentData = await _api.get('/appointments');

      final List<dynamic> appointments =
      appointmentData is List ? appointmentData : [];

      // Lấy ClientId và loại bỏ client trùng
      final Set<String> clientIds = {};

      for (final item in appointments) {
        if (item is! Map<String, dynamic>) continue;

        final clientId = item['clientId']?.toString();

        if (clientId != null && clientId.isNotEmpty) {
          clientIds.add(clientId);
        }
      }

      // Không có khách hàng
      if (clientIds.isEmpty) {
        if (!mounted) return;

        setState(() {
          _clients = [];
          _isLoading = false;
        });

        return;
      }

      // ========================================================
      // GỌI /api/clients/{id} ĐỂ LẤY THÔNG TIN ĐẦY ĐỦ
      // ========================================================

      final List<ClientModel> clients = [];

      for (final clientId in clientIds) {
        try {
          final data = await _api.get('/clients/$clientId');

          if (data is Map<String, dynamic>) {
            clients.add(ClientModel.fromJson(data));
          }
        } catch (_) {
          // Nếu một client lỗi thì bỏ qua client đó,
          // không làm hỏng toàn bộ danh sách.
        }
      }

      // Sắp xếp theo tên
      clients.sort(
            (a, b) => a.fullName.toLowerCase().compareTo(
          b.fullName.toLowerCase(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách khách hàng.';
      });
    }
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(ClientModel client) {
    final avatarUrl = client.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: const Color(0xFFEAF0F7),
        backgroundImage: NetworkImage(_buildImageUrl(avatarUrl)),
      );
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFFEAF0F7),
      child: Text(
        _getInitials(client.fullName),
        style: const TextStyle(
          color: _navy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _buildImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    if (url.startsWith('/')) {
      return 'http://10.0.2.2:5000$url';
    }

    return 'http://10.0.2.2:5000/$url';
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) {
      return '?';
    }

    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  // ============================================================
  // CARD KHÁCH HÀNG
  // ============================================================

  Widget _buildClientCard(ClientModel client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(client),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                // Email
                if (client.email.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 17,
                        color: _muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          client.email,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 6),

                // Số điện thoại
                if (client.phone != null &&
                    client.phone!.trim().isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 17,
                        color: _muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          client.phone!,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 13.5,
                          ),
                        ),
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
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                color: _navy,
                size: 44,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Chưa có khách hàng',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Danh sách khách hàng của bạn sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 40,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Đã xảy ra lỗi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadClients,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.chevron_left,
            color: _navy,
            size: 32,
          ),
        ),

        title: const Text(
          'Danh sách khách hàng',
          style: TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _border,
          ),
        ),
      ),

      body: RefreshIndicator(
        color: _navy,
        onRefresh: _loadClients,

        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: _navy,
          ),
        )
            : _errorMessage != null
            ? _buildError()
            : _clients.isEmpty
            ? _buildEmptyState()
            : ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),
          children: [
            // Header nhỏ
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                const SizedBox(width: 9),

                Text(
                  '${_clients.length} khách hàng',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ..._clients.map(_buildClientCard),
          ],
        ),
      ),
    );
  }
}