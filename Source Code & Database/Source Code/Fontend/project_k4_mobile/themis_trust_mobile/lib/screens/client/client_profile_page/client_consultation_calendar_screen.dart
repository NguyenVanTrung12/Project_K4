import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themis_trust_mobile/services/api_service.dart';

class ClientConsultationCalendarScreen extends StatefulWidget {
  const ClientConsultationCalendarScreen({super.key});

  @override
  State<ClientConsultationCalendarScreen> createState() =>
      _ClientConsultationCalendarScreenState();
}

class _ClientConsultationCalendarScreenState
    extends State<ClientConsultationCalendarScreen> {
  // ============================================================
  // COLORS - đồng bộ ClientProfileScreen
  // ============================================================

  static const Color background = Color(0xFFF7F9FC);
  static const Color darkNavy = Color(0xFF103665);
  static const Color navy = Color(0xFF315A85);
  static const Color gold = Color(0xFFE0AD51);
  static const Color muted = Color(0xFF7A91AA);
  static const Color borderColor = Color(0xFFE1EAF3);

  static const Color green = Color(0xFF1E9B61);
  static const Color red = Color(0xFFC94C5A);
  static const Color orange = Color(0xFFC37A12);
  static const Color purple = Color(0xFF8454AD);

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  String? _errorMessage;

  List<_ClientAppointment> _appointments = [];

  int _selectedTab = 0;

  // ============================================================
  // LIFECYCLE
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

      final userId = prefs.getString('userId');
      final token = prefs.getString('token');

      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _appointments = [];
          _errorMessage = 'Vui lòng đăng nhập để xem lịch tư vấn.';
        });
        return;
      }

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _appointments = [];
          _errorMessage = 'Phiên đăng nhập đã hết hạn.';
        });
        return;
      }

      final api = ApiService();

      /*
       * Endpoint theo backend:
       *
       * GET /api/Appointments
       *
       * Backend tự xác định client hiện tại
       * từ JWT và chỉ trả về các lịch của client đó.
       */
      final result = await api.get('/Appointments', token: token);

      if (result is! List) {
        throw Exception('Dữ liệu lịch tư vấn không hợp lệ.');
      }

      final appointments = result
          .map(
            (item) => _ClientAppointment.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      appointments.sort((a, b) => a.startTime.compareTo(b.startTime));

      if (!mounted) return;

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      String message;

      if (e.statusCode == 401) {
        message = 'Phiên đăng nhập đã hết hạn.';
      } else if (e.statusCode == 403) {
        message = 'Bạn không có quyền xem lịch tư vấn.';
      } else {
        message = e.message.isNotEmpty
            ? e.message
            : 'Không thể tải lịch tư vấn.';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải lịch tư vấn. Vui lòng thử lại.';
      });
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<_ClientAppointment> get _filteredAppointments {
    final now = DateTime.now();

    if (_selectedTab == 0) {
      // Sắp tới
      return _appointments
          .where(
            (item) =>
                item.startTime.isAfter(now) &&
                item.status.toLowerCase() != 'cancelled' &&
                item.status.toLowerCase() != 'completed',
          )
          .toList();
    }

    if (_selectedTab == 1) {
      // Đã hoàn thành
      return _appointments
          .where((item) => item.status.toLowerCase() == 'completed')
          .toList();
    }

    if (_selectedTab == 2) {
      // Đã hủy
      return _appointments
          .where((item) => item.status.toLowerCase() == 'cancelled')
          .toList();
    }

    // Tất cả
    return _appointments;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: gold,
        onRefresh: _loadAppointments,
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,

      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: darkNavy,
          size: 19,
        ),
      ),

      titleSpacing: 0,

      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch tư vấn',
            style: TextStyle(
              color: darkNavy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Lịch hẹn và lịch sử tư vấn của bạn',
            style: TextStyle(
              color: muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),

      actions: [
        IconButton(
          onPressed: _loadAppointments,
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh_rounded, color: navy, size: 22),
        ),

        const SizedBox(width: 6),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: gold, strokeWidth: 2.5),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _buildSummaryCard(),

        const SizedBox(height: 14),

        _buildTabs(),

        const SizedBox(height: 14),

        if (_filteredAppointments.isEmpty)
          _buildEmptyState()
        else
          ..._filteredAppointments.map(
            (appointment) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _buildAppointmentCard(appointment),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard() {
    final upcoming = _appointments.where((item) {
      final status = item.status.toLowerCase();

      return item.startTime.isAfter(DateTime.now()) &&
          status != 'cancelled' &&
          status != 'completed';
    }).length;

    final completed = _appointments
        .where((item) => item.status.toLowerCase() == 'completed')
        .length;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF103665), Color(0xFF315A85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: darkNavy.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0x26FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Lịch tư vấn của tôi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            _appointments.isEmpty
                ? 'Bạn chưa có lịch tư vấn nào.'
                : 'Theo dõi các buổi tư vấn và lịch hẹn của bạn.',
            style: const TextStyle(
              color: Color(0xD9FFFFFF),
              fontSize: 10,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.schedule_rounded,
                  label: 'Sắp tới',
                  value: '$upcoming',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Đã hoàn thành',
                  value: '$completed',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.event_note_outlined,
                  label: 'Tổng lịch',
                  value: '${_appointments.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ITEM
  // ============================================================

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x20FFFFFF)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFFE6AC), size: 17),

          const SizedBox(height: 4),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 7.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    const tabs = ['Sắp tới', 'Đã hoàn thành', 'Đã hủy', 'Tất cả'];

    return Container(
      height: 43,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? darkNavy : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: selected ? Colors.white : muted,
                    fontSize: 9.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // APPOINTMENT CARD
  // ============================================================

  Widget _buildAppointmentCard(_ClientAppointment appointment) {
    final status = _getStatusConfig(appointment.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DATE / TIME
                _buildDateTimeBox(appointment),

                const SizedBox(width: 12),

                // CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              appointment.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: darkNavy,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          _buildStatusChip(status),
                        ],
                      ),

                      const SizedBox(height: 7),

                      _buildInfoRow(
                        Icons.person_outline_rounded,
                        appointment.lawyerName.isEmpty
                            ? 'Luật sư'
                            : appointment.lawyerName,
                      ),

                      const SizedBox(height: 5),

                      if (appointment.location.isNotEmpty)
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          appointment.location,
                        ),

                      if (appointment.notes.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _buildInfoRow(Icons.notes_rounded, appointment.notes),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 11),

            Container(height: 1, color: const Color(0xFFF0F3F7)),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: muted,
                  size: 15,
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    _formatTimeRange(
                      appointment.startTime,
                      appointment.endTime,
                    ),
                    style: const TextStyle(
                      color: navy,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // ========================================================
                // CHỈ HIỂN THỊ KHI PENDING
                // ========================================================

                if (appointment.status.toLowerCase() ==
                    'pending')
                  OutlinedButton.icon(
                    onPressed: () {
                      _cancelAppointment(
                        appointment,
                      );
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 13,
                    ),
                    label: const Text(
                      'Hủy lịch',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                      const Color(0xFFC94C5A),
                      side: const BorderSide(
                        color: Color(0xFFF1C5CB),
                      ),
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE TIME BOX
  // ============================================================

  Widget _buildDateTimeBox(_ClientAppointment appointment) {
    final date = appointment.startTime;

    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E3),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFF0D8A8)),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: const TextStyle(
              color: darkNavy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'THÁNG $month',
            style: const TextStyle(
              color: gold,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Container(width: 32, height: 1, color: const Color(0xFFE7D4AE)),

          const SizedBox(height: 6),

          Text(
            _formatTime(date),
            style: const TextStyle(
              color: navy,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: muted, size: 14),

        const SizedBox(width: 5),

        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 9, height: 1.3),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(_StatusConfig status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: status.dotColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 4),

          Text(
            status.text,
            style: TextStyle(
              color: status.textColor,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  //cancelled appointment//
  Future<void> _cancelAppointment(_ClientAppointment appointment) async {
    final confirmed = await _showCancelDialog(appointment);

    if (!confirmed) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showMessage('Phiên đăng nhập đã hết hạn.', isError: true);
        return;
      }

      if (!mounted) return;

      _showLoadingDialog();

      final api = ApiService();

      await api.patch(
        '/Appointments/${appointment.id}/status',
        token: token,
        body: {'status': 'cancelled'},
      );

      if (!mounted) return;

      Navigator.pop(context);

      _showMessage('Đã hủy lịch tư vấn thành công.');

      await _loadAppointments();
    } on ApiException catch (e) {
      if (!mounted) return;

      // Nếu loading dialog đang mở
      Navigator.of(context).pop();

      String message;

      if (e.statusCode == 400) {
        message = e.message.isNotEmpty
            ? e.message
            : 'Không thể hủy lịch tư vấn.';
      } else if (e.statusCode == 403) {
        message = 'Bạn không có quyền hủy lịch tư vấn này.';
      } else if (e.statusCode == 404) {
        message = 'Không tìm thấy lịch tư vấn.';
      } else {
        message = 'Không thể hủy lịch tư vấn. Vui lòng thử lại.';
      }

      _showMessage(message, isError: true);
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context).pop();

      _showMessage(
        'Không thể hủy lịch tư vấn. Vui lòng thử lại.',
        isError: true,
      );
    }
  }

  //popup hủy//
  Future<bool> _showCancelDialog(
      _ClientAppointment appointment,
      ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ICON
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEEF0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: Color(0xFFC94C5A),
                    size: 28,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Hủy lịch tư vấn?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: darkNavy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  'Bạn có chắc chắn muốn hủy lịch '
                      'tư vấn này không?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 12),

                // APPOINTMENT INFO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius:
                    BorderRadius.circular(11),
                    border: Border.all(
                      color: borderColor,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        appointment.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkNavy,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _formatTimeRange(
                          appointment.startTime,
                          appointment.endTime,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (appointment.lawyerName
                          .isNotEmpty) ...[
                        const SizedBox(height: 4),

                        Text(
                          'Luật sư: ${appointment.lawyerName}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 11),

                const Text(
                  'Sau khi hủy, lịch sẽ chuyển sang trạng thái '
                      '"Đã hủy".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9AA9B8),
                    fontSize: 8.5,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 19),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: navy,
                          side: const BorderSide(
                            color: borderColor,
                          ),
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Giữ lại',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            true,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFFC94C5A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Hủy lịch',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  //loading popup//
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 24,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: gold,
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(width: 15),
                Text(
                  'Đang hủy lịch...',
                  style: TextStyle(
                    color: darkNavy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFC94C5A)
            : const Color(0xFF1E9B61),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        duration: const Duration(
          seconds: 2,
        ),
      ),
    );
  }
  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    String title = 'Chưa có lịch tư vấn';

    String subtitle = 'Các lịch tư vấn của bạn sẽ xuất hiện tại đây.';

    if (_selectedTab == 0) {
      title = 'Không có lịch tư vấn sắp tới';
      subtitle = 'Bạn hiện không có buổi tư vấn nào sắp diễn ra.';
    } else if (_selectedTab == 1) {
      title = 'Chưa có lịch đã hoàn thành';
      subtitle = 'Các buổi tư vấn đã hoàn thành sẽ hiển thị tại đây.';
    } else if (_selectedTab == 2) {
      title = 'Chưa có lịch đã hủy';
      subtitle = 'Bạn chưa có lịch tư vấn nào bị hủy.';
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF5E3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: gold,
              size: 28,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkNavy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 9.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),

        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEEF0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: red,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Không thể tải lịch tư vấn',
                  style: TextStyle(
                    color: darkNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _errorMessage ?? 'Đã xảy ra lỗi không xác định.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _loadAppointments,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
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
  // STATUS
  // ============================================================

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const _StatusConfig(
          text: 'Đã xác nhận',
          backgroundColor: Color(0xFFDFF5E9),
          textColor: green,
          dotColor: Color(0xFF18A96D),
        );

      case 'completed':
        return const _StatusConfig(
          text: 'Đã hoàn thành',
          backgroundColor: Color(0xFFE8EEF5),
          textColor: navy,
          dotColor: navy,
        );

      case 'cancelled':
        return const _StatusConfig(
          text: 'Đã hủy',
          backgroundColor: Color(0xFFFFE7EA),
          textColor: red,
          dotColor: red,
        );

      case 'pending':
      default:
        return const _StatusConfig(
          text: 'Chờ xác nhận',
          backgroundColor: Color(0xFFFFEBCB),
          textColor: orange,
          dotColor: Color(0xFFD48A19),
        );
    }
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');

    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final date = _formatDate(start);

    return '$date • ${_formatTime(start)} - ${_formatTime(end)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    return '$day/$month/$year';
  }
}

// =================================================================
// APPOINTMENT MODEL
// =================================================================

class _ClientAppointment {
  final String id;

  final String title;

  final String lawyerName;

  final String status;

  final String location;

  final String notes;

  final DateTime startTime;

  final DateTime endTime;

  const _ClientAppointment({
    required this.id,
    required this.title,
    required this.lawyerName,
    required this.status,
    required this.location,
    required this.notes,
    required this.startTime,
    required this.endTime,
  });

  factory _ClientAppointment.fromJson(Map<String, dynamic> json) {
    return _ClientAppointment(
      id: json['id']?.toString() ?? '',

      title: _firstString(json, [
        'title',
        'subject',
        'serviceName',
        'consultationType',
        'type',
      ], fallback: 'Lịch tư vấn'),

      lawyerName: _firstString(json, [
        'lawyerName',
        'lawyerFullName',
        'lawyer',
      ]),

      status: json['status']?.toString() ?? 'pending',

      location: _firstString(json, ['location', 'meetingLocation', 'address']),

      notes: _firstString(json, ['notes', 'note', 'description']),

      startTime: _parseDate(json, [
        'startTime',
        'startAt',
        'scheduledAt',
        'appointmentDate',
      ]),

      endTime: _parseDate(json, ['endTime', 'endAt']),
    );
  }

  static String _firstString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  static DateTime _parseDate(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];

      if (value == null) continue;

      final parsed = DateTime.tryParse(value.toString());

      if (parsed != null) {
        return parsed.toLocal();
      }
    }

    return DateTime.now();
  }
}

// =================================================================
// STATUS CONFIG
// =================================================================

class _StatusConfig {
  final String text;

  final Color backgroundColor;

  final Color textColor;

  final Color dotColor;

  const _StatusConfig({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.dotColor,
  });
}
