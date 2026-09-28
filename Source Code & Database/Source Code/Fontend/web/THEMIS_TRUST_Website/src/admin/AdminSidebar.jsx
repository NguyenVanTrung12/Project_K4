import { NavLink } from "react-router-dom";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faHouse,
  faUser,
  faUsers,
  faCalendarDays,
  faBell,
  faGear,
  faFolderOpen,
  faComments,
  faUserTie,
  faClipboardList,
  faUserGroup,
} from "@fortawesome/free-solid-svg-icons";

import { getCurrentUser } from "../api/api";

import "../assets/css/admin/AdminSidebar.css";

// =========================================================
// MENU ADMIN
// =========================================================

const adminMenuItems = [

  {
    label: "Dashboard",
    icon: faHouse,
    path: "/admin/dashboard",
  },

  {
    label: "Quản lý người dùng",
    icon: faUser,
    path: "/admin/users",
  },

  {
    label: "Quản lý luật sư",
    icon: faUsers,
    path: "/admin/lawyers",
  },

  {
    label: "Quản lý tư vấn / yêu cầu",
    icon: faClipboardList,
    path: "/admin/consultations",
  },

  {
    label: "Quản lý vụ án",
    icon: faFolderOpen,
    path: "/admin/cases",
  },

  {
    label: "Lịch hẹn",
    icon: faCalendarDays,
    path: "/admin/appointments",
  },

  {
    label: "Thông báo",
    icon: faBell,
    path: "/admin/notifications",
  },

  // {
  //   label: "Cài đặt hệ thống",
  //   icon: faGear,
  //   path: "/admin/settings",
  // },

];

// =========================================================
// MENU LAWYER
// =========================================================

const lawyerMenuItems = [

  {
    label: "Dashboard",
    icon: faHouse,
    path: "/admin/dashboard",
  },

  {
    label: "Hồ sơ cá nhân",
    icon: faUserTie,
    path: "/admin/profile",
  },

  {
    label: "Khách hàng",
    icon: faUserGroup,
    path: "/admin/clients",
  },

  {
    label: "Hồ sơ vụ án",
    icon: faFolderOpen,
    path: "/admin/cases",
  },

  {
    label: "Yêu cầu tư vấn",
    icon: faClipboardList,
    path: "/admin/consultations",
  },

  {
    label: "Lịch hẹn",
    icon: faCalendarDays,
    path: "/admin/appointments",
  },

  {
    label: "Tin nhắn",
    icon: faComments,
    path: "/admin/chat",
  },

  {
    label: "Thông báo",
    icon: faBell,
    path: "/admin/notifications",
  },

];

// =========================================================
// MENU STAFF
// =========================================================

const staffMenuItems = [

  {
    label: "Dashboard",
    icon: faHouse,
    path: "/admin/dashboard",
  },

  {
    label: "Quản lý tư vấn / yêu cầu",
    icon: faClipboardList,
    path: "/admin/consultations",
  },

  {
    label: "Quản lý vụ án",
    icon: faFolderOpen,
    path: "/admin/cases",
  },

  {
    label: "Lịch hẹn",
    icon: faCalendarDays,
    path: "/admin/appointments",
  },

  {
    label: "Thông báo",
    icon: faBell,
    path: "/admin/notifications",
  },

];

// =========================================================
// ROLE NAME
// =========================================================

const getRoleName = (role) => {

  switch (role) {

    case "admin":
      return "QUẢN TRỊ VIÊN";

    case "lawyer":
      return "LUẬT SƯ";

    case "staff":
      return "NHÂN VIÊN";

    default:
      return "";

  }

};

// =========================================================
// ROLE
// =========================================================

const getRole = (user) => {

  if (!user) {
    return "";
  }

  return String(
    user.role ??
    user.Role ??
    user.roleName ??
    user.RoleName ??
    user.userRole ??
    user.UserRole ??
    ""
  )
    .trim()
    .toLowerCase();

};

// =========================================================
// SIDEBAR
// =========================================================

const AdminSidebar = () => {

  const user = getCurrentUser();

  const role = getRole(user);

  // =======================================================
  // MENU THEO ROLE
  // =======================================================

  let menuItems = [];

  if (role === "admin") {

    menuItems = adminMenuItems;

  }
  else if (role === "lawyer") {

    menuItems = lawyerMenuItems;

  }
  else if (role === "staff") {

    menuItems = staffMenuItems;

  }

  const roleName = getRoleName(role);

  // =======================================================
  // RENDER
  // =======================================================

  return (

    <aside className="admin-sidebar">

      {/* ===================================================
          LOGO
      =================================================== */}

      <div className="admin-sidebar__logo">

        <div className="admin-sidebar__logo-symbol">

          <span>

            <i className="fa-solid fa-scale-balanced"></i>

          </span>

        </div>

        <div className="admin-sidebar__logo-text">

          <strong>THEMIS</strong>

          <strong>TRUST</strong>

        </div>

      </div>

      {/* ===================================================
          ROLE
      =================================================== */}

      <div className="admin-sidebar__role">

        {roleName}

      </div>

      {/* ===================================================
          MENU
      =================================================== */}

      <nav className="admin-sidebar__menu">

        {menuItems.map((item) => (

          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `admin-sidebar__item ${
                isActive
                  ? "admin-sidebar__item--active"
                  : ""
              }`
            }
          >

            <span className="admin-sidebar__icon">

              <FontAwesomeIcon
                icon={item.icon}
              />

            </span>

            <span className="admin-sidebar__label">

              {item.label}

            </span>

          </NavLink>

        ))}

      </nav>

      {/* ===================================================
          BOTTOM
      =================================================== */}

      <div className="admin-sidebar__bottom">

        <div className="admin-sidebar__copyright">

          THEMIS TRUST

        </div>

      </div>

    </aside>

  );

};

export default AdminSidebar;