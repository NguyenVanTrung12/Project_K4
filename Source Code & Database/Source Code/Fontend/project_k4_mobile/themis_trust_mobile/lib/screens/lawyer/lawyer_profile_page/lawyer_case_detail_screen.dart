import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/models/case_event_model.dart';
import 'package:themis_trust_mobile/models/case_model.dart';
import 'package:themis_trust_mobile/services/api_service.dart';


class LawyerCaseDetailScreen extends StatefulWidget {
  final String caseId;

  const LawyerCaseDetailScreen({
    super.key,
    required this.caseId,
  });

  @override
  State<LawyerCaseDetailScreen> createState() =>
      _LawyerCaseDetailScreenState();
}

class _LawyerCaseDetailScreenState
    extends State<LawyerCaseDetailScreen> {
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
  // SERVICES / STATE
  // ============================================================

  final ApiService _api = ApiService();

  CaseModel? _case;

  bool _loading = true;
  String? _error;

  bool _updatingCase = false;
  bool _addingEvent = false;

  @override
  void initState() {
    super.initState();
    _loadCase();
  }

  // ============================================================
  // LOAD CASE
  // ============================================================

  Future<void> _loadCase() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.get(
        '/cases/${widget.caseId}',
      );

      print('');
      print('================================================');
      print('        CASE DETAIL API RESPONSE');
      print('================================================');
      print(data);
      print('================================================');

      if (data is Map) {
        print('CASE ID: ${data['id']}');
        print('CASE TITLE: ${data['title']}');
        print('EVENTS RAW: ${data['events']}');
        print(
          'EVENTS TYPE: ${data['events']?.runtimeType}',
        );

        if (data['events'] is List) {
          final rawEvents = data['events'] as List;

          print(
            'EVENT COUNT FROM API: ${rawEvents.length}',
          );

          for (final event in rawEvents) {
            print('EVENT RAW: $event');
          }
        }
      }

      final caseData = CaseModel.fromJson(
        Map<String, dynamic>.from(data),
      );

      print('');
      print('================================================');
      print('          ANDROID EVENTS RESULT');
      print('================================================');
      print(
        'EVENT COUNT: ${caseData.events.length}',
      );

      for (final event in caseData.events) {
        print('EVENT ID: ${event.id}');
        print('EVENT TITLE: ${event.title}');
        print('EVENT DATE: ${event.eventDate}');
        print('EVENT NOTE: ${event.note}');
        print('EVENT DONE: ${event.isDone}');
      }

      print('================================================');

      if (!mounted) return;

      setState(() {
        _case = caseData;
        _loading = false;
      });
    } catch (e, stackTrace) {
      print('');
      print('================================================');
      print('          LOAD CASE DETAIL ERROR');
      print('================================================');
      print(e);
      print(stackTrace);
      print('================================================');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ============================================================
  // UPDATE CASE
  // ============================================================

  Future<void> _updateCase({
    required String title,
    required String status,
    String? nextStep,
    String? courtName,
    DateTime? closedAt,
  }) async {
    if (_case == null) return;

    setState(() {
      _updatingCase = true;
    });

    try {
      await _api.put(
        '/cases/${_case!.id}',
        body: {
          'title': title,
          'status': status,
          'nextStep': nextStep,
          'courtName': courtName,
          'closedAt': closedAt?.toIso8601String(),
        },
      );

      if (!mounted) return;

      Navigator.pop(context);

      await _loadCase();

      if (!mounted) return;

      _showMessage(
        'Cập nhật hồ sơ thành công.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Không thể cập nhật hồ sơ: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingCase = false;
        });
      }
    }
  }

  // ============================================================
  // ADD EVENT
  // ============================================================

  Future<void> _addEvent({
    required String title,
    required DateTime eventDate,
    String? note,
  }) async {
    if (_case == null) return;

    setState(() {
      _addingEvent = true;
    });

    try {
      final currentEvents = _case!.events;

      final nextSortOrder = currentEvents.isEmpty
          ? 1
          : currentEvents
          .map((e) => e.sortOrder)
          .reduce(
            (a, b) => a > b ? a : b,
      ) +
          1;

      await _api.post(
        '/cases/${_case!.id}/events',
        body: {
          'title': title,
          'eventDate': eventDate.toIso8601String(),
          'note': note,
          'isDone': false,
          'sortOrder': nextSortOrder,
        },
      );

      if (!mounted) return;

      Navigator.pop(context);

      await _loadCase();

      if (!mounted) return;

      _showMessage(
        'Đã thêm sự kiện vào tiến trình.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Không thể thêm sự kiện: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingEvent = false;
        });
      }
    }
  }

  // ============================================================
  // TOGGLE EVENT
  // ============================================================

  Future<void> _toggleEvent(
      CaseEventModel event,
      ) async {
    try {
      await _api.patch(
        '/cases/events/${event.id}/toggle-done',
      );

      await _loadCase();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Không thể cập nhật trạng thái sự kiện: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // DELETE EVENT
  // ============================================================

  Future<void> _deleteEvent(
      CaseEventModel event,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Xóa sự kiện?',
          ),
          content: Text(
            'Bạn có chắc muốn xóa sự kiện "${event.title}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Hủy',
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Xóa',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _api.delete(
        '/cases/events/${event.id}',
      );

      await _loadCase();

      if (!mounted) return;

      _showMessage(
        'Đã xóa sự kiện.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Không thể xóa sự kiện: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
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
      title: Text(
        _case?.title ?? 'Chi tiết hồ sơ',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _text,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _gold,
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_case == null) {
      return const Center(
        child: Text(
          'Không tìm thấy hồ sơ vụ án.',
          style: TextStyle(
            color: _muted,
            fontSize: 15,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _gold,
      onRefresh: _loadCase,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCaseHeader(_case!),

            const SizedBox(height: 16),

            _buildBasicInfo(_case!),

            const SizedBox(height: 16),

            _buildNextStep(_case!),

            const SizedBox(height: 16),

            _buildProgressSection(_case!),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            const Text(
              'Không thể tải hồ sơ vụ án',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadCase,
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Thử lại',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CASE HEADER
  // ============================================================

  Widget _buildCaseHeader(
      CaseModel item,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title.isEmpty
                      ? 'Hồ sơ vụ án'
                      : item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              _buildStatusBadge(
                item.status,
                dark: true,
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (item.docketNo.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.folder_outlined,
                  color: Colors.white70,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Mã hồ sơ: ${item.docketNo}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BASIC INFO
  // ============================================================

  Widget _buildBasicInfo(
      CaseModel item,
      ) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.info_outline,
            title: 'Thông tin hồ sơ',
          ),

          const SizedBox(height: 18),

          _infoRow(
            icon: Icons.person_outline,
            label: 'Khách hàng',
            value: item.clientName.isEmpty
                ? 'Chưa cập nhật'
                : item.clientName,
          ),

          _divider(),

          _infoRow(
            icon: Icons.gavel_outlined,
            label: 'Luật sư',
            value: item.lawyerName?.isNotEmpty == true
                ? item.lawyerName!
                : 'Chưa cập nhật',
          ),

          _divider(),

          _infoRow(
            icon: Icons.account_balance_outlined,
            label: 'Lĩnh vực pháp lý',
            value:
            item.practiceAreaName?.isNotEmpty == true
                ? item.practiceAreaName!
                : 'Chưa cập nhật',
          ),

          _divider(),

          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Ngày mở hồ sơ',
            value: _formatDate(item.openedAt),
          ),

          _divider(),

          _infoRow(
            icon: Icons.balance_outlined,
            label: 'Tòa án',
            value: item.courtName?.isNotEmpty == true
                ? item.courtName!
                : 'Chưa cập nhật',
          ),

          _divider(),

          _infoRow(
            icon: Icons.flag_outlined,
            label: 'Trạng thái',
            value: _statusLabel(item.status),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NEXT STEP
  // ============================================================

  Widget _buildNextStep(
      CaseModel item,
      ) {
    final hasNextStep =
        item.nextStep != null &&
            item.nextStep!.trim().isNotEmpty;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  icon: Icons.next_plan_outlined,
                  title: 'Bước tiếp theo',
                ),
              ),

              IconButton(
                tooltip: 'Cập nhật hồ sơ',
                onPressed: _updatingCase
                    ? null
                    : _showUpdateCaseSheet,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: _gold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEBD8B6),
              ),
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: _gold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasNextStep
                        ? item.nextStep!
                        : 'Chưa cập nhật bước tiếp theo.',
                    style: const TextStyle(
                      color: _text,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _buildProgressSection(
      CaseModel item,
      ) {
    // QUAN TRỌNG:
    // Lấy trực tiếp events từ CaseModel đã parse từ API.
    final events = item.events;

    print(
      'UI BUILD EVENTS COUNT = ${events.length}',
    );

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  icon: Icons.timeline_outlined,
                  title: 'Tiến trình vụ án',
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${events.length} sự kiện',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Center(
                child: Text(
                  'Chưa có sự kiện nào',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (
                int i = 0;
                i < events.length;
                i++
                )
                  _buildTimelineItem(
                    event: events[i],
                    index: i,
                    total: events.length,
                  ),
              ],
            ),

          const SizedBox(height: 4),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addingEvent
                  ? null
                  : _showAddEventSheet,
              icon: const Icon(
                Icons.add,
                size: 19,
              ),
              label: const Text(
                'Thêm sự kiện',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _navy,
                side: const BorderSide(
                  color: _border,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIMELINE ITEM
  // ============================================================

  Widget _buildTimelineItem({
    required CaseEventModel event,
    required int index,
    required int total,
  }) {
    final isLast = index == total - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    _toggleEvent(event);
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.isDone
                          ? _gold
                          : Colors.white,
                      border: Border.all(
                        color: event.isDone
                            ? _gold
                            : _navy,
                        width: 2,
                      ),
                    ),
                    child: event.isDone
                        ? const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    )
                        : null,
                  ),
                ),

                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin:
                      const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      color: _border,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(
                bottom: 16,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: event.isDone
                    ? const Color(0xFFFFFBF4)
                    : const Color(0xFFF7FAFD),
                borderRadius:
                BorderRadius.circular(14),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title.isEmpty
                              ? 'Sự kiện'
                              : event.title,
                          style: TextStyle(
                            color: _text,
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w800,
                            decoration:
                            event.isDone
                                ? TextDecoration
                                .lineThrough
                                : null,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_vert,
                          color: _muted,
                          size: 20,
                        ),
                        onSelected: (value) {
                          if (value == 'toggle') {
                            _toggleEvent(event);
                          }

                          if (value == 'delete') {
                            _deleteEvent(event);
                          }
                        },
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'toggle',
                              child: Text(
                                event.isDone
                                    ? 'Đánh dấu chưa hoàn thành'
                                    : 'Đánh dấu hoàn thành',
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Xóa sự kiện',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: _muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(
                          event.eventDate,
                        ),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  if (event.note != null &&
                      event.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),

                    Text(
                      event.note!,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () {
                      _toggleEvent(event);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          event.isDone
                              ? Icons.check_circle
                              : Icons
                              .radio_button_unchecked,
                          size: 16,
                          color: event.isDone
                              ? _gold
                              : _muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.isDone
                              ? 'Đã hoàn thành'
                              : 'Chưa hoàn thành',
                          style: TextStyle(
                            color: event.isDone
                                ? _gold
                                : _muted,
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPDATE CASE BOTTOM SHEET
  // ============================================================

  void _showUpdateCaseSheet() {
    if (_case == null) return;

    final titleController = TextEditingController(
      text: _case!.title,
    );

    final nextStepController =
    TextEditingController(
      text: _case!.nextStep ?? '',
    );

    final courtController =
    TextEditingController(
      text: _case!.courtName ?? '',
    );

    String selectedStatus = _case!.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                    20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Cập nhật hồ sơ vụ án',
                      style: TextStyle(
                        color: _text,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _inputField(
                      controller: titleController,
                      label: 'Tên vụ án',
                      icon: Icons.title,
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: _validStatus(
                        selectedStatus,
                      ),
                      decoration:
                      _inputDecoration(
                        label: 'Trạng thái',
                        icon: Icons.flag_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'filed',
                          child: Text(
                            'Đã nộp',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'in_review',
                          child: Text(
                            'Đang thụ lý',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'hearing',
                          child: Text(
                            'Đang xét xử',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'resolved',
                          child: Text(
                            'Đã giải quyết',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          selectedStatus = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    _inputField(
                      controller:
                      nextStepController,
                      label: 'Bước tiếp theo',
                      icon: Icons.next_plan_outlined,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 14),

                    _inputField(
                      controller: courtController,
                      label: 'Tòa án',
                      icon:
                      Icons.account_balance_outlined,
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updatingCase
                            ? null
                            : () async {
                          await _updateCase(
                            title:
                            titleController
                                .text
                                .trim(),
                            status:
                            selectedStatus,
                            nextStep:
                            nextStepController
                                .text
                                .trim()
                                .isEmpty
                                ? null
                                : nextStepController
                                .text
                                .trim(),
                            courtName:
                            courtController
                                .text
                                .trim()
                                .isEmpty
                                ? null
                                : courtController
                                .text
                                .trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor:
                          Colors.white,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                        child: _updatingCase
                            ? const SizedBox(
                          width: 21,
                          height: 21,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                            Colors.white,
                          ),
                        )
                            : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ADD EVENT BOTTOM SHEET
  // ============================================================

  void _showAddEventSheet() {
    final titleController =
    TextEditingController();

    final noteController =
    TextEditingController();

    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                    20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Thêm sự kiện',
                      style: TextStyle(
                        color: _text,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _inputField(
                      controller: titleController,
                      label: 'Tên sự kiện',
                      icon: Icons.event_outlined,
                    ),

                    const SizedBox(height: 14),

                    InkWell(
                      borderRadius:
                      BorderRadius.circular(14),
                      onTap: () async {
                        final result =
                        await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate:
                          DateTime(2000),
                          lastDate:
                          DateTime(2100),
                        );

                        if (result == null) {
                          return;
                        }

                        setSheetState(() {
                          selectedDate = result;
                        });
                      },
                      child: InputDecorator(
                        decoration:
                        _inputDecoration(
                          label: 'Ngày sự kiện',
                          icon: Icons
                              .calendar_today_outlined,
                        ),
                        child: Text(
                          _formatDate(
                            selectedDate,
                          ),
                          style: const TextStyle(
                            color: _text,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _inputField(
                      controller: noteController,
                      label: 'Ghi chú',
                      icon: Icons.notes_outlined,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _addingEvent
                            ? null
                            : () async {
                          final title =
                          titleController
                              .text
                              .trim();

                          if (title.isEmpty) {
                            _showMessage(
                              'Vui lòng nhập tên sự kiện.',
                              isError: true,
                            );
                            return;
                          }

                          await _addEvent(
                            title: title,
                            eventDate:
                            selectedDate,
                            note:
                            noteController
                                .text
                                .trim()
                                .isEmpty
                                ? null
                                : noteController
                                .text
                                .trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor:
                          Colors.white,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                        child: _addingEvent
                            ? const SizedBox(
                          width: 21,
                          height: 21,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                            Colors.white,
                          ),
                        )
                            : const Text(
                          'Thêm sự kiện',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // COMMON WIDGETS
  // ============================================================

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _navy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: _navy,
            size: 19,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            color: _text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: _muted,
          ),

          const SizedBox(width: 11),

          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _text,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 12,
      color: _border,
    );
  }

  Widget _buildStatusBadge(
      String status, {
        bool dark = false,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withOpacity(0.14)
            : _navy.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: dark ? Colors.white : _navy,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: _text,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        label: label,
        icon: icon,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _muted,
      ),
      prefixIcon: Icon(
        icon,
        color: _muted,
        size: 20,
      ),
      filled: true,
      fillColor: _background,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _navy,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Chưa cập nhật';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'filed':
        return 'Đã nộp';

      case 'in_review':
        return 'Đang thụ lý';

      case 'hearing':
        return 'Đang xét xử';

      case 'resolved':
        return 'Đã giải quyết';

      default:
        return status.isEmpty
            ? 'Chưa cập nhật'
            : status;
    }
  }

  String? _validStatus(String status) {
    const statuses = [
      'filed',
      'in_review',
      'hearing',
      'resolved',
    ];

    if (statuses.contains(status)) {
      return status;
    }

    return 'filed';
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError ? Colors.redAccent : _navy,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}