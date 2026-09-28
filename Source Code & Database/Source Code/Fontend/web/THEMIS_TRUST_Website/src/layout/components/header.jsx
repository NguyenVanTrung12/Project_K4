import { useEffect, useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import "../../assets/css/header.css";

const API_ORIGIN = "https://localhost:5001";

const TopMenu = () => {
  const [menuOpen, setMenuOpen] = useState(false);
  const [currentUser, setCurrentUser] = useState(null);
  const [userDropdownOpen, setUserDropdownOpen] = useState(false);

  const navigate = useNavigate();

  // =========================================================
  // LOAD USER
  // =========================================================

  const loadCurrentUser = () => {
    try {
      const savedUser = localStorage.getItem("themis_user");

      if (!savedUser) {
        setCurrentUser(null);
        return;
      }

      const user = JSON.parse(savedUser);

      console.log("THEMIS USER:", user);
      console.log("AVATAR:", 
        user.avatarUrl ||
        user.AvatarUrl ||
        user.avatar ||
        user.Avatar
      );

      setCurrentUser(user);
    } catch (error) {
      console.error("Lỗi đọc thông tin người dùng:", error);
      setCurrentUser(null);
    }
  };

  useEffect(() => {
    loadCurrentUser();

    const handleAuthChange = () => {
      loadCurrentUser();
    };

    window.addEventListener("auth-change", handleAuthChange);

    const handleStorageChange = (event) => {
      if (
        event.key === "themis_user" ||
        event.key === "token" ||
        event.key === "accessToken"
      ) {
        loadCurrentUser();
      }
    };

    window.addEventListener("storage", handleStorageChange);

    return () => {
      window.removeEventListener(
        "auth-change",
        handleAuthChange
      );

      window.removeEventListener(
        "storage",
        handleStorageChange
      );
    };
  }, []);

  // =========================================================
  // USER NAME
  // =========================================================

  const getUserName = () => {
    if (!currentUser) {
      return "Tài khoản";
    }

    return (
      currentUser.fullName ||
      currentUser.FullName ||
      currentUser.name ||
      currentUser.Name ||
      currentUser.email ||
      currentUser.Email ||
      "Tài khoản"
    );
  };

  // =========================================================
  // RAW AVATAR
  // =========================================================

  const getRawAvatar = () => {
    if (!currentUser) {
      return null;
    }

    return (
      currentUser.avatarUrl ||
      currentUser.AvatarUrl ||
      currentUser.avatar ||
      currentUser.Avatar ||
      null
    );
  };

  // =========================================================
  // AVATAR URL
  // =========================================================

  const getUserAvatar = () => {
    const avatar = getRawAvatar();

    if (!avatar) {
      return null;
    }

    // Nếu là URL đầy đủ
    if (
      avatar.startsWith("http://") ||
      avatar.startsWith("https://") ||
      avatar.startsWith("data:image/")
    ) {
      return avatar;
    }

    // Nếu backend trả về /uploads/...
    if (avatar.startsWith("/")) {
      return `${API_ORIGIN}${avatar}`;
    }

    // Nếu backend trả về uploads/...
    return `${API_ORIGIN}/${avatar}`;
  };

  // =========================================================
  // CLOSE MOBILE MENU
  // =========================================================

  const closeMenu = () => {
    setMenuOpen(false);
  };

  // =========================================================
  // LOGOUT
  // =========================================================

  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("accessToken");
    localStorage.removeItem("themis_user");

    sessionStorage.removeItem("token");
    sessionStorage.removeItem("accessToken");
    sessionStorage.removeItem("themis_user");

    setCurrentUser(null);
    setUserDropdownOpen(false);
    setMenuOpen(false);

    window.dispatchEvent(
      new Event("auth-change")
    );

    navigate("/");
  };

  // =========================================================
  // PROFILE
  // =========================================================

  const handleProfile = () => {
    setUserDropdownOpen(false);
    closeMenu();

    navigate("/profile");
  };

  // =========================================================
  // EDIT PROFILE
  // =========================================================

  const handleEditProfile = () => {
    setUserDropdownOpen(false);
    closeMenu();

    navigate("/profile/edit");
  };

  // =========================================================
  // AVATAR ERROR
  // =========================================================

  const handleAvatarError = (e) => {
    console.error(
      "Không thể tải avatar:",
      e.currentTarget.src
    );

    e.currentTarget.style.display = "none";
  };

  // =========================================================
  // RENDER
  // =========================================================

  return (
    <header className="top-menu">
      <div className="navbar-container-fluid">

        {/* ===================================================
            LOGO
        ==================================================== */}

        <NavLink
          to="/"
          className="logo"
          onClick={closeMenu}
        >
          <div className="logo-icon">
            <i className="fa-solid fa-scale-balanced"></i>
          </div>

          <div className="logo-text">
            <span className="logo-main">
              THEMIS
            </span>

            <span className="logo-main">
              TRUST
            </span>
          </div>
        </NavLink>

        {/* ===================================================
            NAVIGATION
        ==================================================== */}

        <nav
          className={`nav-links ${
            menuOpen ? "active" : ""
          }`}
        >
          <NavLink
            to="/"
            onClick={closeMenu}
            className={({ isActive }) =>
              `nav-item ${
                isActive ? "nav-active" : ""
              }`
            }
          >
            Trang chủ
          </NavLink>

          <NavLink
            to="/lawyers"
            onClick={closeMenu}
            className={({ isActive }) =>
              `nav-item ${
                isActive ? "nav-active" : ""
              }`
            }
          >
            Đội ngũ luật sư
          </NavLink>

          <NavLink
            to="/services"
            onClick={closeMenu}
            className={({ isActive }) =>
              `nav-item ${
                isActive ? "nav-active" : ""
              }`
            }
          >
            Dịch vụ pháp lý
          </NavLink>

          <NavLink
            to="/about"
            onClick={closeMenu}
            className={({ isActive }) =>
              `nav-item ${
                isActive ? "nav-active" : ""
              }`
            }
          >
            Về chúng tôi
          </NavLink>

          <NavLink
            to="/news"
            onClick={closeMenu}
            className={({ isActive }) =>
              `nav-item ${
                isActive ? "nav-active" : ""
              }`
            }
          >
            Tin tức
          </NavLink>

          <NavLink
            to="/contact"
            onClick={closeMenu}
            className={({ isActive }) =>
              `nav-item ${
                isActive ? "nav-active" : ""
              }`
            }
          >
            Liên hệ
          </NavLink>
        </nav>

        {/* ===================================================
            ACTIONS
        ==================================================== */}

        <div className="nav-actions">

          {/* SEARCH */}

          <button
            type="button"
            className="icon-button"
            aria-label="Tìm kiếm"
          >
            <i className="fa-solid fa-magnifying-glass"></i>
          </button>

          {/* =================================================
              USER
          ================================================== */}

          {currentUser ? (
            <div
              className={`user-menu-wrapper ${
                userDropdownOpen ? "open" : ""
              }`}
              onMouseEnter={() =>
                setUserDropdownOpen(true)
              }
              onMouseLeave={() =>
                setUserDropdownOpen(false)
              }
            >

              {/* USER BUTTON */}

              <button
                type="button"
                className="user-menu-button"
                onClick={() =>
                  setUserDropdownOpen(
                    (prev) => !prev
                  )
                }
              >
                {getUserAvatar() ? (
                  <img
                    src={getUserAvatar()}
                    alt="Avatar"
                    className="header-user-avatar"
                    onError={handleAvatarError}
                  />
                ) : (
                  <span className="user-default-avatar">
                    <i className="fa-solid fa-user"></i>
                  </span>
                )}

                <span className="user-name">
                  {getUserName()}
                </span>

                <i
                  className={`fa-solid fa-chevron-down user-arrow ${
                    userDropdownOpen
                      ? "rotate"
                      : ""
                  }`}
                ></i>
              </button>

              {/* =================================================
                  DROPDOWN
              ================================================== */}

              <div
                className={`user-dropdown ${
                  userDropdownOpen ? "show" : ""
                }`}
              >

                {/* USER INFO */}

                <div className="user-dropdown-header">

                  <div className="dropdown-avatar">
                    {getUserAvatar() ? (
                      <img
                        src={getUserAvatar()}
                        alt="Avatar"
                        onError={handleAvatarError}
                      />
                    ) : (
                      <i className="fa-solid fa-user"></i>
                    )}
                  </div>

                  <div className="dropdown-user-info">
                    <strong>
                      {getUserName()}
                    </strong>

                    <span>
                      {currentUser.email ||
                        currentUser.Email ||
                        ""}
                    </span>
                  </div>
                </div>

                <div className="dropdown-divider"></div>

                {/* PROFILE */}

                <button
                  type="button"
                  className="dropdown-item"
                  onClick={handleProfile}
                >
                  <span className="dropdown-item-icon">
                    <i className="fa-regular fa-user"></i>
                  </span>

                  <span>
                    Hồ sơ cá nhân
                  </span>
                </button>

                {/* EDIT PROFILE */}

                <button
                  type="button"
                  className="dropdown-item"
                  onClick={handleEditProfile}
                >
                  <span className="dropdown-item-icon">
                    <i className="fa-regular fa-pen-to-square"></i>
                  </span>

                  <span>
                    Chỉnh sửa profile
                  </span>
                </button>

                <div className="dropdown-divider"></div>

                {/* LOGOUT */}

                <button
                  type="button"
                  className="dropdown-item logout-item"
                  onClick={handleLogout}
                >
                  <span className="dropdown-item-icon">
                    <i className="fa-solid fa-right-from-bracket"></i>
                  </span>

                  <span>
                    Đăng xuất
                  </span>
                </button>
              </div>
            </div>
          ) : (
            /* =================================================
               LOGIN
            ================================================== */

            <NavLink
              to="/login"
              className="login-button"
              onClick={closeMenu}
            >
              Đăng nhập
            </NavLink>
          )}

          {/* =================================================
              BOOKING
          ================================================== */}

          <NavLink
            to="/booking"
            className="booking-button"
            onClick={closeMenu}
          >
            Đặt lịch tư vấn
          </NavLink>
        </div>

        {/* ===================================================
            MOBILE MENU
        ==================================================== */}

        <button
          type="button"
          className="mobile-menu-button"
          onClick={() =>
            setMenuOpen(!menuOpen)
          }
          aria-label="Mở menu"
        >
          {menuOpen ? "✕" : "☰"}
        </button>
      </div>
    </header>
  );
};

export default TopMenu;