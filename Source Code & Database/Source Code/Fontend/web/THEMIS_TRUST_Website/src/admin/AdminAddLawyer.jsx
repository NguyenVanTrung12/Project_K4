import { useEffect, useRef, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import {
  FaArrowLeft,
  FaUserTie,
  FaUser,
  FaEnvelope,
  FaPhone,
  FaBirthdayCake,
  FaMapMarkerAlt,
  FaGraduationCap,
  FaBriefcase,
  FaIdCard,
  FaClock,
  FaTimes,
  FaCamera,
  FaChevronDown,
  FaCloudUploadAlt,
  FaFilePdf,
  FaTrash,
  FaCheckCircle,
  FaInfoCircle,
  FaShieldAlt,
  FaSave,
} from "react-icons/fa";

import { api } from "../api/api";
import "../assets/css/admin/AdminAddLawyer.css";

// API chạy ở cổng 5001 (khớp với request trong console).
// Nên đặt VITE_API_URL trong file .env rồi restart `npm run dev`.
const API_ORIGIN = (
  import.meta.env.VITE_API_URL || "https://localhost:5001/api"
).replace(/\/api\/?$/, "");

const emptyForm = {
  fullName: "",
  email: "",
  phone: "",
  gender: "Nam",
  birthday: "",
  address: "",
  education: "",
  title: "",
  barLicenseNo: "",
  yearsExp: "",
  bio: "",
  status: "Hoạt động",
  avatarFile: null,
};

// =========================================================
// HELPER
// =========================================================

const toAvatarUrl = (url) => {
  if (!url) return "";

  const value = String(url).trim();

  if (
    value.startsWith("http://") ||
    value.startsWith("https://") ||
    value.startsWith("data:") ||
    value.startsWith("blob:")
  ) {
    return value;
  }

  if (value.startsWith("/")) {
    return `${API_ORIGIN}${value}`;
  }

  return `${API_ORIGIN}/${value}`;
};

const addCacheBust = (url) => {
  if (!url) return "";

  const separator = url.includes("?") ? "&" : "?";
  return `${url}${separator}v=${Date.now()}`;
};

// Lấy thông báo lỗi từ response của ASP.NET Core
const getErrorMessage = (err, fallback) => {
  const data = err?.response?.data;

  let message =
    data?.message ||
    data?.title ||
    data?.error ||
    err?.message ||
    fallback;

  if (data?.errors) {
    const validationMessages = Object.values(data.errors)
      .flat()
      .filter(Boolean);

    if (validationMessages.length > 0) {
      message = validationMessages.join("\n");
    }
  }

  return message;
};

// Lấy ra mảng từ nhiều dạng response khác nhau:
//  - [...]
//  - { $values: [...] }   (ReferenceHandler.Preserve)
//  - { items: [...] } / { data: [...] } / { practiceAreas: [...] }
//  - { data: { $values: [...] } }
const extractList = (raw) => {
  if (Array.isArray(raw)) return raw;
  if (!raw || typeof raw !== "object") return [];

  const candidates = [
    raw.$values,
    raw.items,
    raw.data,
    raw.practiceAreas,
    raw.PracticeAreas,
    raw.result,
  ];

  for (const candidate of candidates) {
    if (Array.isArray(candidate)) return candidate;

    if (candidate && typeof candidate === "object") {
      const nested = extractList(candidate);
      if (nested.length > 0) return nested;
    }
  }

  return [];
};

// Chuẩn hóa 1 lĩnh vực về dạng { id, name }
// (chấp nhận cả id/name và Id/Name)
const normalizePracticeArea = (item) => ({
  id: Number(item?.id ?? item?.Id),
  name: item?.name ?? item?.Name ?? "",
});

function AdminAddLawyer() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const lawyerId = searchParams.get("id");
  const isEdit = Boolean(lawyerId);

  const avatarInputRef = useRef(null);
  const documentInputRef = useRef(null);

  const [formData, setFormData] = useState(emptyForm);

  const [practiceAreas, setPracticeAreas] = useState([]);
  const [practiceAreasLoading, setPracticeAreasLoading] = useState(false);
  const [practiceAreaError, setPracticeAreaError] = useState("");
  const [selectedPracticeAreas, setSelectedPracticeAreas] = useState([]);

  const [avatarPreview, setAvatarPreview] = useState("");

  const [documents, setDocuments] = useState([]);

  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(false);

  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  // =========================================================
  // LOAD PRACTICE AREAS
  // =========================================================

  useEffect(() => {
    loadPracticeAreas();
  }, []);

  // =========================================================
  // LOAD LAWYER WHEN EDIT
  // =========================================================

  useEffect(() => {
    if (isEdit && lawyerId) {
      loadLawyer(lawyerId);
    } else {
      setFormData(emptyForm);
      setAvatarPreview("");
      setSelectedPracticeAreas([]);
      setDocuments([]);
    }
  }, [isEdit, lawyerId]);

  // Giải phóng blob URL khi đổi ảnh hoặc rời trang
  useEffect(() => {
    return () => {
      if (avatarPreview?.startsWith("blob:")) {
        URL.revokeObjectURL(avatarPreview);
      }
    };
  }, [avatarPreview]);

  // =========================================================
  // API - PRACTICE AREAS
  // =========================================================

  const loadPracticeAreas = async () => {
    try {
      setPracticeAreasLoading(true);
      setPracticeAreaError("");

      const response = await api.get("/practiceareas");

      // api.js có thể đã tự bóc response.data (interceptor), khi đó
      // `response` chính là dữ liệu và `response.data` là undefined.
      const raw = response?.data !== undefined ? response.data : response;

      console.log("practiceareas raw:", raw);

      const list = extractList(raw)
        .map(normalizePracticeArea)
        .filter((item) => Number.isFinite(item.id) && item.name);

      setPracticeAreas(list);

      if (list.length === 0) {
        console.warn(
          "API /practiceareas trả về 200 nhưng không có lĩnh vực nào. " +
            "Kiểm tra connection string hoặc dạng JSON trả về."
        );
      }
    } catch (err) {
      console.error("Không thể tải lĩnh vực hành nghề:", err);

      setPracticeAreas([]);
      setPracticeAreaError(
        getErrorMessage(err, "Không thể tải danh sách lĩnh vực.")
      );
    } finally {
      setPracticeAreasLoading(false);
    }
  };

  // =========================================================
  // API - LAWYER
  // =========================================================

  const loadLawyer = async (id) => {
    try {
      setLoadingData(true);
      setError("");

      const response = await api.get(`/lawyers/${id}`);

      const lawyer =
        response?.data?.data ||
        response?.data ||
        response?.data?.item ||
        response;

      if (!lawyer || !lawyer.id) {
        throw new Error("Không tìm thấy thông tin luật sư.");
      }

      const birthdayValue = lawyer.birthday
        ? String(lawyer.birthday).substring(0, 10)
        : "";

      setFormData({
        ...emptyForm,
        fullName: lawyer.fullName || "",
        email: lawyer.email || "",
        phone: lawyer.phone || "",
        gender: lawyer.gender || "Nam",
        birthday: birthdayValue,
        address: lawyer.address || "",
        education: lawyer.education || "",
        title: lawyer.title || "",
        barLicenseNo: lawyer.barLicenseNo || "",
        yearsExp:
          lawyer.yearsExp !== null && lawyer.yearsExp !== undefined
            ? String(lawyer.yearsExp)
            : "",
        bio: lawyer.bio || "",
        status: lawyer.isAvailable ? "Hoạt động" : "Tạm khóa",
      });

      // Avatar
      if (lawyer.avatarUrl) {
        setAvatarPreview(addCacheBust(toAvatarUrl(lawyer.avatarUrl)));
      } else {
        setAvatarPreview("");
      }

      // Practice areas (backend trả practiceAreaIds)
      const areaIds = extractList(lawyer.practiceAreaIds);

      setSelectedPracticeAreas(
        areaIds.map((item) => Number(item)).filter(Number.isFinite)
      );
    } catch (err) {
      console.error("Lỗi tải luật sư:", err);

      setError(getErrorMessage(err, "Không thể tải thông tin luật sư."));
    } finally {
      setLoadingData(false);
    }
  };

  // Upload avatar qua POST /users/{id}/avatar
  // Backend lưu vào User.AvatarUrl.
  const uploadAvatar = async (id, file) => {
    const uploadData = new FormData();

    // Backend nhận IFormFile tên "file".
    // KHÔNG tự set Content-Type, browser sẽ thêm multipart boundary.
    uploadData.append("file", file);

    try {
      const response = await api.post(`/users/${id}/avatar`, uploadData);

      const result = response?.data?.data || response?.data || response;

      return (
        result?.avatarUrl ||
        result?.AvatarUrl ||
        result?.url ||
        result?.Url ||
        null
      );
    } catch (err) {
      console.error("UPLOAD AVATAR THẤT BẠI:", err);

      throw new Error(
        `Tải ảnh thất bại: ${getErrorMessage(err, "Không thể upload ảnh đại diện.")}`
      );
    }
  };

  // =========================================================
  // INPUT CHANGE
  // =========================================================

  const handleChange = (e) => {
    const { name, value } = e.target;

    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));

    setError("");
    setSuccess("");
  };

  // =========================================================
  // AVATAR: chỉ preview, upload khi bấm Lưu
  // =========================================================

  const handleAvatarChange = (e) => {
    const file = e.target.files?.[0];

    if (!file) return;

    setError("");
    setSuccess("");

    const allowedTypes = ["image/jpeg", "image/png", "image/webp"];

    if (!allowedTypes.includes(file.type)) {
      setError("Chỉ chấp nhận ảnh JPG, PNG hoặc WEBP.");
      e.target.value = "";
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      setError("Ảnh không được vượt quá 5MB.");
      e.target.value = "";
      return;
    }

    // Preview ngay bằng blob URL (blob cũ được giải phóng ở useEffect)
    setAvatarPreview(URL.createObjectURL(file));

    setFormData((prev) => ({
      ...prev,
      avatarFile: file,
    }));

    setSuccess("Đã chọn ảnh. Ảnh sẽ được cập nhật khi bấm Lưu.");

    e.target.value = "";
  };

  // =========================================================
  // PRACTICE AREA
  // =========================================================

  const addPracticeArea = (e) => {
    const value = e.target.value;

    if (!value) return;

    const id = Number(value);

    if (!selectedPracticeAreas.includes(id)) {
      setSelectedPracticeAreas((prev) => [...prev, id]);
    }

    e.target.value = "";
  };

  const removePracticeArea = (id) => {
    setSelectedPracticeAreas((prev) =>
      prev.filter((item) => Number(item) !== Number(id))
    );
  };

  const getPracticeAreaName = (id) => {
    const item = practiceAreas.find(
      (practiceArea) => Number(practiceArea.id) === Number(id)
    );

    return item?.name || `Lĩnh vực #${id}`;
  };

  const availablePracticeAreas = practiceAreas.filter(
    (item) => !selectedPracticeAreas.includes(Number(item.id))
  );

  const practiceAreaPlaceholder = practiceAreasLoading
    ? "Đang tải lĩnh vực..."
    : practiceAreas.length === 0
      ? "Chưa có lĩnh vực nào"
      : availablePracticeAreas.length === 0
        ? "Đã chọn hết lĩnh vực"
        : "+ Thêm lĩnh vực";

  // =========================================================
  // DOCUMENTS
  // (Hiện chỉ chọn file trên giao diện, chưa gửi lên backend)
  // =========================================================

  const handleDocumentChange = (e) => {
    const files = Array.from(e.target.files || []);

    if (!files.length) return;

    const validFiles = files.filter((file) => {
      const validType =
        file.type === "application/pdf" ||
        file.type ===
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

      const validSize = file.size <= 10 * 1024 * 1024;

      return validType && validSize;
    });

    if (validFiles.length !== files.length) {
      setError(
        "Chỉ chấp nhận file PDF/DOCX và dung lượng mỗi file tối đa 10MB."
      );
    }

    setDocuments((prev) => [...prev, ...validFiles]);

    e.target.value = "";
  };

  const removeDocument = (index) => {
    setDocuments((prev) => prev.filter((_, i) => i !== index));
  };

  // =========================================================
  // VALIDATE
  // =========================================================

  const validateForm = () => {
    if (!formData.fullName.trim()) {
      return "Vui lòng nhập họ và tên luật sư.";
    }

    if (!formData.email.trim()) {
      return "Vui lòng nhập email.";
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email.trim())) {
      return "Email không hợp lệ.";
    }

    if (!formData.title.trim()) {
      return "Vui lòng nhập chức danh.";
    }

    if (formData.yearsExp !== "") {
      const years = Number(formData.yearsExp);

      if (Number.isNaN(years) || years < 0 || years > 100) {
        return "Số năm kinh nghiệm không hợp lệ.";
      }
    }

    return "";
  };

  // =========================================================
  // SUBMIT
  // =========================================================

  const handleSubmit = async (e) => {
    e.preventDefault();

    setError("");
    setSuccess("");

    const validationError = validateForm();

    if (validationError) {
      setError(validationError);
      return;
    }

    try {
      setLoading(true);

      const payload = {
        fullName: formData.fullName.trim(),
        email: formData.email.trim(),
        phone: formData.phone.trim() || null,
        gender: formData.gender || null,
        birthday: formData.birthday || null,
        address: formData.address.trim() || null,
        education: formData.education.trim() || null,
        title: formData.title.trim(),
        barLicenseNo: formData.barLicenseNo.trim() || null,
        yearsExp: formData.yearsExp === "" ? 0 : Number(formData.yearsExp),
        bio: formData.bio.trim() || null,
        isAvailable: formData.status === "Hoạt động",
        practiceAreaIds: selectedPracticeAreas,
      };

      // =====================================================
      // CREATE
      // =====================================================

      if (!isEdit) {
        payload.password = "123456";

        const response = await api.post("/lawyers", payload);

        const createdLawyer =
          response?.data?.data || response?.data || response;

        const createdLawyerId = createdLawyer?.id || createdLawyer?.Id;

        // Luật sư đã được tạo. Nếu upload ảnh lỗi thì chuyển sang
        // trang sửa để thử lại, tránh bấm Lưu lần nữa bị trùng email.
        if (formData.avatarFile && createdLawyerId) {
          try {
            await uploadAvatar(createdLawyerId, formData.avatarFile);
          } catch (avatarErr) {
            setError(
              `Đã thêm luật sư nhưng chưa tải được ảnh. ${avatarErr.message}\nĐang chuyển sang trang chỉnh sửa để bạn tải lại ảnh...`
            );

            setTimeout(() => {
              navigate(`/admin/lawyers/edit?id=${createdLawyerId}`);
            }, 2500);

            return;
          }
        }

        setSuccess("Thêm luật sư thành công.");

        setTimeout(() => {
          navigate("/admin/lawyers");
        }, 700);

        return;
      }

      // =====================================================
      // UPDATE
      // =====================================================

      await api.put(`/lawyers/${lawyerId}`, payload);

      if (formData.avatarFile) {
        try {
          await uploadAvatar(lawyerId, formData.avatarFile);
        } catch (avatarErr) {
          // Giữ lại avatarFile để bấm Lưu thử lại.
          setError(
            `Đã lưu thông tin nhưng chưa cập nhật được ảnh. ${avatarErr.message}`
          );
          return;
        }
      }

      setSuccess("Cập nhật thông tin luật sư thành công.");

      setTimeout(() => {
        navigate("/admin/lawyers");
      }, 700);
    } catch (err) {
      console.error("Lỗi lưu luật sư:", err);

      setError(getErrorMessage(err, "Không thể lưu thông tin luật sư."));
    } finally {
      setLoading(false);
    }
  };

  // =========================================================
  // CANCEL / BACK
  // =========================================================

  const handleBack = () => {
    navigate("/admin/lawyers");
  };

  // =========================================================
  // RENDER
  // =========================================================

  if (loadingData) {
    return (
      <div className="admin-add-lawyer-page">
        <div className="admin-add-lawyer-card">
          <div style={{ padding: "30px", textAlign: "center" }}>
            Đang tải thông tin luật sư...
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="admin-add-lawyer-page">
      {/* BACK */}

      <button
        type="button"
        className="admin-add-lawyer-back"
        onClick={handleBack}
      >
        <FaArrowLeft />
        <span>Quay lại danh sách</span>
      </button>

      {/* FORM */}

      <form className="admin-add-lawyer-form" onSubmit={handleSubmit}>
        <div className="admin-add-lawyer-layout">
          {/* LEFT */}

          <div className="admin-add-lawyer-left">
            {/* PERSONAL INFORMATION */}

            <div className="admin-add-lawyer-card">
              <div className="admin-add-lawyer-card-title">
                <FaUserTie />
                <h2>
                  {isEdit
                    ? "Chỉnh sửa thông tin luật sư"
                    : "Thông tin luật sư"}
                </h2>
              </div>

              <div className="admin-add-lawyer-basic-grid">
                {/* AVATAR */}

                <div className="admin-add-lawyer-avatar-column">
                  <div
                    className="admin-add-lawyer-avatar"
                    onClick={() => avatarInputRef.current?.click()}
                    style={{ cursor: "pointer" }}
                  >
                    {avatarPreview ? (
                      <img src={avatarPreview} alt="Ảnh đại diện luật sư" />
                    ) : (
                      <FaUser className="admin-add-lawyer-avatar-placeholder" />
                    )}

                    <div className="admin-add-lawyer-camera">
                      <FaCamera />
                    </div>

                    <input
                      ref={avatarInputRef}
                      type="file"
                      accept="image/jpeg,image/png,image/webp"
                      onChange={handleAvatarChange}
                    />
                  </div>

                  <p>Ảnh đại diện</p>
                  <small>JPG, PNG hoặc WEBP · tối đa 5MB</small>
                </div>

                {/* FIELDS */}

                <div className="admin-add-lawyer-fields-grid">
                  {/* HỌ TÊN */}

                  <div className="admin-add-lawyer-field">
                    <label>
                      Họ và tên <span>*</span>
                    </label>

                    <div className="admin-add-lawyer-input">
                      <FaUser />

                      <input
                        type="text"
                        name="fullName"
                        value={formData.fullName}
                        onChange={handleChange}
                        placeholder="Nhập họ và tên"
                      />
                    </div>
                  </div>

                  {/* EMAIL */}

                  <div className="admin-add-lawyer-field">
                    <label>
                      Email <span>*</span>
                    </label>

                    <div className="admin-add-lawyer-input">
                      <FaEnvelope />

                      <input
                        type="email"
                        name="email"
                        value={formData.email}
                        onChange={handleChange}
                        placeholder="example@email.com"
                      />
                    </div>
                  </div>

                  {/* PHONE */}

                  <div className="admin-add-lawyer-field">
                    <label>Số điện thoại</label>

                    <div className="admin-add-lawyer-input">
                      <FaPhone />

                      <input
                        type="text"
                        name="phone"
                        value={formData.phone}
                        onChange={handleChange}
                        placeholder="Nhập số điện thoại"
                      />
                    </div>
                  </div>

                  {/* GENDER */}

                  <div className="admin-add-lawyer-field">
                    <label>Giới tính</label>

                    <div className="admin-add-lawyer-radio-group">
                      <label>
                        <input
                          type="radio"
                          name="gender"
                          value="Nam"
                          checked={formData.gender === "Nam"}
                          onChange={handleChange}
                        />
                        Nam
                      </label>

                      <label>
                        <input
                          type="radio"
                          name="gender"
                          value="Nữ"
                          checked={formData.gender === "Nữ"}
                          onChange={handleChange}
                        />
                        Nữ
                      </label>

                      <label>
                        <input
                          type="radio"
                          name="gender"
                          value="Khác"
                          checked={formData.gender === "Khác"}
                          onChange={handleChange}
                        />
                        Khác
                      </label>
                    </div>
                  </div>

                  {/* BIRTHDAY */}

                  <div className="admin-add-lawyer-field">
                    <label>Ngày sinh</label>

                    <div className="admin-add-lawyer-input">
                      <FaBirthdayCake />

                      <input
                        type="date"
                        name="birthday"
                        value={formData.birthday}
                        onChange={handleChange}
                      />
                    </div>
                  </div>

                  {/* ADDRESS */}

                  <div className="admin-add-lawyer-field">
                    <label>Địa chỉ</label>

                    <div className="admin-add-lawyer-input">
                      <FaMapMarkerAlt />

                      <input
                        type="text"
                        name="address"
                        value={formData.address}
                        onChange={handleChange}
                        placeholder="Nhập địa chỉ"
                      />
                    </div>
                  </div>

                  {/* EDUCATION */}

                  <div className="admin-add-lawyer-field">
                    <label>Học vấn</label>

                    <div className="admin-add-lawyer-input">
                      <FaGraduationCap />

                      <input
                        type="text"
                        name="education"
                        value={formData.education}
                        onChange={handleChange}
                        placeholder="Ví dụ: Thạc sĩ Luật"
                      />
                    </div>
                  </div>

                  {/* TITLE */}

                  <div className="admin-add-lawyer-field">
                    <label>
                      Chức danh <span>*</span>
                    </label>

                    <div className="admin-add-lawyer-input">
                      <FaBriefcase />

                      <input
                        type="text"
                        name="title"
                        value={formData.title}
                        onChange={handleChange}
                        placeholder="Ví dụ: Luật sư cao cấp"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* PROFESSIONAL */}

            <div className="admin-add-lawyer-card">
              <div className="admin-add-lawyer-card-title">
                <FaBriefcase />
                <h2>Thông tin chuyên môn</h2>
              </div>

              <div className="admin-add-lawyer-professional-grid">
                {/* BAR LICENSE */}

                <div className="admin-add-lawyer-field">
                  <label>Số giấy phép hành nghề</label>

                  <div className="admin-add-lawyer-input">
                    <FaIdCard />

                    <input
                      type="text"
                      name="barLicenseNo"
                      value={formData.barLicenseNo}
                      onChange={handleChange}
                      placeholder="Nhập số giấy phép"
                    />
                  </div>
                </div>

                {/* YEARS EXPERIENCE */}

                <div className="admin-add-lawyer-field">
                  <label>Số năm kinh nghiệm</label>

                  <div className="admin-add-lawyer-input">
                    <FaClock />

                    <input
                      type="number"
                      name="yearsExp"
                      min="0"
                      max="100"
                      value={formData.yearsExp}
                      onChange={handleChange}
                      placeholder="Ví dụ: 5"
                    />
                  </div>
                </div>

                {/* PRACTICE AREAS */}

                <div className="admin-add-lawyer-field">
                  <label>Lĩnh vực hành nghề</label>

                  <div className="admin-add-lawyer-tags">
                    {selectedPracticeAreas.map((id) => (
                      <span key={id}>
                        {getPracticeAreaName(id)}

                        <button
                          type="button"
                          onClick={() => removePracticeArea(id)}
                          title="Xóa"
                        >
                          <FaTimes />
                        </button>
                      </span>
                    ))}

                    <select
                      className="admin-add-lawyer-add-tag"
                      value=""
                      onChange={addPracticeArea}
                      disabled={
                        practiceAreasLoading ||
                        availablePracticeAreas.length === 0
                      }
                    >
                      <option value="">{practiceAreaPlaceholder}</option>

                      {availablePracticeAreas.map((item) => (
                        <option key={item.id} value={item.id}>
                          {item.name}
                        </option>
                      ))}
                    </select>
                  </div>

                  {practiceAreaError && (
                    <small
                      style={{
                        display: "block",
                        marginTop: "6px",
                        color: "#c62828",
                        whiteSpace: "pre-line",
                      }}
                    >
                      {practiceAreaError}{" "}
                      <button
                        type="button"
                        onClick={loadPracticeAreas}
                        style={{
                          border: "none",
                          background: "none",
                          color: "#1565c0",
                          cursor: "pointer",
                          textDecoration: "underline",
                          padding: 0,
                          font: "inherit",
                        }}
                      >
                        Tải lại
                      </button>
                    </small>
                  )}
                </div>

                {/* BIO */}

                <div className="admin-add-lawyer-field">
                  <label>Giới thiệu</label>

                  <div className="admin-add-lawyer-textarea">
                    <textarea
                      name="bio"
                      value={formData.bio}
                      onChange={handleChange}
                      maxLength={500}
                      placeholder="Nhập thông tin giới thiệu về luật sư..."
                    />

                    <small>{formData.bio.length}/500</small>
                  </div>
                </div>
              </div>
            </div>

            {/* DOCUMENTS */}

            <div className="admin-add-lawyer-card">
              <div className="admin-add-lawyer-card-title">
                <FaCloudUploadAlt />
                <h2>Hồ sơ đính kèm</h2>
              </div>

              <div
                className="admin-add-lawyer-file-upload"
                onClick={() => documentInputRef.current?.click()}
              >
                <FaCloudUploadAlt />

                <div>
                  <strong>Tải hồ sơ luật sư</strong>
                  <span>Hỗ trợ PDF, DOCX. Dung lượng tối đa 10MB/file.</span>
                </div>

                <button
                  type="button"
                  className="admin-add-lawyer-file-button"
                  onClick={(e) => {
                    e.stopPropagation();
                    documentInputRef.current?.click();
                  }}
                >
                  Chọn file
                </button>

                <input
                  ref={documentInputRef}
                  type="file"
                  multiple
                  accept=".pdf,.docx"
                  onChange={handleDocumentChange}
                />
              </div>

              {documents.length > 0 && (
                <div className="admin-add-lawyer-file-list">
                  {documents.map((file, index) => (
                    <div
                      className="admin-add-lawyer-file-item"
                      key={`${file.name}-${index}`}
                    >
                      <FaFilePdf />

                      <span>
                        {file.name} ({(file.size / 1024 / 1024).toFixed(2)} MB)
                      </span>

                      <button
                        type="button"
                        onClick={() => removeDocument(index)}
                        title="Xóa file"
                      >
                        <FaTrash />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* RIGHT */}

          <div className="admin-add-lawyer-right">
            {/* STATUS */}

            <div className="admin-add-lawyer-side-card">
              <div className="admin-add-lawyer-side-title">
                <FaShieldAlt />
                <h2>Trạng thái</h2>
              </div>

              <span className="admin-add-lawyer-status-label">
                Trạng thái hoạt động
              </span>

              <div className="admin-add-lawyer-select">
                <select
                  name="status"
                  value={formData.status}
                  onChange={handleChange}
                >
                  <option value="Hoạt động">Hoạt động</option>
                  <option value="Tạm khóa">Tạm khóa</option>
                </select>

                <FaChevronDown />
              </div>

              <p className="admin-add-lawyer-side-description">
                Luật sư ở trạng thái hoạt động có thể đăng nhập, nhận yêu cầu
                tư vấn và được hiển thị trên hệ thống.
              </p>
            </div>

            {/* BENEFITS */}

            <div className="admin-add-lawyer-side-card">
              <div className="admin-add-lawyer-side-title">
                <FaCheckCircle />
                <h2>Thông tin cần có</h2>
              </div>

              <ul className="admin-add-lawyer-benefits">
                <li>
                  <FaCheckCircle />
                  <span>Họ tên và email chính xác</span>
                </li>

                <li>
                  <FaCheckCircle />
                  <span>Thông tin giấy phép hành nghề</span>
                </li>

                <li>
                  <FaCheckCircle />
                  <span>Số năm kinh nghiệm</span>
                </li>

                <li>
                  <FaCheckCircle />
                  <span>Lĩnh vực hành nghề</span>
                </li>

                <li>
                  <FaCheckCircle />
                  <span>Thông tin học vấn</span>
                </li>
              </ul>
            </div>

            {/* NOTE */}

            <div className="admin-add-lawyer-side-card admin-add-lawyer-note-card">
              <div className="admin-add-lawyer-side-title">
                <FaInfoCircle />
                <h2>Lưu ý</h2>
              </div>

              <ul>
                <li>Email được sử dụng để đăng nhập vào hệ thống.</li>

                <li>
                  <strong>
                    Không chia sẻ thông tin đăng nhập cho người khác.
                  </strong>
                </li>

                <li>Kiểm tra kỹ thông tin trước khi lưu.</li>
              </ul>
            </div>

            {/* ERROR / SUCCESS */}

            {(error || success) && (
              <div className="admin-add-lawyer-side-card">
                {error && (
                  <div
                    style={{
                      color: "#c62828",
                      fontSize: "12px",
                      lineHeight: 1.5,
                      whiteSpace: "pre-line",
                    }}
                  >
                    {error}
                  </div>
                )}

                {success && (
                  <div
                    style={{
                      color: "#168342",
                      fontSize: "12px",
                      lineHeight: 1.5,
                    }}
                  >
                    {success}
                  </div>
                )}
              </div>
            )}

            {/* ACTIONS */}

            <div className="admin-add-lawyer-actions">
              <button
                type="button"
                className="admin-add-lawyer-cancel"
                onClick={handleBack}
                disabled={loading}
              >
                Hủy
              </button>

              <button
                type="submit"
                className="admin-add-lawyer-save"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <FaClock />
                    Đang lưu...
                  </>
                ) : (
                  <>
                    <FaSave />
                    {isEdit ? "Lưu thay đổi" : "Thêm luật sư"}
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}

export default AdminAddLawyer;
