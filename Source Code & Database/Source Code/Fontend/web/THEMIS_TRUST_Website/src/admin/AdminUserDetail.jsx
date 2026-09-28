import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUser,
  faEnvelope,
  faPhone,
  faLocationDot,
  faCalendarDays,
  faIdCard,
  faBriefcase,
  faCircleCheck,
  faArrowLeft,
  faShieldHalved,
  faClock,
  faFilePen,
  faBan,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../api/api";
import { toAvatarUrl } from "../utils/avatar";

import "../assets/css/admin/AdminUserDetail.css";

/* =========================================================
   AVATAR
   Tự quay về icon người nếu ảnh không tải được
========================================================= */

const DetailAvatar = ({ src, name }) => {
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setFailed(false);
  }, [src]);

  if (!src || failed) {
    return <FontAwesomeIcon icon={faUser} />;
  }

  return (
    <img
      src={src}
      alt={name}
      onError={() => {
        console.warn("Không tải được ảnh đại diện:", src);
        setFailed(true);
      }}
    />
  );
};

/* =========================================================
   HELPERS
========================================================= */

const getRoleName = (value) => {
  switch (String(value || "").toLowerCase()) {
    case "admin":
      return "Quản trị viên";

    case "staff":
      return "Nhân viên";

    case "lawyer":
      return "Luật sư";

    case "client":
    case "user":
      return "Người dùng";

    default:
      return value || "Chưa xác định";
  }
};

const formatDateTime = (value) => {
  if (!value) return "Chưa cập nhật";

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) return "Chưa cập nhật";

  return date.toLocaleString("vi-VN");
};

const formatDate = (value) => {
  if (!value) return "Chưa cập nhật";

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) return "Chưa cập nhật";

  return date.toLocaleDateString("vi-VN");
};

const formatTimeAgo = (value) => {
  if (!value) return "Chưa có dữ liệu";

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) return "Chưa có dữ liệu";

  const minutes = Math.floor((new Date().getTime() - date.getTime()) / 60000);

  if (minutes < 1) return "Vừa xong";
  if (minutes < 60) return `${minutes} phút trước`;

  const hours = Math.floor(minutes / 60);

  if (hours < 24) return `${hours} giờ trước`;

  const days = Math.floor(hours / 24);

  if (days === 1) return "1 ngày trước";
  if (days < 30) return `${days} ngày trước`;

  const months = Math.floor(days / 30);

  if (months < 12) return `${months} tháng trước`;

  return `${Math.floor(months / 12)} năm trước`;
};

/* =========================================================
   COMPONENT
========================================================= */

const AdminUserDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  /* =========================================================
     GET USER DETAIL
  ========================================================= */

  useEffect(() => {
    const fetchUserDetail = async () => {
      try {
        setLoading(true);
        setError("");

        const data = await api.get(`/users/${id}`);

        setUser(data);
      } catch (err) {
        console.error("Không thể lấy thông tin người dùng:", err);

        setError(err?.message || "Không thể tải thông tin người dùng.");
      } finally {
        setLoading(false);
      }
    };

    if (id) {
      fetchUserDetail();
    }
  }, [id]);

  /* =========================================================
     LOADING
  ========================================================= */

  if (loading) {
    return (
      <div className="admin-user-detail-loading">
        Đang tải thông tin người dùng...
      </div>
    );
  }

  /* =========================================================
     ERROR
  ========================================================= */

  if (error) {
    return (
      <div className="admin-user-detail-empty">
        <h3>Không thể tải thông tin người dùng</h3>

        <p>{error}</p>

        <button
          type="button"
          className="admin-user-detail-back"
          onClick={() => navigate("/admin/users")}
        >
          <FontAwesomeIcon icon={faArrowLeft} />

          <span>Quay lại</span>
        </button>
      </div>
    );
  }

  /* =========================================================
     NOT FOUND
  ========================================================= */

  if (!user) {
    return (
      <div className="admin-user-detail-empty">
        Không tìm thấy thông tin người dùng.
        <br />
        <button
          type="button"
          className="admin-user-detail-back"
          onClick={() => navigate("/admin/users")}
        >
          <FontAwesomeIcon icon={faArrowLeft} />

          <span>Quay lại</span>
        </button>
      </div>
    );
  }

  /* =========================================================
     DATA MAPPING
  ========================================================= */

  const fullName =
    user.fullName || user.FullName || user.name || user.Name || "Chưa cập nhật";

  const email = user.email || user.Email || "Chưa cập nhật";

  const phone = user.phone || user.Phone || "Chưa cập nhật";

  // Ghép địa chỉ backend vào đường dẫn ảnh
  const avatar = toAvatarUrl(
    user.avatarUrl || user.AvatarUrl || user.avatar || user.Avatar || ""
  );

  const role = user.role || user.Role || "client";

  const isActive = user.isActive ?? user.IsActive ?? true;

  const createdAt = user.createdAt || user.CreatedAt || null;

  const updatedAt = user.updatedAt || user.UpdatedAt || null;

  const userId = user.id || user.Id || id;

  const roleName = getRoleName(role);

  /* =========================================================
     RENDER
  ========================================================= */

  return (
    <section className="admin-user-detail-page">
      {/* BACK */}

      <button
        type="button"
        className="admin-user-detail-back"
        onClick={() => navigate("/admin/users")}
      >
        <FontAwesomeIcon icon={faArrowLeft} />

        <span>Quay lại</span>
      </button>

      {/* USER HEADER */}

      <section className="admin-user-detail-header">
        {/* AVATAR */}

        <div className="admin-user-detail-avatar-wrapper">
          <div className="admin-user-detail-avatar">
            <DetailAvatar src={avatar} name={fullName} />
          </div>

          <div className="admin-user-detail-status">
            <span
              className={`admin-user-detail-status-dot ${
                isActive ? "active" : "inactive"
              }`}
            ></span>

            {isActive ? "Đang hoạt động" : "Đã khóa"}
          </div>
        </div>

        {/* MAIN INFORMATION */}

        <div className="admin-user-detail-main-info">
          <div className="admin-user-detail-name-row">
            <h1>{fullName}</h1>

            {isActive && (
              <span className="admin-user-detail-verified">
                <FontAwesomeIcon icon={faCircleCheck} />
              </span>
            )}
          </div>

          <p className="admin-user-detail-role">{roleName}</p>

          <div className="admin-user-detail-summary">
            <div className="admin-user-detail-summary-item">
              <FontAwesomeIcon icon={faIdCard} />

              <span>ID: {userId}</span>
            </div>

            <div className="admin-user-detail-summary-item">
              <FontAwesomeIcon icon={faShieldHalved} />

              <span>Vai trò: {roleName}</span>
            </div>

            <div className="admin-user-detail-summary-item">
              <FontAwesomeIcon icon={faCalendarDays} />

              <span>Ngày đăng ký: {formatDate(createdAt)}</span>
            </div>

            <div className="admin-user-detail-summary-item">
              <FontAwesomeIcon icon={faEnvelope} />

              <span>Email: {email}</span>
            </div>

            <div className="admin-user-detail-summary-item">
              <FontAwesomeIcon icon={faPhone} />

              <span>Số điện thoại: {phone}</span>
            </div>

            <div className="admin-user-detail-summary-item">
              <FontAwesomeIcon icon={faClock} />

              <span>Cập nhật: {formatTimeAgo(updatedAt)}</span>
            </div>
          </div>
        </div>
      </section>

      {/* PERSONAL INFORMATION */}

      <section className="admin-user-detail-card">
        <div className="admin-user-detail-section-title">
          <FontAwesomeIcon icon={faUser} />

          <h2>Thông tin cá nhân</h2>
        </div>

        <div className="admin-user-detail-information-grid">
          {/* LEFT COLUMN */}

          <div className="admin-user-detail-column">
            <div className="admin-user-detail-row">
              <div className="admin-user-detail-label">
                <FontAwesomeIcon icon={faUser} />

                <span>Họ và tên</span>
              </div>

              <div className="admin-user-detail-value">{fullName}</div>
            </div>

            <div className="admin-user-detail-row">
              <div className="admin-user-detail-label">
                <FontAwesomeIcon icon={faEnvelope} />

                <span>Email</span>
              </div>

              <div className="admin-user-detail-value">{email}</div>
            </div>

            <div className="admin-user-detail-row">
              <div className="admin-user-detail-label">
                <FontAwesomeIcon icon={faPhone} />

                <span>Số điện thoại</span>
              </div>

              <div className="admin-user-detail-value">{phone}</div>
            </div>
          </div>

          {/* RIGHT COLUMN */}

          <div className="admin-user-detail-column">
            <div className="admin-user-detail-row">
              <div className="admin-user-detail-label">
                <FontAwesomeIcon icon={faShieldHalved} />

                <span>Vai trò</span>
              </div>

              <div className="admin-user-detail-value">{roleName}</div>
            </div>

            <div className="admin-user-detail-row">
              <div className="admin-user-detail-label">
                <FontAwesomeIcon icon={faCircleCheck} />

                <span>Trạng thái</span>
              </div>

              <div className="admin-user-detail-value">
                {isActive ? "Hoạt động" : "Đã khóa"}
              </div>
            </div>

            <div className="admin-user-detail-row">
              <div className="admin-user-detail-label">
                <FontAwesomeIcon icon={faCalendarDays} />

                <span>Ngày đăng ký</span>
              </div>

              <div className="admin-user-detail-value">
                {formatDateTime(createdAt)}
              </div>
            </div>

            <div className="admin-user-detail-row">
              <div className="admin-user-detail-label">
                <FontAwesomeIcon icon={faClock} />

                <span>Cập nhật gần nhất</span>
              </div>

              <div className="admin-user-detail-value">
                {formatDateTime(updatedAt)}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ACCOUNT INFORMATION */}

      <section className="admin-user-detail-card">
        <div className="admin-user-detail-section-title">
          <FontAwesomeIcon icon={faBriefcase} />

          <h2>Thông tin tài khoản</h2>
        </div>

        <div className="admin-user-detail-account-grid">
          <div className="admin-user-detail-account-item">
            <span className="admin-user-detail-account-label">
              ID tài khoản
            </span>

            <strong>{userId}</strong>
          </div>

          <div className="admin-user-detail-account-item">
            <span className="admin-user-detail-account-label">
              Quyền truy cập
            </span>

            <strong>{roleName}</strong>
          </div>

          <div className="admin-user-detail-account-item">
            <span className="admin-user-detail-account-label">
              Trạng thái tài khoản
            </span>

            <strong>{isActive ? "Đang hoạt động" : "Đã khóa"}</strong>
          </div>

          <div className="admin-user-detail-account-item">
            <span className="admin-user-detail-account-label">
              Tạo tài khoản
            </span>

            <strong>{formatDateTime(createdAt)}</strong>
          </div>
        </div>
      </section>

      {/* CONTACT */}

      <section className="admin-user-detail-card">
        <div className="admin-user-detail-section-title">
          <FontAwesomeIcon icon={faPhone} />

          <h2>Thông tin liên hệ</h2>
        </div>

        <div className="admin-user-detail-contact-grid">
          <div className="admin-user-detail-contact-item">
            <FontAwesomeIcon icon={faEnvelope} />

            <div>
              <span>Email</span>

              <strong>{email}</strong>
            </div>
          </div>

          <div className="admin-user-detail-contact-item">
            <FontAwesomeIcon icon={faPhone} />

            <div>
              <span>Số điện thoại</span>

              <strong>{phone}</strong>
            </div>
          </div>

          <div className="admin-user-detail-contact-item">
            <FontAwesomeIcon icon={faLocationDot} />

            <div>
              <span>Địa chỉ</span>

              <strong>Chưa cập nhật</strong>
            </div>
          </div>
        </div>
      </section>

      {/* ACTIVITY */}

      <section className="admin-user-detail-card">
        <div className="admin-user-detail-section-title">
          <FontAwesomeIcon icon={faClock} />

          <h2>Hoạt động tài khoản</h2>
        </div>

        <div className="admin-user-detail-activity">
          <div className="admin-user-detail-activity-item">
            <div className="admin-user-detail-activity-icon">
              <FontAwesomeIcon icon={faUser} />
            </div>

            <div>
              <strong>Tài khoản được tạo</strong>

              <span>{formatDateTime(createdAt)}</span>
            </div>
          </div>

          <div className="admin-user-detail-activity-item">
            <div className="admin-user-detail-activity-icon">
              <FontAwesomeIcon icon={faFilePen} />
            </div>

            <div>
              <strong>Cập nhật thông tin gần nhất</strong>

              <span>{formatDateTime(updatedAt)}</span>
            </div>
          </div>

          <div className="admin-user-detail-activity-item">
            <div className="admin-user-detail-activity-icon">
              <FontAwesomeIcon icon={isActive ? faCircleCheck : faBan} />
            </div>

            <div>
              <strong>
                {isActive
                  ? "Tài khoản đang hoạt động"
                  : "Tài khoản đã bị khóa"}
              </strong>

              <span>Trạng thái hiện tại</span>
            </div>
          </div>
        </div>
      </section>
    </section>
  );
};

export default AdminUserDetail;
