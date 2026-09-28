import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:themis_trust_mobile/screens/lawyer/lawyer_consultation_page/lawyer_consultation_detail.dart';
import 'package:themis_trust_mobile/services/api_service.dart';

class LawyerConsultationCalendar extends StatefulWidget {
  const LawyerConsultationCalendar({
    super.key,
  });

  @override
  State<LawyerConsultationCalendar> createState() =>
      _LawyerConsultationCalendarState();
}

class _LawyerConsultationCalendarState
    extends State<LawyerConsultationCalendar> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF0D3558);
  static const Color darkNavy = Color(0xFF092E50);
  static const Color gold = Color(0xFFC78A2C);
  static const Color muted = Color(0xFF71839A);
  static const Color border = Color(0xFFE2E9F0);
  static const Color background = Color(0xFFF7F9FC);

  // ============================================================
  // API
  // ============================================================

  final ApiService _api = ApiService();

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;

  String? _errorMessage;

  List<_AppointmentItem> _appointments = [];

  // 0 = TẤT CẢ
  // 1 = SẮP TỚI
  // 2 = ĐÃ DIỄN RA
  // 3 = ĐÃ HỦY
  int _selectedTab = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadAppointments();
  }

  // ============================================================
  // LOAD APPOINTMENTS
  // ============================================================

  Future<void> _loadAppointments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception(
          'Không tìm thấy token đăng nhập.',
        );
      }

      debugPrint(
        '================================================',
      );

      debugPrint(
        'LOAD LAWYER APPOINTMENTS',
      );

      debugPrint(
        'GET /api/Appointments',
      );

      debugPrint(
        '================================================',
      );

      final data = await _api.get(
        '/Appointments',
        token: token,
      );

      debugPrint(
        'APPOINTMENTS RESPONSE: $data',
      );

      if (data is! List) {
        throw Exception(
          'Dữ liệu lịch hẹn không hợp lệ.',
        );
      }

      final List<_AppointmentItem> appointments = [];

      for (final item in data) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        try {
          final appointment =
          _AppointmentItem.fromJson(item);

          appointments.add(appointment);

          debugPrint(
            'Appointment ${appointment.id} '
                '=> status=${appointment.status}',
          );
        } catch (e) {
          debugPrint(
            'Không thể đọc appointment: $e',
          );
        }
      }

      // ========================================================
      // SORT
      // ========================================================

      appointments.sort(
            (a, b) => a.scheduledAt.compareTo(
          b.scheduledAt,
        ),
      );

      if (!mounted) return;

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });

      debugPrint(
        'TOTAL APPOINTMENTS: ${appointments.length}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'LOAD APPOINTMENTS ERROR: $e',
      );

      debugPrint(
        'STACK TRACE: $stackTrace',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _getErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('401')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (message.contains('403')) {
      return 'Bạn không có quyền xem danh sách lịch tư vấn.';
    }

    if (message.contains('404')) {
      return 'Không tìm thấy API lịch tư vấn.';
    }

    return 'Không thể tải danh sách lịch tư vấn.';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: RefreshIndicator(
        color: gold,
        onRefresh: _loadAppointments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            10,
            8,
            10,
            20,
          ),
          child: Column(
            children: [
              // ==================================================
              // TITLE
              // ==================================================

              _buildTitle(),

              const SizedBox(height: 12),

              // ==================================================
              // TABS
              // ==================================================

              _buildConsultationTabs(),

              const SizedBox(height: 12),

              // ==================================================
              // LIST
              // ==================================================

              _isLoading
                  ? _buildLoading()
                  : _buildConsultationList(),

              const SizedBox(height: 12),

              // ==================================================
              // STATISTICS
              // ==================================================

              _buildStatisticsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lịch tư vấn',
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'Quản lý lịch hẹn và sắp xếp thời gian làm việc hiệu quả',
                style: TextStyle(
                  color: muted,
                  fontSize: 8.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        GestureDetector(
          onTap: _addConsultation,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
            ),
            decoration: BoxDecoration(
              color: gold,
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.15),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 15,
                ),

                SizedBox(width: 4),

                Text(
                  'Thêm lịch tư vấn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildConsultationTabs() {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(
            index: 0,
            title: 'Tất cả',
            icon: Icons.list_alt_rounded,
          ),

          _buildTabItem(
            index: 1,
            title: 'Sắp tới',
            icon: Icons.schedule_rounded,
          ),

          _buildTabItem(
            index: 2,
            title: 'Đã diễn ra',
            icon: Icons.history_rounded,
          ),

          _buildTabItem(
            index: 3,
            title: 'Đã hủy',
            icon: Icons.event_busy_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final bool selected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: 2,
          ),
          decoration: BoxDecoration(
            color: selected
                ? darkNavy
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? Colors.white
                    : navy,
              ),

              const SizedBox(width: 5),

              Text(
                title,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NORMALIZE STATUS
  // ============================================================

  String _normalizeStatus(String status) {
    final value = status.trim().toLowerCase();

    switch (value) {
      case 'pending':
      case 'chờ xác nhận':
        return 'pending';

      case 'confirmed':
      case 'đã xác nhận':
        return 'confirmed';

      case 'completed':
      case 'complete':
      case 'hoàn thành':
      case 'đã hoàn thành':
        return 'completed';

      case 'cancelled':
      case 'canceled':
      case 'đã hủy':
      case 'đã huỷ':
        return 'cancelled';

      default:
        return value;
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<_AppointmentItem> _getFilteredAppointments() {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final threeDaysLater =
    today.add(
      const Duration(days: 3),
    );

    // ========================================================
    // TẤT CẢ
    // ========================================================

    if (_selectedTab == 0) {
      return List<_AppointmentItem>.from(
        _appointments,
      );
    }

    // ========================================================
    // SẮP TỚI
    // ========================================================

    if (_selectedTab == 1) {
      return _appointments.where((item) {
        final date = item.scheduledAt;

        final status =
        _normalizeStatus(item.status);

        return !date.isBefore(today) &&
            date.isBefore(threeDaysLater) &&
            status != 'cancelled' &&
            status != 'completed';
      }).toList();
    }

    // ========================================================
    // ĐÃ DIỄN RA
    // ========================================================

    if (_selectedTab == 2) {
      return _appointments.where((item) {
        final status =
        _normalizeStatus(item.status);

        // Nếu backend đã chuyển sang completed
        // thì chắc chắn đưa vào Đã diễn ra.
        if (status == 'completed') {
          return true;
        }

        // Nếu thời gian đã qua thì cũng xem là đã diễn ra.
        return item.scheduledAt.isBefore(now) &&
            status != 'cancelled';
      }).toList();
    }

    // ========================================================
    // ĐÃ HỦY
    // ========================================================

    if (_selectedTab == 3) {
      return _appointments.where((item) {
        final status =
        _normalizeStatus(item.status);

        return status == 'cancelled';
      }).toList();
    }

    return [];
  }

  // ============================================================
  // CONSULTATION LIST
  // ============================================================

  Widget _buildConsultationList() {
    final appointments =
    _getFilteredAppointments();

    if (appointments.isEmpty) {
      return _buildEmptyList();
    }

    return Column(
      children: [
        // ======================================================
        // HEADER
        // ======================================================

        Row(
          children: [
            const Icon(
              Icons.event_note_rounded,
              color: gold,
              size: 19,
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Text(
                _getListTitle(),
                style: const TextStyle(
                  color: darkNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            Text(
              '${appointments.length} lịch',
              style: const TextStyle(
                color: muted,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        // ======================================================
        // ITEMS
        // ======================================================

        ...appointments.map(
              (item) => Padding(
            padding: const EdgeInsets.only(
              bottom: 7,
            ),
            child: _buildConsultationListItem(
              item,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LIST TITLE
  // ============================================================

  String _getListTitle() {
    switch (_selectedTab) {
      case 1:
        return 'Lịch tư vấn sắp tới';

      case 2:
        return 'Lịch tư vấn đã diễn ra';

      case 3:
        return 'Lịch tư vấn đã hủy';

      default:
        return 'Tất cả lịch tư vấn';
    }
  }

  // ============================================================
  // LIST ITEM
  // ============================================================

  Widget _buildConsultationListItem(
      _AppointmentItem item,
      ) {
    final colors =
    _getStatusColors(item.status);

    final normalizedStatus =
    _normalizeStatus(item.status);

    final bool isUpcoming =
        item.scheduledAt.isAfter(
          DateTime.now(),
        ) &&
            normalizedStatus != 'completed' &&
            normalizedStatus != 'cancelled';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () {
          _openConsultationDetail(item);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              // =================================================
              // DATE / TIME
              // =================================================

              Container(
                width: 58,
                padding:
                const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? const Color(0xFFFFF4E3)
                      : const Color(0xFFF0F4F8),
                  borderRadius:
                  BorderRadius.circular(7),
                ),
                child: Column(
                  children: [
                    Text(
                      _getShortWeekDay(
                        item.scheduledAt,
                      ),
                      style: TextStyle(
                        color: isUpcoming
                            ? gold
                            : muted,
                        fontSize: 7,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${item.scheduledAt.day}',
                      style: TextStyle(
                        color: isUpcoming
                            ? darkNavy
                            : navy,
                        fontSize: 19,
                        fontWeight:
                        FontWeight.w800,
                        height: 1,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Th${item.scheduledAt.month}',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 6.5,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Container(
                      height: 1,
                      width: 28,
                      color: isUpcoming
                          ? const Color(0xFFE8D3AE)
                          : border,
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _formatTime(
                        item.scheduledAt,
                      ),
                      style: TextStyle(
                        color: isUpcoming
                            ? navy
                            : muted,
                        fontSize: 8,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // =================================================
              // INFORMATION
              // =================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // ===========================================
                    // NAME + STATUS
                    // ===========================================

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.clientName,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: darkNavy,
                              fontSize: 10,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                            colors.background,
                            borderRadius:
                            BorderRadius.circular(
                              5,
                            ),
                          ),
                          child: Text(
                            _getStatusText(
                              item.status,
                            ),
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 6.5,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // ===========================================
                    // TIME
                    // ===========================================

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: muted,
                          size: 13,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          _formatTime(
                            item.scheduledAt,
                          ),
                          style: const TextStyle(
                            color: navy,
                            fontSize: 8,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Container(
                          width: 3,
                          height: 3,
                          decoration:
                          const BoxDecoration(
                            color: border,
                            shape:
                            BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Text(
                          '${item.durationMin} phút',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 7,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // ===========================================
                    // DESCRIPTION
                    // ===========================================

                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons
                              .description_outlined,
                          color: muted,
                          size: 12,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            item.description ??
                                'Lịch tư vấn pháp luật',
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 7,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              // =================================================
              // ARROW
              // =================================================

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF1675D1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyList() {
    String title;

    String subtitle;

    switch (_selectedTab) {
      case 1:
        title = 'Không có lịch tư vấn sắp tới';
        subtitle =
        'Trong 3 ngày gần nhất chưa có lịch tư vấn nào.';
        break;

      case 2:
        title = 'Chưa có lịch đã diễn ra';
        subtitle =
        'Các lịch tư vấn đã qua sẽ xuất hiện tại đây.';
        break;

      case 3:
        title = 'Chưa có lịch đã hủy';
        subtitle =
        'Các lịch tư vấn bị hủy sẽ xuất hiện tại đây.';
        break;

      default:
        title = 'Chưa có lịch tư vấn';
        subtitle =
        'Danh sách lịch tư vấn của bạn đang trống.';
    }

    if (_errorMessage != null) {
      subtitle = _errorMessage!;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: muted,
              size: 29,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkNavy,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 7.5,
              height: 1.4,
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _loadAppointments,
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius:
                  BorderRadius.circular(6),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: border,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: gold,
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatisticsCard() {
    final now = DateTime.now();

    // ==========================================================
    // SẮP TỚI
    // ==========================================================

    final upcomingCount =
        _appointments.where((appointment) {
          final status =
          _normalizeStatus(
            appointment.status,
          );

          return appointment.scheduledAt
              .isAfter(now) &&
              status != 'cancelled' &&
              status != 'completed';
        }).length;

    // ==========================================================
    // ĐÃ DIỄN RA
    // ==========================================================

    final completedCount =
        _appointments.where((appointment) {
          final status =
          _normalizeStatus(
            appointment.status,
          );

          return status == 'completed' ||
              (
                  appointment.scheduledAt
                      .isBefore(now) &&
                      status != 'cancelled'
              );
        }).length;

    // ==========================================================
    // ĐÃ HỦY
    // ==========================================================

    final cancelledCount =
        _appointments.where((appointment) {
          final status =
          _normalizeStatus(
            appointment.status,
          );

          return status == 'cancelled';
        }).length;

    // ==========================================================
    // CARD
    // ==========================================================

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF2E2C7),
        ),
      ),
      child: Row(
        children: [
          // Tổng
          _buildStatisticItem(
            icon: Icons.calendar_month_rounded,
            value: '${_appointments.length}',
            label: 'Tổng lịch',
          ),

          _buildStatisticDivider(),

          // Sắp tới
          _buildStatisticItem(
            icon: Icons.schedule_rounded,
            value: '$upcomingCount',
            label: 'Sắp tới',
          ),

          _buildStatisticDivider(),

          // Đã diễn ra
          _buildStatisticItem(
            icon: Icons.history_rounded,
            value: '$completedCount',
            label: 'Đã diễn ra',
          ),

          _buildStatisticDivider(),

          // Đã hủy
          _buildStatisticItem(
            icon: Icons.event_busy_rounded,
            value: '$cancelledCount',
            label: 'Đã hủy',
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: gold,
            size: 19,
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              color: darkNavy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 6.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE9DCC8),
    );
  }

  // ============================================================
  // ADD
  // ============================================================

  void _addConsultation() {
    _showMessage(
      'Mở form thêm lịch tư vấn',
    );
  }

  // ============================================================
  // OPEN DETAIL
  // ============================================================

  Future<void> _openConsultationDetail(
      _AppointmentItem appointment,
      ) async {
    // ==========================================================
    // MỞ TRANG CHI TIẾT
    // ==========================================================

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LawyerConsultationDetail(
              appointmentId:
              appointment.id,

              consultationDate:
              appointment.scheduledAt.day
                  .toString(),

              consultationDay:
              _getVietnameseWeekday(
                appointment.scheduledAt,
              ),

              consultationMonth:
              'Tháng ${appointment.scheduledAt.month}, '
                  '${appointment.scheduledAt.year}',

              consultationTime:
              _formatAppointmentTime(
                appointment.scheduledAt,
                appointment.durationMin,
              ),

              consultationStatus:
              appointment.status,

              consultationField:
              'Tư vấn pháp lý',

              consultationType:
              'Tư vấn trực tiếp',

              customerName:
              appointment.clientName,

              customerPhone:
              '',

              customerEmail:
              '',

              consultationContent:
              appointment.description ?? '',
            ),
      ),
    );

    // ==========================================================
    // QUAN TRỌNG:
    // KHI QUAY LẠI TỪ DETAIL
    // GỌI LẠI API ĐỂ LẤY STATUS MỚI
    // ==========================================================

    if (!mounted) return;

    debugPrint(
      '================================================',
    );

    debugPrint(
      'RETURN FROM CONSULTATION DETAIL',
    );

    debugPrint(
      'RELOAD APPOINTMENTS',
    );

    debugPrint(
      '================================================',
    );

    await _loadAppointments();
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  String _getStatusText(String status) {
    switch (_normalizeStatus(status)) {
      case 'pending':
        return 'Chờ xác nhận';

      case 'confirmed':
        return 'Đã xác nhận';

      case 'completed':
        return 'Đã hoàn thành';

      case 'cancelled':
        return 'Đã hủy';

      default:
        return status;
    }
  }

  // ============================================================
  // STATUS COLORS
  // ============================================================

  _StatusColors _getStatusColors(
      String status,
      ) {
    switch (_normalizeStatus(status)) {
    // ========================================================
    // CONFIRMED
    // ========================================================

      case 'confirmed':
        return const _StatusColors(
          background: Color(0xFFDFF5E9),
          text: Color(0xFF1E9B61),
          dot: Color(0xFF18A96D),
        );

    // ========================================================
    // COMPLETED
    // ========================================================

      case 'completed':
        return const _StatusColors(
          background: Color(0xFFE6F0FF),
          text: Color(0xFF2872C7),
          dot: Color(0xFF2872C7),
        );

    // ========================================================
    // CANCELLED
    // ========================================================

      case 'cancelled':
        return const _StatusColors(
          background: Color(0xFFFFE7EA),
          text: Color(0xFFB53C4C),
          dot: Color(0xFFB53C4C),
        );

    // ========================================================
    // PENDING
    // ========================================================

      case 'pending':
      default:
        return const _StatusColors(
          background: Color(0xFFFFEBCB),
          text: Color(0xFFC37A12),
          dot: Color(0xFFD48A19),
        );
    }
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  String _formatTime(
      DateTime dateTime,
      ) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatAppointmentTime(
      DateTime start,
      int durationMin,
      ) {
    final end = start.add(
      Duration(
        minutes: durationMin,
      ),
    );

    String formatTime(
        DateTime time,
        ) {
      final hour =
      time.hour.toString().padLeft(2, '0');

      final minute =
      time.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    }

    return '${formatTime(start)} - '
        '${formatTime(end)}';
  }

  String _getVietnameseWeekday(
      DateTime date,
      ) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Thứ 2';

      case DateTime.tuesday:
        return 'Thứ 3';

      case DateTime.wednesday:
        return 'Thứ 4';

      case DateTime.thursday:
        return 'Thứ 5';

      case DateTime.friday:
        return 'Thứ 6';

      case DateTime.saturday:
        return 'Thứ 7';

      case DateTime.sunday:
        return 'Chủ nhật';

      default:
        return '';
    }
  }

  String _getShortWeekDay(
      DateTime date,
      ) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'THỨ 2';

      case DateTime.tuesday:
        return 'THỨ 3';

      case DateTime.wednesday:
        return 'THỨ 4';

      case DateTime.thursday:
        return 'THỨ 5';

      case DateTime.friday:
        return 'THỨ 6';

      case DateTime.saturday:
        return 'THỨ 7';

      default:
        return 'CHỦ NHẬT';
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        duration:
        const Duration(seconds: 1),
      ),
    );
  }
}

// =================================================================
// APPOINTMENT MODEL
// =================================================================

class _AppointmentItem {
  final String id;

  final String clientId;

  final String clientName;

  final String lawyerId;

  final String lawyerName;

  final String? caseId;

  final DateTime scheduledAt;

  final int durationMin;

  final String status;

  final String? description;

  const _AppointmentItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.lawyerId,
    required this.lawyerName,
    required this.scheduledAt,
    required this.durationMin,
    required this.status,
    this.caseId,
    this.description,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory _AppointmentItem.fromJson(
      Map<String, dynamic> json,
      ) {
    final scheduledAtString =
    json['scheduledAt']?.toString();

    if (scheduledAtString == null ||
        scheduledAtString.isEmpty) {
      throw Exception(
        'Appointment không có scheduledAt',
      );
    }

    final scheduledAt =
    DateTime.tryParse(
      scheduledAtString,
    );

    if (scheduledAt == null) {
      throw Exception(
        'scheduledAt không hợp lệ: '
            '$scheduledAtString',
      );
    }

    final status =
        json['status']?.toString() ??
            'pending';

    debugPrint(
      'PARSE APPOINTMENT: '
          'id=${json['id']} '
          'status=$status',
    );

    return _AppointmentItem(
      id:
      json['id']?.toString() ??
          '',

      clientId:
      json['clientId']?.toString() ??
          '',

      clientName:
      json['clientName']?.toString() ??
          'Khách hàng',

      lawyerId:
      json['lawyerId']?.toString() ??
          '',

      lawyerName:
      json['lawyerName']?.toString() ??
          'Luật sư',

      caseId:
      json['caseId']?.toString(),

      scheduledAt:
      scheduledAt.toLocal(),

      durationMin:
      int.tryParse(
        json['durationMin']
            ?.toString() ??
            '30',
      ) ??
          30,

      status:
      status,

      description:
      json['description']?.toString(),
    );
  }
}

// =================================================================
// STATUS COLORS
// =================================================================

class _StatusColors {
  final Color background;

  final Color text;

  final Color dot;

  const _StatusColors({
    required this.background,
    required this.text,
    required this.dot,
  });
}