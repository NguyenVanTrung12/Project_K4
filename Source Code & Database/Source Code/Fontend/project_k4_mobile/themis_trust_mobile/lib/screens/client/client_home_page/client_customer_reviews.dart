import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/models/review_model.dart';
import 'package:themis_trust_mobile/services/review_service.dart';

class ClientHomeCustomerReviewsWidget extends StatefulWidget {
  const ClientHomeCustomerReviewsWidget({super.key, this.onReviewPressed});

  final ValueChanged<ReviewModel>? onReviewPressed;

  @override
  State<ClientHomeCustomerReviewsWidget> createState() =>
      _ClientHomeCustomerReviewsWidgetState();
}

// =================================================================
// STATE
// =================================================================
class _ClientHomeCustomerReviewsWidgetState
    extends State<ClientHomeCustomerReviewsWidget> {
  // ===============================================================
  // SERVICE
  // ===============================================================
  final ReviewService _reviewService = ReviewService();

  // ===============================================================
  // DATA
  // ===============================================================
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ===============================================================
  // INIT
  // ===============================================================
  @override
  void initState() {
    super.initState();
    _fetchReviews();
  } // ===============================================================
  // CALL API
  // ===============================================================

  Future<void> _fetchReviews() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
      // ===========================================================
      // GỌI REVIEW SERVICE
      // ===========================================================
      final List<ReviewModel> result = await _reviewService.getReviews();
      if (!mounted) return;
      // ===========================================================
      // SẮP XẾP REVIEW MỚI NHẤT TRƯỚC
      // ===========================================================
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // ===========================================================
      // CHỈ HIỂN THỊ TỐI ĐA 3 REVIEW
      // ===========================================================
      final List<ReviewModel> displayReviews = result.take(3).toList();
      setState(() {
        _reviews = displayReviews;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Lỗi khi lấy danh sách đánh giá: $e');
      setState(() {
        _reviews = [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  } // =============================================================== // BUILD // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(13, 22, 13, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================== // HEADER // ======================================================
          const Text(
            'KHÁCH HÀNG NÓI VỀ CHÚNG TÔI',
            style: TextStyle(
              color: Color(0xFF17609D),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.45,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Niềm tin từ khách hàng',
            style: TextStyle(
              color: Color(0xFF0B2C57),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          // ====================================================== // CONTENT // ======================================================
          if (_isLoading)
            _buildLoading()
          else if (_errorMessage != null)
            _buildError()
          else if (_reviews.isEmpty)
              _buildEmpty()
            else
              _buildReviews(),
        ],
      ),
    );
  } // =============================================================== // REVIEWS // ===============================================================

  Widget _buildReviews() {
    return Column(
      children: _reviews.map((review) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ClientCustomerReviewCard(
            review: review,
            onTap: () {
              widget.onReviewPressed?.call(review);
            },
          ),
        );
      }).toList(),
    );
  } // =============================================================== // LOADING // ===============================================================

  Widget _buildLoading() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          height: 125,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFE3EBF4)),
          ),
          child: const Center(
            child: SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }),
    );
  } // =============================================================== // ERROR // ===============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'Không thể tải đánh giá khách hàng',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF647E98),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _fetchReviews,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  } // =============================================================== // EMPTY // ===============================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            'Chưa có đánh giá từ khách hàng',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
// =================================================================
// REVIEW CARD
// =================================================================

class _ClientCustomerReviewCard extends StatelessWidget {
  const _ClientCustomerReviewCard({required this.review, this.onTap});

  final ReviewModel review;
  final VoidCallback? onTap; // =============================================================== // BUILD // ===============================================================
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(11, 11, 10, 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFE3EBF4), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF173A5D).withOpacity(0.035),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================================================== // AVATAR // ==================================================
              _buildAvatar(),
              const SizedBox(width: 13),
              // ================================================== // CONTENT // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------------------------------------- // REVIEW CONTENT // ----------------------------------------------
                    _buildReviewContent(),
                    const SizedBox(height: 11),
                    // ---------------------------------------------- // CUSTOMER + STAR // ----------------------------------------------
                    _buildCustomerInfo(),
                    const SizedBox(height: 4),
                    // ---------------------------------------------- // ROLE + DATE // ----------------------------------------------
                    _buildDateInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } // =============================================================== // AVATAR // ===============================================================

  Widget _buildAvatar() {
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEAF0F6),
      ),
      child: ClipOval(child: _buildDefaultAvatar()),
    );
  } // =============================================================== // DEFAULT AVATAR // ===============================================================

  Widget _buildDefaultAvatar() {
    return const Center(
      child: Icon(Icons.person_rounded, color: Color(0xFF7890A8), size: 35),
    );
  } // =============================================================== // REVIEW CONTENT // ===============================================================

  Widget _buildReviewContent() {
    final String content = review.comment?.trim() ?? '';
    return Text(
      content.isNotEmpty
          ? '“$content”'
          : '“Khách hàng chưa để lại nội dung đánh giá.”',
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF7188A3),
        fontSize: 12.5,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        height: 1.42,
      ),
    );
  } // =============================================================== // CUSTOMER INFO // ===============================================================

  Widget _buildCustomerInfo() {
    final String name = review.clientName?.trim().isNotEmpty == true
        ? review.clientName!.trim()
        : 'Khách hàng';

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF123E72),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildStars(),
      ],
    );
  }
  // =============================================================== // STARS // ===============================================================

  Widget _buildStars() {
    final int fullStars = review.rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < fullStars ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFEBA321),
          size: 15,
        );
      }),
    );
  } // =============================================================== // DATE // ===============================================================

  Widget _buildDateInfo() {
    return Text(
      'Khách hàng | ${_formatDate(review.createdAt)}',
      style: const TextStyle(
        color: Color(0xFF7890A8),
        fontSize: 10.5,
        fontWeight: FontWeight.w400,
      ),
    );
  } // =============================================================== // FORMAT DATE // ===============================================================

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }
}
