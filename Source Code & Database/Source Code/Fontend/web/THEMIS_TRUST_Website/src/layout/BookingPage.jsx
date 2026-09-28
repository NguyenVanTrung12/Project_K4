import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { api, getCurrentUser } from "../api/api";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faScaleBalanced,
  faShieldHalved,
  faUsers,
  faClock,
  faUser,
  faPhone,
  faEnvelope,
  faBuilding,
  faVideo,
  faCalendarDays,
  faFileLines,
  faArrowRight,
  faLock,
  faHeadset,
  faChevronLeft,
  faChevronRight,
} from "@fortawesome/free-solid-svg-icons";

import "../assets/css/bookingPage.css";

/* =====================================================
   FORM MẶC ĐỊNH
===================================================== */

const initialForm = {
  fullName: "",
  phone: "",
  email: "",
  consultationType: "",
  meetingType: "office",
  consultationDate: "",
  consultationTime: "",
  content: "",
};

const emptyAccount = { fullName: "", phone: "", email: "" };

const WEEK_DAYS = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

const TIME_SLOTS = [
  "08:00",
  "09:00",
  "10:00",
  "11:00",
  "13:30",
  "14:30",
  "15:30",
  "16:30",
  "17:00",
];

/* =====================================================
   LẤY THÔNG TIN TÀI KHOẢN ĐANG ĐĂNG NHẬP

   QUAN TRỌNG:
   Dùng chung getCurrentUser() với phần Header/Login của hệ thống.
   Không quét toàn bộ localStorage/sessionStorage vì có thể lấy nhầm
   một user cũ đang còn được lưu trong trình duyệt.
===================================================== */

const text = (value) => (value == null ? "" : String(value).trim());

const pickAccountInfo = (user) => ({
  fullName: text(user?.fullName ?? user?.FullName ?? user?.name ?? user?.Name),
  phone: text(user?.phone ?? user?.Phone ?? user?.phoneNumber),
  email: text(user?.email ?? user?.Email),
});

/* =====================================================
   STYLE NHỎ CHO PHẦN TỰ ĐIỀN
===================================================== */

const hintStyle = {
  marginLeft: "8px",
  fontStyle: "normal",
  fontSize: "12px",
  fontWeight: 400,
  color: "#19a579",
};

const lockedInputStyle = {
  color: "#5b6b7b",
  cursor: "not-allowed",
};

const noticeStyle = {
  marginBottom: "14px",
  padding: "10px 14px",
  borderRadius: "8px",
  background: "#f1f8f5",
  border: "1px solid #cfeadf",
  color: "#1c6b52",
  fontSize: "13px",
  lineHeight: 1.5,
};

const noticeWarnStyle = {
  ...noticeStyle,
  background: "#fff8e6",
  border: "1px solid #f3dfa2",
  color: "#8a6410",
};

// =====================================================
// DATE HELPERS
// =====================================================
const formatDateValue = (date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");

  return `${year}-${month}-${day}`;
};

const startOfDay = (date) => {
  const d = new Date(date);

  d.setHours(0, 0, 0, 0);

  return d;
};

const isSameDate = (date1, date2) => {
  return (
    date1.getFullYear() === date2.getFullYear() &&
    date1.getMonth() === date2.getMonth() &&
    date1.getDate() === date2.getDate()
  );
};

const getDaysInMonth = (year, month) => {
  return new Date(
    year,
    month + 1,
    0
  ).getDate();
};

const getFirstDayOffset = (year, month) => {
  const firstDay = new Date(
    year,
    month,
    1
  );

  // JS: CN = 0
  // Đổi thành T2 = 0 ... CN = 6
  return (firstDay.getDay() + 6) % 7;
};


const BookingPage = () => {
  /* =====================================================
     GET LAWYER ID FROM URL
     Ví dụ: /booking?lawyerId=xxxxxxxx
  ===================================================== */

  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const lawyerId = searchParams.get("lawyerId");

  /* =====================================================
     STATE
  ===================================================== */

  const today = new Date();

  const [calendarMonth, setCalendarMonth] = useState(
    new Date(
      today.getFullYear(),
      today.getMonth(),
      1
    )
  );

  const [formData, setFormData] = useState({
    ...initialForm,
    consultationDate: formatDateValue(today),
  });

  const [submitState, setSubmitState] = useState({
    loading: false,
    message: "",
    error: "",
  });

  // Thông tin lấy từ tài khoản đăng nhập
  const [account, setAccount] = useState(emptyAccount);
  const [accountRole, setAccountRole] = useState("");
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [accountLoading, setAccountLoading] = useState(true);
  const calendarDays = [];

  const calendarYear = calendarMonth.getFullYear();
  const calendarMonthIndex = calendarMonth.getMonth();

  const firstDayOffset = getFirstDayOffset(
    calendarYear,
    calendarMonthIndex
  );

  for (let i = 0; i < firstDayOffset; i++) {
    calendarDays.push(null);
  }

  const daysInMonth = getDaysInMonth(
    calendarYear,
    calendarMonthIndex
  );

  for (let day = 1; day <= daysInMonth; day++) {
    calendarDays.push(
      new Date(
        calendarYear,
        calendarMonthIndex,
        day
      )
    );
  }
  /* =====================================================
     TỰ ĐIỀN THÔNG TIN TỪ TÀI KHOẢN
  ===================================================== */

  useEffect(() => {
    let cancelled = false;

    const loadAccount = async () => {
      // =====================================================
      // LẤY ĐÚNG USER ĐANG ĐĂNG NHẬP
      // =====================================================
      // Header/Login của hệ thống đang dùng getCurrentUser().
      // Vì vậy BookingPage cũng phải dùng cùng nguồn này.
      const currentUser = getCurrentUser();

      if (!currentUser?.id) {
        if (cancelled) return;

        setAccount(emptyAccount);
        setAccountRole("");
        setIsLoggedIn(false);
        setFormData((prev) => ({
          ...prev,
          fullName: "",
          phone: "",
          email: "",
        }));
        setAccountLoading(false);
        return;
      }

      // Lấy trước dữ liệu đang lưu trong tài khoản hiện tại
      let info = pickAccountInfo(currentUser);

      let role = text(
        currentUser?.role ??
        currentUser?.Role ??
        ""
      ).toLowerCase();

      // =====================================================
      // LẤY THÔNG TIN MỚI NHẤT TỪ BACKEND
      // ID luôn lấy từ currentUser đã xác định ở trên
      // =====================================================
      try {
        const response = await api.get(`/users/${currentUser.id}`);

        const data =
          response && response.data && !response.fullName
            ? response.data
            : response;

        const fresh = pickAccountInfo(data);

        info = {
          fullName: fresh.fullName || info.fullName,
          phone: fresh.phone || info.phone,
          email: fresh.email || info.email,
        };

        role = text(
          data?.role ??
          data?.Role ??
          role
        ).toLowerCase();
      } catch (err) {
        console.warn(
          "Không lấy được thông tin tài khoản từ server:",
          err
        );
      }

      if (cancelled) return;

      setAccount(info);
      setAccountRole(role);
      setIsLoggedIn(true);

      setFormData((prev) => ({
        ...prev,
        // Khi đã đăng nhập, thông tin form luôn lấy từ đúng currentUser
        // và dữ liệu mới nhất từ API, không lấy từ user khác trong storage.
        fullName: info.fullName,
        phone: info.phone,
        email: info.email,
      }));

      console.log("========== BOOKING ACCOUNT ==========");
      console.log("Current user:", currentUser);
      console.log("Current user ID:", currentUser.id);
      console.log("Current role:", role);
      console.log("Account used for booking:", info);

      setAccountLoading(false);
    };

    loadAccount();

    return () => {
      cancelled = true;
    };
  }, []);

  // Trường nào có sẵn trong tài khoản thì khóa lại, không cần nhập
  const locked = {
    fullName: isLoggedIn && Boolean(account.fullName),
    phone: isLoggedIn && Boolean(account.phone),
    email: isLoggedIn && Boolean(account.email),
  };

  const isClient = isLoggedIn && accountRole === "client";

  // Trường bắt buộc mà tài khoản đang thiếu
  const missingFields = [];

  if (isLoggedIn && !account.fullName) missingFields.push("họ và tên");
  if (isLoggedIn && !account.phone) missingFields.push("số điện thoại");

  /* =====================================================
     FORM CHANGE
  ===================================================== */

  const handleChange = (event) => {
    const { name, value } = event.target;

    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSelectTime = (time) => {
    setFormData((prev) => ({
      ...prev,
      consultationTime: time,
    }));
  };

  const handleMeetingType = (type) => {
    setFormData((prev) => ({
      ...prev,
      meetingType: type,
    }));
  };

  /* =====================================================
     SUBMIT

     Frontend -> POST /api/appointments/public
     Backend tạo Appointment + ConsultationRequest
  ===================================================== */

  const showError = (message) => {
    setSubmitState({
      loading: false,
      message: "",
      error: message,
    });
  };

  const handleLoginRedirect = () => {
    const returnUrl =
      window.location.pathname + window.location.search;

    navigate(`/login?returnUrl=${encodeURIComponent(returnUrl)}`);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (accountLoading) {
      showError("Đang kiểm tra trạng thái đăng nhập. Vui lòng thử lại.");
      return;
    }

    if (!isLoggedIn) {
      showError("Bạn cần đăng nhập trước khi đặt lịch tư vấn.");
      handleLoginRedirect();
      return;
    }

    if (!isClient) {
      showError("Chỉ tài khoản khách hàng (Client) mới được phép đặt lịch tư vấn.");
      return;
    }

    if (!lawyerId) {
      showError(
        "Không xác định được luật sư bạn đã chọn. Vui lòng quay lại trang luật sư và chọn lại."
      );
      return;
    }

    if (!formData.fullName.trim()) {
      showError("Vui lòng nhập họ và tên.");
      return;
    }

    if (!formData.phone.trim()) {
      showError("Vui lòng nhập số điện thoại.");
      return;
    }

    if (!formData.consultationDate) {
      showError("Vui lòng chọn ngày tư vấn.");
      return;
    }

    if (!formData.consultationTime) {
      showError("Vui lòng chọn khung giờ tư vấn.");
      return;
    }

    // if (!formData.consultationType) {
    //   showError("Vui lòng chọn lĩnh vực tư vấn.");
    //   return;
    // }

    setSubmitState({
      loading: true,
      message: "",
      error: "",
    });

    try {
      /* Calendar hiện tại của giao diện đang cố định tháng 9/2026 */

      const scheduledAt =
        `${formData.consultationDate}T${formData.consultationTime}:00`;

      const meetingType =
        formData.meetingType === "online" ? "Online" : "Trực tiếp";

      const description = [
        `[Lĩnh vực: ${formData.consultationType}]`,
        `[Hình thức: ${meetingType}]`,
        formData.content ? `Nội dung: ${formData.content}` : "",
      ]
        .filter(Boolean)
        .join(" ");

      const requestData = {
        fullName: formData.fullName.trim(),
        phone: formData.phone.trim(),
        email: formData.email.trim(),
        lawyerId: lawyerId,
        scheduledAt: scheduledAt,
        description: description,
      };

      console.log("========== ĐẶT LỊCH ==========");
      console.log("Lawyer ID:", lawyerId);
      console.log("Request:", requestData);

      const response = await api.post("/appointments/public", requestData);

      console.log("Đặt lịch thành công:", response);

      setSubmitState({
        loading: false,
        message:
          "Đặt lịch thành công. Chúng tôi sẽ liên hệ để xác nhận lịch hẹn.",
        error: "",
      });

      // Xóa các ô đã nhập, nhưng giữ lại thông tin tài khoản
      const currentDate = new Date();

      setFormData({
        ...initialForm,
        fullName: account.fullName,
        phone: account.phone,
        email: account.email,
        consultationDate: formatDateValue(currentDate),
        consultationTime: "",
      });

      setCalendarMonth(
        new Date(
          currentDate.getFullYear(),
          currentDate.getMonth(),
          1
        )
      );
    } catch (err) {
      console.error("Lỗi đặt lịch:", err);

      showError(
        err?.response?.data?.message ||
        err?.response?.data?.title ||
        err?.message ||
        "Không thể đặt lịch."
      );
    }
  };

  return (
    <div className="booking-page">
      {/* =================================================
          TOP / HERO
      ================================================= */}

      <section className="booking-hero">
        {/* LEFT BACKGROUND */}

        <div className="booking-hero__left">
          <div className="booking-hero__background"></div>

          <div className="booking-hero__overlay"></div>

          <div className="booking-hero__content">
            {/* LOGO */}

            <div className="booking-brand">
              <div className="booking-brand__icon">
                <FontAwesomeIcon icon={faScaleBalanced} />
              </div>

              <div className="booking-brand__text">
                <strong>THEMIS TRUST</strong>

                <span>LAW &amp; JUSTICE</span>
              </div>
            </div>

            {/* HERO TITLE */}

            <div className="booking-intro">
              <div className="booking-intro__label">
                TƯ VẤN HÔM NAY – GIẢI PHÁP NGÀY MAI
                <span></span>
              </div>

              <h1>
                Đặt lịch tư vấn
                <br />
                cùng luật sư
                <br />
                <em>chuyên nghiệp</em>
              </h1>

              <div className="booking-intro__line"></div>

              <p>
                Chúng tôi luôn sẵn sàng lắng nghe và đồng hành cùng bạn trên
                mọi vấn đề pháp lý. Đặt lịch tư vấn ngay để được hỗ trợ nhanh
                chóng, chính xác và bảo mật.
              </p>
            </div>

            {/* FEATURES */}

            <div className="booking-features">
              <div className="booking-feature">
                <div className="booking-feature__icon">
                  <FontAwesomeIcon icon={faShieldHalved} />
                </div>

                <span>
                  Bảo mật
                  <br />
                  thông tin
                </span>
              </div>

              <div className="booking-feature">
                <div className="booking-feature__icon">
                  <FontAwesomeIcon icon={faUsers} />
                </div>

                <span>
                  Luật sư
                  <br />
                  chuyên môn cao
                </span>
              </div>

              <div className="booking-feature">
                <div className="booking-feature__icon">
                  <FontAwesomeIcon icon={faClock} />
                </div>

                <span>
                  Linh hoạt
                  <br />
                  thời gian
                </span>
              </div>
            </div>

            {/* QUOTE */}

            <div className="booking-quote">
              <p>
                “Pháp luật là điểm tựa,
                <br />
                chúng tôi là người đồng hành.”
              </p>

              <div className="booking-quote__line"></div>
            </div>
          </div>
        </div>

        {/* RIGHT FORM */}

        <div className="booking-hero__right">
          <div className="booking-card">
            {/* CARD HEADER */}

            <div className="booking-card__header">
              <div>
                <h2>Đặt lịch tư vấn</h2>

                <p>
                  Chọn thời gian phù hợp và để lại thông tin, chúng tôi sẽ liên
                  hệ xác nhận lịch hẹn trong thời gian sớm nhất.
                </p>
              </div>

              <div className="booking-card__support">
                <div className="booking-card__support-icon">
                  <FontAwesomeIcon icon={faHeadset} />
                </div>

                <span>Tư vấn trực tiếp hoặc trực tuyến</span>
              </div>
            </div>

            {/* FORM */}

            <form className="booking-form" onSubmit={handleSubmit}>
              {/* THÔNG BÁO TỰ ĐIỀN */}

              {!accountLoading && !isLoggedIn && (
                <div style={noticeWarnStyle}>
                  <strong>Bạn cần đăng nhập để đặt lịch tư vấn.</strong>
                  <div style={{ marginTop: "6px" }}>
                    Vui lòng đăng nhập tài khoản Client trước khi gửi yêu cầu đặt lịch.
                  </div>
                  <button
                    type="button"
                    onClick={handleLoginRedirect}
                    style={{
                      marginTop: "12px",
                      border: "none",
                      borderRadius: "7px",
                      padding: "10px 18px",
                      background: "#1c6b52",
                      color: "#fff",
                      cursor: "pointer",
                      fontWeight: 600,
                    }}
                  >
                    Đăng nhập để đặt lịch
                  </button>
                </div>
              )}

              {!accountLoading && isLoggedIn && !isClient && (
                <div style={noticeWarnStyle}>
                  Tài khoản hiện tại không phải tài khoản Client. Chỉ Client mới được phép đặt lịch tư vấn.
                </div>
              )}

              {!accountLoading && isClient && (
                <div style={missingFields.length > 0 ? noticeWarnStyle : noticeStyle}>
                  {missingFields.length > 0
                    ? `Đã điền sẵn thông tin từ tài khoản của bạn. Vui lòng bổ sung: ${missingFields.join(", ")}.`
                    : "Đã điền sẵn thông tin liên hệ từ tài khoản của bạn."}
                </div>
              )}

              {/* ROW 1 */}

              <div className="booking-form__row">
                {/* FULL NAME */}

                <div className="booking-field">
                  <label>
                    Họ và tên
                    <span>*</span>
                    {locked.fullName && <em style={hintStyle}>✓ Từ tài khoản</em>}
                  </label>

                  <div className="booking-input">
                    <FontAwesomeIcon icon={faUser} />

                    <input
                      type="text"
                      name="fullName"
                      value={formData.fullName}
                      onChange={handleChange}
                      placeholder="Nhập họ và tên của bạn"
                      required
                      readOnly={locked.fullName}
                      style={locked.fullName ? lockedInputStyle : undefined}
                    />
                  </div>
                </div>

                {/* PHONE */}

                <div className="booking-field">
                  <label>
                    Số điện thoại
                    <span>*</span>
                    {locked.phone && <em style={hintStyle}>✓ Từ tài khoản</em>}
                  </label>

                  <div className="booking-input">
                    <FontAwesomeIcon icon={faPhone} />

                    <input
                      type="tel"
                      name="phone"
                      value={formData.phone}
                      onChange={handleChange}
                      placeholder="Nhập số điện thoại"
                      required
                      readOnly={locked.phone}
                      style={locked.phone ? lockedInputStyle : undefined}
                    />
                  </div>
                </div>
              </div>

              {/* ROW 2 */}

              <div className="booking-form__row">
                {/* EMAIL */}

                <div className="booking-field">
                  <label>
                    Email
                    {locked.email && <em style={hintStyle}>✓ Từ tài khoản</em>}
                  </label>

                  <div className="booking-input">
                    <FontAwesomeIcon icon={faEnvelope} />

                    <input
                      type="email"
                      name="email"
                      value={formData.email}
                      onChange={handleChange}
                      placeholder="Nhập email (nếu có)"
                      readOnly={locked.email}
                      style={locked.email ? lockedInputStyle : undefined}
                    />
                  </div>
                </div>

                {/* CONSULTATION TYPE */}

                {/* <div className="booking-field">
                  <label>
                    Lĩnh vực tư vấn
                    <span>*</span>
                  </label>

                  <div className="booking-input">
                    <FontAwesomeIcon icon={faScaleBalanced} />

                    <select
                      name="consultationType"
                      value={formData.consultationType}
                      onChange={handleChange}
                      required
                    >
                      <option value="">Chọn lĩnh vực tư vấn</option>

                      <option value="business">Doanh nghiệp</option>

                      <option value="civil">Dân sự</option>

                      <option value="land">Đất đai</option>

                      <option value="marriage">Hôn nhân &amp; Gia đình</option>

                      <option value="criminal">Hình sự</option>

                      <option value="administrative">Hành chính</option>

                      <option value="labor">Lao động</option>

                      <option value="investment">Đầu tư &amp; Giấy phép</option>
                    </select>
                  </div>
                </div> */}
              </div>

              {/* MEETING TYPE */}

              <div className="booking-field">
                <label>
                  Hình thức tư vấn
                  <span>*</span>
                </label>

                <div className="booking-meeting">
                  <button
                    type="button"
                    className={
                      formData.meetingType === "office"
                        ? "booking-meeting__item active"
                        : "booking-meeting__item"
                    }
                    onClick={() => handleMeetingType("office")}
                  >
                    <FontAwesomeIcon icon={faBuilding} />

                    <span>Trực tiếp tại văn phòng</span>
                  </button>

                  <button
                    type="button"
                    className={
                      formData.meetingType === "online"
                        ? "booking-meeting__item active"
                        : "booking-meeting__item"
                    }
                    onClick={() => handleMeetingType("online")}
                  >
                    <FontAwesomeIcon icon={faVideo} />

                    <span>
                      Tư vấn trực tuyến
                      <small>(Online)</small>
                    </span>
                  </button>
                </div>
              </div>

              {/* DATE + TIME */}

              <div className="booking-date-time">
                {/* DATE */}

                <div className="booking-date">
                  <div className="booking-field">
                    <label>
                      Chọn ngày tư vấn
                      <span>*</span>
                    </label>

                    <div className="booking-calendar">
                      <div className="booking-calendar__header">
                        <button type="button" aria-label="Tháng trước">
                          <FontAwesomeIcon icon={faChevronLeft} />
                        </button>

                        <strong>Tháng 9, 2026</strong>

                        <button type="button" aria-label="Tháng sau">
                          <FontAwesomeIcon icon={faChevronRight} />
                        </button>
                      </div>

                      <div className="booking-calendar__week">
                        <span>T2</span>
                        <span>T3</span>
                        <span>T4</span>
                        <span>T5</span>
                        <span>T6</span>
                        <span>T7</span>
                        <span>CN</span>
                      </div>

                      <div className="booking-calendar">
                        <div className="booking-calendar__header">
                          <button
                            type="button"
                            className="booking-calendar__nav"
                            disabled={
                              calendarMonth <=
                              new Date(
                                today.getFullYear(),
                                today.getMonth(),
                                1
                              )
                            }
                            onClick={() => {
                              const currentMonth = new Date(
                                today.getFullYear(),
                                today.getMonth(),
                                1
                              );

                              if (calendarMonth <= currentMonth) {
                                return;
                              }

                              setCalendarMonth(
                                new Date(
                                  calendarYear,
                                  calendarMonthIndex - 1,
                                  1
                                )
                              );
                            }}
                          >
                            ‹
                          </button>

                          <strong>
                            Tháng {calendarMonthIndex + 1}, {calendarYear}
                          </strong>

                          <button
                            type="button"
                            className="booking-calendar__nav"
                            onClick={() => {
                              setCalendarMonth(
                                new Date(
                                  calendarYear,
                                  calendarMonthIndex + 1,
                                  1
                                )
                              );
                            }}
                          >
                            ›
                          </button>
                        </div>

                        <div className="booking-calendar__week">
                          {WEEK_DAYS.map((day) => (
                            <div key={day}>
                              {day}
                            </div>
                          ))}
                        </div>

                        <div className="booking-calendar__days">
                          {calendarDays.map((date, index) => {
                            // Ô trống đầu tháng
                            if (!date) {
                              return (
                                <button
                                  type="button"
                                  key={`empty-${index}`}
                                  className="empty"
                                  disabled
                                />
                              );
                            }

                            const dateValue = formatDateValue(date);

                            const currentDate = startOfDay(date);
                            const todayDate = startOfDay(new Date());

                            // Ngày đã qua
                            const isPast = currentDate < todayDate;

                            // Ngày hôm nay
                            const isToday = isSameDate(
                              date,
                              todayDate
                            );

                            // Ngày đang chọn
                            const isSelected =
                              formData.consultationDate === dateValue;

                            return (
                              <button
                                type="button"
                                key={dateValue}
                                disabled={isPast}
                                className={[
                                  isSelected ? "selected" : "",
                                  isToday ? "today" : "",
                                  isPast ? "past" : "",
                                ]
                                  .filter(Boolean)
                                  .join(" ")}
                                onClick={() => {
                                  if (isPast) {
                                    return;
                                  }

                                  setFormData((prev) => ({
                                    ...prev,
                                    consultationDate: dateValue,
                                    consultationTime: "",
                                  }));
                                }}
                              >
                                {date.getDate()}
                              </button>
                            );
                          })}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* TIME */}

                <div className="booking-time">
                  <div className="booking-field">
                    <label>Chọn khung giờ</label>

                    <div className="booking-time__grid">
                      {TIME_SLOTS.map((time) => {
                        const selectedDate = formData.consultationDate
                          ? new Date(
                            `${formData.consultationDate}T00:00:00`
                          )
                          : null;

                        const now = new Date();

                        let isPastTime = false;

                        /*
                         * Nếu chọn NGÀY HÔM NAY
                         * thì những giờ đã qua sẽ bị khóa.
                         */
                        if (
                          selectedDate &&
                          isSameDate(selectedDate, now)
                        ) {
                          const [hour, minute] = time
                            .split(":")
                            .map(Number);

                          const slotDate = new Date(
                            selectedDate.getFullYear(),
                            selectedDate.getMonth(),
                            selectedDate.getDate(),
                            hour,
                            minute,
                            0,
                            0
                          );

                          isPastTime = slotDate <= now;
                        }

                        const isActive =
                          formData.consultationTime === time;

                        return (
                          <button
                            type="button"
                            key={time}
                            disabled={isPastTime}
                            className={[
                              isActive ? "active" : "",
                              isPastTime ? "past" : "",
                            ]
                              .filter(Boolean)
                              .join(" ")}
                            onClick={() => {
                              if (isPastTime) {
                                return;
                              }

                              handleSelectTime(time);
                            }}
                          >
                            {time}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>
              </div>

              {/* CONTENT */}

              <div className="booking-field">
                <label>Nội dung cần tư vấn</label>

                <div className="booking-textarea">
                  <FontAwesomeIcon icon={faFileLines} />

                  <textarea
                    name="content"
                    value={formData.content}
                    onChange={handleChange}
                    placeholder="Vui lòng nhập nội dung chi tiết để chúng tôi hỗ trợ tốt hơn..."
                    rows="3"
                  />
                </div>
              </div>

              {/* ERROR / SUCCESS */}

              {submitState.error && (
                <div className="booking-error">{submitState.error}</div>
              )}

              {submitState.message && (
                <div className="booking-success">{submitState.message}</div>
              )}

              {/* SUBMIT */}

              <button
                type="submit"
                className="booking-submit"
                disabled={submitState.loading || accountLoading}
              >
                <FontAwesomeIcon icon={faCalendarDays} />

                <span>
                  {accountLoading
                    ? "Đang kiểm tra..."
                    : !isLoggedIn
                      ? "Đăng nhập để đặt lịch"
                      : !isClient
                        ? "Chỉ Client mới được đặt lịch"
                        : submitState.loading
                          ? "Đang gửi..."
                          : "Đặt lịch ngay"}
                </span>

                <FontAwesomeIcon
                  icon={faArrowRight}
                  className="booking-submit__arrow"
                />
              </button>

              {/* SECURITY */}

              <div className="booking-security">
                <FontAwesomeIcon icon={faLock} />

                <span>Thông tin của bạn được bảo mật tuyệt đối.</span>
              </div>
            </form>
          </div>
        </div>
      </section>

      {/* =================================================
          PROCESS
      ================================================= */}

      <section className="booking-process">
        <div className="booking-process__container">
          {/* TITLE */}

          <div className="booking-process__title">
            <h2>
              Quy trình
              <br />
              đặt lịch tư vấn
            </h2>

            <span></span>
          </div>

          {/* STEPS */}

          <div className="booking-process__steps">
            <div className="booking-process__step">
              <div className="booking-process__number">
                <div>
                  <FontAwesomeIcon icon={faCalendarDays} />
                </div>

                <strong>01</strong>
              </div>

              <p>
                Chọn thời gian
                <br />
                và điền thông tin
              </p>
            </div>

            <div className="booking-process__arrow">
              <FontAwesomeIcon icon={faArrowRight} />
            </div>

            <div className="booking-process__step">
              <div className="booking-process__number">
                <div>
                  <FontAwesomeIcon icon={faEnvelope} />
                </div>

                <strong>02</strong>
              </div>

              <p>
                Chúng tôi xác nhận
                <br />
                lịch hẹn qua điện thoại/email
              </p>
            </div>

            <div className="booking-process__arrow">
              <FontAwesomeIcon icon={faArrowRight} />
            </div>

            <div className="booking-process__step">
              <div className="booking-process__number">
                <div>
                  <FontAwesomeIcon icon={faUsers} />
                </div>

                <strong>03</strong>
              </div>

              <p>
                Gặp gỡ luật sư
                <br />
                (Trực tiếp hoặc trực tuyến)
              </p>
            </div>

            <div className="booking-process__arrow">
              <FontAwesomeIcon icon={faArrowRight} />
            </div>

            <div className="booking-process__step">
              <div className="booking-process__number">
                <div>
                  <FontAwesomeIcon icon={faFileLines} />
                </div>

                <strong>04</strong>
              </div>

              <p>
                Nhận giải pháp pháp lý
                <br />
                dành riêng cho bạn
              </p>
            </div>
          </div>

          {/* QUOTE */}

          <div className="booking-process__quote">
            <p>
              “Sự an tâm của bạn
              <br />
              là sứ mệnh của chúng tôi.”
            </p>

            <div>
              <span></span>

              <small>THEMIS TRUST</small>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default BookingPage;
