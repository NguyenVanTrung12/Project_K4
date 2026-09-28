import 'package:flutter/material.dart';

class LawyerConsultationRequestDetail extends StatefulWidget {
  const LawyerConsultationRequestDetail({
    super.key, required Object request,
  });

  @override
  State<LawyerConsultationRequestDetail> createState() =>
      _LawyerConsultationRequestDetailState();
}

class _LawyerConsultationRequestDetailState
    extends State<LawyerConsultationRequestDetail> {
  // ============================================================
  // MÀU SẮC
  // ============================================================

  static const Color navy = Color(0xFF0D3558);
  static const Color darkNavy = Color(0xFF082D50);
  static const Color gold = Color(0xFFC88B2D);
  static const Color muted = Color(0xFF71839A);
  static const Color border = Color(0xFFE2EAF2);
  static const Color background = Color(0xFFF5F8FC);

  // ============================================================
  // DỮ LIỆU MẪU
  // Sau này có thể thay bằng dữ liệu từ API
  // ============================================================

  final String customerName = 'Phạm Thị Thảo';

  final String customerPhone = '0908 123 456';

  final String customerEmail = 'thaopham@gmail.com';

  final String customerAddress =
      'Quận 1, TP. Hồ Chí Minh';

  final String requestCode = '#YC000123';

  final String requestTime = '2 giờ trước';

  final String consultationField =
      'Hôn nhân & Gia đình';

  final String consultationTitle =
      'Tôi muốn được tư vấn về thủ tục ly hôn và quyền nuôi con';

  final String consultationDetail =
      'Tôi đang gặp vấn đề trong hôn nhân, muốn được tư vấn về quyền nuôi con sau ly hôn. Mong luật sư hỗ trợ và tư vấn chi tiết các thủ tục cần thiết.';

  final String expectedTime =
      'Trong tuần này';

  final String expectedType =
      'Trực tiếp tại văn phòng';

  final String additionalNote =
      'Mong được sắp xếp lịch sớm. Cảm ơn!';

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
            // HEADER
            _buildHeader(),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics:
                const BouncingScrollPhysics(),

                padding:
                const EdgeInsets.fromLTRB(
                  9,
                  7,
                  9,
                  12,
                ),

                child: Column(
                  children: [
                    // ------------------------------------------
                    // THÔNG TIN KHÁCH HÀNG
                    // ------------------------------------------

                    _buildCustomerCard(),

                    const SizedBox(
                      height: 8,
                    ),

                    // ------------------------------------------
                    // THÔNG TIN YÊU CẦU
                    // ------------------------------------------

                    _buildRequestInformation(),

                    const SizedBox(
                      height: 8,
                    ),

                    // ------------------------------------------
                    // THÔNG TIN MONG MUỐN
                    // ------------------------------------------

                    _buildExpectedInformation(),

                    const SizedBox(
                      height: 8,
                    ),

                    // ------------------------------------------
                    // TÀI LIỆU ĐÍNH KÈM
                    // ------------------------------------------

                    _buildAttachments(),

                    const SizedBox(
                      height: 8,
                    ),

                    // ------------------------------------------
                    // 3 NÚT THAO TÁC
                    // ------------------------------------------

                    _buildActionButtons(),

                    const SizedBox(
                      height: 5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // KHÔNG KHAI BÁO bottomNavigationBar Ở ĐÂY
      //
      // BottomNavigationBar CŨ của bạn nằm ở widget cha.
      // ========================================================
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 58,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 7,
          ),

          // NÚT BACK
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_left_rounded,
                color: navy,
                size: 30,
              ),
            ),
          ),

          // TITLE
          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                const Text(
                  'Chi tiết yêu cầu tư vấn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: darkNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                const Text(
                  'Xem thông tin và trao đổi với khách hàng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    fontSize: 7.5,
                  ),
                ),
              ],
            ),
          ),

          // MORE
          GestureDetector(
            onTap: _showMoreOptions,
            child: Container(
              width: 38,
              height: 38,
              margin:
              const EdgeInsets.only(
                right: 5,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.more_vert_rounded,
                color: muted,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER CARD
  // ============================================================

  Widget _buildCustomerCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        12,
        10,
        8,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(9),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // AVATAR
          _buildAvatar(),

          const SizedBox(
            width: 9,
          ),

          // THÔNG TIN
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        customerName,
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
                      width: 5,
                    ),

                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFDDF5E8,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          4,
                        ),
                      ),
                      child:
                      const Text(
                        'Khách hàng mới',
                        style:
                        TextStyle(
                          color:
                          Color(
                            0xFF15955B,
                          ),
                          fontSize: 6,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 6,
                ),

                _buildCustomerInfoRow(
                  Icons.phone_rounded,
                  customerPhone,
                ),

                const SizedBox(
                  height: 3,
                ),

                _buildCustomerInfoRow(
                  Icons.mail_rounded,
                  customerEmail,
                ),

                const SizedBox(
                  height: 3,
                ),

                _buildCustomerInfoRow(
                  Icons.location_on_rounded,
                  customerAddress,
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          // TRẠNG THÁI
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: gold,
                    size: 13,
                  ),

                  const SizedBox(
                    width: 3,
                  ),

                  const Text(
                    'Gửi yêu cầu',
                    style: TextStyle(
                      color: muted,
                      fontSize: 6.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                requestTime,
                style:
                const TextStyle(
                  color: muted,
                  fontSize: 6.5,
                ),
              ),

              const SizedBox(
                height: 7,
              ),

              Container(
                width: 68,
                height: 27,
                alignment:
                Alignment.center,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFFFE3E5,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    5,
                  ),
                ),
                child:
                const Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    Icon(
                      Icons.circle,
                      color:
                      Color(
                        0xFFED4048,
                      ),
                      size: 7,
                    ),

                    SizedBox(
                      width: 5,
                    ),

                    Text(
                      'Mới',
                      style:
                      TextStyle(
                        color:
                        Color(
                          0xFFE8464E,
                        ),
                        fontSize: 7,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration:
      const BoxDecoration(
        shape: BoxShape.circle,
        color:
        Color(0xFFE6EBEF),
      ),
      child: const Icon(
        Icons.person_rounded,
        color:
        Color(0xFF7E8C9A),
        size: 38,
      ),
    );
  }

  // ============================================================
  // CUSTOMER INFO
  // ============================================================

  Widget _buildCustomerInfoRow(
      IconData icon,
      String text,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: navy,
          size: 12,
        ),

        const SizedBox(
          width: 6,
        ),

        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              color: muted,
              fontSize: 7,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REQUEST INFORMATION
  // ============================================================

  Widget _buildRequestInformation() {
    return _buildSectionCard(
      child: Column(
        children: [
          _buildSectionHeader(
            icon:
            Icons.description_rounded,
            title:
            'Thông tin yêu cầu tư vấn',
            trailing:
            requestCode,
          ),

          const SizedBox(
            height: 8,
          ),

          _buildInfoRow(
            icon:
            Icons.groups_rounded,
            label:
            'Lĩnh vực',
            value:
            consultationField,
          ),

          _buildDivider(),

          _buildInfoRow(
            icon:
            Icons.description_outlined,
            label:
            'Tiêu đề',
            value:
            consultationTitle,
          ),

          _buildDivider(),

          _buildInfoRow(
            icon:
            Icons.notes_rounded,
            label:
            'Nội dung chi tiết',
            value:
            consultationDetail,
            multiline:
            true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXPECTED INFORMATION
  // ============================================================

  Widget _buildExpectedInformation() {
    return _buildSectionCard(
      child: Column(
        children: [
          _buildSectionHeader(
            icon:
            Icons.calendar_month_rounded,
            title:
            'Thông tin mong muốn',
          ),

          const SizedBox(
            height: 9,
          ),

          Row(
            children: [
              Expanded(
                child:
                _buildExpectedItem(
                  icon:
                  Icons.calendar_today_rounded,
                  title:
                  'Thời gian mong muốn',
                  value:
                  expectedTime,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                _buildExpectedItem(
                  icon:
                  Icons.access_time_rounded,
                  title:
                  'Hình thức tư vấn',
                  value:
                  expectedType,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 7,
          ),

          _buildNoteItem(),
        ],
      ),
    );
  }

  // ============================================================
  // EXPECTED ITEM
  // ============================================================

  Widget _buildExpectedItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      height: 55,
      padding:
      const EdgeInsets.all(8),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF6F8FB),
        borderRadius:
        BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration:
            const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: navy,
              size: 15,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color: muted,
                    fontSize: 6.5,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color: navy,
                    fontSize: 7,
                    fontWeight:
                    FontWeight.w600,
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
  // NOTE
  // ============================================================

  Widget _buildNoteItem() {
    return Container(
      width: double.infinity,
      height: 48,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF6F8FB),
        borderRadius:
        BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration:
            const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child:
            const Icon(
              Icons
                  .chat_bubble_outline_rounded,
              color: navy,
              size: 14,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ghi chú thêm',
                  style:
                  TextStyle(
                    color: muted,
                    fontSize: 6.5,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  additionalNote,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color: navy,
                    fontSize: 7,
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
  // ATTACHMENTS
  // ============================================================

  Widget _buildAttachments() {
    return _buildSectionCard(
      child: Column(
        children: [
          _buildSectionHeader(
            icon:
            Icons.attach_file_rounded,
            title:
            'Tài liệu đính kèm (2)',
            trailing:
            'Xem tất cả',
            trailingIsAction:
            true,
            onTrailingTap:
            _viewAllFiles,
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              Expanded(
                child:
                _buildFileCard(
                  icon:
                  Icons.picture_as_pdf_rounded,
                  iconColor:
                  const Color(
                    0xFFE7333A,
                  ),
                  backgroundColor:
                  const Color(
                    0xFFFFE5E5,
                  ),
                  name:
                  'Đơn xin tư vấn.pdf',
                  size:
                  '1.2 MB',
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child:
                _buildFileCard(
                  icon:
                  Icons.image_rounded,
                  iconColor:
                  const Color(
                    0xFF4388D7,
                  ),
                  backgroundColor:
                  const Color(
                    0xFFE4F0FF,
                  ),
                  name:
                  'Giấy tờ liên quan.jpg',
                  size:
                  '2.5 MB',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILE CARD
  // ============================================================

  Widget _buildFileCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String name,
    required String size,
  }) {
    return GestureDetector(
      onTap: () {
        _showMessage(
          'Mở $name',
        );
      },
      child: Container(
        height: 54,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 7,
        ),
        decoration:
        BoxDecoration(
          color:
          const Color(0xFFF6F8FB),
          borderRadius:
          BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Container(
              width: 31,
              height: 36,
              decoration:
              BoxDecoration(
                color: backgroundColor,
                borderRadius:
                BorderRadius.circular(5),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 17,
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            Expanded(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      color: navy,
                      fontSize: 6.8,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    size,
                    style:
                    const TextStyle(
                      color: muted,
                      fontSize: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 3 ACTION BUTTONS
  // NẰM NGAY DƯỚI TÀI LIỆU ĐÍNH KÈM
  // ============================================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        // ĐẶT LỊCH
        Expanded(
          child:
          _buildOutlineActionButton(
            icon:
            Icons.calendar_month_rounded,
            title:
            'Đặt lịch tư vấn',
            onTap:
            _goToBooking,
          ),
        ),

        const SizedBox(
          width: 6,
        ),

        // NHẮN TIN
        Expanded(
          child:
          _buildOutlineActionButton(
            icon:
            Icons.chat_rounded,
            title:
            'Nhắn tin',
            onTap:
            _goToMessages,
          ),
        ),

        const SizedBox(
          width: 6,
        ),

        // XỬ LÝ
        Expanded(
          child:
          _buildPrimaryActionButton(),
        ),
      ],
    );
  }

  // ============================================================
  // OUTLINE BUTTON
  // ============================================================

  Widget _buildOutlineActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 43,
      child: OutlinedButton(
        onPressed: onTap,
        style:
        OutlinedButton.styleFrom(
          foregroundColor: navy,
          side:
          const BorderSide(
            color:
            Color(0xFF7898B8),
            width: 1,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(7),
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: navy,
              size: 14,
            ),

            const SizedBox(
              width: 4,
            ),

            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  color: navy,
                  fontSize: 7,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _buildPrimaryActionButton() {
    return SizedBox(
      height: 43,
      child: ElevatedButton(
        onPressed:
        _processRequest,
        style:
        ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor:
          Colors.white,
          elevation: 0,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(7),
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 15,
            ),

            const SizedBox(
              width: 4,
            ),

            const Flexible(
              child: Text(
                'Xử lý yêu cầu',
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style:
                TextStyle(
                  fontSize: 7,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        11,
        10,
        11,
        10,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(9),
        border: Border.all(
          color: border,
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? trailing,
    bool trailingIsAction = false,
    VoidCallback? onTrailingTap,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: gold,
          size: 18,
        ),

        const SizedBox(
          width: 7,
        ),

        Expanded(
          child: Text(
            title,
            style:
            const TextStyle(
              color: darkNavy,
              fontSize: 11,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ),

        if (trailing != null)
          GestureDetector(
            onTap:
            trailingIsAction
                ? onTrailingTap
                : null,
            child: Row(
              children: [
                Text(
                  trailing,
                  style:
                  TextStyle(
                    color:
                    trailingIsAction
                        ? const Color(
                      0xFF1478D4,
                    )
                        : muted,
                    fontSize: 7,
                    fontWeight:
                    trailingIsAction
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),

                if (trailingIsAction)
                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                    color:
                    Color(0xFF1478D4),
                    size: 14,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool multiline = false,
  }) {
    return Row(
      crossAxisAlignment:
      multiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 27,
          child: Icon(
            icon,
            color: navy,
            size: 15,
          ),
        ),

        SizedBox(
          width: 78,
          child: Text(
            label,
            style:
            const TextStyle(
              color: navy,
              fontSize: 7,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            maxLines:
            multiline ? 5 : 2,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              color:
              Color(0xFF61748A),
              fontSize: 7,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin:
      const EdgeInsets.symmetric(
        vertical: 6,
      ),
      color:
      const Color(0xFFEAF0F5),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goToBooking() {
    Navigator.pushNamed(
      context,
      '/lawyer-book-consultation',
    );
  }

  void _goToMessages() {
    Navigator.pushNamed(
      context,
      '/lawyer-messages',
    );
  }

  // ============================================================
  // XỬ LÝ YÊU CẦU
  // ============================================================

  void _processRequest() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
          const Text(
            'Xử lý yêu cầu',
            style:
            TextStyle(
              color: navy,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          content:
          const Text(
            'Bạn có muốn tiếp nhận và xử lý yêu cầu tư vấn này không?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
              const Text(
                'Hủy',
                style:
                TextStyle(
                  color: muted,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _showMessage(
                  'Đã tiếp nhận yêu cầu tư vấn',
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor: gold,
              ),
              child:
              const Text(
                'Xác nhận',
                style:
                TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MORE OPTIONS
  // ============================================================

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
      Colors.white,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const SizedBox(
                height: 8,
              ),

              Container(
                width: 40,
                height: 4,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFD8DEE5,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    4,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              ListTile(
                leading:
                const Icon(
                  Icons
                      .calendar_month_rounded,
                  color: navy,
                ),
                title:
                const Text(
                  'Đặt lịch tư vấn',
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

                  _goToBooking();
                },
              ),

              ListTile(
                leading:
                const Icon(
                  Icons.chat_rounded,
                  color: navy,
                ),
                title:
                const Text(
                  'Nhắn tin với khách hàng',
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

                  _goToMessages();
                },
              ),

              ListTile(
                leading:
                const Icon(
                  Icons.check_circle_rounded,
                  color: gold,
                ),
                title:
                const Text(
                  'Xử lý yêu cầu',
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

                  _processRequest();
                },
              ),

              const SizedBox(
                height: 8,
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // VIEW ALL FILES
  // ============================================================

  void _viewAllFiles() {
    _showMessage(
      'Hiển thị tất cả tài liệu',
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
        Text(message),
        duration:
        const Duration(
          seconds: 1,
        ),
      ),
    );
  }
}