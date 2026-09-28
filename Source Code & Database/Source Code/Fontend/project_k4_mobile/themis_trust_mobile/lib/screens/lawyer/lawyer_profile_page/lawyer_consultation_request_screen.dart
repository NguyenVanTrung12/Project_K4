import 'package:flutter/material.dart';

import 'package:themis_trust_mobile/services/api_service.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_profile_page/lawyer_consultation_detail.dart';

class LawyerConsultationRequestScreen
    extends StatefulWidget {
  const LawyerConsultationRequestScreen({
    super.key,
  });

  @override
  State<LawyerConsultationRequestScreen> createState() =>
      _LawyerConsultationRequestScreenState();
}

class _LawyerConsultationRequestScreenState
    extends State<LawyerConsultationRequestScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _navy = Color(0xFF123963);
  static const Color _gold = Color(0xFFC68A2B);
  static const Color _text = Color(0xFF173A63);
  static const Color _muted = Color(0xFF71869D);
  static const Color _border = Color(0xFFDCE5EF);
  static const Color _background = Color(0xFFF7FAFD);

  // ============================================================
  // API
  // ============================================================

  final ApiService _api = ApiService();

  // ============================================================
  // STATE
  // ============================================================

  final TextEditingController _searchController =
  TextEditingController();

  int _selectedTab = 0;

  bool _loading = false;

  String? _error;

  List<Map<String, dynamic>> _appointments = [];

  final List<String> _tabs = [
    'Tổng',
    'Đang tiến hành',
    'Hoàn thành',
    'Đã hủy',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadConsultationRequests();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD API
  // ============================================================

  Future<void> _loadConsultationRequests() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      /*
       * GET /api/appointments
       *
       * Backend đã [Authorize].
       *
       * Khi Lawyer đăng nhập:
       * backend phải trả các appointment thuộc lawyer đó.
       */

      final result =
      await _api.get('/appointments');

      if (result is! List) {
        throw Exception(
          'Dữ liệu lịch hẹn không hợp lệ.',
        );
      }

      final List<Map<String, dynamic>> data = [];

      for (final item in result) {
        if (item is Map) {
          data.add(
            Map<String, dynamic>.from(item),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _appointments = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.message.isNotEmpty
            ? e.message
            : 'Không thể tải yêu cầu tư vấn.';
      });
    } catch (e) {
      debugPrint(
        'Load consultation requests error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Không thể tải yêu cầu tư vấn.';
      });
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> get _filteredAppointments {
    final keyword =
    _searchController.text.trim().toLowerCase();

    Iterable<Map<String, dynamic>> result =
        _appointments;

    // ----------------------------------------------------------
    // TAB
    // ----------------------------------------------------------

    if (_selectedTab == 1) {
      result = result.where((item) {
        final status =
            item['status']?.toString().toLowerCase() ??
                '';

        return status == 'pending' ||
            status == 'confirmed';
      });
    }

    if (_selectedTab == 2) {
      result = result.where((item) {
        final status =
            item['status']?.toString().toLowerCase() ??
                '';

        return status == 'completed';
      });
    }

    if (_selectedTab == 3) {
      result = result.where((item) {
        final status =
            item['status']?.toString().toLowerCase() ??
                '';

        return status == 'cancelled' ||
            status == 'canceled';
      });
    }

    // ----------------------------------------------------------
    // SEARCH
    // ----------------------------------------------------------

    if (keyword.isNotEmpty) {
      result = result.where((item) {
        final clientName =
            item['clientName']
                ?.toString()
                .toLowerCase() ??
                '';

        final description =
            item['description']
                ?.toString()
                .toLowerCase() ??
                '';

        final appointmentId =
            item['id']
                ?.toString()
                .toLowerCase() ??
                '';

        return clientName.contains(keyword) ||
            description.contains(keyword) ||
            appointmentId.contains(keyword);
      });
    }

    return result.toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearch(),

          _buildTabs(),

          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: _text,
          size: 20,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        'Yêu cầu tư vấn',
        style: TextStyle(
          color: _text,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText:
          'Tìm kiếm yêu cầu tư vấn...',
          hintStyle: const TextStyle(
            color: _muted,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: _muted,
          ),
          suffixIcon:
          _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(
              Icons.close,
              color: _muted,
            ),
            onPressed: () {
              _searchController.clear();

              setState(() {});
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: _border,
            ),
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: _border,
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: _navy,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _border,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        child: Row(
          children: List.generate(
            _tabs.length,
                (index) {
              final selected =
                  _selectedTab == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                child: Container(
                  height: 52,
                  margin:
                  const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected
                            ? _gold
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        color: selected
                            ? _navy
                            : _muted,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
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

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color: _gold,
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    final items =
        _filteredAppointments;

    if (items.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: _gold,
      onRefresh:
      _loadConsultationRequests,
      child: ListView.builder(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          24,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(
            items[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard(
      Map<String, dynamic> appointment,
      ) {
    final appointmentId =
        appointment['id']?.toString() ?? '';

    final clientName =
        appointment['clientName']?.toString() ??
            'Khách hàng';

    final clientId =
        appointment['clientId']?.toString() ?? '';

    final status =
        appointment['status']?.toString() ??
            'pending';

    final description =
        appointment['description']?.toString() ??
            '';

    final scheduledAt =
    DateTime.tryParse(
      appointment['scheduledAt']
          ?.toString() ??
          '',
    );

    final duration =
        int.tryParse(
          appointment['durationMin']
              ?.toString() ??
              '',
        ) ??
            30;

    final statusText =
    _statusText(status);

    final statusColor =
    _statusColor(status);

    final dateText =
    scheduledAt != null
        ? _formatDateTime(
      scheduledAt,
      duration,
    )
        : 'Chưa có thời gian';

    return GestureDetector(
      onTap: () {
        _openDetail(
          appointment: appointment,
          appointmentId: appointmentId,
          clientId: clientId,
          clientName: clientName,
          status: status,
          description: description,
          scheduledAt: scheduledAt,
        );
      },
      child: Container(
        margin:
        const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
        const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color: _border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.025),
              blurRadius: 8,
              offset:
              const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                  BoxDecoration(
                    color: _navy.withValues(
                      alpha: 0.08,
                    ),
                    shape:
                    BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: _navy,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style:
                        const TextStyle(
                          color: _text,
                          fontSize: 15,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        description.isNotEmpty
                            ? description
                            : 'Yêu cầu tư vấn',
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color: statusColor
                        .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    statusText,
                    style:
                    TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(
              height: 1,
              color: _border,
            ),

            const SizedBox(height: 11),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: _muted,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    dateText,
                    style:
                    const TextStyle(
                      color: _muted,
                      fontSize: 12,
                    ),
                  ),
                ),

                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: _navy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OPEN DETAIL
  // ============================================================

  void _openDetail({
    required Map<String, dynamic>
    appointment,
    required String appointmentId,
    required String clientId,
    required String clientName,
    required String status,
    required String description,
    required DateTime? scheduledAt,
  }) {
    if (appointmentId.isEmpty) {
      return;
    }

    final date =
    scheduledAt != null
        ? scheduledAt.day
        .toString()
        .padLeft(2, '0')
        : '';

    final month =
    scheduledAt != null
        ? _monthName(
      scheduledAt.month,
    )
        : '';

    final dayName =
    scheduledAt != null
        ? _dayName(
      scheduledAt.weekday,
    )
        : '';

    final time =
    scheduledAt != null
        ? '${scheduledAt.hour.toString().padLeft(2, '0')}:'
        '${scheduledAt.minute.toString().padLeft(2, '0')}'
        : '';

    final parsed =
    _parseDescription(
      description,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LawyerConsultationDetail(
              appointmentId:
              appointmentId,

              consultationDate:
              date,

              consultationDay:
              dayName,

              consultationMonth:
              month,

              consultationTime:
              time,

              consultationStatus:
              status,

              consultationField:
              parsed['field'] ?? 'Tư vấn pháp luật',

              consultationType:
              parsed['type'] ?? 'Chưa cập nhật',

              customerName:
              clientName,

              customerPhone:
              '',

              customerEmail:
              '',

              consultationContent:
              parsed['content'] ?? description,
            ),
      ),
    );
  }

  // ============================================================
  // DESCRIPTION PARSER
  // ============================================================

  Map<String, String> _parseDescription(
      String description,
      ) {
    if (description.trim().isEmpty) {
      return {
        'field': 'Tư vấn pháp luật',
        'type': 'Chưa cập nhật',
        'content': '',
      };
    }

    String field = 'Tư vấn pháp luật';
    String type = 'Chưa cập nhật';
    String content = description;

    final lower =
    description.toLowerCase();

    if (lower.contains('online')) {
      type = 'Online';
    } else if (lower.contains('trực tiếp')) {
      type = 'Trực tiếp';
    }

    final fieldMatch =
    RegExp(
      r'(?:lĩnh vực|field)\s*:\s*([^|\n]+)',
      caseSensitive: false,
    ).firstMatch(description);

    if (fieldMatch != null) {
      final value =
      fieldMatch.group(1)?.trim();

      if (value != null &&
          value.isNotEmpty) {
        field = value;
      }
    }

    final contentMatch =
    RegExp(
      r'(?:nội dung|message|content)\s*:\s*(.*)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(description);

    if (contentMatch != null) {
      final value =
      contentMatch.group(1)?.trim();

      if (value != null &&
          value.isNotEmpty) {
        content = value;
      }
    }

    return {
      'field': field,
      'type': type,
      'content': content,
    };
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return RefreshIndicator(
      color: _gold,
      onRefresh:
      _loadConsultationRequests,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 70),

          Icon(
            Icons.inbox_outlined,
            size: 58,
            color: _muted,
          ),

          SizedBox(height: 16),

          Center(
            child: Text(
              'Chưa có yêu cầu tư vấn',
              style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),

          SizedBox(height: 6),

          Center(
            child: Text(
              'Các yêu cầu tư vấn sẽ được hiển thị tại đây.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 12),

            const Text(
              'Không thể tải yêu cầu tư vấn',
              style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _error ?? '',
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed:
              _loadConsultationRequests,
              style:
              ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusText(
      String status,
      ) {
    switch (
    status.trim().toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';

      case 'confirmed':
        return 'Đã xác nhận';

      case 'completed':
        return 'Đã hoàn thành';

      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';

      default:
        return status.isNotEmpty
            ? status
            : 'Chưa xác định';
    }
  }

  Color _statusColor(
      String status,
      ) {
    switch (
    status.trim().toLowerCase()) {
      case 'confirmed':
        return const Color(
          0xFF16945D,
        );

      case 'completed':
        return const Color(
          0xFF1476D4,
        );

      case 'cancelled':
      case 'canceled':
        return const Color(
          0xFFD93025,
        );

      default:
        return const Color(
          0xFFC27A15,
        );
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateTime(
      DateTime date,
      int duration,
      ) {
    final start =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    final endDate =
    date.add(
      Duration(
        minutes: duration,
      ),
    );

    final end =
        '${endDate.hour.toString().padLeft(2, '0')}:'
        '${endDate.minute.toString().padLeft(2, '0')}';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  $start - $end';
  }

  String _monthName(
      int month,
      ) {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  String _dayName(
      int weekday,
      ) {
    const days = [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];

    if (weekday < 1 || weekday > 7) {
      return '';
    }

    return days[weekday - 1];
  }
}