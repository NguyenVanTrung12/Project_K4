import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_request_page/lawyer_consultation_request_detail.dart';

class LawyerConsultationRequest extends StatefulWidget {
  const LawyerConsultationRequest({
    super.key,
  });

  @override
  State<LawyerConsultationRequest> createState() =>
      _LawyerConsultationRequestState();
}

class _LawyerConsultationRequestState
    extends State<LawyerConsultationRequest> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF0D3558);
  static const Color darkNavy = Color(0xFF092E50);
  static const Color gold = Color(0xFFC78A2C);

  static const Color muted = Color(0xFF71839A);
  static const Color border = Color(0xFFE1E8F0);
  static const Color background = Color(0xFFF5F8FC);

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController =
  TextEditingController();

  String _searchText = '';

  // ============================================================
  // DATA
  // Sau này thay bằng dữ liệu API
  // ============================================================

  final List<_ConsultationRequest> _requests = [
    _ConsultationRequest(
      name: 'Phạm Thị Thảo',
      time: '2 giờ trước',
      field: 'Hôn nhân & Gia đình',
      content:
      'Tôi muốn được tư vấn về thủ tục ly hôn và quyền nuôi con. Mong luật sư hỗ trợ...',
      messageCount: 3,
      attachmentCount: 1,
      status: 'Mới',
      statusColor: Color(0xFFFFE2E5),
      statusTextColor: Color(0xFFE84B57),
      fieldIcon: Icons.groups_rounded,
      avatarType: 0,
    ),
    _ConsultationRequest(
      name: 'Lê Quốc Bảo',
      time: '5 giờ trước',
      field: 'Dân sự',
      content:
      'Tôi cần tư vấn về tranh chấp đất đai giữa các thành viên trong gia đình...',
      messageCount: 5,
      attachmentCount: 2,
      status: 'Đang xử lý',
      statusColor: Color(0xFFFFF0D8),
      statusTextColor: Color(0xFFD88918),
      fieldIcon: Icons.description_rounded,
      avatarType: 1,
    ),
    _ConsultationRequest(
      name: 'Nguyễn Thị Mai',
      time: '1 ngày trước',
      field: 'Lao động',
      content:
      'Công ty tôi đang có dấu hiệu chấm dứt hợp đồng trái luật. Tôi muốn được tư vấn...',
      messageCount: 4,
      attachmentCount: 0,
      status: 'Đã phản hồi',
      statusColor: Color(0xFFDDF5E8),
      statusTextColor: Color(0xFF18955C),
      fieldIcon: Icons.business_center_rounded,
      avatarType: 0,
    ),
    _ConsultationRequest(
      name: 'Trần Văn Nam',
      time: '2 ngày trước',
      field: 'Kinh doanh & Doanh nghiệp',
      content:
      'Tôi cần tư vấn về thủ tục thành lập công ty và các loại giấy phép liên quan...',
      messageCount: 2,
      attachmentCount: 1,
      status: 'Đã hẹn lịch',
      statusColor: Color(0xFFE4EEFF),
      statusTextColor: Color(0xFF3779D4),
      fieldIcon: Icons.business_rounded,
      avatarType: 1,
    ),
  ];

  // ============================================================
  // FILTERED DATA
  // ============================================================

  List<_ConsultationRequest> get _filteredRequests {
    if (_searchText.trim().isEmpty) {
      return _requests;
    }

    final keyword =
    _searchText.trim().toLowerCase();

    return _requests.where((request) {
      return request.name
          .toLowerCase()
          .contains(keyword) ||
          request.field
              .toLowerCase()
              .contains(keyword) ||
          request.content
              .toLowerCase()
              .contains(keyword);
    }).toList();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchText =
            _searchController.text;
      });
    });
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics:
                const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(
                  10,
                  7,
                  10,
                  15,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(
                      height: 10,
                    ),

                    _buildSearchBar(),

                    const SizedBox(
                      height: 10,
                    ),

                    _buildRequestList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Yêu cầu tư vấn',
          style: TextStyle(
            color: darkNavy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),

        SizedBox(
          height: 4,
        ),

        Text(
          'Quản lý và phản hồi các yêu cầu tư vấn từ khách hàng',
          style: TextStyle(
            color: muted,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(7),
              border: Border.all(
                color: border,
              ),
            ),
            child: TextField(
              controller:
              _searchController,
              style: const TextStyle(
                color: navy,
                fontSize: 8,
              ),
              decoration:
              const InputDecoration(
                border:
                InputBorder.none,
                hintText:
                'Tìm kiếm theo tên khách hàng, nội dung, lĩnh vực...',
                hintStyle:
                TextStyle(
                  color:
                  Color(0xFF91A2B5),
                  fontSize: 7.5,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: navy,
                  size: 19,
                ),
                prefixIconConstraints:
                BoxConstraints(
                  minWidth: 34,
                ),
                contentPadding:
                EdgeInsets.symmetric(
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 7,
        ),

        GestureDetector(
          onTap: _openFilter,
          child: Container(
            height: 36,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 11,
            ),
            decoration:
            BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(7),
              border: Border.all(
                color: border,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons
                      .filter_alt_outlined,
                  color: navy,
                  size: 16,
                ),

                SizedBox(
                  width: 4,
                ),

                Text(
                  'Bộ lọc',
                  style:
                  TextStyle(
                    color: navy,
                    fontSize: 8,
                    fontWeight:
                    FontWeight.w600,
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
  // REQUEST LIST
  // ============================================================

  Widget _buildRequestList() {
    final requests =
        _filteredRequests;

    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: requests.map(
            (request) {
          return Padding(
            padding:
            const EdgeInsets.only(
              bottom: 8,
            ),
            child:
            _buildRequestCard(
              request,
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard(
      _ConsultationRequest request,
      ) {
    return GestureDetector(
      onTap: () {
        _openRequestDetail(
          request,
        );
      },
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.fromLTRB(
          10,
          10,
          7,
          9,
        ),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(9),
          border: Border.all(
            color: border,
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(
                0.015,
              ),
              blurRadius: 5,
              offset:
              const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildCustomerAvatar(
              request,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  _buildRequestTitle(
                    request,
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  _buildField(
                    request,
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    request.content,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      color:
                      Color(0xFF60748B),
                      fontSize: 7.5,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  _buildRequestMeta(
                    request,
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 3,
            ),

            const Padding(
              padding:
              EdgeInsets.only(
                top: 37,
              ),
              child: Icon(
                Icons
                    .chevron_right_rounded,
                color: navy,
                size: 21,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOMER AVATAR
  // ============================================================

  Widget _buildCustomerAvatar(
      _ConsultationRequest request,
      ) {
    return Container(
      width: 52,
      height: 52,
      decoration:
      BoxDecoration(
        shape: BoxShape.circle,
        color:
        request.avatarType == 0
            ? const Color(
          0xFFE9EDF1,
        )
            : const Color(
          0xFFE4E9EF,
        ),
      ),
      child: Icon(
        request.avatarType == 0
            ? Icons.person_rounded
            : Icons.person_rounded,
        color:
        const Color(0xFF7C8A9A),
        size: 31,
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildRequestTitle(
      _ConsultationRequest request,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            request.name,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              color: darkNavy,
              fontSize: 10,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(
          width: 4,
        ),

        Column(
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            Text(
              request.time,
              style:
              const TextStyle(
                color: muted,
                fontSize: 7,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            _buildStatusBadge(
              request,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _buildField(
      _ConsultationRequest request,
      ) {
    return Row(
      children: [
        Icon(
          request.fieldIcon,
          color: navy,
          size: 14,
        ),

        const SizedBox(
          width: 5,
        ),

        Expanded(
          child: Text(
            request.field,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              color: navy,
              fontSize: 7.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusBadge(
      _ConsultationRequest request,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
      BoxDecoration(
        color: request.statusColor,
        borderRadius:
        BorderRadius.circular(5),
      ),
      child: Text(
        request.status,
        style:
        TextStyle(
          color:
          request.statusTextColor,
          fontSize: 6.5,
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // META
  // ============================================================

  Widget _buildRequestMeta(
      _ConsultationRequest request,
      ) {
    return Row(
      children: [
        const Icon(
          Icons
              .chat_bubble_outline_rounded,
          color: muted,
          size: 14,
        ),

        const SizedBox(
          width: 4,
        ),

        Text(
          '${request.messageCount}',
          style:
          const TextStyle(
            color: muted,
            fontSize: 7,
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        const Icon(
          Icons.attach_file_rounded,
          color: muted,
          size: 14,
        ),

        const SizedBox(
          width: 4,
        ),

        Text(
          request.attachmentCount == 0
              ? 'Không có tệp'
              : '${request.attachmentCount} tệp đính kèm',
          style:
          const TextStyle(
            color: muted,
            fontSize: 7,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 50,
      ),
      child: const Column(
        children: [
          Icon(
            Icons
                .search_off_rounded,
            color: Color(0xFF9AA9B8),
            size: 45,
          ),

          SizedBox(
            height: 10,
          ),

          Text(
            'Không tìm thấy yêu cầu tư vấn',
            style:
            TextStyle(
              color: navy,
              fontSize: 10,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          SizedBox(
            height: 4,
          ),

          Text(
            'Hãy thử tìm kiếm với từ khóa khác.',
            style:
            TextStyle(
              color: muted,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
      Colors.white,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top:
          Radius.circular(18),
        ),
      ),
      builder:
          (context) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(
              18,
              15,
              18,
              20,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                const Center(
                  child: SizedBox(
                    width: 40,
                    child:
                    Divider(
                      thickness: 3,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Bộ lọc yêu cầu tư vấn',
                  style:
                  TextStyle(
                    color: darkNavy,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                _buildFilterOption(
                  'Mới',
                ),

                _buildFilterOption(
                  'Đang xử lý',
                ),

                _buildFilterOption(
                  'Đã phản hồi',
                ),

                _buildFilterOption(
                  'Đã hẹn lịch',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
      String title,
      ) {
    return ListTile(
      contentPadding:
      EdgeInsets.zero,
      leading:
      const Icon(
        Icons.circle_outlined,
        color: navy,
      ),
      title: Text(
        title,
        style:
        const TextStyle(
          color: navy,
          fontSize: 10,
        ),
      ),
      onTap: () {
        Navigator.pop(
          context,
        );

        _showMessage(
          'Đã chọn bộ lọc: $title',
        );
      },
    );
  }

  // ============================================================
  // DETAIL
  // ============================================================

  void _openRequestDetail(
      _ConsultationRequest request,
      ) {
    _showMessage(
      'Mở chi tiết yêu cầu của ${request.name}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LawyerConsultationRequestDetail(
              request: request,
            ),
      ),
    );
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
        const Duration(
          seconds: 1,
        ),
      ),
    );
  }
}

// ================================================================
// REQUEST MODEL
// ================================================================

class _ConsultationRequest {
  final String name;
  final String time;
  final String field;
  final String content;

  final int messageCount;
  final int attachmentCount;

  final String status;

  final Color statusColor;
  final Color statusTextColor;

  final IconData fieldIcon;

  final int avatarType;

  const _ConsultationRequest({
    required this.name,
    required this.time,
    required this.field,
    required this.content,
    required this.messageCount,
    required this.attachmentCount,
    required this.status,
    required this.statusColor,
    required this.statusTextColor,
    required this.fieldIcon,
    required this.avatarType,
  });
}