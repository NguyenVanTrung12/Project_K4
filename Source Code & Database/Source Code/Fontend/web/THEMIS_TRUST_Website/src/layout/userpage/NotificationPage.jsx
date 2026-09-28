import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import { api } from "../../api/api";

import {
  faCalendarDays,
  faFileLines,
  faCreditCard,
  faBell,
  faGear,
  faEnvelope,
  faVolumeHigh,
  faBullhorn,
  faMagnifyingGlass,
  faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/userpage/NotificationPage.css";

/* =========================================================
   CẤU HÌNH
========================================================= */

const NOTIFICATIONS_ENDPOINT = "/notifications";

// Đánh dấu tất cả đã đọc
const READ_ALL_ENDPOINT = "/notifications/read-all";

// ⚠️ Đánh dấu một thông báo đã đọc. Nếu backend đặt tên khác thì đổi ở đây.
// Nếu endpoint này lỗi, thông báo vẫn được đánh dấu đã đọc trên giao diện
// nhưng sẽ hiện lại là chưa đọc khi tải lại trang.
const READ_ONE_ENDPOINT = (id) => `/notifications/${id}/read`;

// Backend lưu CreatedAt bằng giờ UTC nhưng JSON không kèm "Z".
// Đặt false nếu backend lưu giờ địa phương (DateTime.Now).
const SERVER_TIME_IS_UTC = true;

const POLL_MS = 30000; // tự kiểm tra thông báo mới
const CLOCK_MS = 60000; // làm mới nhãn "x phút trước"

const AUTH_MESSAGE =
  "Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng xuất và đăng nhập lại.";

const FORBIDDEN_MESSAGE =
  "Tài khoản của bạn hiện chưa có quyền xem thông báo (lỗi 403). Vui lòng liên hệ quản trị viên.";

// Bấm vào thông báo thì chuyển tới trang tương ứng
const TARGET_ROUTES = {
  appointment: "/my-consultations",
  consultation: "/consultation-requests",
};

const notificationFilters = [
  { id: "all", label: "Tất cả", icon: faEnvelope },
  { id: "appointment", label: "Lịch hẹn", icon: faCalendarDays },
  { id: "consultation", label: "Yêu cầu tư vấn", icon: faFileLines },
  { id: "payment", label: "Thanh toán", icon: faCreditCard },
  { id: "system", label: "Hệ thống", icon: faGear },
];

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

// Bỏ dấu + chữ thường: gõ "lich" vẫn ra "Lịch"
const normalizeText = (value) =>
  String(value || "")
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d");

// Chuỗi ngày không có múi giờ thì coi là UTC (xem SERVER_TIME_IS_UTC)
const parseServerDate = (value) => {
  if (!value) return null;

  let text = String(value).trim();

  if (SERVER_TIME_IS_UTC && !/(Z|[+-]\d{2}:?\d{2})$/i.test(text)) {
    text = `${text}Z`;
  }

  const parsed = new Date(text);

  return Number.isNaN(parsed.getTime()) ? null : parsed;
};

const formatRelativeTime = (date) => {
  if (!date) return "";

  const minutes = Math.floor((Date.now() - date.getTime()) / 60000);

  if (minutes < 1) return "Vừa xong";

  if (minutes < 60) return `${minutes} phút trước`;

  const hours = Math.floor(minutes / 60);

  if (hours < 24) return `${hours} giờ trước`;

  const days = Math.floor(hours / 24);

  if (days < 7) return `${days} ngày trước`;

  return date.toLocaleString("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

// type của backend -> nhóm lọc trên giao diện
const getCategory = (type) => {
  if (type.includes("appointment")) return "appointment";
  if (type.includes("consultation")) return "consultation";
  if (type.includes("payment") || type.includes("invoice")) return "payment";

  return "system";
};

const CATEGORY_STYLE = {
  appointment: { icon: faCalendarDays, iconClass: "gold" },
  consultation: { icon: faFileLines, iconClass: "red" },
  payment: { icon: faCreditCard, iconClass: "gold" },
  system: { icon: faBell, iconClass: "blue" },
};

// Một số type cụ thể có icon riêng
const TYPE_ICON = {
  case_update: faFileLines,
  message: faEnvelope,
  welcome: faGear,
};

const toNotification = (raw) => {
  const type = String(pick(raw, ["type", "Type"])).trim().toLowerCase();

  const category = getCategory(type);

  const style = CATEGORY_STYLE[category];

  const priority = String(pick(raw, ["priority", "Priority"])).toLowerCase();

  return {
    id: getId(raw),
    type,
    category,
    title: String(pick(raw, ["title", "Title"]) || "Thông báo"),
    description: String(
      pick(raw, ["body", "Body", "message", "Message", "description", "Description"])
    ),
    date: parseServerDate(pick(raw, ["createdAt", "CreatedAt"])),
    isRead: Boolean(raw?.isRead ?? raw?.IsRead ?? false),
    important:
      Boolean(raw?.isImportant ?? raw?.IsImportant ?? false) ||
      ["high", "urgent"].includes(priority),
    icon: TYPE_ICON[type] || style.icon,
    iconClass: style.iconClass,
  };
};

// So sánh nhanh để tải lại âm thầm không gây render thừa
const signature = (list) =>
  list.map((item) => `${item.id}:${item.isRead ? 1 : 0}`).join("|");

/* =========================================================
   NOTIFICATION PAGE
========================================================= */

const NotificationPage = () => {
  const navigate = useNavigate();

  /* =======================================================
     STATE
  ======================================================= */

  const [notifications, setNotifications] = useState([]);
  const [activeFilter, setActiveFilter] = useState("all");
  const [searchKeyword, setSearchKeyword] = useState("");

  const [loading, setLoading] = useState(true);
  const [markingAll, setMarkingAll] = useState(false);
  const [error, setError] = useState("");

  // 401/403 -> dừng tự động tải lại để không spam lỗi
  const pollBlockedRef = useRef(false);

  // Chỉ để làm mới nhãn thời gian "x phút trước"
  const [, setClockTick] = useState(0);

  /* =======================================================
     LOAD DATA
     silent = true: tải lại âm thầm, không hiện "Đang tải..."
  ======================================================= */

  const loadNotifications = async (silent = false) => {
    try {
      if (!silent) setLoading(true);

      const data = await api.get(NOTIFICATIONS_ENDPOINT);

      const list = toList(data)
        .map(toNotification)
        .filter((item) => item.id)
        .sort((a, b) => (b.date?.getTime() || 0) - (a.date?.getTime() || 0));

      setNotifications((prev) =>
        signature(prev) === signature(list) ? prev : list
      );

      setError("");
    } catch (err) {
      console.error("Không thể lấy danh sách thông báo:", err);

      if (hasStatus(err, 401) || hasStatus(err, 403)) {
        pollBlockedRef.current = true;

        setError(hasStatus(err, 401) ? AUTH_MESSAGE : FORBIDDEN_MESSAGE);
      } else if (!silent) {
        setNotifications([]);

        setError("Không thể tải thông báo. Vui lòng thử lại sau.");
      }
    } finally {
      if (!silent) setLoading(false);
    }
  };

  useEffect(() => {
    loadNotifications();
  }, []);

  // Tự kiểm tra thông báo mới; tab ẩn thì tạm dừng, quay lại thì cập nhật ngay
  useEffect(() => {
    const tick = () => {
      if (!document.hidden && !pollBlockedRef.current) loadNotifications(true);
    };

    const timer = setInterval(tick, POLL_MS);

    document.addEventListener("visibilitychange", tick);

    return () => {
      clearInterval(timer);
      document.removeEventListener("visibilitychange", tick);
    };
  }, []);

  useEffect(() => {
    const timer = setInterval(() => setClockTick((n) => n + 1), CLOCK_MS);

    return () => clearInterval(timer);
  }, []);

  /* =======================================================
     DỮ LIỆU HIỂN THỊ
  ======================================================= */

  const filteredNotifications = useMemo(() => {
    const keyword = normalizeText(searchKeyword);

    return notifications.filter((item) => {
      const matchFilter =
        activeFilter === "all" || item.category === activeFilter;

      const matchSearch =
        !keyword ||
        normalizeText(`${item.title} ${item.description}`).includes(keyword);

      return matchFilter && matchSearch;
    });
  }, [notifications, activeFilter, searchKeyword]);

  // Số chưa đọc: tổng và theo từng nhóm
  const unreadCount = useMemo(
    () => notifications.filter((item) => !item.isRead).length,
    [notifications]
  );

  const unreadByCategory = useMemo(() => {
    const counts = {};

    notifications.forEach((item) => {
      if (!item.isRead) {
        counts[item.category] = (counts[item.category] || 0) + 1;
      }
    });

    return counts;
  }, [notifications]);

  // Thông báo quan trọng: được backend đánh dấu, hoặc lịch hẹn chưa đọc
  const importantList = useMemo(
    () =>
      notifications.filter(
        (item) =>
          !item.isRead && (item.important || item.category === "appointment")
      ),
    [notifications]
  );

  const topImportant = importantList[0] || null;

  // Báo số chưa đọc cho ProfileSidebar để badge cập nhật ngay
  useEffect(() => {
    if (loading || error) return;

    window.dispatchEvent(
      new CustomEvent("notifications:unread", {
        detail: { count: unreadCount },
      })
    );
  }, [unreadCount, loading, error]);

  /* =======================================================
     MARK ALL READ
  ======================================================= */

  const handleMarkAllRead = async () => {
    if (unreadCount === 0 || markingAll) return;

    try {
      setMarkingAll(true);

      setError("");

      await api.patch(READ_ALL_ENDPOINT, {});

      setNotifications((prev) =>
        prev.map((item) => ({ ...item, isRead: true }))
      );
    } catch (err) {
      console.error("Không thể đánh dấu đã đọc:", err);

      setError(
        hasStatus(err, 401)
          ? AUTH_MESSAGE
          : "Không thể đánh dấu tất cả đã đọc. Vui lòng thử lại."
      );
    } finally {
      setMarkingAll(false);
    }
  };

  /* =======================================================
     CLICK NOTIFICATION
     Đánh dấu đã đọc rồi chuyển tới trang liên quan
  ======================================================= */

  const handleNotificationClick = (notification) => {
    if (!notification.isRead) {
      setNotifications((prev) =>
        prev.map((item) =>
          String(item.id) === String(notification.id)
            ? { ...item, isRead: true }
            : item
        )
      );

      api
        .patch(READ_ONE_ENDPOINT(notification.id), {})
        .catch((err) =>
          console.warn("Không thể lưu trạng thái đã đọc:", err)
        );
    }

    const target = TARGET_ROUTES[notification.category];

    if (target) navigate(target);
  };

  /* =======================================================
     RENDER
  ======================================================= */

  return (
    <section className="notification-page">
      {/* =================================================
          HERO
      ================================================= */}

      <div className="notification-hero">
        <div className="notification-hero__content">
          <h1>Thông báo</h1>

          <p>
            Cập nhật nhanh chóng các thông tin, lịch hẹn và
            <br />
            những nội dung quan trọng từ Themis.
          </p>
        </div>

        <div className="notification-hero__quote">
          <span className="notification-quote-mark">“</span>

          <p>
            Thông tin minh bạch
            <br />
            là nền tảng của niềm tin.
          </p>

          <div className="notification-quote-line"></div>

          <span className="notification-quote-brand">THEMIS TRUST</span>
        </div>
      </div>

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

      {/* =================================================
          FILTER BAR
      ================================================= */}

      <div className="notification-toolbar">
        <div className="notification-filter-list">
          {notificationFilters.map((filter) => {
            const badge =
              filter.id === "all"
                ? unreadCount
                : unreadByCategory[filter.id] || 0;

            return (
              <button
                type="button"
                key={filter.id}
                className={`notification-filter ${
                  activeFilter === filter.id ? "active" : ""
                }`}
                onClick={() => setActiveFilter(filter.id)}
              >
                <FontAwesomeIcon icon={filter.icon} />

                <span>{filter.label}</span>

                {badge > 0 && <span className="filter-badge">{badge}</span>}
              </button>
            );
          })}
        </div>

        {/* SEARCH */}

        <div className="notification-search">
          <FontAwesomeIcon icon={faMagnifyingGlass} />

          <input
            type="text"
            placeholder="Tìm kiếm thông báo..."
            value={searchKeyword}
            onChange={(e) => setSearchKeyword(e.target.value)}
          />
        </div>
      </div>

      {/* =================================================
          MAIN
      ================================================= */}

      <div className="notification-content">
        {/* =================================================
            NOTIFICATION LIST
        ================================================= */}

        <div className="notification-list-card">
          {loading ? (
            <div className="notification-empty">
              <p>Đang tải thông báo...</p>
            </div>
          ) : filteredNotifications.length > 0 ? (
            filteredNotifications.map((notification) => (
              <div
                className={`notification-item ${
                  !notification.isRead ? "unread" : ""
                }`}
                key={notification.id}
                onClick={() => handleNotificationClick(notification)}
              >
                {/* ICON */}

                <div
                  className={`notification-item__icon ${notification.iconClass}`}
                >
                  <FontAwesomeIcon icon={notification.icon} />
                </div>

                {/* CONTENT */}

                <div className="notification-item__content">
                  <h3>{notification.title}</h3>

                  <p>{notification.description}</p>
                </div>

                {/* TIME */}

                <div className="notification-item__right">
                  <span className="notification-time">
                    {formatRelativeTime(notification.date)}
                  </span>

                  <FontAwesomeIcon
                    icon={faArrowRight}
                    className="notification-arrow"
                  />
                </div>

                {/* UNREAD DOT */}

                {!notification.isRead && (
                  <span className="notification-unread-dot"></span>
                )}
              </div>
            ))
          ) : (
            <div className="notification-empty">
              <FontAwesomeIcon icon={faBell} />

              <h3>Không có thông báo</h3>

              <p>
                {notifications.length === 0
                  ? "Bạn chưa có thông báo nào."
                  : "Không tìm thấy thông báo phù hợp."}
              </p>
            </div>
          )}
        </div>

        {/* =================================================
            RIGHT SIDEBAR
        ================================================= */}

        <aside className="notification-sidebar">
          {/* =================================================
              IMPORTANT
          ================================================= */}

          <div className="notification-important-card">
            <div className="notification-sidebar-title">
              <div className="notification-sidebar-title__icon">
                <FontAwesomeIcon icon={faVolumeHigh} />
              </div>

              <h2>Thông báo quan trọng</h2>

              <span className="important-count">{importantList.length}</span>
            </div>

            {topImportant ? (
              <div
                className="important-notification"
                style={{ cursor: "pointer" }}
                onClick={() => handleNotificationClick(topImportant)}
              >
                <div className="important-notification__icon">
                  <FontAwesomeIcon icon={faBullhorn} />
                </div>

                <div className="important-notification__content">
                  <h3>{topImportant.title}</h3>

                  <p>{topImportant.description}</p>
                </div>

                <FontAwesomeIcon
                  icon={faArrowRight}
                  className="important-arrow"
                />
              </div>
            ) : (
              <p style={{ padding: "12px 4px", color: "#6b7280" }}>
                Hiện không có thông báo quan trọng nào.
              </p>
            )}
          </div>

          {/* =================================================
              UNREAD
          ================================================= */}

          <div className="unread-card">
            <div className="unread-card__icon">
              <FontAwesomeIcon icon={faEnvelope} />
            </div>

            <div className="unread-card__content">
              <h3>
                {unreadCount > 0
                  ? `Bạn có ${unreadCount} thông báo chưa đọc`
                  : "Bạn đã đọc hết thông báo"}
              </h3>

              <p>
                {unreadCount > 0
                  ? "Hãy kiểm tra để không bỏ lỡ những thông tin quan trọng."
                  : "Thông báo mới sẽ xuất hiện tại đây."}
              </p>

              <button
                type="button"
                onClick={handleMarkAllRead}
                disabled={unreadCount === 0 || markingAll}
              >
                {markingAll ? "Đang xử lý..." : "Đánh dấu tất cả đã đọc"}
              </button>
            </div>
          </div>

          {/* =================================================
              QUOTE CARD
          ================================================= */}

          <div className="notification-sidebar-quote">
            <div className="sidebar-quote-overlay"></div>

            <div className="sidebar-quote-content">
              <p>
                “Mỗi thông báo
                <br />
                là một bước tiến gần hơn
                <br />
                đến giải pháp pháp lý
                <br />
                của bạn.”
              </p>

              <div className="sidebar-quote-line"></div>

              <span>THEMIS TRUST</span>
            </div>
          </div>
        </aside>
      </div>
    </section>
  );
};

export default NotificationPage;
