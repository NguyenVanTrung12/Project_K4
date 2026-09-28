import 'package:flutter/material.dart';

import 'package:themis_trust_mobile/services/api_service.dart';

class LawyerConsultationDetail extends StatefulWidget {
  final String appointmentId;

  final String consultationDate;
  final String consultationDay;
  final String consultationMonth;
  final String consultationTime;
  final String consultationStatus;
  final String consultationField;
  final String consultationType;

  final String customerName;
  final String customerPhone;
  final String customerEmail;

  final String consultationContent;

  const LawyerConsultationDetail({
    super.key,
    required this.appointmentId,
    required this.consultationDate,
    required this.consultationDay,
    required this.consultationMonth,
    required this.consultationTime,
    required this.consultationStatus,
    required this.consultationField,
    required this.consultationType,
    required this.customerName,
    this.customerPhone = '',
    this.customerEmail = '',
    this.consultationContent = '',
  });

  @override
  State<LawyerConsultationDetail> createState() =>
      _LawyerConsultationDetailState();
}

class _LawyerConsultationDetailState
    extends State<LawyerConsultationDetail> {
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

  late String _status;

  String _customerName = '';
  String _customerPhone = '';
  String _customerEmail = '';

  bool _isLoadingCustomer = false;
  bool _isUpdatingStatus = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Lấy dữ liệu được truyền từ màn hình trước trước.
    _status = widget.consultationStatus;

    _customerName = widget.customerName;
    _customerPhone = widget.customerPhone;
    _customerEmail = widget.customerEmail;

    // Sau đó lấy dữ liệu mới nhất từ backend.
    _loadAppointmentData();
  }

  // ============================================================
  // LOAD APPOINTMENT DATA
  //
  // GET /api/appointments
  //
  // Không gọi:
  // GET /api/users/{clientId}
  //
  // Vì AppointmentDto đã trả trực tiếp:
  // clientName
  // clientPhone
  // clientEmail
  // ============================================================

  Future<void> _loadAppointmentData() async {
    if (widget.appointmentId.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingCustomer = true;
    });

    try {
      final result = await _api.get('/appointments');

      if (result is! List) {
        debugPrint(
          'GET /appointments không trả về List.',
        );
        return;
      }

      Map<String, dynamic>? appointment;

      for (final item in result) {
        if (item is! Map) {
          continue;
        }

        final map = Map<String, dynamic>.from(item);

        final id = map['id']?.toString() ?? '';

        if (id == widget.appointmentId) {
          appointment = map;
          break;
        }
      }

      if (appointment == null) {
        debugPrint(
          'Không tìm thấy appointment: ${widget.appointmentId}',
        );
        return;
      }

      // ========================================================
      // LẤY CLIENT
      // ========================================================

      final clientName =
          appointment['clientName']?.toString().trim() ?? '';

      final clientPhone =
          appointment['clientPhone']?.toString().trim() ?? '';

      final clientEmail =
          appointment['clientEmail']?.toString().trim() ?? '';

      // ========================================================
      // LẤY STATUS
      // ========================================================

      final appointmentStatus =
          appointment['status']?.toString().trim() ?? '';

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint(
        '===========================================',
      );

      debugPrint(
        'APPOINTMENT DETAIL',
      );

      debugPrint(
        'Appointment ID: ${appointment['id']}',
      );

      debugPrint(
        'Client ID: ${appointment['clientId']}',
      );

      debugPrint(
        'Client Name: $clientName',
      );

      debugPrint(
        'Client Phone: $clientPhone',
      );

      debugPrint(
        'Client Email: $clientEmail',
      );

      debugPrint(
        'Lawyer ID: ${appointment['lawyerId']}',
      );

      debugPrint(
        'Lawyer Name: ${appointment['lawyerName']}',
      );

      debugPrint(
        'Status: $appointmentStatus',
      );

      debugPrint(
        '===========================================',
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // UPDATE UI
      // ========================================================

      setState(() {
        if (clientName.isNotEmpty) {
          _customerName = clientName;
        }

        if (clientPhone.isNotEmpty) {
          _customerPhone = clientPhone;
        }

        if (clientEmail.isNotEmpty) {
          _customerEmail = clientEmail;
        }

        if (appointmentStatus.isNotEmpty) {
          _status = appointmentStatus;
        }
      });
    } on ApiException catch (e) {
      debugPrint(
        'Load appointment detail ApiException: '
            '${e.statusCode} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      // Không xoá dữ liệu đã có từ màn hình trước.
    } catch (e) {
      debugPrint(
        'Load appointment detail error: $e',
      );

      if (!mounted) {
        return;
      }

      // Không chặn giao diện.
      // Dữ liệu được truyền từ màn hình trước vẫn được giữ.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCustomer = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  24,
                ),
                child: Column(
                  children: [
                    _buildAppointmentOverview(),

                    const SizedBox(height: 12),

                    _buildCustomerSection(),

                    const SizedBox(height: 12),

                    _buildConsultationContent(),

                    const SizedBox(height: 12),

                    _buildAppointmentInformation(),
                  ],
                ),
              ),
            ),

            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 62,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: border,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),

          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: border,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: navy,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch hẹn',
                  style: TextStyle(
                    color: darkNavy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '#${widget.appointmentId}',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          _buildHeaderStatus(),

          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER STATUS
  // ============================================================

  Widget _buildHeaderStatus() {
    final status = _status.trim().toLowerCase();

    Color color;
    Color backgroundColor;
    IconData icon;

    if (status == 'cancelled' ||
        status == 'canceled' ||
        status == 'đã hủy') {
      color = const Color(0xFFD93025);
      backgroundColor = const Color(0xFFFFE9E9);
      icon = Icons.cancel_rounded;
    } else if (status == 'confirmed' ||
        status == 'đã xác nhận') {
      color = const Color(0xFF16945D);
      backgroundColor = const Color(0xFFE5F7EE);
      icon = Icons.check_circle_rounded;
    } else if (status == 'completed' ||
        status == 'đã hoàn thành') {
      color = const Color(0xFF1476D4);
      backgroundColor = const Color(0xFFE8F3FF);
      icon = Icons.task_alt_rounded;
    } else {
      color = const Color(0xFFC27A15);
      backgroundColor = const Color(0xFFFFF0DA);
      icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),

          const SizedBox(width: 5),

          Text(
            _getStatusText(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPOINTMENT OVERVIEW
  // ============================================================

  Widget _buildAppointmentOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080D3558),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateCard(),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: gold,
                      size: 18,
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        widget.consultationTime,
                        style: const TextStyle(
                          color: darkNavy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _buildInfoLine(
                  icon: Icons.calendar_month_rounded,
                  text: widget.consultationMonth,
                ),

                const SizedBox(height: 8),

                _buildInfoLine(
                  icon: Icons.gavel_rounded,
                  text: widget.consultationField,
                ),

                const SizedBox(height: 8),

                _buildInfoLine(
                  icon: Icons.location_on_outlined,
                  text: widget.consultationType,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE CARD
  // ============================================================

  Widget _buildDateCard() {
    return Container(
      width: 92,
      height: 98,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFF2E3CB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 29,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: gold,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Text(
              widget.consultationDay,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            widget.consultationDate,
            style: const TextStyle(
              color: darkNavy,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            widget.consultationMonth,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: muted,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO LINE
  // ============================================================

  Widget _buildInfoLine({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: muted,
          size: 15,
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            text.isNotEmpty
                ? text
                : 'Chưa cập nhật',
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CUSTOMER SECTION
  // ============================================================

  Widget _buildCustomerSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.person_outline_rounded,
            title: 'Thông tin khách hàng',
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: border,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildCustomerAvatar(),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            _customerName.isNotEmpty
                                ? _customerName
                                : 'Chưa cập nhật',
                            style: const TextStyle(
                              color: darkNavy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 5),

                          const Text(
                            'Khách hàng đặt lịch tư vấn',
                            style: TextStyle(
                              color: muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isLoadingCustomer)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: gold,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                const Divider(
                  height: 1,
                  color: border,
                ),

                const SizedBox(height: 12),

                _buildCustomerInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Số điện thoại',
                  value: _customerPhone,
                ),

                const SizedBox(height: 10),

                _buildCustomerInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _customerEmail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER AVATAR
  // ============================================================

  Widget _buildCustomerAvatar() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFE6ECF2),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFD8E0E8),
        ),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF8292A3),
        size: 31,
      ),
    );
  }

  // ============================================================
  // CUSTOMER INFO ROW
  // ============================================================

  Widget _buildCustomerInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            color: navy,
            size: 16,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: muted,
                  fontSize: 9,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value.isNotEmpty
                    ? value
                    : 'Chưa cập nhật',
                style: const TextStyle(
                  color: darkNavy,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONSULTATION CONTENT
  // ============================================================

  Widget _buildConsultationContent() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.description_outlined,
            title: 'Nội dung tư vấn',
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: border,
              ),
            ),
            child: Text(
              widget.consultationContent.isNotEmpty
                  ? widget.consultationContent
                  : 'Khách hàng chưa cung cấp nội dung tư vấn.',
              style: const TextStyle(
                color: Color(0xFF536B84),
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPOINTMENT INFORMATION
  // ============================================================

  Widget _buildAppointmentInformation() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.event_note_outlined,
            title: 'Thông tin lịch hẹn',
          ),

          const SizedBox(height: 12),

          _buildDetailRow(
            label: 'Mã lịch hẹn',
            value: '#${widget.appointmentId}',
          ),

          _buildDetailDivider(),

          _buildDetailRow(
            label: 'Ngày hẹn',
            value:
            '${widget.consultationDay}, '
                '${widget.consultationDate} '
                '${widget.consultationMonth}',
          ),

          _buildDetailDivider(),

          _buildDetailRow(
            label: 'Thời gian',
            value: widget.consultationTime,
          ),

          _buildDetailDivider(),

          _buildDetailRow(
            label: 'Lĩnh vực',
            value: widget.consultationField,
          ),

          _buildDetailDivider(),

          _buildDetailRow(
            label: 'Hình thức',
            value: widget.consultationType,
          ),

          _buildDetailDivider(),

          _buildDetailRow(
            label: 'Trạng thái',
            value: _getStatusText(),
            valueColor: _getStatusColor(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? darkNavy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL DIVIDER
  // ============================================================

  Widget _buildDetailDivider() {
    return const Divider(
      height: 1,
      color: border,
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: border,
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8ED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: gold,
            size: 18,
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: darkNavy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _buildBottomActions() {
    final normalizedStatus =
    _status.trim().toLowerCase();

    final bool isCancelled =
        normalizedStatus == 'cancelled' ||
            normalizedStatus == 'canceled' ||
            normalizedStatus == 'đã hủy';

    final bool isCompleted =
        normalizedStatus == 'completed' ||
            normalizedStatus == 'đã hoàn thành';

    final bool isConfirmed =
        normalizedStatus == 'confirmed' ||
            normalizedStatus == 'đã xác nhận';

    // ============================================================
    // CANCELLED / COMPLETED
    // ============================================================

    if (isCancelled || isCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          12,
          10,
          12,
          12,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: navy,
              side: const BorderSide(
                color: border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'Quay lại danh sách',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    // ============================================================
    // PENDING / CONFIRMED
    // ============================================================

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed:
                _isUpdatingStatus
                    ? null
                    : _cancelAppointment,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Hủy lịch',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                  const Color(0xFFD93025),
                  side: const BorderSide(
                    color: Color(0xFFE7A5A1),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed:
                isConfirmed ||
                    _isUpdatingStatus
                    ? null
                    : _confirmAppointment,
                icon: _isUpdatingStatus
                    ? const SizedBox(
                  width: 17,
                  height: 17,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(
                  isConfirmed
                      ? Icons
                      .check_circle_rounded
                      : Icons.check_rounded,
                  size: 18,
                ),
                label: Text(
                  _isUpdatingStatus
                      ? 'Đang lưu...'
                      : isConfirmed
                      ? 'Đã xác nhận'
                      : 'Xác nhận',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF16945D),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  const Color(0xFFDDEFE6),
                  disabledForegroundColor:
                  const Color(0xFF16945D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateAppointmentStatus(
      String newStatus,
      ) async {
    if (_isUpdatingStatus) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final result = await _api.patch(
        '/appointments/${widget.appointmentId}/status',
        body: {
          'status': newStatus,
        },
      );

      String savedStatus = newStatus;

      if (result is Map) {
        final apiStatus =
        result['status']?.toString();

        if (apiStatus != null &&
            apiStatus.isNotEmpty) {
          savedStatus = apiStatus;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _status = savedStatus;
      });

      _showMessage(
        newStatus == 'confirmed'
            ? 'Đã xác nhận lịch hẹn'
            : 'Đã hủy lịch hẹn',
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      if (e.statusCode == 401) {
        _showMessage(
          'Phiên đăng nhập đã hết hạn. '
              'Vui lòng đăng nhập lại.',
        );
      } else if (e.statusCode == 403) {
        _showMessage(
          'Bạn không có quyền thay đổi lịch hẹn này.',
        );
      } else {
        _showMessage(
          e.message.isNotEmpty
              ? e.message
              : 'Không thể cập nhật trạng thái.',
        );
      }
    } catch (e) {
      debugPrint(
        'Update appointment status error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể kết nối máy chủ.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  // ============================================================
  // CONFIRM APPOINTMENT
  // ============================================================

  void _confirmAppointment() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
          title: const Text(
            'Xác nhận lịch hẹn',
            style: TextStyle(
              color: darkNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn xác nhận '
                'lịch hẹn này không?',
            style: TextStyle(
              color: muted,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Đóng',
                style: TextStyle(
                  color: muted,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _updateAppointmentStatus(
                  'confirmed',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF16945D),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Xác nhận',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CANCEL APPOINTMENT
  // ============================================================

  void _cancelAppointment() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
          title: const Text(
            'Hủy lịch hẹn',
            style: TextStyle(
              color: darkNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn hủy '
                'lịch hẹn này không?',
            style: TextStyle(
              color: muted,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Đóng',
                style: TextStyle(
                  color: muted,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _updateAppointmentStatus(
                  'cancelled',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFD93025),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Hủy lịch',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  String _getStatusText() {
    final status =
    _status.trim().toLowerCase();

    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';

      case 'confirmed':
        return 'Đã xác nhận';

      case 'completed':
        return 'Đã hoàn thành';

      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';

      case 'chờ xác nhận':
      case 'đã xác nhận':
      case 'đã hoàn thành':
      case 'đã hủy':
        return _status;

      default:
        return _status.isNotEmpty
            ? _status
            : 'Chưa xác định';
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _getStatusColor() {
    final status =
    _status.trim().toLowerCase();

    switch (status) {
      case 'confirmed':
      case 'đã xác nhận':
        return const Color(0xFF16945D);

      case 'completed':
      case 'đã hoàn thành':
        return const Color(0xFF1476D4);

      case 'cancelled':
      case 'canceled':
      case 'đã hủy':
        return const Color(0xFFD93025);

      default:
        return const Color(0xFFC27A15);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(
          seconds: 2,
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }
}