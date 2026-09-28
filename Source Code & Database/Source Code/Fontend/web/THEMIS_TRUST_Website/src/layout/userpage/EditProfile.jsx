import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faArrowLeft,
  faUser,
  faEnvelope,
  faPhone,
  faCalendarDays,
  faVenusMars,
  faLocationDot,
  faCamera,
  faFloppyDisk,
  faShieldHalved,
} from "@fortawesome/free-solid-svg-icons";

import { api, getCurrentUser } from "../../api/api";

/*
=========================================================
GIỚI TÍNH

Database SQL Server hiện tại chỉ cho phép:

Nam
Nữ
Khác
NULL

Vì vậy value phải dùng đúng các giá trị này.
KHÔNG dùng male / female / other.
=========================================================
*/

const GENDER_OPTIONS = [
  {
    value: "",
    label: "-- Chưa chọn --",
  },
  {
    value: "Nam",
    label: "Nam",
  },
  {
    value: "Nữ",
    label: "Nữ",
  },
  {
    value: "Khác",
    label: "Khác",
  },
];

/*
=========================================================
LẤY FULL URL CHO AVATAR
=========================================================
*/

const getFullApiUrl = (url) => {
  if (!url) {
    return "";
  }

  if (
    url.startsWith("http://") ||
    url.startsWith("https://")
  ) {
    return url;
  }

  const baseUrl =
    import.meta.env.VITE_API_URL ||
    "https://localhost:5001/api";

  const serverUrl = baseUrl.replace(/\/api\/?$/, "");

  return `${serverUrl}${url.startsWith("/") ? "" : "/"}${url}`;
};

/*
=========================================================
CHUẨN HÓA GIỚI TÍNH

Nếu dữ liệu cũ đang là:
male
female
other

thì chuyển thành:
Nam
Nữ
Khác
=========================================================
*/

const normalizeGender = (gender) => {
  if (gender === undefined || gender === null) {
    return "";
  }

  const value = String(gender).trim();

  switch (value.toLowerCase()) {
    case "male":
    case "nam":
      return "Nam";

    case "female":
    case "nữ":
    case "nu":
      return "Nữ";

    case "other":
    case "khác":
    case "khac":
      return "Khác";

    default:
      return "";
  }
};

/*
=========================================================
COMPONENT
=========================================================
*/

const EditProfile = () => {
  const navigate = useNavigate();

  const fileInputRef = useRef(null);

  const user = useMemo(() => getCurrentUser(), []);

  const userId =
    user?.id ||
    user?.Id ||
    user?.userId ||
    user?.UserId ||
    null;

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploadingAvatar, setUploadingAvatar] = useState(false);

  const [error, setError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  const [avatarUrl, setAvatarUrl] = useState("");
  const [avatarPreview, setAvatarPreview] = useState("");

  const [form, setForm] = useState({
    fullName: "",
    email: "",
    phone: "",
    birthDate: "",
    gender: "",
    address: "",
  });

  const [fieldErrors, setFieldErrors] = useState({});

  /*
  ========================================================
  PICK VALUE
  ========================================================
  */

  const pick = (obj, keys) => {
    for (const key of keys) {
      const value = obj?.[key];

      if (
        value !== undefined &&
        value !== null &&
        String(value).trim() !== ""
      ) {
        return value;
      }
    }

    return "";
  };

  /*
  ========================================================
  LOAD PROFILE
  ========================================================
  */

  const loadProfile = async () => {
    if (!userId) {
      setError(
        "Không xác định được người dùng. Vui lòng đăng nhập lại."
      );

      setLoading(false);

      return;
    }

    try {
      setLoading(true);
      setError("");
      setSuccessMsg("");

      const raw = await api.get(`/users/${userId}`);

      const base =
        raw?.data && typeof raw.data === "object"
          ? raw.data
          : raw;

      /*
      Backend hiện tại có thể trả:

      {
        id,
        fullName,
        email,
        gender,
        ...
        dateOfBirth,
        address
      }

      hoặc có thể có client/user lồng nhau.

      Ta gộp lại để hỗ trợ cả hai.
      */

      const data = {
        ...(base?.client || base?.Client || {}),
        ...(base?.user || base?.User || {}),
        ...(base || {}),
      };

      /*
      ============================
      NGÀY SINH
      ============================
      */

      const rawBirthDate = pick(data, [
        "dateOfBirth",
        "DateOfBirth",
        "birthDate",
        "BirthDate",
        "dob",
        "Dob",
      ]);

      /*
      ============================
      GIỚI TÍNH
      ============================
      */

      const rawGender = pick(data, [
        "gender",
        "Gender",
        "sex",
        "Sex",
      ]);

      const normalizedGender =
        normalizeGender(rawGender);

      /*
      ============================
      SET FORM
      ============================
      */

      setForm({
        fullName: pick(data, [
          "fullName",
          "FullName",
          "name",
          "Name",
        ]),

        email: pick(data, [
          "email",
          "Email",
        ]),

        phone: pick(data, [
          "phone",
          "Phone",
          "phoneNumber",
          "PhoneNumber",
        ]),

        birthDate: rawBirthDate
          ? String(rawBirthDate).slice(0, 10)
          : "",

        gender: normalizedGender,

        address: pick(data, [
          "address",
          "Address",
        ]),
      });

      /*
      ============================
      AVATAR
      ============================
      */

      setAvatarUrl(
        pick(data, [
          "avatarUrl",
          "AvatarUrl",
          "avatar",
          "Avatar",
        ])
      );
    } catch (err) {
      console.error(
        "Lỗi tải thông tin cá nhân:",
        err
      );

      setError(
        err?.message ||
          "Không thể tải thông tin cá nhân."
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadProfile();
  }, [userId]);

  /*
  ========================================================
  HANDLE CHANGE
  ========================================================
  */

  const handleChange = (field) => (e) => {
    const value = e.target.value;

    setForm((prev) => ({
      ...prev,
      [field]: value,
    }));

    setFieldErrors((prev) => ({
      ...prev,
      [field]: "",
    }));

    setError("");
  };

  /*
  ========================================================
  VALIDATE
  ========================================================
  */

  const validate = () => {
    const errors = {};

    if (!form.fullName.trim()) {
      errors.fullName =
        "Vui lòng nhập họ và tên.";
    }

    if (
      form.phone &&
      !/^[0-9]{9,11}$/.test(
        form.phone.trim()
      )
    ) {
      errors.phone =
        "Số điện thoại không hợp lệ.";
    }

    /*
    Chặn luôn giá trị giới tính không hợp lệ
    trước khi gửi backend.
    */

    const allowedGender = [
      "",
      "Nam",
      "Nữ",
      "Khác",
    ];

    if (
      !allowedGender.includes(form.gender)
    ) {
      errors.gender =
        "Giới tính không hợp lệ.";
    }

    setFieldErrors(errors);

    return Object.keys(errors).length === 0;
  };

  /*
  ========================================================
  AVATAR
  ========================================================
  */

  const handleAvatarClick = () => {
    fileInputRef.current?.click();
  };

  const handleAvatarChange = async (e) => {
    const file = e.target.files?.[0];

    if (!file) {
      return;
    }

    if (!file.type.startsWith("image/")) {
      alert(
        "Vui lòng chọn một tệp hình ảnh."
      );

      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      alert(
        "Kích thước ảnh tối đa 5MB."
      );

      return;
    }

    const previewUrl =
      URL.createObjectURL(file);

    setAvatarPreview(previewUrl);

    try {
      setUploadingAvatar(true);
      setError("");
      setSuccessMsg("");

      const formData = new FormData();

      formData.append("file", file);

      const result = await api.post(
        `/users/${userId}/avatar`,
        formData
      );

      const newAvatarUrl =
        result?.avatarUrl ||
        result?.data?.avatarUrl ||
        result?.avatar ||
        result?.data?.avatar ||
        "";

      setAvatarUrl(newAvatarUrl);

      setSuccessMsg(
        "Đã cập nhật ảnh đại diện."
      );
    } catch (err) {
      console.error(
        "Lỗi upload ảnh đại diện:",
        err
      );

      alert(
        err?.message ||
          "Không thể tải ảnh đại diện lên."
      );

      setAvatarPreview("");
    } finally {
      setUploadingAvatar(false);

      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    }
  };

  /*
  ========================================================
  SAVE PROFILE
  ========================================================
  */

  const handleSave = async () => {
    setSuccessMsg("");
    setError("");

    if (!validate()) {
      return;
    }

    try {
      setSaving(true);

      /*
      ======================================================
      CHUẨN HÓA GENDER TRƯỚC KHI GỬI

      "" -> null
      Nam -> Nam
      Nữ -> Nữ
      Khác -> Khác
      ======================================================
      */

      const normalizedGender =
        normalizeGender(form.gender);

      /*
      ======================================================
      PAYLOAD

      ĐÚNG VỚI:

      UserProfileUpdateRequest

      FullName
      Email
      Phone
      Gender
      DateOfBirth
      Address
      ======================================================
      */

      const payload = {
        fullName: form.fullName.trim(),

        email: form.email.trim(),

        phone: form.phone.trim()
          ? form.phone.trim()
          : null,

        gender: normalizedGender
          ? normalizedGender
          : null,

        dateOfBirth: form.birthDate
          ? form.birthDate
          : null,

        address: form.address.trim()
          ? form.address.trim()
          : null,
      };

      console.log(
        "PROFILE UPDATE PAYLOAD:",
        payload
      );

      await api.patch(
        `/users/${userId}/profile`,
        payload
      );

      /*
      Cập nhật lại form sau khi lưu
      */

      setForm((prev) => ({
        ...prev,
        gender: normalizedGender,
      }));

      setSuccessMsg(
        "Đã lưu thay đổi hồ sơ thành công."
      );
    } catch (err) {
      console.error(
        "Lỗi cập nhật hồ sơ:",
        err
      );

      setError(
        err?.message ||
          "Không thể lưu thay đổi."
      );
    } finally {
      setSaving(false);
    }
  };

  /*
  ========================================================
  CANCEL
  ========================================================
  */

  const handleCancel = () => {
    navigate(-1);
  };

  /*
  ========================================================
  AVATAR DISPLAY
  ========================================================
  */

  const displayAvatar =
    avatarPreview ||
    getFullApiUrl(avatarUrl);

  const initials =
    (form.fullName || "?")
      .trim()
      .charAt(0)
      .toUpperCase();

  /*
  ========================================================
  LOADING
  ========================================================
  */

  if (loading) {
    return (
      <div style={styles.page}>
        <div style={styles.loadingBox}>
          Đang tải thông tin...
        </div>
      </div>
    );
  }

  /*
  ========================================================
  RENDER
  ========================================================
  */

  return (
    <div style={styles.page}>
      <button
        type="button"
        style={styles.backButton}
        onClick={handleCancel}
      >
        <FontAwesomeIcon
          icon={faArrowLeft}
        />

        <span>Quay lại</span>
      </button>

      <div style={styles.card}>
        <h1 style={styles.title}>
          Chỉnh sửa hồ sơ
        </h1>

        <p style={styles.subtitle}>
          Cập nhật thông tin cá nhân của bạn.
          Thông tin này sẽ được dùng khi bạn
          gửi yêu cầu tư vấn hoặc đặt lịch với
          luật sư.
        </p>

        {error && (
          <div style={styles.errorBanner}>
            {error}
          </div>
        )}

        {successMsg && (
          <div style={styles.successBanner}>
            {successMsg}
          </div>
        )}

        {/* =========================================
            AVATAR
        ========================================= */}

        <div style={styles.avatarSection}>
          <div style={styles.avatarWrapper}>
            {displayAvatar ? (
              <img
                src={displayAvatar}
                alt="Ảnh đại diện"
                style={styles.avatarImg}
                onError={(e) => {
                  e.currentTarget.style.display =
                    "none";
                }}
              />
            ) : (
              <div
                style={
                  styles.avatarFallback
                }
              >
                {initials}
              </div>
            )}

            <button
              type="button"
              style={
                styles.avatarCameraButton
              }
              onClick={
                handleAvatarClick
              }
              disabled={uploadingAvatar}
              title="Đổi ảnh đại diện"
            >
              <FontAwesomeIcon
                icon={faCamera}
              />
            </button>

            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              style={{
                display: "none",
              }}
              onChange={
                handleAvatarChange
              }
            />
          </div>

          <div>
            <div
              style={styles.avatarName}
            >
              {form.fullName ||
                "Khách hàng"}
            </div>

            <div
              style={styles.avatarHint}
            >
              {uploadingAvatar
                ? "Đang tải ảnh lên..."
                : "Nhấn vào biểu tượng máy ảnh để đổi ảnh đại diện (tối đa 5MB)."}
            </div>
          </div>
        </div>

        {/* =========================================
            FORM
        ========================================= */}

        <div style={styles.grid}>
          <Field
            icon={faUser}
            label="Họ và tên"
            required
            value={form.fullName}
            onChange={handleChange(
              "fullName"
            )}
            error={
              fieldErrors.fullName
            }
            placeholder="Nhập họ và tên"
          />

          <Field
            icon={faEnvelope}
            label="Email"
            value={form.email}
            disabled
            hint="Email dùng để đăng nhập, không thể thay đổi tại đây."
          />

          <Field
            icon={faPhone}
            label="Số điện thoại"
            value={form.phone}
            onChange={handleChange(
              "phone"
            )}
            error={fieldErrors.phone}
            placeholder="Nhập số điện thoại"
          />

          <Field
            icon={faCalendarDays}
            label="Ngày sinh"
            type="date"
            value={form.birthDate}
            onChange={handleChange(
              "birthDate"
            )}
          />

          {/* =====================================
              GENDER
          ===================================== */}

          <div style={styles.fieldBox}>
            <label
              style={styles.fieldLabel}
            >
              <FontAwesomeIcon
                icon={faVenusMars}
                style={
                  styles.fieldIcon
                }
              />

              Giới tính
            </label>

            <select
              value={form.gender}
              onChange={handleChange(
                "gender"
              )}
              style={{
                ...styles.input,
                ...(fieldErrors.gender
                  ? styles.inputError
                  : {}),
              }}
            >
              {GENDER_OPTIONS.map(
                (option) => (
                  <option
                    key={option.value}
                    value={
                      option.value
                    }
                  >
                    {option.label}
                  </option>
                )
              )}
            </select>

            {fieldErrors.gender && (
              <div
                style={
                  styles.fieldError
                }
              >
                {fieldErrors.gender}
              </div>
            )}
          </div>

          {/* =====================================
              ADDRESS
          ===================================== */}

          <div
            style={{
              ...styles.fieldBox,
              gridColumn: "1 / -1",
            }}
          >
            <label
              style={styles.fieldLabel}
            >
              <FontAwesomeIcon
                icon={faLocationDot}
                style={
                  styles.fieldIcon
                }
              />

              Địa chỉ
            </label>

            <input
              type="text"
              value={form.address}
              onChange={handleChange(
                "address"
              )}
              style={styles.input}
              placeholder="Nhập địa chỉ"
            />
          </div>
        </div>

        {/* =========================================
            SECURITY
        ========================================= */}

        <div style={styles.securityBox}>
          <FontAwesomeIcon
            icon={faShieldHalved}
            style={
              styles.securityIcon
            }
          />

          <div>
            <strong>
              Bảo mật thông tin
            </strong>

            <div
              style={{
                color: "#666",
                marginTop: "4px",
              }}
            >
              Thông tin cá nhân của bạn luôn
              được bảo mật tuyệt đối theo
              chính sách của Themis.
            </div>
          </div>
        </div>

        {/* =========================================
            ACTIONS
        ========================================= */}

        <div style={styles.actions}>
          <button
            type="button"
            onClick={handleCancel}
            style={
              styles.cancelButton
            }
            disabled={saving}
          >
            Hủy
          </button>

          <button
            type="button"
            onClick={handleSave}
            style={styles.saveButton}
            disabled={saving}
          >
            <FontAwesomeIcon
              icon={faFloppyDisk}
            />

            <span>
              {saving
                ? "Đang lưu..."
                : "Lưu thay đổi"}
            </span>
          </button>
        </div>
      </div>
    </div>
  );
};

/*
=========================================================
FIELD COMPONENT
=========================================================
*/

const Field = ({
  icon,
  label,
  value,
  onChange,
  placeholder,
  type = "text",
  disabled = false,
  required = false,
  error = "",
  hint = "",
}) => (
  <div style={styles.fieldBox}>
    <label style={styles.fieldLabel}>
      <FontAwesomeIcon
        icon={icon}
        style={styles.fieldIcon}
      />

      {label}

      {required && (
        <span
          style={{
            color: "#e11d48",
          }}
        >
          {" "}
          *
        </span>
      )}
    </label>

    <input
      type={type}
      value={value}
      onChange={onChange}
      disabled={disabled}
      placeholder={placeholder}
      style={{
        ...styles.input,
        ...(disabled
          ? styles.inputDisabled
          : {}),
        ...(error
          ? styles.inputError
          : {}),
      }}
    />

    {error && (
      <div style={styles.fieldError}>
        {error}
      </div>
    )}

    {hint && !error && (
      <div style={styles.fieldHint}>
        {hint}
      </div>
    )}
  </div>
);

/*
=========================================================
STYLES
=========================================================
*/

const styles = {
  page: {
    maxWidth: "900px",
    margin: "0 auto",
    padding: "24px 16px 60px",
    fontFamily: "inherit",
  },

  backButton: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    background: "none",
    border: "none",
    color: "#1e3a8a",
    fontWeight: 600,
    cursor: "pointer",
    marginBottom: "16px",
    padding: "8px 0",
  },

  card: {
    background: "#fff",
    borderRadius: "14px",
    boxShadow:
      "0 2px 12px rgba(0,0,0,0.06)",
    padding: "28px",
  },

  title: {
    margin: 0,
    fontSize: "22px",
    color: "#111827",
  },

  subtitle: {
    color: "#6b7280",
    marginTop: "6px",
    marginBottom: "24px",
    fontSize: "14px",
  },

  errorBanner: {
    background: "#fef2f2",
    border: "1px solid #fecaca",
    color: "#b91c1c",
    padding: "10px 14px",
    borderRadius: "8px",
    marginBottom: "16px",
    fontSize: "14px",
  },

  successBanner: {
    background: "#f0fdf4",
    border: "1px solid #bbf7d0",
    color: "#15803d",
    padding: "10px 14px",
    borderRadius: "8px",
    marginBottom: "16px",
    fontSize: "14px",
  },

  avatarSection: {
    display: "flex",
    alignItems: "center",
    gap: "18px",
    paddingBottom: "24px",
    marginBottom: "24px",
    borderBottom:
      "1px solid #f0f0f0",
  },

  avatarWrapper: {
    position: "relative",
    width: "84px",
    height: "84px",
    flexShrink: 0,
  },

  avatarImg: {
    width: "84px",
    height: "84px",
    borderRadius: "50%",
    objectFit: "cover",
    border: "2px solid #e5e7eb",
  },

  avatarFallback: {
    width: "84px",
    height: "84px",
    borderRadius: "50%",
    background: "#dbeafe",
    color: "#1e3a8a",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: "28px",
    fontWeight: 700,
  },

  avatarCameraButton: {
    position: "absolute",
    bottom: "-2px",
    right: "-2px",
    width: "30px",
    height: "30px",
    borderRadius: "50%",
    background: "#1e3a8a",
    color: "#fff",
    border: "2px solid #fff",
    cursor: "pointer",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: "12px",
  },

  avatarName: {
    fontWeight: 700,
    fontSize: "16px",
    color: "#111827",
  },

  avatarHint: {
    fontSize: "13px",
    color: "#6b7280",
    marginTop: "4px",
    maxWidth: "360px",
  },

  grid: {
    display: "grid",
    gridTemplateColumns:
      "1fr 1fr",
    gap: "18px",
  },

  fieldBox: {
    display: "flex",
    flexDirection: "column",
    gap: "6px",
  },

  fieldLabel: {
    fontSize: "13px",
    fontWeight: 600,
    color: "#374151",
    display: "flex",
    alignItems: "center",
    gap: "6px",
  },

  fieldIcon: {
    color: "#1e3a8a",
    fontSize: "12px",
  },

  input: {
    padding: "10px 12px",
    borderRadius: "8px",
    border:
      "1px solid #d1d5db",
    fontSize: "14px",
    outline: "none",
    background: "#fff",
  },

  inputDisabled: {
    background: "#f3f4f6",
    color: "#9ca3af",
    cursor: "not-allowed",
  },

  inputError: {
    borderColor: "#f87171",
  },

  fieldError: {
    color: "#dc2626",
    fontSize: "12px",
  },

  fieldHint: {
    color: "#9ca3af",
    fontSize: "12px",
  },

  securityBox: {
    display: "flex",
    gap: "12px",
    background: "#fffbeb",
    border:
      "1px solid #fde68a",
    borderRadius: "10px",
    padding: "16px",
    marginTop: "28px",
    fontSize: "14px",
  },

  securityIcon: {
    color: "#d97706",
    fontSize: "20px",
    marginTop: "2px",
  },

  actions: {
    display: "flex",
    justifyContent: "flex-end",
    gap: "12px",
    marginTop: "28px",
  },

  cancelButton: {
    padding: "10px 20px",
    borderRadius: "8px",
    border:
      "1px solid #d1d5db",
    background: "#fff",
    color: "#374151",
    cursor: "pointer",
    fontWeight: 600,
  },

  saveButton: {
    padding: "10px 22px",
    borderRadius: "8px",
    border: "none",
    background: "#1e3a8a",
    color: "#fff",
    cursor: "pointer",
    fontWeight: 600,
    display: "flex",
    alignItems: "center",
    gap: "8px",
  },

  loadingBox: {
    padding: "60px",
    textAlign: "center",
    color: "#6b7280",
  },
};

export default EditProfile;