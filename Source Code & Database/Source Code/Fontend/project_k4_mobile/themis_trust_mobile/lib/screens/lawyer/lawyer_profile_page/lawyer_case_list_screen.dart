import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/models/case_model.dart';
import 'package:themis_trust_mobile/screens/lawyer/lawyer_profile_page/lawyer_case_detail_screen.dart';
import 'package:themis_trust_mobile/services/api_service.dart';

class LawyerCaseListScreen extends StatefulWidget {
  const LawyerCaseListScreen({super.key});

  @override
  State<LawyerCaseListScreen> createState() => _LawyerCaseListScreenState();
}

class _LawyerCaseListScreenState extends State<LawyerCaseListScreen> {
  final ApiService _api = ApiService();

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
  // DATA
  // ============================================================

  List<CaseModel> _cases = [];

  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });

    _loadCases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD CASES
  // ============================================================

  Future<void> _loadCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.get('/cases');

      print('===== CASE API RESPONSE =====');
      print(data);
      print('=============================');

      List<dynamic> list;

      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'];
        } else if (data['items'] is List) {
          list = data['items'];
        } else {
          throw Exception('API không trả về danh sách vụ án.');
        }
      } else {
        throw Exception('Dữ liệu API không hợp lệ.');
      }

      final cases = list
          .map((json) => CaseModel.fromJson(
        Map<String, dynamic>.from(json),
      ))
          .toList();

      cases.sort((a, b) {
        final dateA = a.openedAt ?? DateTime(1900);
        final dateB = b.openedAt ?? DateTime(1900);

        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        _cases = cases;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('===== LOAD CASES ERROR =====');
      print(e);
      print(stackTrace);
      print('=============================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu: $e';
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  List<CaseModel> get _filteredCases {
    final keyword = _searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) {
      return _cases;
    }

    return _cases.where((item) {
      return item.title.toLowerCase().contains(keyword) ||
          item.docketNo.toLowerCase().contains(keyword) ||
          item.clientId.toLowerCase().contains(keyword) ||
          item.status.toLowerCase().contains(keyword);
    }).toList();
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Chưa cập nhật';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'filed':
        return 'Đã nộp';

      case 'in_review':
        return 'Đang thụ lý';

      case 'hearing':
        return 'Đang xét xử';

      case 'resolved':
        return 'Đã giải quyết';

      default:
        return 'Không xác định';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'filed':
      case 'open':
        return const Color(0xFF316895);

      case 'in_progress':
      case 'pending':
        return const Color(0xFFC68A2B);

      case 'completed':
      case 'closed':
        return const Color(0xFF2E7D5B);

      case 'cancelled':
        return const Color(0xFFC94B4B);

      default:
        return _muted;
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'filed':
      case 'open':
        return const Color(0xFFEAF3FF);

      case 'in_progress':
      case 'pending':
        return const Color(0xFFFFF6E7);

      case 'completed':
      case 'closed':
        return const Color(0xFFEAF7F0);

      case 'cancelled':
        return const Color(0xFFFFEEEE);

      default:
        return const Color(0xFFF0F4F8);
    }
  }

  // ============================================================
  // CASE CARD
  // ============================================================

  Widget _buildCaseCard(CaseModel item) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO:
        // Chuyển sang màn hình chi tiết hồ sơ vụ án.
        //
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LawyerCaseDetailScreen(
              caseId: item.id,
            ),
          ),
        );
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ==================================================
            // ICON HỒ SƠ
            // ==================================================

            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0F7),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.folder_outlined, color: _navy, size: 25),
            ),

            const SizedBox(width: 13),

            // ==================================================
            // CONTENT
            // ==================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÊN VỤ ÁN
                  Text(
                    item.title.isEmpty ? 'Chưa có tên vụ án' : item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // MÃ HỒ SƠ
                  Row(
                    children: [
                      const Icon(Icons.tag_outlined, size: 15, color: _muted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.docketNo.isEmpty
                              ? 'Chưa có mã hồ sơ'
                              : item.docketNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // NGÀY MỞ
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: _muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Ngày mở: ${_formatDate(item.openedAt)}',
                        style: const TextStyle(color: _muted, fontSize: 12.5),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),

                  // STATUS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBackground(item.status),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      _statusLabel(item.status),
                      style: TextStyle(
                        color: _statusColor(item.status),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ==================================================
            // ARROW
            // ==================================================
            const Icon(Icons.chevron_right_rounded, color: _gold, size: 27),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tên vụ án, mã hồ sơ...',
          hintStyle: const TextStyle(color: _muted, fontSize: 13.5),
          prefixIcon: const Icon(Icons.search_rounded, color: _navy, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _muted,
                    size: 19,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    final bool isSearching = _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF0F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_outlined,
                color: _navy,
                size: 44,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isSearching ? 'Không tìm thấy hồ sơ' : 'Chưa có hồ sơ vụ án',
              style: const TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isSearching
                  ? 'Không có hồ sơ phù hợp với từ khóa tìm kiếm.'
                  : 'Các hồ sơ vụ án của bạn sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F1),
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
              style: const TextStyle(color: _muted, fontSize: 14),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadCases,
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
    final filteredCases = _filteredCases;

    return Scaffold(
      backgroundColor: _background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.chevron_left_rounded, color: _navy, size: 32),
        ),

        title: const Text(
          'Hồ sơ vụ án',
          style: TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: RefreshIndicator(
        color: _navy,
        onRefresh: _loadCases,

        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _navy))
            : _errorMessage != null
            ? _buildErrorState()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                children: [
                  // SEARCH
                  _buildSearchBar(),

                  const SizedBox(height: 18),

                  // HEADER COUNT
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
                        '${filteredCases.length} hồ sơ',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // CASE LIST
                  if (filteredCases.isEmpty)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: _buildEmptyState(),
                    )
                  else
                    ...filteredCases.map(_buildCaseCard),
                ],
              ),
      ),
    );
  }
}
