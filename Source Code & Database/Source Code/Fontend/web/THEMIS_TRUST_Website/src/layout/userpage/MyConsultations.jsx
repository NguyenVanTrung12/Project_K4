import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faPlus,
  faClock,
  faVideo,
  faLocationDot,
  faUser,
  faFileLines,
  faChevronRight,
  faChevronLeft,
  faCircleInfo,
  faCalendarDays,
  faPhone,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../../api/api";

import "../../assets/css/userpage/MyConsultations.css";

/* =========================================================
   CẤU HÌNH
========================================================= */

// Khách gọi endpoint này chỉ nhận lịch hẹn của chính mình.
const APPOINTMENTS_ENDPOINT = "/appointments";

// ⚠️ Endpoint khách tự hủy lịch. Backend hiện chỉ có
// PATCH /appointments/{id}/status dành cho admin/staff/lawyer,
// nên cần thêm endpoint này (xem hướng dẫn kèm theo).
const CANCEL_ENDPOINT = (id) => `/appointments/${id}/cancel`;

// Trang đặt lịch (đổi cho đúng route của bạn)
const BOOKING_ROUTE = "/booking";

// Trạng thái nào được phép hủy
const CANCELLABLE_STATUSES = ["pending"];

const AUTH_MESSAGE =
  "Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng xuất và đăng nhập lại.";

const WEEK_DAYS = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

const filterItems = [
  { label: "Tất cả", value: "all" },
  { label: "Sắp tới", value: "upcoming" },
  { label: "Đã hoàn thành", value: "completed" },
  { label: "Đã hủy", value: "cancelled" },
];

// Trạng thái của backend -> nhãn + class CSS
const STATUS_MAP = {
  pending: { label: "Chờ xác nhận", className: "upcoming" },
  confirmed: { label: "Đã xác nhận", className: "upcoming" },
  completed: { label: "Đã hoàn thành", className: "completed" },
  cancelled: { label: "Đã hủy", className: "cancelled" },
};

/* =========================================================
   HELPERS
========================================================= */

const toList = (data) =>
  Array.isArray(data) ? data : data?.items || data?.data || [];

const getId = (item) => item?.id || item?.Id || null;

const hasStatus = (err, code) =>
  err?.status === code ||
  err?.response?.status === code ||
  new RegExp(`\\b${code}\\b`).test(String(err?.message || ""));

const pick = (obj, keys) => {
  for (const key of keys) {
    const value = obj?.[key];

    if (value !== undefined && value !== null && String(value).trim() !== "") {
      return value;
    }
  }

  return "";
};

const normalizeText = (value) =>
  String(value || "")
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d");

const pad = (value) => String(value).padStart(2, "0");

// "YYYY-MM-DD" theo giờ địa phương, dùng để gom lịch theo ngày
const toDateKey = (date) =>
  `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;

const formatDateKey = (key) => {
  const [year, month, day] = key.split("-");

  return `${day}/${month}/${year}`;
};

const formatClock = (date) =>
  date.toLocaleTimeString("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });

const truncate = (text, max) =>
  text.length > max ? `${text.slice(0, max).trim()}…` : text;

// Chuyên mục (nếu backend có trả) -> class màu trong CSS
const getCategoryClass = (category) => {
  const value = normalizeText(category);

  if (value.includes("lao dong")) return "labor";
  if (value.includes("doanh nghiep")) return "business";
  if (value.includes("dat dai")) return "land";
  if (value.includes("hon nhan") || value.includes("gia dinh")) return "family";

  return "";
};

// Hình thức tư vấn (nếu backend có trả)
const getTypeInfo = (rawType) => {
  const value = normalizeText(rawType);

  if (!value) return null;

  if (/(online|truc tuyen|video)/.test(value)) {
    return { label: "Trực tuyến", icon: faVideo };
  }

  if (/(office|offline|van phong)/.test(value)) {
    return { label: "Tại văn phòng", icon: faLocationDot };
  }

  return { label: String(rawType), icon: faLocationDot };
};

// AppointmentDto -> dữ liệu hiển thị của một thẻ
const toConsultation = (appointment) => {
  const start = new Date(
    appointment?.scheduledAt || appointment?.ScheduledAt || ""
  );

  if (Number.isNaN(start.getTime())) return null;

  const duration =
    Number(appointment?.durationMin ?? appointment?.DurationMin) || 60;

  const end = new Date(start.getTime() + duration * 60000);

  const status = String(appointment?.status || appointment?.Status || "")
    .trim()
    .toLowerCase();

  const statusInfo = STATUS_MAP[status] || {
    label: status || "Chờ xác nhận",
    className: "upcoming",
  };

  const description = String(
    appointment?.description || appointment?.Description || ""
  ).trim();

  const lawyerName = String(
    appointment?.lawyerName || appointment?.LawyerName || ""
  ).trim();

  const category = String(
    pick(appointment, [
      "practiceAreaName",
      "PracticeAreaName",
      "category",
      "Category",
    ])
  );

  const typeInfo = getTypeInfo(
    pick(appointment, [
      "consultationType",
      "ConsultationType",
      "meetingType",
      "MeetingType",
      "type",
      "Type",
      "location",
      "Location",
    ])
  );

  const meetingUrl = String(
    pick(appointment, [
      "meetingUrl",
      "MeetingUrl",
      "meetingLink",
      "MeetingLink",
      "joinUrl",
      "JoinUrl",
    ])
  );

  return {
    id: getId(appointment),
    start,
    dateKey: toDateKey(start),
    day: pad(start.getDate()),
    month: `Tháng ${start.getMonth() + 1}`,
    year: String(start.getFullYear()),
    time: `${formatClock(start)} - ${formatClock(end)}`,

    title: description ? truncate(description, 70) : "Lịch tư vấn pháp lý",
    // Chỉ hiện dòng mô tả khi tiêu đề đã bị cắt bớt
    description: description.length > 70 ? description : "",

    category,
    categoryClass: getCategoryClass(category),

    typeLabel: typeInfo?.label || "",
    typeIcon: typeInfo?.icon || faVideo,

    lawyer: lawyerName
      ? /^(luat su|ls\b)/.test(normalizeText(lawyerName))
        ? lawyerName
        : `Luật sư ${lawyerName}`
      : "",

    status,
    statusLabel: statusInfo.label,
    statusClass: statusInfo.className,

    meetingUrl,
    showJoin: Boolean(meetingUrl) && status === "confirmed",
    showCancel: CANCELLABLE_STATUSES.includes(status),
  };
};

// Lịch sắp tới xếp gần nhất trước, lịch đã xong / hủy xếp mới nhất trước
const sortConsultations = (list) => {
  const isActive = (item) => item.statusClass === "upcoming";

  const active = list
    .filter(isActive)
    .sort((a, b) => a.start - b.start);

  const rest = list
    .filter((item) => !isActive(item))
    .sort((a, b) => b.start - a.start);

  return [...active, ...rest];
};

/* =========================================================
   COMPONENT
========================================================= */

const MyConsultations = () => {
  const navigate = useNavigate();

  /* =======================================================
     STATE
  ======================================================= */

  const [activeFilter, setActiveFilter] = useState("all");
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [cancelingId, setCancelingId] = useState(null);
  const [error, setError] = useState("");

  // Lịch tháng bên phải
  const [viewMonth, setViewMonth] = useState(() => {
    const now = new Date();

    return { year: now.getFullYear(), month: now.getMonth() };
  });

  // Ngày đang chọn để lọc ("YYYY-MM-DD" hoặc rỗng)
  const [selectedDate, setSelectedDate] = useState("");

  /* =======================================================
     LOAD DATA
     silent = true: tải lại âm thầm, không hiện "Đang tải..."
  ======================================================= */

  const loadAppointments = async (silent = false) => {
    try {
      if (!silent) setLoading(true);

      const data = await api.get(APPOINTMENTS_ENDPOINT);

      setAppointments(toList(data));

      setError("");
    } catch (err) {
      console.error("Không thể tải lịch tư vấn:", err);

      if (hasStatus(err, 401)) {
        setError(AUTH_MESSAGE);
      } else if (!silent) {
        setAppointments([]);

        setError("Không thể tải lịch tư vấn. Vui lòng thử lại sau.");
      }
    } finally {
      if (!silent) setLoading(false);
    }
  };

  useEffect(() => {
    loadAppointments();
  }, []);

  // Quay lại tab thì cập nhật ngay (luật sư có thể vừa xác nhận lịch)
  useEffect(() => {
    const onVisible = () => {
      if (!document.hidden) loadAppointments(true);
    };

    document.addEventListener("visibilitychange", onVisible);

    return () => document.removeEventListener("visibilitychange", onVisible);
  }, []);

  /* =======================================================
     DỮ LIỆU HIỂN THỊ
  ======================================================= */

  const consultations = useMemo(
    () =>
      sortConsultations(appointments.map(toConsultation).filter(Boolean)),
    [appointments]
  );

  const filteredConsultations = useMemo(
    () =>
      consultations.filter((item) => {
        if (activeFilter !== "all" && item.statusClass !== activeFilter) {
          return false;
        }

        if (selectedDate && item.dateKey !== selectedDate) return false;

        return true;
      }),
    [consultations, activeFilter, selectedDate]
  );

  /* =======================================================
     LỊCH THÁNG
  ======================================================= */

  // Ngày có lịch (không tính lịch đã hủy)
  const eventDays = useMemo(
    () =>
      new Set(
        consultations
          .filter((item) => item.statusClass !== "cancelled")
          .map((item) => item.dateKey)
      ),
    [consultations]
  );

  const todayKey = toDateKey(new Date());

  const calendarCells = useMemo(() => {
    const { year, month } = viewMonth;

    // Tuần bắt đầu từ Thứ 2
    const offset = (new Date(year, month, 1).getDay() + 6) % 7;

    const daysInMonth = new Date(year, month + 1, 0).getDate();

    return [
      ...Array(offset).fill(null),
      ...Array.from({ length: daysInMonth }, (_, index) => index + 1),
    ];
  }, [viewMonth]);

  const changeMonth = (step) => {
    setViewMonth(({ year, month }) => {
      const next = new Date(year, month + step, 1);

      return { year: next.getFullYear(), month: next.getMonth() };
    });
  };

  const handleSelectDay = (dateKey) => {
    setSelectedDate((prev) => (prev === dateKey ? "" : dateKey));
  };

  /* =======================================================
     HANDLERS
  ======================================================= */

  const handleJoin = (consultation) => {
    if (consultation.meetingUrl) {
      window.open(consultation.meetingUrl, "_blank", "noopener,noreferrer");
    }
  };

  const handleDetail = (consultation) => {
    console.log("Xem chi tiết:", consultation.id);

    // Sau này:
    // navigate(`/consultations/${consultation.id}`);
  };

  const handleCancel = async (consultation) => {
    if (!window.confirm("Bạn có chắc muốn hủy lịch tư vấn này?")) return;

    try {
      setCancelingId(consultation.id);

      setError("");

      await api.patch(CANCEL_ENDPOINT(consultation.id), {});

      setAppointments((prev) =>
        prev.map((item) =>
          String(getId(item)) === String(consultation.id)
            ? { ...item, status: "cancelled" }
            : item
        )
      );

      loadAppointments(true);
    } catch (err) {
      console.error("Không thể hủy lịch:", err);

      if (hasStatus(err, 401)) {
        setError(AUTH_MESSAGE);
      } else if (hasStatus(err, 403)) {
        setError("Bạn không có quyền hủy lịch hẹn này.");
      } else if (hasStatus(err, 404)) {
        setError("Không tìm thấy lịch hẹn hoặc chức năng hủy lịch.");
      } else {
        setError("Không thể hủy lịch. Vui lòng thử lại sau.");
      }
    } finally {
      setCancelingId(null);
    }
  };

  const handleBooking = () => {
    navigate(BOOKING_ROUTE);
  };

  /* =======================================================
     RENDER
  ======================================================= */

  return (
    <div className="my-consultations">
      {/* ===================================================
          HEADER BANNER
      =================================================== */}

      <section className="consultations-hero">
        <div className="consultations-hero__content">
          <h1>Lịch tư vấn của tôi</h1>

          <p>
            Quản lý lịch hẹn, theo dõi trạng thái và không bỏ lỡ bất kỳ buổi
            tư vấn nào.
          </p>
        </div>

        <div className="consultations-hero__quote">
          <span className="quote-mark">“</span>

          <p>
            Thời gian của bạn
            <br />
            là ưu tiên của chúng tôi.
          </p>

          <div className="quote-line"></div>
        </div>
      </section>

      {/* ERROR */}

      {error && (
        <div
          style={{
            margin: "0 0 15px",
            padding: "12px 16px",
            borderRadius: "8px",
            background: "#fff1f0",
            color: "#cf1322",
          }}
        >
          {error}
        </div>
      )}

      {/* ===================================================
          TOP ACTION
      =================================================== */}

      <div className="consultations-top">
        {/* FILTER */}

        <div className="consultation-filters">
          {filterItems.map((filter) => (
            <button
              type="button"
              key={filter.value}
              className={activeFilter === filter.value ? "active" : ""}
              onClick={() => setActiveFilter(filter.value)}
            >
              {filter.label}
            </button>
          ))}
        </div>

        {/* NEW BOOKING */}

        <button
          type="button"
          className="new-consultation-button"
          onClick={handleBooking}
        >
          <FontAwesomeIcon icon={faPlus} />

          <span>Đặt lịch tư vấn mới</span>
        </button>
      </div>

      {/* ===================================================
          MAIN CONTENT
      =================================================== */}

      <div className="consultations-content">
        {/* =================================================
            LEFT
        ================================================= */}

        <div className="consultations-list">
          {/* Đang lọc theo ngày */}

          {selectedDate && (
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                gap: "12px",
                marginBottom: "12px",
                padding: "10px 14px",
                borderRadius: "8px",
                background: "rgba(0, 0, 0, 0.04)",
              }}
            >
              <span>Lịch ngày {formatDateKey(selectedDate)}</span>

              <button
                type="button"
                onClick={() => setSelectedDate("")}
                style={{
                  border: "none",
                  background: "transparent",
                  cursor: "pointer",
                  textDecoration: "underline",
                }}
              >
                Bỏ lọc
              </button>
            </div>
          )}

          {loading ? (
            <div className="consultations-empty">
              <p>Đang tải lịch tư vấn...</p>
            </div>
          ) : filteredConsultations.length > 0 ? (
            filteredConsultations.map((consultation) => (
              <div className="consultation-card" key={consultation.id}>
                {/* =========================================
                    DATE
                ========================================= */}

                <div className="consultation-date">
                  <strong>{consultation.day}</strong>

                  <span>{consultation.month}</span>

                  <small>{consultation.year}</small>
                </div>

                {/* =========================================
                    INFORMATION
                ========================================= */}

                <div className="consultation-info">
                  {/* TITLE */}

                  <div className="consultation-title">
                    <h2>{consultation.title}</h2>

                    {consultation.category && (
                      <span
                        className={`consultation-category ${consultation.categoryClass}`}
                      >
                        {consultation.category}
                      </span>
                    )}
                  </div>

                  {/* TIME */}

                  <div className="consultation-row">
                    <FontAwesomeIcon icon={faClock} />

                    <span>{consultation.time}</span>
                  </div>

                  {/* TYPE */}

                  {consultation.typeLabel && (
                    <div className="consultation-row">
                      <FontAwesomeIcon icon={consultation.typeIcon} />

                      <span>{consultation.typeLabel}</span>
                    </div>
                  )}

                  {/* LAWYER */}

                  {consultation.lawyer && (
                    <div className="consultation-row">
                      <FontAwesomeIcon icon={faUser} />

                      <span>{consultation.lawyer}</span>
                    </div>
                  )}

                  {/* DESCRIPTION */}

                  {consultation.description && (
                    <div className="consultation-row">
                      <FontAwesomeIcon icon={faFileLines} />

                      <span>{consultation.description}</span>
                    </div>
                  )}
                </div>

                {/* =========================================
                    ACTIONS
                ========================================= */}

                <div className="consultation-actions">
                  {/* STATUS */}

                  <span
                    className={`consultation-status ${consultation.statusClass}`}
                  >
                    {consultation.statusClass === "upcoming" && (
                      <span className="status-icon">●</span>
                    )}

                    {consultation.statusClass === "completed" && (
                      <span className="status-icon">✓</span>
                    )}

                    {consultation.statusClass === "cancelled" && (
                      <span className="status-icon">×</span>
                    )}

                    {consultation.statusLabel}
                  </span>

                  {/* JOIN (chỉ khi có đường dẫn buổi tư vấn) */}

                  {consultation.showJoin && (
                    <button
                      type="button"
                      className="join-button"
                      onClick={() => handleJoin(consultation)}
                    >
                      <FontAwesomeIcon icon={faVideo} />

                      <span>Tham gia ngay</span>
                    </button>
                  )}

                  {/* DETAIL */}

                  <button
                    type="button"
                    className="detail-button"
                    onClick={() => handleDetail(consultation)}
                  >
                    Xem chi tiết
                  </button>

                  {/* CANCEL */}

                  {consultation.showCancel && (
                    <button
                      type="button"
                      className="cancel-button"
                      disabled={cancelingId === consultation.id}
                      onClick={() => handleCancel(consultation)}
                    >
                      <span>×</span>

                      {cancelingId === consultation.id
                        ? "Đang hủy..."
                        : "Hủy lịch"}
                    </button>
                  )}
                </div>
              </div>
            ))
          ) : (
            <div className="consultations-empty">
              <FontAwesomeIcon icon={faCalendarDays} />

              <h3>Không có lịch tư vấn</h3>

              <p>
                {selectedDate
                  ? "Không có lịch tư vấn nào vào ngày này."
                  : "Hiện chưa có lịch tư vấn trong mục này."}
              </p>
            </div>
          )}
        </div>

        {/* =================================================
            RIGHT SIDEBAR
        ================================================= */}

        <aside className="consultations-sidebar">
          {/* ===============================================
              CALENDAR
          =============================================== */}

          <div className="consultation-calendar">
            <div className="calendar-header">
              <h3>
                Lịch tháng {viewMonth.month + 1}, {viewMonth.year}
              </h3>

              <div style={{ display: "flex", gap: "6px" }}>
                <button
                  type="button"
                  aria-label="Tháng trước"
                  onClick={() => changeMonth(-1)}
                >
                  <FontAwesomeIcon icon={faChevronLeft} />
                </button>

                <button
                  type="button"
                  aria-label="Tháng sau"
                  onClick={() => changeMonth(1)}
                >
                  <FontAwesomeIcon icon={faChevronRight} />
                </button>
              </div>
            </div>

            <div className="calendar-week">
              {WEEK_DAYS.map((day) => (
                <span key={day}>{day}</span>
              ))}
            </div>

            <div className="calendar-days">
              {calendarCells.map((day, index) => {
                // Ô trống đầu tháng
                if (day === null) {
                  return (
                    <button
                      type="button"
                      key={`empty-${index}`}
                      disabled
                      tabIndex={-1}
                      aria-hidden="true"
                    />
                  );
                }

                const dateKey = `${viewMonth.year}-${pad(
                  viewMonth.month + 1
                )}-${pad(day)}`;

                const className = [
                  selectedDate === dateKey ? "selected" : "",
                  eventDays.has(dateKey) ? "has-event" : "",
                  dateKey === todayKey ? "today" : "",
                ]
                  .filter(Boolean)
                  .join(" ");

                return (
                  <button
                    type="button"
                    key={dateKey}
                    className={className}
                    style={
                      dateKey === todayKey ? { fontWeight: 700 } : undefined
                    }
                    onClick={() => handleSelectDay(dateKey)}
                  >
                    {day}
                  </button>
                );
              })}
            </div>
          </div>

          {/* ===============================================
              NOTICE
          =============================================== */}

          <div className="consultation-notice">
            <h3>
              <span className="notice-icon">
                <FontAwesomeIcon icon={faCircleInfo} />
              </span>
              Thông tin cần lưu ý
            </h3>

            <ul>
              <li>
                <FontAwesomeIcon icon={faCalendarDays} />

                <span>Vui lòng tham gia đúng giờ hẹn.</span>
              </li>

              <li>
                <FontAwesomeIcon icon={faVideo} />

                <span>
                  Kiểm tra thiết bị và kết nối mạng ổn định nếu tư vấn trực
                  tuyến.
                </span>
              </li>

              <li>
                <FontAwesomeIcon icon={faFileLines} />

                <span>
                  Chuẩn bị trước các tài liệu liên quan để buổi tư vấn đạt
                  hiệu quả tốt nhất.
                </span>
              </li>

              <li>
                <FontAwesomeIcon icon={faPhone} />

                <span>Liên hệ hỗ trợ nếu cần thay đổi lịch hẹn.</span>
              </li>
            </ul>
          </div>

          {/* ===============================================
              QUOTE CARD
          =============================================== */}

          <div className="consultation-sidebar-quote">
            <div>
              <span className="sidebar-quote-mark">“</span>

              <p>
                Mỗi cuộc tư vấn là
                <br />
                một bước gần hơn đến
                <br />
                công lý.
              </p>

              <div className="sidebar-quote-line"></div>

              <small>THEMIS TRUST</small>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
};

export default MyConsultations;
