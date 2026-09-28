import { getCurrentUser } from "../api/api";

import {
  Routes,
  Route,
  Navigate,
  Outlet,
} from "react-router-dom";

import "../assets/css/admin/AdminLawyerPages.css";

// =========================================================
// LAYOUT
// =========================================================

import AdminSidebar from "./AdminSidebar";
import AdminHeader from "./AdminHeader";

// =========================================================
// DASHBOARD + PROFILE
// =========================================================

import AdminDashboard from "./AdminDashboard";
import AdminProfile from "./AdminProfile";

// =========================================================
// ADMIN - USER
// =========================================================

import UserManagement from "./UserManagement";
import AdminUserDetail from "./AdminUserDetail";

// =========================================================
// ADMIN - LAWYER
// =========================================================

import LawyerManagement from "./LawyerManagement";
import AdminAddLawyer from "./AdminAddLawyer";
import AdminLawyerDetail from "./AdminLawyerDetail";

// =========================================================
// CONSULTATION
// =========================================================

import ConsultationManagement from "./ConsultationManagement";
import AdminConsultationDetail from "./AdminConsultationDetail";

// =========================================================
// OTHER ADMIN
// =========================================================

import AdminNotifications from "./AdminNotifications";
import AdminSystemSettings from "./AdminSystemSettings";

// =========================================================
// SHARED / LAWYER
// =========================================================

import CaseManagement from "./CaseManagement";
import AppointmentManagement from "./AppointmentManagement";
import ClientManagement from "./ClientManagement";
import Chat from "./Chat";


// =========================================================
// NORMALIZE ROLE
// =========================================================

function normalizeRole(value) {
  if (value === null || value === undefined) {
    return "";
  }

  return String(value)
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "");
}


// =========================================================
// LẤY ROLE TỪ USER
// =========================================================

function getRoleFromUser(user) {

  if (!user) {
    return "";
  }

  /*
   * Hỗ trợ nhiều trường hợp dữ liệu trả về từ API/localStorage
   */

  const roleValue =
    user.role ??
    user.Role ??
    user.roleName ??
    user.RoleName ??
    user.userRole ??
    user.UserRole ??
    user.user?.role ??
    user.user?.Role ??
    user.data?.role ??
    user.data?.Role ??
    user.userInfo?.role ??
    user.userInfo?.Role;

  return normalizeRole(roleValue);
}


// =========================================================
// KIỂM TRA USER ĐĂNG NHẬP
// =========================================================

function isLoggedIn() {

  const user = getCurrentUser();

  return !!user;
}


// =========================================================
// ADMIN LAYOUT
// =========================================================

const AdminLayout = () => {

  return (
    <div className="admin-layout">

      <AdminSidebar />

      <div className="admin-layout__right">

        <AdminHeader />

        <main className="admin-layout__content">
          <Outlet />
        </main>

      </div>

    </div>
  );
};


// =========================================================
// TRANG KHÔNG CÓ QUYỀN
// =========================================================

const AccessDenied = () => {

  return (
    <div
      style={{
        minHeight: "400px",
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        alignItems: "center",
        padding: "40px",
        textAlign: "center",
      }}
    >

      <div
        style={{
          fontSize: "48px",
          marginBottom: "16px",
        }}
      >
        🔒
      </div>

      <h2>
        Bạn không có quyền truy cập
      </h2>

      <p
        style={{
          color: "#6b7280",
          marginTop: "8px",
        }}
      >
        Tài khoản của bạn không được phép sử dụng chức năng này.
      </p>

      <button
        type="button"
        onClick={() => {
          window.location.href = "/admin/dashboard";
        }}
        style={{
          marginTop: "20px",
          padding: "10px 20px",
          border: "none",
          borderRadius: "8px",
          background: "#2563eb",
          color: "#fff",
          cursor: "pointer",
        }}
      >
        Về Dashboard
      </button>

    </div>
  );
};


// =========================================================
// ROLE GUARD
// =========================================================

const RoleGuard = ({
  allowedRoles = [],
  children,
}) => {

  const user = getCurrentUser();

  // -------------------------------------------------------
  // CHƯA ĐĂNG NHẬP
  // -------------------------------------------------------

  if (!user) {

    return (
      <Navigate
        to="/login"
        replace
      />
    );
  }


  // -------------------------------------------------------
  // LẤY ROLE ĐỘNG
  // -------------------------------------------------------

  const role = getRoleFromUser(user);


  // -------------------------------------------------------
  // DEBUG
  // -------------------------------------------------------

  console.log(
    "ADMIN ROLE:",
    role,
    "| USER:",
    user,
    "| ALLOWED:",
    allowedRoles
  );


  // -------------------------------------------------------
  // KIỂM TRA QUYỀN
  // -------------------------------------------------------

  if (!allowedRoles.includes(role)) {

    return (
      <AccessDenied />
    );
  }


  return children;
};


// =========================================================
// ADMIN ONLY
// =========================================================

const AdminOnly = ({
  children,
}) => {

  return (
    <RoleGuard
      allowedRoles={[
        "admin",
      ]}
    >
      {children}
    </RoleGuard>
  );
};


// =========================================================
// ADMIN + STAFF
// =========================================================

const AdminStaff = ({
  children,
}) => {

  return (
    <RoleGuard
      allowedRoles={[
        "admin",
        "staff",
      ]}
    >
      {children}
    </RoleGuard>
  );
};


// =========================================================
// ADMIN + STAFF + LAWYER
// =========================================================

const StaffLawyer = ({
  children,
}) => {

  return (
    <RoleGuard
      allowedRoles={[
        "admin",
        "staff",
        "lawyer",
      ]}
    >
      {children}
    </RoleGuard>
  );
};


// =========================================================
// LAWYER ONLY
// =========================================================

const LawyerOnly = ({
  children,
}) => {

  return (
    <RoleGuard
      allowedRoles={[
        "lawyer",
      ]}
    >
      {children}
    </RoleGuard>
  );
};


// =========================================================
// ADMIN PAGE
// =========================================================

const AdminPage = () => {

  const user = getCurrentUser();


  // =======================================================
  // CHƯA ĐĂNG NHẬP
  // =======================================================

  if (!user) {

    return (
      <Navigate
        to="/login"
        replace
      />
    );
  }


  // =======================================================
  // LẤY ROLE ĐỘNG
  // =======================================================

  const role = getRoleFromUser(user);


  // =======================================================
  // DEBUG ROLE
  // =======================================================

  console.log(
    "======================================"
  );

  console.log(
    "CURRENT USER:",
    user
  );

  console.log(
    "CURRENT ROLE:",
    role
  );

  console.log(
    "======================================"
  );


  // =======================================================
  // ROLE ĐƯỢC PHÉP VÀO ADMIN
  // =======================================================

  const validRoles = [
    "admin",
    "staff",
    "lawyer",
  ];


  // =======================================================
  // ROLE KHÔNG HỢP LỆ
  // =======================================================

  if (!validRoles.includes(role)) {

    return (
      <Navigate
        to="/"
        replace
      />
    );
  }


  // =======================================================
  // ROUTES
  // =======================================================

  return (

    <Routes>

      <Route
        element={
          <AdminLayout />
        }
      >

        {/* =================================================
            ROOT
        ================================================= */}

        <Route
          index
          element={
            <Navigate
              to="dashboard"
              replace
            />
          }
        />


        {/* =================================================
            DASHBOARD
            ADMIN + STAFF + LAWYER
        ================================================= */}

        <Route
          path="dashboard"
          element={
            <StaffLawyer>
              <AdminDashboard />
            </StaffLawyer>
          }
        />


        {/* =================================================
            PROFILE
            ADMIN + STAFF + LAWYER
        ================================================= */}

        <Route
          path="profile"
          element={
            <StaffLawyer>
              <AdminProfile />
            </StaffLawyer>
          }
        />


        {/* =================================================
            USERS
            ADMIN ONLY
        ================================================= */}

        <Route
          path="users"
          element={
            <AdminOnly>
              <UserManagement />
            </AdminOnly>
          }
        />


        {/* =================================================
            USER DETAIL
            ADMIN + STAFF
        ================================================= */}

        <Route
          path="users/:id"
          element={
            <AdminStaff>
              <AdminUserDetail />
            </AdminStaff>
          }
        />


        {/* =================================================
            LAWYERS
            ADMIN ONLY
        ================================================= */}

        <Route
          path="lawyers"
          element={
            <AdminOnly>
              <LawyerManagement />
            </AdminOnly>
          }
        />


        {/* =================================================
            ADD LAWYER
            ADMIN ONLY
        ================================================= */}

        <Route
          path="lawyers/add"
          element={
            <AdminOnly>
              <AdminAddLawyer />
            </AdminOnly>
          }
        />


        {/* =================================================
            EDIT LAWYER
            ADMIN ONLY
        ================================================= */}

        <Route
          path="lawyers/edit"
          element={
            <AdminOnly>
              <AdminAddLawyer />
            </AdminOnly>
          }
        />


        {/* =================================================
            LAWYER DETAIL
            ADMIN + STAFF
        ================================================= */}

        <Route
          path="lawyers/:id"
          element={
            <AdminStaff>
              <AdminLawyerDetail />
            </AdminStaff>
          }
        />


        {/* =================================================
            CONSULTATIONS
            ADMIN + STAFF + LAWYER
        ================================================= */}

        <Route
          path="consultations"
          element={
            <StaffLawyer>
              <ConsultationManagement />
            </StaffLawyer>
          }
        />


        {/* =================================================
            CONSULTATION DETAIL
            ADMIN + STAFF + LAWYER
        ================================================= */}

        <Route
          path="consultations/:id"
          element={
            <StaffLawyer>
              <AdminConsultationDetail />
            </StaffLawyer>
          }
        />


        {/* =================================================
            CASES
            ADMIN + STAFF + LAWYER

            ADMIN:
            - Xem tất cả hồ sơ
            - Thêm
            - Sửa
            - Xóa
            - Upload tài liệu

            STAFF:
            - Xem tất cả hồ sơ

            LAWYER:
            - Backend chỉ trả hồ sơ được phân công
            - Có thể xem/sửa/thao tác trên hồ sơ được phân công
        ================================================= */}

        <Route
          path="cases"
          element={
            <StaffLawyer>

              <CaseManagement
                role={role}
                isAdmin={
                  role === "admin"
                }
                isStaff={
                  role === "staff"
                }
                isLawyer={
                  role === "lawyer"
                }
              />

            </StaffLawyer>
          }
        />


        {/* =================================================
            APPOINTMENTS
            ADMIN + STAFF + LAWYER
        ================================================= */}

        <Route
          path="appointments"
          element={
            <StaffLawyer>

              <AppointmentManagement
                role={role}
                isAdmin={
                  role === "admin"
                }
                isStaff={
                  role === "staff"
                }
                isLawyer={
                  role === "lawyer"
                }
              />

            </StaffLawyer>
          }
        />


        {/* =================================================
            CLIENTS
            ADMIN + STAFF + LAWYER
        ================================================= */}

        <Route
          path="clients"
          element={
            <StaffLawyer>

              <ClientManagement
                role={role}
                isAdmin={
                  role === "admin"
                }
                isStaff={
                  role === "staff"
                }
                isLawyer={
                  role === "lawyer"
                }
              />

            </StaffLawyer>
          }
        />


        {/* =================================================
            CHAT
            LAWYER ONLY
        ================================================= */}

        <Route
          path="chat"
          element={
            <LawyerOnly>
              <Chat />
            </LawyerOnly>
          }
        />


        {/* =================================================
            NOTIFICATIONS
            ADMIN + STAFF + LAWYER
        ================================================= */}

        <Route
          path="notifications/*"
          element={
            <StaffLawyer>
              <AdminNotifications />
            </StaffLawyer>
          }
        />


        {/* =================================================
            SETTINGS
            ADMIN ONLY
        ================================================= */}

        {/* <Route
          path="settings"
          element={
            <AdminOnly>
              <AdminSystemSettings />
            </AdminOnly>
          }
        /> */}


        {/* =================================================
            FALLBACK
        ================================================= */}

        <Route
          path="*"
          element={
            <Navigate
              to="dashboard"
              replace
            />
          }
        />

      </Route>

    </Routes>
  );
};


export default AdminPage;