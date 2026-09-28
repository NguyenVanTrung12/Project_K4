import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/models/practice_area_model.dart';
import 'package:themis_trust_mobile/services/practice_area_service.dart';

class ClientHomeLegalFieldsWidget extends StatefulWidget {
  const ClientHomeLegalFieldsWidget({
    super.key,
    this.onViewAll,
    this.onFieldSelected,
  });

  final VoidCallback? onViewAll;
  final ValueChanged<String>? onFieldSelected;

  @override
  State<ClientHomeLegalFieldsWidget> createState() =>
      _ClientHomeLegalFieldsWidgetState();
}

class _ClientHomeLegalFieldsWidgetState
    extends State<ClientHomeLegalFieldsWidget> {
  final PracticeAreaService _practiceAreaService = PracticeAreaService();

  List<PracticeAreaModel> _practiceAreas = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPracticeAreaServices();
  }

  // =============================================================
  // LOAD API
  // =============================================================

  Future<void> _loadPracticeAreaServices() async {
    try {
      final result = await _practiceAreaService.getPracticeAreas();

      if (!mounted) return;

      setState(() {
        _practiceAreas = result.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      debugPrint('Load Legal Services Error: $e');
    }
  }

  // =============================================================
  // ICON
  // =============================================================
  // =============================================================
  // ICON
  // =============================================================

  IconData _getIcon(String? iconKey) {
    switch (iconKey?.toLowerCase()) {
      // Hình sự
      case 'gavel':
        return Icons.gavel_outlined;

      // Dân sự
      case 'balance':
        return Icons.balance_outlined;

      // Doanh nghiệp
      case 'apartment':
        return Icons.apartment_outlined;

      // Hôn nhân
      case 'family_restroom':
        return Icons.family_restroom_outlined;

      // Đất đai
      case 'landscape':
        return Icons.landscape_outlined;

      default:
        return Icons.gavel_outlined;
    }
  }

  // =============================================================
  // ICON COLOR
  // =============================================================

  Color _getIconColor(String? iconKey) {
    switch (iconKey?.toLowerCase()) {
      // Hình sự
      case 'gavel':
        return const Color(0xFF90601F);

      // Dân sự
      case 'balance':
        return const Color(0xFF15539A);

      // Doanh nghiệp
      case 'apartment':
        return const Color(0xFF98621D);

      // Hôn nhân
      case 'family_restroom':
        return const Color(0xFFD6334C);

      // Đất đai
      case 'landscape':
        return const Color(0xFFA54D38);

      default:
        return const Color(0xFF1460A0);
    }
  }

  // =============================================================
  // ICON BACKGROUND
  // =============================================================

  Color _getIconBackground(String? iconKey) {
    switch (iconKey?.toLowerCase()) {
      // Hình sự
      case 'gavel':
        return const Color(0xFFF8F0E4);

      // Dân sự
      case 'balance':
        return const Color(0xFFEAF2FF);

      // Doanh nghiệp
      case 'apartment':
        return const Color(0xFFF8F0E2);

      // Hôn nhân
      case 'family_restroom':
        return const Color(0xFFFFE9ED);

      // Đất đai
      case 'landscape':
        return const Color(0xFFFFEEEA);

      default:
        return const Color(0xFFEAF3FF);
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
      padding: const EdgeInsets.fromLTRB(13, 22, 13, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          _buildHeader(),

          const SizedBox(height: 7),

          // ======================================================
          // DESCRIPTION
          // ======================================================
          const Text(
            'Chúng tôi cung cấp đa dạng các dịch vụ pháp lý,',
            style: TextStyle(
              color: Color(0xFF6F88A4),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),

          const Text(
            'đáp ứng mọi nhu cầu của cá nhân và doanh nghiệp.',
            style: TextStyle(
              color: Color(0xFF6F88A4),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // CONTENT
          // ======================================================
          _buildContent(),
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
          child: Text(
            'Các lĩnh vực pháp lý\nphổ biến',
            style: TextStyle(
              color: Color(0xFF0B2C57),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -0.3,
            ),
          ),
        ),

      ],
    );
  }

  // =============================================================
  // CONTENT
  // =============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_practiceAreas.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'Chưa có dịch vụ pháp lý',
            style: TextStyle(color: Color(0xFF7189A4), fontSize: 13),
          ),
        ),
      );
    }

    return _buildLegalFieldGrid();
  }

  // =============================================================
  // ERROR
  // =============================================================

  Widget _buildError() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 36,
          ),

          const SizedBox(height: 8),

          const Text(
            'Không thể tải dữ liệu',
            style: TextStyle(
              color: Color(0xFF123A69),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });

              _loadPracticeAreaServices();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // GRID
  // =============================================================

  Widget _buildLegalFieldGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      itemCount: _practiceAreas.length,

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.91,
      ),

      itemBuilder: (context, index) {
        final service = _practiceAreas[index];

        return _ClientLegalFieldCard(
          name: service.name,

          sortOrder: service.sortOrder,

          icon: _getIcon(service.iconKey),

          iconColor: _getIconColor(service.iconKey),

          iconBackground: _getIconBackground(service.iconKey),

          onTap: () {
            widget.onFieldSelected?.call(service.name);
          },
        );
      },
    );
  }
}

// =================================================================
// LEGAL FIELD CARD
// =================================================================

class _ClientLegalFieldCard extends StatelessWidget {
  const _ClientLegalFieldCard({
    required this.name,
    required this.sortOrder,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.onTap,
  });

  final String name;
  final int sortOrder;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 9, 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4ECF5), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF183B60).withOpacity(0.035),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==============================
              // ICON + NÚT MŨI TÊN
              // ==============================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon lĩnh vực
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBackground,
                    ),
                    child: Icon(icon, color: iconColor, size: 30),
                  ),
                  //Nút mũi tên
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEAF3FF),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF2973B8),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ==============================
              // TÊN LĨNH VỰC
              // ==============================
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF123A69),
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              // ==============================
              // SORT ORDER
              //==============================
              Text(
                'Lĩnh vực $sortOrder',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7A8CA3),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
