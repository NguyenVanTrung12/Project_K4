import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/models/lawyer_model.dart';
import 'package:themis_trust_mobile/screens/client/client_consultation_page/client_consultation_screen.dart';
import 'package:themis_trust_mobile/services/lawyer_service.dart';
import 'package:themis_trust_mobile/screens/client/client_lawyer_page/client_lawyer_detail_screen.dart';

class ClientLawyersScreen extends StatefulWidget {
  const ClientLawyersScreen({super.key});

  @override
  State<ClientLawyersScreen> createState() => _ClientLawyersScreenState();
}

class _ClientLawyersScreenState extends State<ClientLawyersScreen> {
  // =============================================================
  // FILTER
  // =============================================================
  String _selectedCategory = 'Tất cả';
  String _selectedSort = 'Mặc định';
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  LawyerModel? _lawyer;

  // =============================================================
  // API
  // =============================================================
  final LawyerService _lawyerService = LawyerService();
  List<_ClientLawyerItemData> _lawyers = [];
  bool _isLoading = true;
  String? _errorMessage; // ============================================================= // INIT // =============================================================
  @override
  void initState() {
    super.initState();
    _fetchLawyers();
  } // ============================================================= // GET LAWYERS FROM API // =============================================================

  Future<void> _fetchLawyers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
      final List<LawyerModel> result = await _lawyerService.getAll();
      final List<_ClientLawyerItemData> lawyers = result.map((lawyer) {
        return _ClientLawyerItemData(
          id: lawyer.id,
          name: lawyer.fullName,
          title: lawyer.title,
          rating: lawyer.ratingAvg,
          // LawyerDto hiện tại chưa có số lượng review
          reviews: 0,
          experience: lawyer.yearsExp,
          // LawyerDto hiện tại chưa có giá tư vấn
          price: 0,
          specialties: List<String>.from(lawyer.practiceAreas),
          imageUrl: lawyer.avatarUrl ?? '',
          isActive: lawyer.isAvailable,
          isFeatured: false,
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _lawyers = lawyers;
        // Nếu category cũ không còn trong API
        // thì quay về Tất cả.
        if (_selectedCategory != 'Tất cả' &&
            !lawyers.any(
              (lawyer) => lawyer.specialties.contains(_selectedCategory),
            )) {
          _selectedCategory = 'Tất cả';
        }
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lawyers = [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // =============================================================
  // CATEGORY FROM API
  // =============================================================
  List<String> get _categoriesFromApi {
    final Set<String> categories = {};
    for (final lawyer in _lawyers) {
      categories.addAll(lawyer.specialties);
    }
    final List<String> result = ['Tất cả'];
    final List<String> sortedCategories = categories.toList()..sort();
    result.addAll(sortedCategories);
    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =============================================================
  // BUILD
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // =====================================================
            // HEADER
            // =====================================================
            _buildLawyerHeader(),
            // =====================================================
            // CONTENT
            // =====================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 15),
                child: Column(
                  children: [
                    // Bộ lọc + tìm kiếm
                    _buildFilterRow(), const SizedBox(height: 13),
                    // Danh mục
                    _buildCategoryList(), const SizedBox(height: 14),
                    // Danh sách luật sư
                    _buildLawyerGrid(), const SizedBox(height: 14),
                    // Phân trang
                    _buildPagination(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // LAWYER HEADER
  // =============================================================
  Widget _buildLawyerHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đội ngũ luật sư',
                  style: TextStyle(
                    color: Color(0xFF123E72),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tìm kiếm và lựa chọn luật sư phù hợp',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF7890A8),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // FILTER ROW
  // =============================================================
  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(child: _buildSortButton()),
        const SizedBox(width: 10),
        Expanded(child: _buildSearchField()),
      ],
    );
  }

  // =============================================================
  // SORT BUTTON
  // =============================================================
  Widget _buildSortButton() {
    return GestureDetector(
      onTap: _showSortBottomSheet,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFE0E8F1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.swap_vert_rounded,
              color: Color(0xFF153E6B),
              size: 21,
            ),
            const SizedBox(width: 8),
            const Text(
              'Sắp xếp theo:',
              style: TextStyle(color: Color(0xFF8A9CB0), fontSize: 11),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _selectedSort,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF234D78),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF153E6B),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SEARCH
  // =============================================================
  Widget _buildSearchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE0E8F1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,

        // Tìm kiếm ngay khi người dùng nhập
        onChanged: (value) {
          setState(() {
            _currentPage = 1;
          });
        },

        textInputAction: TextInputAction.search,

        decoration: InputDecoration(
          border: InputBorder.none,

          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF153E6B),
            size: 21,
          ),

          hintText: 'Tìm tên luật sư...',
          hintStyle: const TextStyle(
            color: Color(0xFF8A9CB0),
            fontSize: 11,
          ),

          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
          ),

          // Nút X khi đang tìm kiếm
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();

              setState(() {
                _currentPage = 1;
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF8A9CB0),
              size: 18,
            ),
          )
              : null,
        ),
      ),
    );
  }

  // =============================================================
  // CATEGORY LIST
  // =============================================================
  Widget _buildCategoryList() {
    final categories = _categoriesFromApi;

    return SizedBox(
      height: 39,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),

        itemCount: categories.length,

        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },

        itemBuilder: (context, index) {
          final String category = categories[index];

          final bool selected =
              _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;

                // Đổi danh mục -> quay về trang đầu
                _currentPage = 1;
              });
            },

            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFC68A2B)
                    : Colors.white,

                borderRadius: BorderRadius.circular(20),

                border: Border.all(
                  color: selected
                      ? const Color(0xFFC68A2B)
                      : const Color(0xFFDDE6EF),
                ),
              ),

              child: Text(
                category,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF234D78),
                  fontSize: 11,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =============================================================
  // LAWYER GRID
  // =============================================================
  Widget _buildLawyerGrid() {
    // ===========================================================
    // LOADING
    // ===========================================================
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 50),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF17609D)),
        ),
      );
    }
    // ===========================================================
    // ERROR
    // ===========================================================
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    // ===========================================================
    // FILTER
    // ===========================================================
    final List<_ClientLawyerItemData> filteredLawyers = _getFilteredLawyers();
    if (filteredLawyers.isEmpty) {
      return _buildEmptyState();
    }
    // ===========================================================
    // PAGINATION
    // ===========================================================
    const int pageSize = 6;
    final int totalPages = (filteredLawyers.length / pageSize).ceil();
    if (_currentPage > totalPages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentPage > totalPages) {
          setState(() {
            _currentPage = totalPages;
          });
        }
      });
    }
    final int startIndex = ((_currentPage - 1) * pageSize).clamp(
      0,
      filteredLawyers.length,
    );
    final int endIndex = (startIndex + pageSize).clamp(
      startIndex,
      filteredLawyers.length,
    );
    final List<_ClientLawyerItemData> pageLawyers = filteredLawyers.sublist(
      startIndex,
      endIndex,
    );
    // ===========================================================
    // GRID
    // ===========================================================
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pageLawyers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 9,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),

      itemBuilder: (context, index) {
        final lawyer = pageLawyers[index];
        return _ClientLawyerCard(
          lawyer: lawyer,
          onProfilePressed: () {
            _openLawyerProfile(lawyer);
          },
          onBookPressed: () {
            _onBookConsultation(lawyer);
          },
        );
      },
    );
  }
  String _normalizeText(String text) {
    const vietnamese = 'àáạảãâầấậẩẫăằắặẳẵ'
        'èéẹẻẽêềếệểễ'
        'ìíịỉĩ'
        'òóọỏõôồốộổỗơờớợởỡ'
        'ùúụủũưừứựửữ'
        'ỳýỵỷỹ'
        'đ';

    const withoutTone = 'aaaaaaaaaaaaaaaaa'
        'eeeeeeeeeee'
        'iiiii'
        'ooooooooooooooooo'
        'uuuuuuuuuuu'
        'yyyyy'
        'd';

    String result = text.toLowerCase();

    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(
        vietnamese[i],
        withoutTone[i],
      );
    }

    return result;
  }
  // =============================================================
  // FILTER DATA
  // =============================================================
  List<_ClientLawyerItemData> _getFilteredLawyers() {
    final String keyword = _normalizeText(
      _searchController.text.trim(),
    );

    final String selectedCategory = _normalizeText(
      _selectedCategory.trim(),
    );

    List<_ClientLawyerItemData> result = _lawyers.where((lawyer) {
      // ==========================================================
      // 1. LỌC THEO DANH MỤC
      // ==========================================================

      final bool categoryMatch =
          _selectedCategory == 'Tất cả' ||
              lawyer.specialties.any(
                    (specialty) =>
                _normalizeText(specialty.trim()) == selectedCategory,
              );

      // ==========================================================
      // 2. TÌM KIẾM THEO TÊN LUẬT SƯ
      // ==========================================================

      final String lawyerName = _normalizeText(
        lawyer.name.trim(),
      );

      final bool searchMatch =
          keyword.isEmpty ||
              lawyerName.contains(keyword);

      return categoryMatch && searchMatch;
    }).toList();

    // ==========================================================
    // 3. SẮP XẾP
    // ==========================================================

    switch (_selectedSort) {
      case 'Đánh giá cao nhất':
        result.sort(
              (a, b) => b.rating.compareTo(a.rating),
        );
        break;

      case 'Kinh nghiệm nhiều nhất':
        result.sort(
              (a, b) => b.experience.compareTo(a.experience),
        );
        break;

      case 'Giá thấp nhất':
        result.sort(
              (a, b) => a.price.compareTo(b.price),
        );
        break;

      case 'Giá cao nhất':
        result.sort(
              (a, b) => b.price.compareTo(a.price),
        );
        break;

      case 'Mặc định':
      default:
        break;
    }

    return result;
  }

  // =============================================================
  // ERROR STATE
  // =============================================================
  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF9AAABD),
            size: 42,
          ),
          const SizedBox(height: 10),
          const Text(
            'Không thể tải danh sách luật sư',
            style: TextStyle(
              color: Color(0xFF304E6C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: _fetchLawyers, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  // =============================================================
  // EMPTY STATE
  // =============================================================
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            color: Colors.grey.shade400,
            size: 45,
          ),
          const SizedBox(height: 10),
          Text(
            'Không tìm thấy luật sư phù hợp',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // PAGINATION
  // =============================================================
  Widget _buildPagination() {
    if (_isLoading || _errorMessage != null) {
      return const SizedBox.shrink();
    }
    final int totalItems = _getFilteredLawyers().length;
    const int pageSize = 6;
    final int totalPages = (totalItems / pageSize).ceil();
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageButton(
          icon: Icons.chevron_left_rounded,
          onTap: () {
            if (_currentPage > 1) {
              setState(() {
                _currentPage--;
              });
            }
          },
        ),
        const SizedBox(width: 7),
        ...List.generate(totalPages, (index) {
          final int page = index + 1;
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: _buildPageNumber(page),
          );
        }),
        _buildPageButton(
          icon: Icons.chevron_right_rounded,
          onTap: () {
            if (_currentPage < totalPages) {
              setState(() {
                _currentPage++;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPageNumber(int page) {
    final bool selected = _currentPage == page;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentPage = page;
        });
      },
      child: Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFC68A2B) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? const Color(0xFFC68A2B) : const Color(0xFFDCE5EE),
          ),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF244B75),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDCE5EE)),
        ),
        child: Icon(icon, color: const Color(0xFF244B75), size: 18),
      ),
    );
  }

  // =============================================================
  // SORT BOTTOM SHEET
  // =============================================================
  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final options = [
          'Mặc định',
          'Đánh giá cao nhất',
          'Kinh nghiệm nhiều nhất',
          'Giá thấp nhất',
          'Giá cao nhất',
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sắp xếp theo',
                    style: TextStyle(
                      color: Color(0xFF123E72),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...options.map((option) {
                  final bool selected = _selectedSort == option;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFFC68A2B)
                            : const Color(0xFF304E6C),
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Color(0xFFC68A2B),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSort = option;
                        _currentPage = 1;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // =============================================================
// OPEN LAWYER DETAIL
// =============================================================
  void _openLawyerProfile(_ClientLawyerItemData lawyer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ClientLawyerDetailScreen(
            lawyerId: lawyer.id.toString(),
          );
        },
      ),
    );
  }

  // =============================================================
  // BOOK CONSULTATION
  // =============================================================
  void _onBookConsultation(_ClientLawyerItemData lawyer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientConsultationScreen(
          lawyerId: lawyer.id.toString(),
        ),
      ),
    );
  }
}

// =================================================================
// LAWYER ITEM MODEL
// =================================================================
class _ClientLawyerItemData {
  const _ClientLawyerItemData({
    required this.id,
    required this.name,
    required this.title,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.price,
    required this.specialties,
    required this.imageUrl,
    required this.isActive,
    required this.isFeatured,
  });

  final dynamic id;
  final String name;
  final String title;
  final double rating;
  final int reviews;
  final int experience;
  final int price;
  final List<String> specialties;
  final String imageUrl;
  final bool isActive;
  final bool isFeatured;
}

// =================================================================
// LAWYER CARD
// =================================================================
class _ClientLawyerCard extends StatelessWidget {
  const _ClientLawyerCard({
    required this.lawyer,
    this.onProfilePressed,
    this.onBookPressed,
  });

  final _ClientLawyerItemData lawyer;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onBookPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lawyer.isFeatured
              ? const Color(0xFFE8BD70)
              : const Color(0xFFE1EAF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // IMAGE
            // ====================================================
            _buildImage(),
            const SizedBox(height: 7),
            // ====================================================
            // NAME
            // ====================================================
            Text(
              lawyer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF103665),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            // ====================================================
            // TITLE
            // ====================================================
            Text(
              lawyer.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF7A91AA), fontSize: 9.5),
            ),
            const SizedBox(height: 5),
            // ====================================================
            // RATING
            // ====================================================
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFEAA62C),
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  lawyer.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFFE08E14),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    lawyer.reviews > 0
                        ? '${lawyer.reviews} đánh giá'
                        : 'Chưa có số đánh giá',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8297AC),
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ====================================================
            // EXPERIENCE
            // ====================================================
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF597996),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${lawyer.experience} năm kinh nghiệm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF647E98),
                      fontSize: 8.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ====================================================
            // SPECIALTIES
            // ====================================================
            SizedBox(
              height: 23,
              child: lawyer.specialties.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lawyer.specialties.length,
                      separatorBuilder: (_, __) {
                        return const SizedBox(width: 4);
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FF),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            lawyer.specialties[index],
                            style: const TextStyle(
                              color: Color(0xFF316895),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Spacer(),
            // ==================================================== // PRICE // ====================================================
            if (lawyer.price > 0)
              Text(
                'Từ ${_formatPrice(lawyer.price)} / giờ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF183D69),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              const Text(
                'Liên hệ để biết phí',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF183D69),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 7),
            // ==================================================== // BUTTONS // ====================================================
            Row(
              children: [
                // ------------------------------------------------
                // XEM HỒ SƠ
                // ------------------------------------------------
                Expanded(
                  child: SizedBox(
                    height: 31,
                    child: OutlinedButton(
                      onPressed: onProfilePressed,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(
                          color: Color(0xFF759CC1),
                          width: 1.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 12,
                            color: Color(0xFF316A9D),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Xem hồ sơ',
                            style: TextStyle(
                              color: Color(0xFF316A9D),
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                // ------------------------------------------------ // ĐẶT LỊCH // ------------------------------------------------
                Expanded(
                  child: SizedBox(
                    height: 31,
                    child: ElevatedButton(
                      onPressed: onBookPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC48A2B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 11),
                          SizedBox(width: 3),
                          Text(
                            'Đặt lịch tư vấn',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
  } // ============================================================= // IMAGE // =============================================================
  String _formatPrice(num price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
    )} đ';
  }
  Widget _buildImage() {
    return SizedBox(
      height: 91,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: lawyer.imageUrl.isNotEmpty
                ? Image.network(
                    _resolveImageUrl(lawyer.imageUrl),
                    width: 91,
                    height: 91,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar();
                    },
                  )
                : _buildDefaultAvatar(),
          ),
          // ------------------------------------------------------- // FEATURED // -------------------------------------------------------
          if (lawyer.isFeatured)
            Positioned(
              left: -2,
              top: -1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFFC68A2B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: const Text(
                  'Nổi bật',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // ------------------------------------------------------- // ACTIVE // -------------------------------------------------------
          if (lawyer.isActive)
            Positioned(right: 1, top: 1, child: _buildActiveStatus()),
        ],
      ),
    );
  } // ============================================================= // RESOLVE IMAGE URL // =============================================================

  String _resolveImageUrl(String url) {
    if (url.isEmpty) {
      return '';
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    const String serverUrl = 'http://10.0.2.2:5000';
    if (url.startsWith('/')) {
      return '$serverUrl$url';
    }
    return '$serverUrl/$url';
  }
  // =============================================================
  // DEFAULT AVATAR
  // =============================================================
  Widget _buildDefaultAvatar() {
    return Container(
      width: 91,
      height: 91,
      decoration: BoxDecoration(
        color: const Color(0xFFE7EDF3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF8296AA),
        size: 45,
      ),
    );
  } // ============================================================= // ACTIVE STATUS // =============================================================

  Widget _buildActiveStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFEADD)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Color(0xFF12A875), size: 6),
          SizedBox(width: 3),
          Text(
            'Đang hoạt động',
            style: TextStyle(
              color: Color(0xFF14986E),
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
