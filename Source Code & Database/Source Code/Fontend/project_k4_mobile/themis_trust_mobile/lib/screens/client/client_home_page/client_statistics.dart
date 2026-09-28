import 'package:flutter/material.dart';
import 'package:themis_trust_mobile/services/api_service.dart';

class ClientHomeStatisticsWidget extends StatefulWidget {
  const ClientHomeStatisticsWidget({
    super.key,
  });

  @override
  State<ClientHomeStatisticsWidget> createState() =>
      _ClientHomeStatisticsWidgetState();
}

class _ClientHomeStatisticsWidgetState
    extends State<ClientHomeStatisticsWidget> {
  // =============================================================
  // API
  // =============================================================

  final ApiService _api = ApiService();

  // =============================================================
  // STATE
  // =============================================================

  int _lawyers = 0;
  int _clients = 0;
  int _cases = 0;
  double _rating = 0;

  bool _isLoading = true;

  // =============================================================
  // COLORS
  // =============================================================

  static const Color _blue = Color(0xFF174B87);
  static const Color _gold = Color(0xFF9B691E);

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _loadStatistics();
  }

  // =============================================================
  // LOAD STATISTICS
  // =============================================================

  Future<void> _loadStatistics() async {
    try {
      final data = await _api.get(
        '/dashboard/public-stats',
      );

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Dữ liệu thống kê không hợp lệ',
        );
      }

      if (!mounted) return;

      setState(() {
        _lawyers = _toInt(data['lawyers']);
        _clients = _toInt(data['clients']);
        _cases = _toInt(data['cases']);
        _rating = _toDouble(data['rating']);

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'LOAD PUBLIC STATISTICS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // =============================================================
  // CONVERT INT
  // =============================================================

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(
      value.toString(),
    ) ??
        0;
  }

  // =============================================================
  // CONVERT DOUBLE
  // =============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    ) ??
        0;
  }

  // =============================================================
  // FORMAT NUMBER
  //
  // 2500 -> 2.500
  // 5000 -> 5.000
  // =============================================================

  String _formatNumber(int number) {
    final text = number.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  // =============================================================
  // FORMAT RATING
  //
  // 4.5 -> 4.5
  // 5 -> 5
  // =============================================================

  String _formatRating(double rating) {
    if (rating == rating.roundToDouble()) {
      return rating.toInt().toString();
    }

    return rating.toStringAsFixed(1);
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: _isLoading
          ? const _StatisticsLoading()
          : Column(
        children: [
          // =================================================
          // ROW 1
          // =================================================

          Row(
            children: [
              Expanded(
                child: _ClientStatisticsItem(
                  icon:
                  Icons.person_outline_rounded,
                  value:
                  '${_formatNumber(_lawyers)}+',
                  description:
                  'Luật sư\nchuyên môn',
                  iconType:
                  _ClientStatisticsIconType
                      .blue,
                ),
              ),

              const SizedBox(width: 4),

              Expanded(
                child: _ClientStatisticsItem(
                  icon: Icons
                      .workspace_premium_outlined,
                  value:
                  '${_formatNumber(_clients)}+',
                  description:
                  'Khách hàng\ntin tưởng',
                  iconType:
                  _ClientStatisticsIconType
                      .gold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // =================================================
          // ROW 2
          // =================================================

          Row(
            children: [
              Expanded(
                child: _ClientStatisticsItem(
                  icon: Icons
                      .folder_copy_outlined,
                  value:
                  '${_formatNumber(_cases)}+',
                  description:
                  'Vụ việc đã hỗ trợ',
                  iconType:
                  _ClientStatisticsIconType
                      .gold,
                ),
              ),

              const SizedBox(width: 4),

              Expanded(
                child: _ClientStatisticsItem(
                  icon: Icons
                      .verified_user_outlined,
                  value:
                  '${_formatRating(_rating)}/5',
                  description:
                  'Điểm đánh giá\ntrung bình',
                  iconType:
                  _ClientStatisticsIconType
                      .gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =================================================================
// LOADING
// =================================================================

class _StatisticsLoading extends StatelessWidget {
  const _StatisticsLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatisticsLoadingItem(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _StatisticsLoadingItem(),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Row(
          children: [
            Expanded(
              child: _StatisticsLoadingItem(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _StatisticsLoadingItem(),
            ),
          ],
        ),
      ],
    );
  }
}

// =================================================================
// LOADING ITEM
// =================================================================

class _StatisticsLoadingItem
    extends StatelessWidget {
  const _StatisticsLoadingItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8EEF5),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFC68A2B),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// STATISTICS ICON TYPE
// =================================================================

enum _ClientStatisticsIconType {
  blue,
  gold,
}

// =================================================================
// STATISTICS ITEM
// =================================================================

class _ClientStatisticsItem
    extends StatelessWidget {
  const _ClientStatisticsItem({
    required this.icon,
    required this.value,
    required this.description,
    required this.iconType,
  });

  final IconData icon;
  final String value;
  final String description;
  final _ClientStatisticsIconType iconType;

  @override
  Widget build(BuildContext context) {
    final bool isBlue =
        iconType ==
            _ClientStatisticsIconType.blue;

    return Container(
      height: 118,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8EEF5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173A5D)
                .withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ======================================================
          // ICON CIRCLE
          // ======================================================

          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBlue
                  ? const Color(0xFFEAF2FC)
                  : const Color(0xFFF8F0E3),
            ),
            child: Icon(
              icon,
              size: 27,
              color: isBlue
                  ? const Color(0xFF174B87)
                  : const Color(0xFF9B691E),
            ),
          ),

          const SizedBox(width: 12),

          // ======================================================
          // TEXT
          // ======================================================

          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                    Color(0xFF102E52),
                    fontSize: 23,
                    fontWeight:
                    FontWeight.w700,
                    height: 1.0,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  description,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                    Color(0xFF7188A3),
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}