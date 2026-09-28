import 'package:flutter/material.dart';

class ClientHomeBannerWidget extends StatefulWidget {
  const ClientHomeBannerWidget({
    super.key,
    this.onSearch,
    this.onTopicSelected,
  });

  final ValueChanged<String>? onSearch;
  final ValueChanged<String>? onTopicSelected;

  @override
  State<ClientHomeBannerWidget> createState() =>
      _ClientHomeBannerWidgetState();
}

class _ClientHomeBannerWidgetState
    extends State<ClientHomeBannerWidget> {
  final TextEditingController _searchController =
  TextEditingController();

  final List<String> _popularTopics = [
    'Tranh chấp đất đai',
    'Ly hôn',
    'Thành lập công ty',
    'Tư vấn hình sự',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final String keyword = _searchController.text.trim();

    if (keyword.isEmpty) {
      return;
    }

    widget.onSearch?.call(keyword);
  }

  void _handleTopicSelected(String topic) {
    setState(() {
      _searchController.text = topic;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(
          offset: _searchController.text.length,
        ),
      );
    });

    widget.onTopicSelected?.call(topic);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF061D32),
      child: Stack(
        children: [
          // ======================================================
          // BACKGROUND
          // ======================================================

          Positioned.fill(
            child: Image.asset(
              'assets/images/banner1.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ======================================================
          // DARK OVERLAY
          // ======================================================

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF061D32).withOpacity(0.10),
                    const Color(0xFF061D32).withOpacity(0.18),
                    const Color(0xFF061D32).withOpacity(0.45),
                    const Color(0xFF061D32).withOpacity(0.92),
                  ],
                  stops: const [
                    0.0,
                    0.30,
                    0.65,
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              80,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // SMALL TITLE
                // ------------------------------------------------

                const Text(
                  'NỀN TẢNG KẾT NỐI BẠN\n'
                      'VỚI LUẬT SƯ UY TÍN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    letterSpacing: 0.15,
                  ),
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // MAIN TITLE
                // ------------------------------------------------

                const Text(
                  'Tìm đúng luật sư\n'
                      'cho vấn đề của bạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 33,
                    fontWeight: FontWeight.w700,
                    height: 1.13,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 19),

                // ------------------------------------------------
                // DESCRIPTION
                // ------------------------------------------------

                const Text(
                  'Themis Trust giúp bạn dễ dàng tìm\n'
                      'kiếm luật sư phù hợp và nhận tư vấn\n'
                      'pháp lý chuyên nghiệp, nhanh chóng,\n'
                      'bảo mật.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w400,
                    height: 1.52,
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // SEARCH BOX
                // ------------------------------------------------

                _buildSearchBox(),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // POPULAR TITLE
                // ------------------------------------------------

                const Text(
                  'Tìm kiếm phổ biến:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 13),

                // ------------------------------------------------
                // POPULAR TOPICS
                // ------------------------------------------------

                _buildPopularTopics(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BOX
  // ============================================================

  Widget _buildSearchBox() {
    return Container(
      width: double.infinity,
      height: 72,
      padding: const EdgeInsets.only(
        left: 16,
        right: 6,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E9ED),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ------------------------------------------------------
          // SEARCH ICON
          // ------------------------------------------------------

          const Icon(
            Icons.search_rounded,
            color: Color(0xFF315B82),
            size: 28,
          ),

          const SizedBox(width: 10),

          // ------------------------------------------------------
          // TEXT FIELD
          // ------------------------------------------------------

          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _handleSearch();
              },
              style: const TextStyle(
                color: Color(0xFF183A5A),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText:
                'Bạn đang cần hỗ trợ về vấn đề gì?',
                hintStyle: TextStyle(
                  color: Color(0xFF8DA4B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ------------------------------------------------------
          // SEARCH BUTTON
          // ------------------------------------------------------

          GestureDetector(
            onTap: _handleSearch,
            child: Container(
              width: 61,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFC79132),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 29,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POPULAR TOPICS
  // ============================================================

  Widget _buildPopularTopics() {
    return Wrap(
      spacing: 12,
      runSpacing: 11,
      children: _popularTopics.map(
            (String topic) {
          return _buildTopicItem(topic);
        },
      ).toList(),
    );
  }

  // ============================================================
  // TOPIC ITEM
  // ============================================================

  Widget _buildTopicItem(String topic) {
    return GestureDetector(
      onTap: () {
        _handleTopicSelected(topic);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF112F4B).withOpacity(0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF31516D),
            width: 1,
          ),
        ),
        child: Text(
          topic,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}