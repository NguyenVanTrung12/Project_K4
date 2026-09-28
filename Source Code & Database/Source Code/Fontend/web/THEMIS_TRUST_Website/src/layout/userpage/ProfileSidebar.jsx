import { useEffect, useRef, useState } from "react";
import { NavLink } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUser,
  faCalendarDays,
  faComments,
  faBell,
  faGear,
  faRightFromBracket,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../../api/api";

import "../../assets/css/userpage/ProfileSidebar.css";

/* =========================================================
   CẤU HÌNH
========================================================= */

const NOTIFICATIONS_ENDPOINT = "/notifications";

// Tự kiểm tra lại số thông báo chưa đọc (ms)
const POLL_MS = 30000;

// Trang Thông báo phát sự kiện này mỗi khi số chưa đọc thay đổi
// (đọc một thông báo, đánh dấu tất cả đã đọc...) để badge cập nhật ngay.
const UNREAD_EVENT = "notifications:unread";

/* =========================================================
   HELPERS
========================================================= */

const toList = (data) =>
  Array.isArray(data) ? data : data?.items || data?.data || [];

const hasStatus = (err, code) =>
  err?.status === code ||
  err?.response?.status === code ||
  new RegExp(`\\b${code}\\b`).test(String(err?.message || ""));

const formatBadge = (count) => (count > 99 ? "99+" : String(count));

/* =========================================================
   COMPONENT
========================================================= */

const ProfileSidebar = () => {
  const [unreadCount, setUnreadCount] = useState(0);

  // 401/403 -> dừng tự tải lại để không spam lỗi
  const blockedRef = useRef(false);

  /* =======================================================
     SỐ THÔNG BÁO CHƯA ĐỌC
  ======================================================= */

  useEffect(() => {
    let cancelled = false;

    const loadUnreadCount = async () => {
      if (document.hidden || blockedRef.current) return;

      try {
        const data = await api.get(NOTIFICATIONS_ENDPOINT);

        if (cancelled) return;

        const count = toList(data).filter(
          (item) => !(item?.isRead ?? item?.IsRead ?? false)
        ).length;

        setUnreadCount(count);
      } catch (err) {
        if (hasStatus(err, 401) || hasStatus(err, 403)) {
          blockedRef.current = true;
        }

        // Lỗi khác (mạng...) thì giữ nguyên số cũ
        console.warn("Không thể tải số thông báo chưa đọc:", err);
      }
    };

    loadUnreadCount();

    const timer = setInterval(loadUnreadCount, POLL_MS);

    // Quay lại tab thì cập nhật ngay
    document.addEventListener("visibilitychange", loadUnreadCount);

    // Trang Thông báo báo số mới -> cập nhật tức thì
    const handleUnreadEvent = (event) => {
      const count = Number(event?.detail?.count);

      if (Number.isFinite(count)) setUnreadCount(count);
    };

    window.addEventListener(UNREAD_EVENT, handleUnreadEvent);

    return () => {
      cancelled = true;

      clearInterval(timer);

      document.removeEventListener("visibilitychange", loadUnreadCount);

      window.removeEventListener(UNREAD_EVENT, handleUnreadEvent);
    };
  }, []);

  /* =======================================================
     MENU
  ======================================================= */

  const menuItems = [
    {
      label: "Trang cá nhân",
      icon: faUser,
      path: "/profile",
    },
    {
      label: "Lịch tư vấn của tôi",
      icon: faCalendarDays,
      path: "/profile/my-consultations",
    },

    {
      label: "Nhắn tin",
      icon: faComments,
      path: "/profile/chats",
    },

    {
      label: "Thông báo",
      icon: faBell,
      path: "/profile/notifications",
      notification: unreadCount,
    },
    // {
    //   label: "Cài đặt",
    //   icon: faGear,
    //   path: "/profile/settings",
    // },
  ];

  const handleLogout = () => {
    console.log("Đăng xuất");

    // Sau này:
    // localStorage.removeItem("token");
    // navigate("/login");
  };

  return (
    <aside className="profile-sidebar">
      {/* =================================================
          MENU
      ================================================= */}

      <nav className="profile-sidebar__menu">
        {menuItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            /*
              Chỉ "/profile" mới dùng end.
              Nhờ vậy khi đang ở /profile/my-consultations
              thì "Trang cá nhân" sẽ KHÔNG active.
            */
            end={item.path === "/profile"}
            className={({ isActive }) =>
              `profile-sidebar__item ${isActive ? "active" : ""}`
            }
          >
            {/* ICON */}

            <span className="profile-sidebar__item-icon">
              <FontAwesomeIcon icon={item.icon} />
            </span>

            {/* TEXT */}

            <span className="profile-sidebar__item-label">{item.label}</span>

            {/* NOTIFICATION (chỉ hiện khi > 0) */}

            {item.notification > 0 && (
              <span className="profile-sidebar__notification">
                {formatBadge(item.notification)}
              </span>
            )}
          </NavLink>
        ))}
      </nav>

      {/* =================================================
          LOGOUT
      ================================================= */}

      <button
        type="button"
        className="profile-sidebar__logout"
        onClick={handleLogout}
      >
        <FontAwesomeIcon icon={faRightFromBracket} />

        <span>Đăng xuất</span>
      </button>
    </aside>
  );
};

export default ProfileSidebar;
