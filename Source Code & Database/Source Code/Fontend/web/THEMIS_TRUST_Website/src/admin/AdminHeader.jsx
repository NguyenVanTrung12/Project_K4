
import { useEffect, useState } from "react";

import {
  api,
  getCurrentUser,
  logout,
} from "../api/api";

import {
  useNavigate,
} from "react-router-dom";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faBars,
  faMagnifyingGlass,
  faBell,
  faChevronDown,
} from "@fortawesome/free-solid-svg-icons";

import "../../src/assets/css/admin/AdminHeader.css";


// =========================================================
// API SERVER
// =========================================================

const getServerBaseUrl = () => {
  const apiUrl =
    import.meta.env.VITE_API_URL ||
    "https://localhost:7139/api";

  return apiUrl.replace(/\/api\/?$/, "");
};


// =========================================================
// AVATAR URL
// =========================================================

const buildAvatarUrl = (avatarUrl) => {
  if (!avatarUrl) {
    return "";
  }

  // Nếu backend đã trả URL đầy đủ
  if (
    avatarUrl.startsWith("http://") ||
    avatarUrl.startsWith("https://")
  ) {
    return avatarUrl;
  }

  // URL tương đối bắt đầu bằng /
  const serverBaseUrl = getServerBaseUrl();

  if (avatarUrl.startsWith("/")) {
    return `${serverBaseUrl}${avatarUrl}`;
  }

  // URL tương đối không có /
  return `${serverBaseUrl}/${avatarUrl}`;
};


// =========================================================
// DEFAULT AVATAR
// =========================================================

const DEFAULT_AVATAR =
  "https://ui-avatars.com/api/?name=Themis&background=245986&color=fff&size=256";


// =========================================================
// COMPONENT
// =========================================================

const AdminHeader = ({
  onToggleSidebar,
  sidebarCollapsed = false,
}) => {

  const [searchKeyword, setSearchKeyword] = useState("");
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [unread, setUnread] = useState(0);

  const user = getCurrentUser();
  const navigate = useNavigate();


  // =========================================================
  // ROLE
  // =========================================================

  const role = String(
    user?.role ||
    user?.Role ||
    ""
  )
    .trim()
    .toLowerCase();


  const getRoleName = () => {

    switch (role) {

      case "admin":
        return "Quản trị viên";

      case "lawyer":
        return "Luật sư";

      case "staff":
        return "Nhân viên";

      default:
        return "Người dùng";
    }
  };


  // =========================================================
  // NOTIFICATION
  // =========================================================

  useEffect(() => {

    api
      .get("/notifications/unread-count")
      .then((data) => {

        if (typeof data === "number") {
          setUnread(data);
        }
        else if (data?.count !== undefined) {
          setUnread(data.count);
        }
        else if (data?.unreadCount !== undefined) {
          setUnread(data.unreadCount);
        }

      })
      .catch(() => {
        setUnread(0);
      });

  }, []);


  // =========================================================
  // SEARCH
  // =========================================================

  const handleSearch = (event) => {

    const value = event.target.value;

    setSearchKeyword(value);
  };


  // =========================================================
  // TOGGLE SIDEBAR
  // =========================================================

  const handleToggleSidebar = () => {

    if (onToggleSidebar) {
      onToggleSidebar();
    }

  };


  // =========================================================
  // PROFILE
  // =========================================================

  const handleProfileClick = () => {

    setShowProfileMenu(
      (prev) => !prev
    );

  };


  // =========================================================
  // PROFILE PAGE
  // =========================================================

  const handleProfile = () => {

    setShowProfileMenu(false);

    navigate("/admin/profile");

  };


  // =========================================================
  // LOGOUT
  // =========================================================

  const handleLogout = () => {

    logout();

    navigate(
      "/login",
      {
        replace: true,
      }
    );

  };


  // =========================================================
  // AVATAR
  // =========================================================

  const avatarUrl =
    buildAvatarUrl(
      user?.avatarUrl
    ) || DEFAULT_AVATAR;


  // =========================================================
  // AVATAR ERROR
  // =========================================================

  const handleAvatarError = (e) => {

    // Tránh loop vô hạn nếu avatar mặc định cũng lỗi
    if (
      e.currentTarget.dataset.fallback === "true"
    ) {
      return;
    }

    e.currentTarget.dataset.fallback = "true";

    e.currentTarget.src =
      DEFAULT_AVATAR;
  };


  // =========================================================
  // RENDER
  // =========================================================

  return (

    <header
      className={`admin-header ${
        sidebarCollapsed
          ? "admin-header--collapsed"
          : ""
      }`}
    >

      {/* =====================================================
          LEFT
      ===================================================== */}

      <div className="admin-header__left">

        {/* MENU */}

        <button
          type="button"
          className="admin-header__menu-button"
          onClick={handleToggleSidebar}
          aria-label="Mở hoặc đóng menu"
        >

          <FontAwesomeIcon
            icon={faBars}
          />

        </button>


        {/* SEARCH */}

        <div className="admin-header__search">

          <FontAwesomeIcon
            icon={faMagnifyingGlass}
            className="admin-header__search-icon"
          />

          <input
            type="text"
            value={searchKeyword}
            onChange={handleSearch}
            placeholder="Tìm kiếm..."
          />

        </div>

      </div>


      {/* =====================================================
          RIGHT
      ===================================================== */}

      <div className="admin-header__right">

        {/* ===================================================
            NOTIFICATION
        =================================================== */}

        <button
          type="button"
          className="admin-header__notification"
          aria-label="Thông báo"
          onClick={() =>
            navigate("/admin/notifications")
          }
        >

          <FontAwesomeIcon
            icon={faBell}
          />

          {unread > 0 && (
            <span className="admin-header__notification-badge">
              {unread}
            </span>
          )}

        </button>


        {/* ===================================================
            PROFILE
        =================================================== */}

        <div className="admin-header__profile-container">

          <button
            type="button"
            className="admin-header__profile"
            onClick={handleProfileClick}
          >

            {/* =================================================
                AVATAR
            ================================================= */}

            <div className="admin-header__avatar">

              <img
                src={avatarUrl}
                alt={
                  user?.fullName ||
                  getRoleName()
                }
                onError={handleAvatarError}
              />

            </div>


            {/* =================================================
                PROFILE INFO
            ================================================= */}

            <div className="admin-header__profile-info">

              <strong>
                {user?.fullName || "Người dùng"}
              </strong>

              <span>
                {getRoleName()}
              </span>

            </div>


            {/* =================================================
                ARROW
            ================================================= */}

            <FontAwesomeIcon
              icon={faChevronDown}
              className={
                `admin-header__profile-arrow ${
                  showProfileMenu
                    ? "rotate"
                    : ""
                }`
              }
            />

          </button>


          {/* =================================================
              DROPDOWN
          ================================================= */}

          {showProfileMenu && (

            <div className="admin-header__dropdown">

              <button
                type="button"
                onClick={handleProfile}
              >
                Thông tin cá nhân
              </button>


              <button
                type="button"
                onClick={() =>
                  navigate("/admin/profile")
                }
              >
                Cài đặt tài khoản
              </button>


              <div className="admin-header__dropdown-divider"></div>


              <button
                type="button"
                className="logout"
                onClick={handleLogout}
              >
                Đăng xuất
              </button>

            </div>

          )}

        </div>

      </div>

    </header>

  );
};


export default AdminHeader;

