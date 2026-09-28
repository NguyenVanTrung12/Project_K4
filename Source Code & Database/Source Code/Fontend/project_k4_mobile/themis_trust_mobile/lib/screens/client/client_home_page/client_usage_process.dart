import 'package:flutter/material.dart';

class ClientHomeUsageProcessWidget extends StatelessWidget {
  const ClientHomeUsageProcessWidget({
    super.key,
    this.onStartPressed,
    this.onStepPressed,
  });

  final VoidCallback? onStartPressed;
  final ValueChanged<int>? onStepPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        14,
        22,
        14,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          const Text(
            'QUY TRÌNH SỬ DỤNG',
            style: TextStyle(
              color: Color(0xFF17609D),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 3),

          const Text(
            'Chỉ 4 bước đơn giản',
            style: TextStyle(
              color: Color(0xFF0B2C57),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          // ======================================================
          // DESCRIPTION
          // ======================================================

          const Text(
            'Từ tìm kiếm luật sư đến nhận tư vấn, mọi\n'
                'thủ tục đều trở nên dễ dàng và nhanh chóng\n'
                'với Themis & Cộng sự.',
            style: TextStyle(
              color: Color(0xFF7189A4),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 15),

          // ======================================================
          // STEPS
          // ======================================================

          _buildSteps(),

          const SizedBox(height: 13),

          // ======================================================
          // START BUTTON
          // ======================================================
        ],
      ),
    );
  }

  // =============================================================
  // STEPS
  // =============================================================

  Widget _buildSteps() {
    return Column(
      children: List.generate(
        _usageSteps.length,
            (index) {
          final step = _usageSteps[index];

          return _ClientUsageStepItem(
            stepNumber: step.stepNumber,
            title: step.title,
            description: step.description,
            icon: step.icon,
            isLast: index == _usageSteps.length - 1,
            onTap: () {
              onStepPressed?.call(
                step.stepNumber,
              );
            },
          );
        },
      ),
    );
  }

  // =============================================================
  // START BUTTON
  // =============================================================

}

// =================================================================
// DATA
// =================================================================

class _ClientUsageStepData {
  const _ClientUsageStepData({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });

  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
}

// =================================================================
// USAGE STEPS
// =================================================================

const List<_ClientUsageStepData> _usageSteps = [
  _ClientUsageStepData(
    stepNumber: 1,
    title: 'Tìm kiếm luật sư',
    description:
    'Lọc theo lĩnh vực, kinh nghiệm,\n'
        'đánh giá...',
    icon: Icons.search_rounded,
  ),

  _ClientUsageStepData(
    stepNumber: 2,
    title: 'Đặt lịch tư vấn',
    description:
    'Chọn thời gian và hình thức\n'
        'tư vấn phù hợp.',
    icon: Icons.calendar_month_rounded,
  ),

  _ClientUsageStepData(
    stepNumber: 3,
    title: 'Trao đổi & tư vấn',
    description:
    'Nhận tư vấn trực tiếp từ luật sư\n'
        'qua chat hoặc cuộc gọi.',
    icon: Icons.chat_bubble_rounded,
  ),

  _ClientUsageStepData(
    stepNumber: 4,
    title: 'Theo dõi hồ sơ',
    description:
    'Cập nhật tiến độ và đánh giá\n'
        'dịch vụ.',
    icon: Icons.description_rounded,
  ),
];

// =================================================================
// STEP ITEM
// =================================================================

class _ClientUsageStepItem extends StatelessWidget {
  const _ClientUsageStepItem({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.isLast,
    this.onTap,
  });

  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 103,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // ICON + CONNECTOR
            // ====================================================

            SizedBox(
              width: 67,
              child: Column(
                children: [
                  // ------------------------------------------------
                  // ICON CIRCLE
                  // ------------------------------------------------

                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEAF3FF),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF15549A),
                      size: 28,
                    ),
                  ),

                  // ------------------------------------------------
                  // VERTICAL LINE
                  // ------------------------------------------------

                  if (!isLast)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.only(
                            top: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDDEAF8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 11),

            // ====================================================
            // CONTENT
            // ====================================================

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  right: 3,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // ----------------------------------------------
                    // TITLE
                    // ----------------------------------------------

                    Text(
                      '$stepNumber. $title',
                      style: const TextStyle(
                        color: Color(0xFF123E72),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // ----------------------------------------------
                    // DESCRIPTION
                    // ----------------------------------------------

                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF7189A4),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}