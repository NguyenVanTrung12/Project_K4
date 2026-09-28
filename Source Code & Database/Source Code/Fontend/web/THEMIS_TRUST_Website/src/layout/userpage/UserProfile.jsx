import { useEffect, useMemo, useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUser,
  faCalendarDays,
  faPenToSquare,
  faFileLines,
  faEnvelope,
  faPhone,
  faVenusMars,
  faLocationDot,
  faBriefcase,
  faShieldHalved,
  faCamera,
  faChevronRight,
  faClock,
  faFileCircleCheck,
  faFileCircleXmark,
  faFileCircleExclamation,
} from "@fortawesome/free-solid-svg-icons";

import { api, getCurrentUser } from "../../api/api";

import "../../assets/css/userpage/UserProfile.css";

import profileBackground from "../../assets/images/banner/banner1.png";

/* =========================================================
   CẤU HÌNH ENDPOINT
   ⚠️ Đối chiếu với Swagger và đổi nếu backend đặt tên khác.
========================================================= */

// Hồ sơ đầy đủ của người đang đăng nhập.
// Nếu lỗi, trang vẫn hiện dữ liệu từ getCurrentUser().
const PROFILE_ENDPOINT = (userId) => `/users/${userId}`;

// Khách gọi endpoint này chỉ nhận lịch hẹn của chính mình.
const APPOINTMENTS_ENDPOINT = "/appointments";

// Yêu cầu tư vấn.
const REQUESTS_ENDPOINT = "/consultationrequests";

const UPCOMING_LIMIT = 3;
const REQUEST_LIMIT = 3;

const AUTH_MESSAGE =
  "Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng xuất và đăng nhập lại.";

/* =========================================================
   HELPERS
========================================================= */

const API_ORIGIN = (
  import.meta.env.VITE_API_URL || "https://localhost:5001/api"
).replace(/\/api\/?$/, "");

// Backend trả "/uploads/avatars/abc.jpg" nên cần ghép địa chỉ backend
const toAvatarUrl = (url) => {
  if (!url) return "";

  const value = String(url).trim();

  if (/^(https?:|data:|blob:)/i.test(value)) return value;

  return value.startsWith("/")
    ? `${API_ORIGIN}${value}`
    : `${API_ORIGIN}/${value}`;
};

const toList = (data) =>
  Array.isArray(data) ? data : data?.items || data?.data || [];

const getId = (item) =>
  item?.id || item?.Id || item?.userId || item?.UserId || null;

const hasStatus = (err, code) =>
  err?.status === code ||
  err?.response?.status === code ||
  new RegExp(`\\b${code}\\b`).test(String(err?.message || ""));

// Lấy giá trị đầu tiên không rỗng trong danh sách key
const pick = (obj, keys) => {
  for (const key of keys) {
    const value = obj?.[key];

    if (value !== undefined && value !== null && String(value).trim() !== "") {
      return value;
    }
  }

  return "";
};

// Bỏ dấu, chữ thường, để so sánh trạng thái / giới tính
const normalizeText = (value) =>
  String(value || "")
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d");

// Gộp object gốc với user/client lồng bên trong (nếu có)
const flatten = (raw) => {
  const data = raw?.data && typeof raw.data === "object" ? raw.data : raw;

  return {
    ...(data?.client || data?.Client || {}),
    ...(data?.user || data?.User || {}),
    ...(data || {}),
  };
};

const normalizeProfile = (raw) => {
  const src = flatten(raw);

  return {
    fullName: pick(src, ["fullName", "FullName", "name", "Name"]),
    email: pick(src, ["email", "Email"]),
    phone: pick(src, ["phone", "Phone", "phoneNumber", "PhoneNumber"]),
    address: pick(src, ["address", "Address"]),
    birthday: pick(src, [
      "dateOfBirth",
      "DateOfBirth",
      "birthDate",
      "BirthDate",
      "birthday",
      "Birthday",
      "dob",
      "Dob",
    ]),
    gender: pick(src, ["gender", "Gender", "sex", "Sex"]),
    occupation: pick(src, [
      "occupation",
      "Occupation",
      "job",
      "Job",
      "jobTitle",
      "JobTitle",
    ]),
    bio: pick(src, ["bio", "Bio", "about", "About"]),
    avatarUrl: pick(src, ["avatarUrl", "AvatarUrl", "avatar", "Avatar"]),
    role: pick(src, ["role", "Role"]),
  };
};

// Dữ liệu từ API ghi đè dữ liệu gốc, nhưng chỉ khi có giá trị
const mergeProfile = (base, extra) => {
  const merged = { ...base };

  Object.entries(extra).forEach(([key, value]) => {
    if (value) merged[key] = value;
  });

  return merged;
};

const ROLE_LABELS = {
  client: "Khách hàng",
  lawyer: "Luật sư",
  admin: "Quản trị viên",
  staff: "Nhân viên",
};

const getRoleLabel = (role) =>
  ROLE_LABELS[String(role || "").trim().toLowerCase()] || "Khách hàng";

const getInitials = (name) => {
  const words = String(name || "")
    .trim()
    .split(/\s+/)
    .filter(Boolean);

  if (words.length === 0) return "?";

  if (words.length === 1) return words[0][0].toUpperCase();

  return (words[0][0] + words[words.length - 1][0]).toUpperCase();
};

const formatGender = (value) => {
  const v = normalizeText(value);

  if (!v) return "";

  if (["male", "m", "nam"].includes(v)) return "Nam";
  if (["female", "f", "nu"].includes(v)) return "Nữ";
  if (["other", "khac"].includes(v)) return "Khác";

  return String(value);
};

// Ngày sinh: cắt thẳng từ chuỗi ISO để không bị lệch múi giờ
const formatBirthday = (value) => {
  if (!value) return "";

  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(value));

  if (match) {
    if (match[1] === "0001") return "";

    return `${match[3]}/${match[2]}/${match[1]}`;
  }

  return formatDate(value);
};

const formatDate = (value) => {
  if (!value) return "";

  const parsed = new Date(value);

  if (Number.isNaN(parsed.getTime())) return "";

  return parsed.toLocaleDateString("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
};

const formatClock = (date) =>
  date.toLocaleTimeString("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });

/* ---------- Lịch hẹn ---------- */

const APPOINTMENT_STATUS = {
  pending: { label: "Chờ xác nhận", icon: faFileCircleExclamation },
  confirmed: { label: "Đã xác nhận", icon: faFileCircleCheck },
};

const toUpcoming = (appointment) => {
  const scheduledAt = new Date(
    appointment?.scheduledAt || appointment?.ScheduledAt || ""
  );

  if (Number.isNaN(scheduledAt.getTime())) return null;

  const durationMin = Number(
    appointment?.durationMin ?? appointment?.DurationMin ?? 60
  );

  const end = new Date(scheduledAt.getTime() + (durationMin || 60) * 60000);

  const status = String(appointment?.status || appointment?.Status || "")
    .trim()
    .toLowerCase();

  const lawyerName = appointment?.lawyerName || appointment?.LawyerName || "";

  const description = String(
    appointment?.description || appointment?.Description || ""
  ).trim();

  return {
    id: getId(appointment),
    scheduledAt,
    status,
    day: String(scheduledAt.getDate()).padStart(2, "0"),
    month: `Tháng ${scheduledAt.getMonth() + 1}`,
    time: `${formatClock(scheduledAt)} - ${formatClock(end)}`,
    lawyerName,
    title:
      description ||
      (lawyerName ? `Tư vấn với ${lawyerName}` : "Buổi tư vấn pháp lý"),
  };
};

/* ---------- Yêu cầu tư vấn ---------- */

const REQUEST_STATUS_GROUPS = [
  {
    values: ["responded", "answered", "replied", "resolved", "completed", "done"],
    label: "Đã phản hồi",
    type: "success",
    icon: faFileCircleCheck,
  },
  {
    values: ["closed", "cancelled", "canceled", "rejected", "declined"],
    label: "Đã đóng",
    type: "closed",
    icon: faFileCircleXmark,
  },
  {
    values: ["in_progress", "processing", "assigned", "accepted"],
    label: "Đang xử lý",
    type: "warning",
    icon: faFileCircleExclamation,
  },
  {
    values: ["new", "pending", "open", "submitted"],
    label: "Chờ tiếp nhận",
    type: "warning",
    icon: faFileCircleExclamation,
  },
];

const getRequestStatus = (status) => {
  const value = String(status || "")
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, "_");

  const group = REQUEST_STATUS_GROUPS.find((item) =>
    item.values.includes(value)
  );

  return (
    group || {
      label: status || "Đang xử lý",
      type: "warning",
      icon: faFileCircleExclamation,
    }
  );
};

const toRequestItem = (request) => {
  const status = getRequestStatus(request?.status || request?.Status);

  const createdAt = request?.createdAt || request?.CreatedAt || "";

  return {
    id: getId(request),
    title: request?.title || request?.Title || "Yêu cầu tư vấn",
    createdAt,
    date: formatDate(createdAt),
    status: status.label,
    statusType: status.type,
    icon: status.icon,
  };
};

/* =========================================================
   ẢNH ĐẠI DIỆN
   Không có ảnh (hoặc ảnh lỗi) thì hiện chữ cái đầu của tên,
   không render <img src="">.
========================================================= */

const ProfileAvatar = ({ src, name }) => {
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setFailed(false);
  }, [src]);

  if (src && !failed) {
    return <img src={src} alt={name} onError={() => setFailed(true)} />;
  }

  return (
    <div
      role="img"
      aria-label={name}
      style={{
        width: "100%",
        height: "100%",
        minWidth: "120px",
        minHeight: "120px",
        borderRadius: "50%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "#e8edf4",
        color: "#51627d",
        fontSize: "40px",
        fontWeight: 700,
      }}
    >
      {getInitials(name)}
    </div>
  );
};

const emptyStyle = {
  padding: "24px 0",
  textAlign: "center",
  color: "#6b7280",
};

/* =========================================================
   COMPONENT
========================================================= */

const UserProfile = () => {
  const navigate = useNavigate();

  const user = useMemo(() => getCurrentUser(), []);

  const userId = getId(user);

  /* =======================================================
     STATE
  ======================================================= */

  const [remoteProfile, setRemoteProfile] = useState({});
  const [appointments, setAppointments] = useState([]);
  const [requests, setRequests] = useState([]);

  const [loading, setLoading] = useState(true);

  const [appointmentsFailed, setAppointmentsFailed] = useState(false);
  const [requestsFailed, setRequestsFailed] = useState(false);
  const [authExpired, setAuthExpired] = useState(false);

  /* =======================================================
     LOAD DATA
  ======================================================= */

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      setLoading(true);

      const [profileRes, appointmentsRes, requestsRes] =
        await Promise.allSettled([
          userId
            ? api.get(PROFILE_ENDPOINT(userId))
            : Promise.reject(new Error("Chưa đăng nhập")),
          api.get(APPOINTMENTS_ENDPOINT),
          api.get(REQUESTS_ENDPOINT),
        ]);

      if (cancelled) return;

      const results = [profileRes, appointmentsRes, requestsRes];

      setAuthExpired(
        results.some(
          (result) =>
            result.status === "rejected" && hasStatus(result.reason, 401)
        )
      );

      // --- Hồ sơ: lỗi thì dùng tạm dữ liệu từ getCurrentUser() ---
      if (profileRes.status === "fulfilled") {
        setRemoteProfile(normalizeProfile(profileRes.value));
      } else {
        console.warn(
          `Không tải được hồ sơ (${PROFILE_ENDPOINT(userId)}):`,
          profileRes.reason
        );
      }

      // --- Lịch hẹn ---
      if (appointmentsRes.status === "fulfilled") {
        const now = Date.now();

        const upcoming = toList(appointmentsRes.value)
          .map(toUpcoming)
          .filter(
            (item) =>
              item &&
              APPOINTMENT_STATUS[item.status] &&
              item.scheduledAt.getTime() >= now
          )
          .sort((a, b) => a.scheduledAt - b.scheduledAt);

        setAppointments(upcoming);
        setAppointmentsFailed(false);
      } else {
        console.error("Không tải được lịch hẹn:", appointmentsRes.reason);

        setAppointments([]);
        setAppointmentsFailed(true);
      }

      // --- Yêu cầu tư vấn ---
      if (requestsRes.status === "fulfilled") {
        const ownId = String(userId || "");

        // Phòng khi backend trả cả yêu cầu của người khác
        const own = toList(requestsRes.value).filter((request) => {
          const clientId = request?.clientId || request?.ClientId;

          return !clientId || !ownId || String(clientId) === ownId;
        });

        const items = own
          .map(toRequestItem)
          .sort(
            (a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0)
          );

        setRequests(items);
        setRequestsFailed(false);
      } else {
        console.error("Không tải được yêu cầu tư vấn:", requestsRes.reason);

        setRequests([]);
        setRequestsFailed(true);
      }

      setLoading(false);
    };

    load();

    return () => {
      cancelled = true;
    };
  }, [userId]);

  /* =======================================================
     HỒ SƠ HIỂN THỊ
  ======================================================= */

  const profile = useMemo(
    () => mergeProfile(normalizeProfile(user), remoteProfile),
    [user, remoteProfile]
  );

  const displayName = profile.fullName || "Người dùng";

  const avatarSrc = toAvatarUrl(profile.avatarUrl);

  const EMPTY = "Chưa cập nhật";

  const upcomingList = appointments.slice(0, UPCOMING_LIMIT);

  const requestList = requests.slice(0, REQUEST_LIMIT);

  /* =======================================================
     HANDLERS
  ======================================================= */

  const handleChangeAvatar = () => {
    console.log("Thay đổi ảnh đại diện");
  };

  // Nút "Chỉnh sửa hồ sơ" ở phần hero (đầu trang)
  const handleEditProfile = () => {
    navigate("/profile/edit");
  };

  // Nút "Chỉnh sửa" ở khối "Thông tin cá nhân"
  const handleEditPersonalInfo = () => {
    navigate("/profile/edit");
  };

  const handleConsultationDetail = (item) => {
    navigate("/my-consultations", { state: { appointmentId: item.id } });
  };

  const handleRequestDetail = (request) => {
    navigate("/consultation-requests", { state: { requestId: request.id } });
  };

  return (
    <div className="user-profile">
      {/* =================================================
          MAIN CONTENT
      ================================================= */}

      <main className="profile-main">
        {authExpired && (
          <div
            style={{
              margin: "0 0 15px",
              padding: "12px 16px",
              borderRadius: "8px",
              background: "#fff1f0",
              color: "#cf1322",
            }}
          >
            {AUTH_MESSAGE}
          </div>
        )}

        {/* =================================================
            PROFILE HERO
        ================================================= */}

        <section className="profile-hero">
          {/* Background */}

          <img
            src={profileBackground}
            alt=""
            className="profile-hero__background"
          />

          {/* Overlay */}

          <div className="profile-hero__overlay"></div>

          {/* =================================================
              AVATAR
          ================================================= */}

          <div className="profile-avatar">
            <ProfileAvatar src={avatarSrc} name={displayName} />

            <button
              type="button"
              className="profile-avatar__camera"
              aria-label="Thay đổi ảnh đại diện"
              onClick={handleChangeAvatar}
            >
              <FontAwesomeIcon icon={faCamera} />
            </button>
          </div>

          {/* =================================================
              USER INFORMATION
          ================================================= */}

          <div className="profile-hero__info">
            {/* Name */}

            <div className="profile-hero__name-row">
              <h1>{displayName}</h1>

              <span className="profile-role">{getRoleLabel(profile.role)}</span>
            </div>

            {/* Description */}

            {profile.bio && (
              <p className="profile-hero__description">{profile.bio}</p>
            )}

            {/* Contact */}

            <div className="profile-contact-list">
              {profile.email && (
                <div>
                  <FontAwesomeIcon icon={faEnvelope} />

                  <span>{profile.email}</span>
                </div>
              )}

              {profile.phone && (
                <div>
                  <FontAwesomeIcon icon={faPhone} />

                  <span>{profile.phone}</span>
                </div>
              )}

              {profile.address && (
                <div>
                  <FontAwesomeIcon icon={faLocationDot} />

                  <span>{profile.address}</span>
                </div>
              )}
            </div>
          </div>

          {/* =================================================
              EDIT PROFILE
          ================================================= */}

          <button
            type="button"
            className="profile-edit-button"
            onClick={handleEditProfile}
          >
            <FontAwesomeIcon icon={faPenToSquare} />

            <span>Chỉnh sửa hồ sơ</span>
          </button>
        </section>

        {/* =================================================
            CONTENT
        ================================================= */}

        <section className="profile-content">
          {/* =================================================
              LEFT COLUMN
          ================================================= */}

          <div className="profile-card profile-information">
            {/* CARD HEADER */}

            <div className="profile-card__header">
              <h2>
                <FontAwesomeIcon icon={faUser} />

                <span>Thông tin cá nhân</span>
              </h2>

              <button
                type="button"
                className="profile-card__edit"
                onClick={handleEditPersonalInfo}
              >
                <FontAwesomeIcon icon={faPenToSquare} />

                <span>Chỉnh sửa</span>
              </button>
            </div>

            {/* PERSONAL INFORMATION */}

            <div className="personal-info-list">
              {/* Họ tên */}

              <div className="personal-info-row">
                <div className="personal-info-label">
                  <FontAwesomeIcon icon={faUser} />

                  <span>Họ và tên</span>
                </div>

                <strong>{profile.fullName || EMPTY}</strong>
              </div>

              {/* Email */}

              <div className="personal-info-row">
                <div className="personal-info-label">
                  <FontAwesomeIcon icon={faEnvelope} />

                  <span>Email</span>
                </div>

                <strong>{profile.email || EMPTY}</strong>
              </div>

              {/* Phone */}

              <div className="personal-info-row">
                <div className="personal-info-label">
                  <FontAwesomeIcon icon={faPhone} />

                  <span>Số điện thoại</span>
                </div>

                <strong>{profile.phone || EMPTY}</strong>
              </div>

              {/* Birthday */}

              <div className="personal-info-row">
                <div className="personal-info-label">
                  <FontAwesomeIcon icon={faCalendarDays} />

                  <span>Ngày sinh</span>
                </div>

                <strong>{formatBirthday(profile.birthday) || EMPTY}</strong>
              </div>

              {/* Gender */}

              <div className="personal-info-row">
                <div className="personal-info-label">
                  <FontAwesomeIcon icon={faVenusMars} />

                  <span>Giới tính</span>
                </div>

                <strong>{formatGender(profile.gender) || EMPTY}</strong>
              </div>

              {/* Address */}

              <div className="personal-info-row">
                <div className="personal-info-label">
                  <FontAwesomeIcon icon={faLocationDot} />

                  <span>Địa chỉ</span>
                </div>

                <strong>{profile.address || EMPTY}</strong>
              </div>

              {/* Job */}

              {/* <div className="personal-info-row">
                <div className="personal-info-label">
                  <FontAwesomeIcon icon={faBriefcase} />

                  <span>Nghề nghiệp</span>
                </div>

                <strong>{profile.occupation || EMPTY}</strong>
              </div> */}
            </div>

            {/* SECURITY */}

            <div className="profile-security">
              <div className="profile-security__icon">
                <FontAwesomeIcon icon={faShieldHalved} />
              </div>

              <div>
                <strong>Bảo mật thông tin</strong>

                <p>
                  Thông tin cá nhân của bạn luôn được bảo mật tuyệt đối theo
                  chính sách của Themis.
                </p>
              </div>
            </div>
          </div>

          {/* =================================================
              RIGHT COLUMN
          ================================================= */}

          <div className="profile-right-column">
            {/* =================================================
                UPCOMING CONSULTATIONS
            ================================================= */}

            <div className="profile-card-consultation-card">
              {/* Header */}

              <div className="profile-card__header">
                <h2>
                  <FontAwesomeIcon icon={faCalendarDays} />

                  <span>Lịch tư vấn sắp tới</span>
                </h2>

                <NavLink to="/my-consultations" className="profile-view-all">
                  <span>Xem tất cả</span>

                  <FontAwesomeIcon icon={faChevronRight} />
                </NavLink>
              </div>

              {/* Consultation list */}

              <div className="consultation-list">
                {loading ? (
                  <div style={emptyStyle}>Đang tải lịch tư vấn...</div>
                ) : appointmentsFailed ? (
                  <div style={emptyStyle}>Không thể tải lịch tư vấn.</div>
                ) : upcomingList.length === 0 ? (
                  <div style={emptyStyle}>
                    Bạn chưa có lịch tư vấn nào sắp tới.
                  </div>
                ) : (
                  upcomingList.map((item) => (
                    <div
                      className="consultation-item"
                      key={item.id || item.scheduledAt.getTime()}
                    >
                      {/* Date */}

                      <div className="consultation-date">
                        <strong>{item.day}</strong>

                        <span>{item.month}</span>
                      </div>

                      {/* Info */}

                      <div className="consultation-info">
                        <h3>{item.title}</h3>

                        <div className="consultation-meta">
                          {/* Time */}

                          <span>
                            <FontAwesomeIcon icon={faClock} />

                            {item.time}
                          </span>

                          {/* Lawyer */}

                          {item.lawyerName && (
                            <span>
                              <FontAwesomeIcon icon={faUser} />

                              {item.lawyerName}
                            </span>
                          )}

                          {/* Status */}

                          <span>
                            <FontAwesomeIcon
                              icon={APPOINTMENT_STATUS[item.status].icon}
                            />

                            {APPOINTMENT_STATUS[item.status].label}
                          </span>
                        </div>
                      </div>

                      {/* Detail */}

                      <button
                        type="button"
                        className="consultation-detail"
                        onClick={() => handleConsultationDetail(item)}
                      >
                        Xem chi tiết
                      </button>
                    </div>
                  ))
                )}
              </div>
            </div>

            {/* =================================================
                CONSULTATION REQUESTS
            ================================================= */}

            <div className="profile-card request-card">
              {/* Header */}

              <div className="profile-card__header">
                <h2>
                  <FontAwesomeIcon icon={faFileLines} />

                  <span>Yêu cầu tư vấn của tôi</span>
                </h2>

                <NavLink to="/consultation-requests" className="profile-view-all">
                  <span>Xem tất cả</span>

                  <FontAwesomeIcon icon={faChevronRight} />
                </NavLink>
              </div>

              {/* Request list */}

              <div className="request-list">
                {loading ? (
                  <div style={emptyStyle}>Đang tải yêu cầu tư vấn...</div>
                ) : requestsFailed ? (
                  <div style={emptyStyle}>Không thể tải yêu cầu tư vấn.</div>
                ) : requestList.length === 0 ? (
                  <div style={emptyStyle}>Bạn chưa có yêu cầu tư vấn nào.</div>
                ) : (
                  requestList.map((request, index) => (
                    <div className="request-item" key={request.id || index}>
                      {/* Icon */}

                      <div className="request-icon">
                        <FontAwesomeIcon icon={request.icon} />
                      </div>

                      {/* Information */}

                      <div className="request-info">
                        <h3>{request.title}</h3>

                        <span>{request.date}</span>
                      </div>

                      {/* Status */}

                      <span
                        className={
                          `request-status ` +
                          `request-status--${request.statusType}`
                        }
                      >
                        {request.status}
                      </span>

                      {/* Detail */}

                      <button
                        type="button"
                        className="request-detail"
                        onClick={() => handleRequestDetail(request)}
                      >
                        Xem chi tiết
                      </button>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        </section>
      </main>
    </div>
  );
};

export default UserProfile;
