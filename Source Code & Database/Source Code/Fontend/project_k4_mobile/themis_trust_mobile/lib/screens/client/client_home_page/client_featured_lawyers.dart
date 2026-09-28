import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/models/lawyer_model.dart';
import 'package:themis_trust_mobile/screens/client/client_lawyer_page/client_lawyers_screen.dart';
import 'package:themis_trust_mobile/services/lawyer_service.dart';

class ClientHomeFeaturedLawyersWidget extends StatefulWidget {
  const ClientHomeFeaturedLawyersWidget({
    super.key,
    this.onViewAll,
    this.onLawyerSelected,
    this.onBookConsultation,
  });

  final VoidCallback? onViewAll;
  final ValueChanged<LawyerModel>? onLawyerSelected;
  final ValueChanged<LawyerModel>? onBookConsultation;

  @override
  State<ClientHomeFeaturedLawyersWidget> createState() =>
      _ClientHomeFeaturedLawyersWidgetState();
}

class _ClientHomeFeaturedLawyersWidgetState
    extends State<ClientHomeFeaturedLawyersWidget> {
  // =============================================================
  // SERVICE
  // =============================================================

  final LawyerService _lawyerService = LawyerService();

  // =============================================================
  // DATA
  // =============================================================

  List<LawyerModel> _lawyers = [];
  bool _isLoading = true;
  String? _errorMessage;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();
    _fetchFeaturedLawyers();
  }

  // =============================================================
  // CALL API
  // =============================================================

  Future<void> _fetchFeaturedLawyers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final List<LawyerModel> result =
      await _lawyerService.GetLatest();

      if (!mounted) return;

      // DEBUG AVATAR
      for (final lawyer in result) {
        debugPrint(
          '[LAWYER] ${lawyer.fullName} | '
              'avatarUrl = "${lawyer.avatarUrl}"',
        );
      }

      // Chỉ lấy luật sư đang hoạt động
      final List<LawyerModel> availableLawyers = result
          .where((lawyer) => lawyer.isAvailable)
          .toList();

      // Sắp xếp theo đánh giá cao → thấp
      availableLawyers.sort(
            (a, b) => b.ratingAvg.compareTo(a.ratingAvg),
      );

      // Lấy tối đa 6 luật sư
      final List<LawyerModel> featuredLawyers =
      availableLawyers.take(6).toList();

      setState(() {
        _lawyers = featuredLawyers;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('Lỗi khi lấy danh sách luật sư: $e');

      setState(() {
        _lawyers = [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(13, 22, 13, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),

          if (_isLoading)
            _buildLoading()
          else if (_errorMessage != null)
            _buildError()
          else if (_lawyers.isEmpty)
              _buildEmpty()
            else
              _buildLawyerGrid(),
        ],
      ),
    );
  }

  // =============================================================
  // HEADER
  // =============================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LUẬT SƯ NỔI BẬT',
                style: TextStyle(
                  color: Color(0xFF17609D),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Đội ngũ luật sư\n'
                    'giàu kinh nghiệm',
                style: TextStyle(
                  color: Color(0xFF0B2C57),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: () {
            if (widget.onViewAll != null) {
              widget.onViewAll!();
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ClientLawyersScreen(),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xem tất cả luật sư',
                  style: TextStyle(
                    color: Color(0xFF17609D),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF17609D),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // LAWYER GRID
  // =============================================================

  Widget _buildLawyerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lawyers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 9,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final LawyerModel lawyer = _lawyers[index];

        return _ClientHomeLawyerCard(
          lawyer: lawyer,
          onProfilePressed: () {
            widget.onLawyerSelected?.call(lawyer);
          },
          onBookPressed: () {
            widget.onBookConsultation?.call(lawyer);
          },
        );
      },
    );
  }

  // =============================================================
  // LOADING
  // =============================================================

  Widget _buildLoading() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 9,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: const Color(0xFFE6EDF5),
            ),
          ),
          child: const Center(
            child: SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // ERROR
  // =============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'Không thể tải danh sách luật sư',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF647E98),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _fetchFeaturedLawyers,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // EMPTY
  // =============================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 42,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            'Chưa có luật sư',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// LAWYER CARD
// =================================================================

class _ClientHomeLawyerCard extends StatelessWidget {
  const _ClientHomeLawyerCard({
    required this.lawyer,
    this.onProfilePressed,
    this.onBookPressed,
  });

  final LawyerModel lawyer;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onBookPressed;

  // =============================================================
  // AVATAR URL
  // =============================================================

  String get avatarUrl {
    final String? url = lawyer.avatarUrl;

    if (url == null || url.trim().isEmpty) {
      return '';
    }

    final String value = url.trim();

    // API trả URL đầy đủ
    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    // API trả đường dẫn tương đối
    if (value.startsWith('/')) {
      return 'http://10.0.2.2:5000$value';
    }

    // Trường hợp API trả thiếu dấu /
    return 'http://10.0.2.2:5000/$value';
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE1EAF3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173A5D).withOpacity(0.045),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),

            const SizedBox(height: 7),

            Text(
              lawyer.fullName.isNotEmpty
                  ? lawyer.fullName
                  : 'Luật sư',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF103665),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              lawyer.title.isNotEmpty
                  ? lawyer.title
                  : 'Luật sư',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7A91AA),
                fontSize: 10.5,
              ),
            ),

            const SizedBox(height: 5),

            _buildRating(),

            const SizedBox(height: 4),

            _buildExperience(),

            const SizedBox(height: 6),

            _buildPracticeAreas(),

            const Spacer(),

            const SizedBox(height: 6),

            _buildCasesWon(),

            const SizedBox(height: 8),

            _buildButtons(),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // AVATAR
  // =============================================================

  Widget _buildAvatar() {
    final String url = avatarUrl;

    debugPrint(
      '[AVATAR] ${lawyer.fullName} -> "$url"',
    );

    return SizedBox(
      width: double.infinity,
      height: 105,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: avatarUrl.isNotEmpty
                ? Image.network(
              avatarUrl,
              width: 105,
              height: 105,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAvatar();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  width: 105,
                  height: 105,
                  color: const Color(0xFFE9EEF4),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            )
                : _buildDefaultAvatar(),
          ),
          // ------------------------------------------------------- // ACTIVE // -------------------------------------------------------
          if (lawyer.isAvailable)
            Positioned(top: 3, right: 2, child: _buildActiveStatus()),
        ],
      ),
    );
  }

  // =============================================================
  // DEFAULT AVATAR
  // =============================================================

  Widget _buildDefaultAvatar() {
    return Container(
      width: double.infinity,
      height: 105,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF4),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 52,
        color: Color(0xFF8296AA),
      ),
    );
  }

  // =============================================================
  // ACTIVE STATUS
  // =============================================================

  Widget _buildActiveStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFBFEADD),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: Color(0xFF12A875),
            size: 7,
          ),
          SizedBox(width: 4),
          Text(
            'Đang hoạt động',
            style: TextStyle(
              color: Color(0xFF14986E),
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // RATING
  // =============================================================

  Widget _buildRating() {
    return Row(
      children: [
        const Icon(
          Icons.star_rounded,
          color: Color(0xFFEAA62C),
          size: 15,
        ),
        const SizedBox(width: 3),
        Text(
          lawyer.ratingAvg.toStringAsFixed(1),
          style: const TextStyle(
            color: Color(0xFFE08E14),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 3),
        const Expanded(
          child: Text(
            'Đánh giá',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF8297AC),
              fontSize: 8.5,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // EXPERIENCE
  // =============================================================

  Widget _buildExperience() {
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: Color(0xFF597996),
          size: 13,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${lawyer.yearsExp} năm kinh nghiệm',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF647E98),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // PRACTICE AREAS
  // =============================================================

  Widget _buildPracticeAreas() {
    final List<String> areas = lawyer.practiceAreas;

    if (areas.isEmpty) {
      return Container(
        height: 24,
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Text(
          'Pháp lý',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFF316895),
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final List<String> displayAreas =
    areas.take(2).toList();

    return SizedBox(
      height: 24,
      child: Row(
        children: [
          for (int i = 0; i < displayAreas.length; i++) ...[
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  displayAreas[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF316895),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (i < displayAreas.length - 1)
              const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  // =============================================================
  // CASES WON
  // =============================================================

  Widget _buildCasesWon() {
    return Row(
      children: [
        const Icon(
          Icons.gavel_rounded,
          color: Color(0xFF597996),
          size: 13,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${lawyer.casesWon} vụ việc đã xử lý',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF647E98),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // BUTTONS
  // =============================================================

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: onProfilePressed,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: const BorderSide(
                  color: Color(0xFF759CC1),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Xem hồ sơ',
                maxLines: 1,
                style: TextStyle(
                  color: Color(0xFF316A9D),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 5),

        Expanded(
          child: SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: onBookPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC48A2B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Đặt lịch tư vấn',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}