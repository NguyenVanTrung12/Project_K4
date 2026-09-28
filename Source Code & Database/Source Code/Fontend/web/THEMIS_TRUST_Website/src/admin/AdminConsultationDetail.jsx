import { useEffect, useMemo, useState } from "react";
import { NavLink, useNavigate, useParams } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faArrowLeft,
  faUser,
  faEnvelope,
  faPhone,
  faCalendarDays,
  faVenusMars,
  faLocationDot,
  faFileLines,
  faComments,
  faPaperclip,
  faUserTie,
  faExchangeAlt,
  faCircleCheck,
  faPaperPlane,
  faFilePdf,
  faDownload,
  faClock,
  faNoteSticky,
  faBan,
  faBriefcase,
  faPlus,
} from "@fortawesome/free-solid-svg-icons";

import "../assets/css/admin/AdminConsultationDetail.css";
import { api } from "../api/api";

// Ảnh mặc định (fallback) khi API không trả về avatar.
// Dùng SVG dạng inline (data URI) thay vì import file tĩnh,
// để không phụ thuộc vào việc file ảnh có tồn tại đúng đường dẫn hay không
// (tránh lỗi Vite "Failed to resolve import" khi file không tồn tại).
const defaultUserAvatar =
  "data:image/svg+xml;utf8," +
  encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
      <rect width="100" height="100" fill="#e5e7eb"/>
      <circle cx="50" cy="38" r="18" fill="#9ca3af"/>
      <path d="M20 88c0-18 14-30 30-30s30 12 30 30" fill="#9ca3af"/>
    </svg>`
  );

const defaultLawyerAvatar =
  "data:image/svg+xml;utf8," +
  encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
      <rect width="100" height="100" fill="#dbeafe"/>
      <circle cx="50" cy="38" r="18" fill="#60a5fa"/>
      <path d="M20 88c0-18 14-30 30-30s30 12 30 30" fill="#60a5fa"/>
    </svg>`
  );

const STATUS_LABELS = {
  pending: "Chờ xử lý",
  new: "Mới",
  processing: "Đang xử lý",
  assigned: "Đã phân công",
  completed: "Hoàn thành",
  cancelled: "Đã đóng",
};

const PRIORITY_LABELS = {
  low: "Thấp",
  normal: "Bình thường",
  high: "Cao",
  urgent: "Khẩn cấp",
};

const AdminConsultationDetail = () => {
  const navigate = useNavigate();
  const { id } = useParams();

  const [consultation, setConsultation] = useState(null);
  const [lawyers, setLawyers] = useState([]);
  const [cases, setCases] = useState([]);

  const [loading, setLoading] = useState(true);
  const [loadingCases, setLoadingCases] = useState(false);
  const [error, setError] = useState("");

  const [changingLawyer, setChangingLawyer] = useState(false);
  const [updatingStatus, setUpdatingStatus] = useState(false);
  const [closingRequest, setClosingRequest] = useState(false);

  const [selectedLawyerId, setSelectedLawyerId] = useState("");
  const [selectedStatus, setSelectedStatus] = useState("");

  const [note, setNote] = useState("");
  const [savingNote, setSavingNote] = useState(false);

  /* =========================================================
     LOAD CONSULTATION
  ========================================================= */

  const loadConsultation = async () => {
    if (!id) {
      setError("Không tìm thấy mã yêu cầu tư vấn.");
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError("");

      const data = await api.get(`/consultation-requests/${id}`);

      setConsultation(data);
      setSelectedLawyerId(data?.lawyerId || "");
      setSelectedStatus(data?.status || "pending");
    } catch (err) {
      console.error("Lỗi lấy chi tiết yêu cầu tư vấn:", err);

      setError(
        err?.message || "Không thể tải thông tin yêu cầu tư vấn."
      );
    } finally {
      setLoading(false);
    }
  };

  /* =========================================================
     LOAD LAWYERS
  ========================================================= */

  const loadLawyers = async () => {
    try {
      const data = await api.get("/lawyers");

      const list = Array.isArray(data)
        ? data
        : data?.items || [];

      setLawyers(list);
    } catch (err) {
      console.error("Lỗi lấy danh sách luật sư:", err);
      setLawyers([]);
    }
  };

  /* =========================================================
     LOAD CASES
     
     Mục đích:
     - Kiểm tra khách hàng này đã có hồ sơ vụ án chưa.
     - Nếu có hồ sơ thì hiển thị để Admin xem.
     - Hồ sơ vụ án được tạo bởi Lawyer, không tự động tạo
       khi khách hàng gửi yêu cầu tư vấn.
  ========================================================= */

  const loadCases = async (clientId) => {
    if (!clientId) {
      setCases([]);
      return;
    }

    try {
      setLoadingCases(true);

      const data = await api.get("/cases");

      const allCases = Array.isArray(data)
        ? data
        : data?.items || [];

      const clientCases = allCases.filter(
        (item) =>
          String(item.clientId) === String(clientId)
      );

      setCases(clientCases);
    } catch (err) {
      console.warn(
        "Không thể tải hồ sơ vụ án:",
        err
      );

      setCases([]);
    } finally {
      setLoadingCases(false);
    }
  };

  useEffect(() => {
    loadConsultation();
    loadLawyers();
  }, [id]);

  useEffect(() => {
    if (consultation?.clientId) {
      loadCases(consultation.clientId);
    }
  }, [consultation?.clientId]);

  /* =========================================================
     HELPERS
  ========================================================= */

  const formatDateTime = (value) => {
    if (!value) {
      return "--";
    }

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
      return value;
    }

    return date.toLocaleString("vi-VN", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const formatDate = (value) => {
    if (!value) {
      return "--";
    }

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
      return value;
    }

    return date.toLocaleDateString("vi-VN");
  };

  const formatPriority = (priority) => {
    return (
      PRIORITY_LABELS[priority] ||
      priority ||
      "--"
    );
  };

  const formatStatus = (status) => {
    return (
      STATUS_LABELS[status] ||
      status ||
      "--"
    );
  };

  const getStatusClass = (status) => {
    switch (status) {
      case "completed":
        return "admin-consultation-detail-tag-green";

      case "cancelled":
        return "admin-consultation-detail-tag-red";

      case "pending":
      case "new":
        return "admin-consultation-detail-tag-orange";

      default:
        return "admin-consultation-detail-tag-green";
    }
  };

  const getPriorityClass = (priority) => {
    switch (priority) {
      case "urgent":
      case "high":
        return "admin-consultation-detail-tag-red";

      case "low":
        return "admin-consultation-detail-tag-blue";

      default:
        return "admin-consultation-detail-tag-orange";
    }
  };

  // Ghép URL tương đối từ API (vd: "/uploads/avatar.jpg")
  // với base URL của server để ra URL ảnh đầy đủ dùng được trong <img src>
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
      "http://localhost:5000/api";

    const serverUrl = baseUrl.replace(
      /\/api\/?$/,
      ""
    );

    return `${serverUrl}${
      url.startsWith("/") ? "" : "/"
    }${url}`;
  };

  /* =========================================================
     ASSIGNED LAWYER
  ========================================================= */

  const assignedLawyer = useMemo(() => {
    if (!consultation?.lawyerId) {
      return null;
    }

    return (
      lawyers.find(
        (lawyer) =>
          String(lawyer.id) ===
          String(consultation.lawyerId)
      ) || null
    );
  }, [consultation, lawyers]);

  /* =========================================================
     AVATARS (đã sửa: build URL đầy đủ từ API, có fallback)
  ========================================================= */

  const clientAvatarSrc = useMemo(() => {
    return (
      getFullApiUrl(consultation?.clientAvatar) ||
      defaultUserAvatar
    );
  }, [consultation]);

  const lawyerAvatarSrc = useMemo(() => {
    return (
      getFullApiUrl(
        assignedLawyer?.avatarUrl ||
          assignedLawyer?.user?.avatarUrl
      ) || defaultLawyerAvatar
    );
  }, [assignedLawyer]);

  /* =========================================================
     DOCUMENTS
  ========================================================= */

  const documents = useMemo(() => {
    if (!consultation?.attachmentUrl) {
      return [];
    }

    const url = consultation.attachmentUrl;

    const fileName =
      url.split("/").pop() ||
      "Tài liệu đính kèm";

    return [
      {
        name: fileName,
        url: getFullApiUrl(url),
      },
    ];
  }, [consultation]);

  /* =========================================================
     HISTORY
  ========================================================= */

  const history = useMemo(() => {
    if (!consultation) {
      return [];
    }

    const result = [];

    if (consultation.createdAt) {
      result.push({
        time: formatDateTime(
          consultation.createdAt
        ),
        title: "Khách hàng gửi yêu cầu tư vấn",
        description: `${
          consultation.clientName ||
          "Khách hàng"
        } đã gửi yêu cầu tư vấn.`,
        type: "customer",
      });
    }

    if (consultation.lawyerId) {
      result.push({
        time: formatDateTime(
          consultation.updatedAt ||
            consultation.createdAt
        ),
        title: "Đã phân công luật sư",
        description: consultation.lawyerName
          ? `Luật sư ${consultation.lawyerName} được phân công xử lý.`
          : "Yêu cầu đã được phân công luật sư.",
        type: "lawyer",
      });
    }

    if (
      consultation.updatedAt &&
      consultation.updatedAt !==
        consultation.createdAt
    ) {
      result.push({
        time: formatDateTime(
          consultation.updatedAt
        ),
        title: "Yêu cầu được cập nhật",
        description: `Trạng thái hiện tại: ${formatStatus(
          consultation.status
        )}.`,
        type: "system",
      });
    }

    return result;
  }, [consultation]);

  /* =========================================================
     CASES
  ========================================================= */

  const clientCases = useMemo(() => {
    if (!consultation?.clientId) {
      return [];
    }

    return cases.filter(
      (item) =>
        String(item.clientId) ===
        String(consultation.clientId)
    );
  }, [cases, consultation]);

  /* =========================================================
     BACK
  ========================================================= */

  const handleBack = () => {
    navigate(-1);
  };

  /* =========================================================
     CHANGE LAWYER
  ========================================================= */

  const handleChangeLawyer = async () => {
    if (!consultation) {
      return;
    }

    if (!selectedLawyerId) {
      alert("Vui lòng chọn luật sư.");
      return;
    }

    try {
      setChangingLawyer(true);

      await api.patch(
        `/consultation-requests/${consultation.id}`,
        {
          lawyerId: selectedLawyerId,
        }
      );

      await loadConsultation();

      alert("Đã cập nhật luật sư phụ trách.");
    } catch (err) {
      console.error(err);

      alert(
        err?.message ||
          "Không thể thay đổi luật sư."
      );
    } finally {
      setChangingLawyer(false);
    }
  };

  /* =========================================================
     UPDATE STATUS
  ========================================================= */

  const handleUpdateStatus = async () => {
    if (!consultation) {
      return;
    }

    if (!selectedStatus) {
      alert("Vui lòng chọn trạng thái.");
      return;
    }

    try {
      setUpdatingStatus(true);

      await api.patch(
        `/consultation-requests/${consultation.id}`,
        {
          status: selectedStatus,
        }
      );

      await loadConsultation();

      alert("Đã cập nhật trạng thái.");
    } catch (err) {
      console.error(err);

      alert(
        err?.message ||
          "Không thể cập nhật trạng thái."
      );
    } finally {
      setUpdatingStatus(false);
    }
  };

  /* =========================================================
     CANCEL REQUEST
  ========================================================= */

  const handleCancelRequest = async () => {
    if (!consultation) {
      return;
    }

    if (
      consultation.status ===
      "cancelled"
    ) {
      alert(
        "Yêu cầu này đã được đóng."
      );
      return;
    }

    const confirmed = window.confirm(
      "Bạn có chắc muốn đóng yêu cầu tư vấn này?"
    );

    if (!confirmed) {
      return;
    }

    try {
      setClosingRequest(true);

      await api.patch(
        `/consultation-requests/${consultation.id}`,
        {
          status: "cancelled",
        }
      );

      await loadConsultation();

      alert(
        "Đã đóng yêu cầu tư vấn."
      );
    } catch (err) {
      console.error(err);

      alert(
        err?.message ||
          "Không thể đóng yêu cầu."
      );
    } finally {
      setClosingRequest(false);
    }
  };

  /* =========================================================
     SEND NOTIFICATION
     
     Backend hiện chưa có endpoint riêng.
  ========================================================= */

  const handleSendNotification = () => {
    alert(
      "Backend hiện chưa có API gửi thông báo thủ công cho khách hàng."
    );
  };

  /* =========================================================
     SAVE NOTE
     
     Backend hiện chưa có API lưu note.
  ========================================================= */

  const handleAddNote = async () => {
    if (!note.trim()) {
      return;
    }

    alert(
      "Backend hiện chưa có API lưu ghi chú nội bộ."
    );

    setNote("");
  };

  /* =========================================================
     CREATE CASE
     
     Quan trọng:
     Admin không tự động tạo hồ sơ khi khách đặt lịch.
     
     Lawyer sẽ là người tạo hồ sơ sau khi tiếp nhận yêu cầu.
     
     Nút này chỉ dẫn tới màn hình quản lý hồ sơ.
  ========================================================= */

  const handleViewCases = () => {
    navigate("/admin/cases");
  };

  /* =========================================================
     LOADING
  ========================================================= */

  if (loading) {
    return (
      <div className="admin-consultation-detail-page">
        <div
          style={{
            padding: "40px",
            textAlign: "center",
          }}
        >
          Đang tải thông tin yêu cầu tư vấn...
        </div>
      </div>
    );
  }

  /* =========================================================
     ERROR
  ========================================================= */

  if (error || !consultation) {
    return (
      <div className="admin-consultation-detail-page">
        <button
          type="button"
          className="admin-consultation-detail-back"
          onClick={handleBack}
        >
          <FontAwesomeIcon
            icon={faArrowLeft}
          />

          <span>Quay lại</span>
        </button>

        <div
          style={{
            padding: "40px",
            textAlign: "center",
          }}
        >
          <h2>
            Không thể tải yêu cầu tư vấn
          </h2>

          <p>
            {error ||
              "Không tìm thấy yêu cầu tư vấn."}
          </p>
        </div>
      </div>
    );
  }

  /* =========================================================
     RETURN
  ========================================================= */

  return (
    <div className="admin-consultation-detail-page">

      {/* =====================================================
          BACK
      ===================================================== */}

      <button
        type="button"
        className="admin-consultation-detail-back"
        onClick={handleBack}
      >
        <FontAwesomeIcon
          icon={faArrowLeft}
        />

        <span>Quay lại</span>
      </button>

      {/* =====================================================
          MAIN LAYOUT
      ===================================================== */}

      <div className="admin-consultation-detail-layout">

        {/* =================================================
            LEFT COLUMN
        ================================================= */}

        <main className="admin-consultation-detail-main">

          {/* =================================================
              CUSTOMER INFORMATION
          ================================================= */}

          <section className="admin-consultation-detail-card">

            <div className="admin-consultation-detail-card-title">
              <FontAwesomeIcon
                icon={faUser}
              />

              <h2>
                Thông tin khách hàng
              </h2>
            </div>

            <div className="admin-consultation-detail-customer">

              <div className="admin-consultation-detail-customer-avatar">
                <img
                  src={clientAvatarSrc}
                  alt={
                    consultation.clientName ||
                    "Khách hàng"
                  }
                  onError={(e) => {
                    e.currentTarget.onerror = null;
                    e.currentTarget.src = defaultUserAvatar;
                  }}
                />
              </div>

              <div className="admin-consultation-detail-customer-info">

                <div className="admin-consultation-detail-customer-name">
                  <h1>
                    {consultation.clientName ||
                      "--"}
                  </h1>

                  <span>
                    Khách hàng
                  </span>
                </div>

                <div className="admin-consultation-detail-customer-grid">

                  <div>
                    <FontAwesomeIcon
                      icon={faEnvelope}
                    />

                    <span>
                      {consultation.clientEmail ||
                        "--"}
                    </span>
                  </div>

                  <div>
                    <FontAwesomeIcon
                      icon={faPhone}
                    />

                    <span>
                      {consultation.phone ||
                        "--"}
                    </span>
                  </div>

                  <div>
                    <FontAwesomeIcon
                      icon={faVenusMars}
                    />

                    <span>
                      {consultation.gender ||
                        "--"}
                    </span>
                  </div>

                  <div>
                    <FontAwesomeIcon
                      icon={faCalendarDays}
                    />

                    <span>
                      Ngày sinh:{" "}
                      {formatDate(
                        consultation.birthDate
                      )}
                    </span>
                  </div>

                  <div>
                    <FontAwesomeIcon
                      icon={faLocationDot}
                    />

                    <span>
                      {consultation.address ||
                        "--"}
                    </span>
                  </div>

                  <div>
                    <FontAwesomeIcon
                      icon={faCalendarDays}
                    />

                    <span>
                      Thành viên từ:{" "}
                      {formatDate(
                        consultation.clientCreatedAt
                      )}
                    </span>
                  </div>

                </div>
              </div>
            </div>
          </section>

          {/* =================================================
              REQUEST INFORMATION
          ================================================= */}

          <section className="admin-consultation-detail-card">

            <div className="admin-consultation-detail-card-title">

              <FontAwesomeIcon
                icon={faFileLines}
              />

              <h2>
                Thông tin yêu cầu tư vấn
              </h2>

            </div>

            <div className="admin-consultation-detail-request-grid">

              <div className="admin-consultation-detail-request-row">
                <span>
                  Mã yêu cầu
                </span>

                <strong className="admin-consultation-detail-code">
                  {consultation.id}
                </strong>
              </div>

              <div className="admin-consultation-detail-request-row">
                <span>
                  Ngày gửi yêu cầu
                </span>

                <strong>
                  {formatDateTime(
                    consultation.createdAt
                  )}
                </strong>
              </div>

              <div className="admin-consultation-detail-request-row">
                <span>
                  Lĩnh vực pháp lý
                </span>

                <strong className="admin-consultation-detail-tag admin-consultation-detail-tag-blue">
                  {consultation.practiceAreaName ||
                    consultation.practiceArea?.name ||
                    consultation.fieldName ||
                    "--"}
                </strong>
              </div>

              <div className="admin-consultation-detail-request-row">
                <span>
                  Hình thức tư vấn
                </span>

                <strong className="admin-consultation-detail-tag admin-consultation-detail-tag-green">
                  <FontAwesomeIcon
                    icon={faComments}
                  />

                  {consultation.consultationType ||
                    consultation.type ||
                    consultation.method ||
                    "--"}
                </strong>
              </div>

              <div className="admin-consultation-detail-request-row">
                <span>
                  Ưu tiên
                </span>

                <strong
                  className={`admin-consultation-detail-tag ${getPriorityClass(
                    consultation.priority
                  )}`}
                >
                  {formatPriority(
                    consultation.priority
                  )}
                </strong>
              </div>

              <div className="admin-consultation-detail-request-row">
                <span>
                  Trạng thái
                </span>

                <strong
                  className={`admin-consultation-detail-tag ${getStatusClass(
                    consultation.status
                  )}`}
                >
                  <span className="admin-consultation-detail-status-dot"></span>

                  {formatStatus(
                    consultation.status
                  )}
                </strong>
              </div>

            </div>
          </section>

          {/* =================================================
              CONTENT
          ================================================= */}

          <section className="admin-consultation-detail-card">

            <div className="admin-consultation-detail-card-title">

              <FontAwesomeIcon
                icon={faComments}
              />

              <h2>
                Nội dung yêu cầu tư vấn
              </h2>

            </div>

            <div className="admin-consultation-detail-content">

              <div className="admin-consultation-detail-content-heading">

                <strong>
                  {consultation.title ||
                    "--"}
                </strong>

                <span>
                  {formatDateTime(
                    consultation.createdAt
                  )}
                </span>

              </div>

              <p>
                {consultation.description ||
                  "--"}
              </p>

            </div>
          </section>

          {/* =================================================
              DOCUMENTS
          ================================================= */}

          <section className="admin-consultation-detail-card">

            <div className="admin-consultation-detail-card-title">

              <FontAwesomeIcon
                icon={faPaperclip}
              />

              <h2>
                Tài liệu đính kèm
              </h2>

            </div>

            <div className="admin-consultation-detail-documents">

              {documents.length > 0 ? (
                documents.map(
                  (document, index) => (
                    <div
                      className="admin-consultation-detail-document"
                      key={`${document.url}-${index}`}
                    >

                      <div className="admin-consultation-detail-document-icon">

                        <FontAwesomeIcon
                          icon={faFilePdf}
                        />

                      </div>

                      <div className="admin-consultation-detail-document-info">

                        <strong>
                          {document.name}
                        </strong>

                        <span>
                          Tài liệu đính kèm
                        </span>

                      </div>

                      <a
                        href={document.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="admin-consultation-detail-download"
                      >
                        <FontAwesomeIcon
                          icon={faDownload}
                        />
                      </a>

                    </div>
                  )
                )
              ) : (
                <div
                  style={{
                    padding: "20px",
                    textAlign: "center",
                    color: "#888",
                  }}
                >
                  Không có tài liệu đính kèm
                </div>
              )}

            </div>
          </section>

          {/* =================================================
              CASE MANAGEMENT
              
              Đây là phần quan trọng cho flow mới.
          ================================================= */}

          <section className="admin-consultation-detail-card">

            <div className="admin-consultation-detail-card-title">

              <FontAwesomeIcon
                icon={faBriefcase}
              />

              <h2>
                Hồ sơ vụ án của khách hàng
              </h2>

            </div>

            <div
              style={{
                padding: "0 0 20px 0",
              }}
            >

              <div
                style={{
                  background: "#f5f8ff",
                  border: "1px solid #dce6ff",
                  borderRadius: "10px",
                  padding: "16px",
                  marginBottom: "16px",
                }}
              >
                <strong>
                  Quy trình:
                </strong>

                <span
                  style={{
                    marginLeft: "8px",
                  }}
                >
                  Khách hàng gửi yêu cầu → Luật sư
                  tiếp nhận → Luật sư tạo hồ sơ vụ án.
                </span>
              </div>

              {loadingCases ? (
                <div
                  style={{
                    padding: "20px",
                    textAlign: "center",
                    color: "#777",
                  }}
                >
                  Đang tải hồ sơ vụ án...
                </div>
              ) : clientCases.length > 0 ? (
                <div
                  style={{
                    display: "flex",
                    flexDirection: "column",
                    gap: "12px",
                  }}
                >
                  {clientCases.map((caseItem) => (
                    <div
                      key={caseItem.id}
                      style={{
                        border: "1px solid #e5e7eb",
                        borderRadius: "10px",
                        padding: "16px",
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        gap: "20px",
                      }}
                    >
                      <div>
                        <strong
                          style={{
                            display: "block",
                            marginBottom: "5px",
                          }}
                        >
                          {caseItem.docketNo ||
                            "Chưa có mã hồ sơ"}
                        </strong>

                        <span
                          style={{
                            display: "block",
                            color: "#555",
                          }}
                        >
                          {caseItem.title ||
                            "Chưa có tiêu đề"}
                        </span>

                        <small
                          style={{
                            display: "block",
                            marginTop: "5px",
                            color: "#777",
                          }}
                        >
                          Luật sư:{" "}
                          {caseItem.lawyerName ||
                            "Chưa phân công"}
                        </small>
                      </div>

                      <button
                        type="button"
                        onClick={() =>
                          navigate(
                            `/admin/cases/${caseItem.id}`
                          )
                        }
                        className="admin-consultation-detail-action admin-consultation-detail-action-blue"
                      >
                        <FontAwesomeIcon
                          icon={faFileLines}
                        />

                        <span>
                          Xem hồ sơ
                        </span>
                      </button>
                    </div>
                  ))}
                </div>
              ) : (
                <div
                  style={{
                    padding: "25px",
                    textAlign: "center",
                    border: "1px dashed #d1d5db",
                    borderRadius: "10px",
                    color: "#777",
                  }}
                >
                  <FontAwesomeIcon
                    icon={faFileLines}
                    style={{
                      fontSize: "28px",
                      marginBottom: "10px",
                    }}
                  />

                  <div>
                    Khách hàng chưa có hồ sơ vụ án.
                  </div>

                  <small>
                    Hồ sơ sẽ được tạo bởi luật sư sau khi
                    tiếp nhận yêu cầu tư vấn.
                  </small>
                </div>
              )}

              <div
                style={{
                  marginTop: "16px",
                  display: "flex",
                  justifyContent: "flex-end",
                }}
              >
                <button
                  type="button"
                  onClick={handleViewCases}
                  className="admin-consultation-detail-action admin-consultation-detail-action-blue"
                >
                  <FontAwesomeIcon
                    icon={faFileLines}
                  />

                  <span>
                    Quản lý hồ sơ vụ án
                  </span>
                </button>
              </div>

            </div>
          </section>

          {/* =================================================
              PROCESS HISTORY
          ================================================= */}

          <section className="admin-consultation-detail-card">

            <div className="admin-consultation-detail-card-title">

              <FontAwesomeIcon
                icon={faClock}
              />

              <h2>
                Lịch sử xử lý
              </h2>

            </div>

            <div className="admin-consultation-detail-history">

              {history.length > 0 ? (
                history.map(
                  (item, index) => (
                    <div
                      className="admin-consultation-detail-history-item"
                      key={`${item.time}-${index}`}
                    >

                      <div className="admin-consultation-detail-history-time">
                        {item.time}
                      </div>

                      <div
                        className={`admin-consultation-detail-history-marker ${item.type}`}
                      ></div>

                      <div className="admin-consultation-detail-history-content">

                        <strong>
                          {item.title}
                        </strong>

                        <span>
                          {item.description}
                        </span>

                      </div>

                    </div>
                  )
                )
              ) : (
                <div
                  style={{
                    padding: "20px",
                    textAlign: "center",
                    color: "#888",
                  }}
                >
                  Chưa có lịch sử xử lý
                </div>
              )}

            </div>
          </section>

        </main>

        {/* =================================================
            RIGHT COLUMN
        ================================================= */}

        <aside className="admin-consultation-detail-sidebar">

          {/* =================================================
              LAWYER
          ================================================= */}

          <section className="admin-consultation-detail-card">

            <div className="admin-consultation-detail-card-title">

              <FontAwesomeIcon
                icon={faUserTie}
              />

              <h2>
                Luật sư phụ trách
              </h2>

            </div>

            {consultation.lawyerId ? (
              <>

                <div className="admin-consultation-detail-lawyer">

                  <img
                    src={lawyerAvatarSrc}
                    alt={
                      consultation.lawyerName ||
                      "Luật sư"
                    }
                    onError={(e) => {
                      e.currentTarget.onerror = null;
                      e.currentTarget.src = defaultLawyerAvatar;
                    }}
                  />

                  <div>

                    <strong>
                      {consultation.lawyerName ||
                        assignedLawyer?.fullName ||
                        assignedLawyer?.name ||
                        "--"}
                    </strong>

                    <span>
                      {assignedLawyer?.title ||
                        assignedLawyer?.user?.title ||
                        "Luật sư"}
                    </span>

                  </div>

                </div>

                <div className="admin-consultation-detail-lawyer-contact">

                  <div>

                    <FontAwesomeIcon
                      icon={faEnvelope}
                    />

                    <span>
                      {assignedLawyer?.email ||
                        assignedLawyer?.user?.email ||
                        "--"}
                    </span>

                  </div>

                  <div>

                    <FontAwesomeIcon
                      icon={faPhone}
                    />

                    <span>
                      {assignedLawyer?.phone ||
                        assignedLawyer?.user?.phone ||
                        "--"}
                    </span>

                  </div>

                </div>

                <NavLink
                  to={`/admin/lawyers/${consultation.lawyerId}`}
                  className="admin-consultation-detail-profile-button"
                >
                  <span>
                    Xem hồ sơ luật sư
                  </span>

                  <FontAwesomeIcon
                    icon={faArrowLeft}
                  />
                </NavLink>

              </>
            ) : (
              <div
                style={{
                  padding: "20px",
                  textAlign: "center",
                  color: "#888",
                }}
              >
                Chưa phân công luật sư
              </div>
            )}

          </section>

          {/* =================================================
              ADMIN ACTIONS
          ================================================= */}

          <section className="admin-consultation-detail-card">

            <div className="admin-consultation-detail-card-title">

              <FontAwesomeIcon
                icon={faCalendarDays}
              />

              <h2>
                Thao tác quản trị
              </h2>

            </div>

            <div className="admin-consultation-detail-actions">

              {/* CHANGE LAWYER */}

              <div
                style={{
                  width: "100%",
                  marginBottom: "12px",
                }}
              >

                <label
                  style={{
                    display: "block",
                    marginBottom: "6px",
                    fontWeight: "600",
                  }}
                >
                  Luật sư phụ trách
                </label>

                <select
                  value={selectedLawyerId}
                  onChange={(e) =>
                    setSelectedLawyerId(
                      e.target.value
                    )
                  }
                  disabled={changingLawyer}
                  style={{
                    width: "100%",
                    padding: "10px",
                    borderRadius: "8px",
                    border: "1px solid #ddd",
                  }}
                >

                  <option value="">
                    -- Chưa phân công --
                  </option>

                  {lawyers.map((lawyer) => (
                    <option
                      key={lawyer.id}
                      value={lawyer.id}
                    >
                      {lawyer.fullName ||
                        lawyer.name ||
                        lawyer.email ||
                        "Luật sư"}
                    </option>
                  ))}

                </select>

              </div>

              <button
                type="button"
                onClick={
                  handleChangeLawyer
                }
                disabled={
                  changingLawyer ||
                  !selectedLawyerId
                }
                className="admin-consultation-detail-action admin-consultation-detail-action-blue"
              >

                <FontAwesomeIcon
                  icon={faExchangeAlt}
                />

                <span>
                  {changingLawyer
                    ? "Đang cập nhật..."
                    : "Cập nhật luật sư"}
                </span>

              </button>

              {/* STATUS */}

              <div
                style={{
                  width: "100%",
                  marginTop: "10px",
                  marginBottom: "5px",
                }}
              >

                <label
                  style={{
                    display: "block",
                    marginBottom: "6px",
                    fontWeight: "600",
                  }}
                >
                  Trạng thái yêu cầu
                </label>

                <select
                  value={selectedStatus}
                  onChange={(e) =>
                    setSelectedStatus(
                      e.target.value
                    )
                  }
                  disabled={
                    updatingStatus
                  }
                  style={{
                    width: "100%",
                    padding: "10px",
                    borderRadius: "8px",
                    border: "1px solid #ddd",
                  }}
                >

                  <option value="pending">
                    Chờ xử lý
                  </option>

                  <option value="new">
                    Mới
                  </option>

                  <option value="processing">
                    Đang xử lý
                  </option>

                  <option value="assigned">
                    Đã phân công
                  </option>

                  <option value="completed">
                    Hoàn thành
                  </option>

                  <option value="cancelled">
                    Đã đóng
                  </option>

                </select>

              </div>

              <button
                type="button"
                onClick={
                  handleUpdateStatus
                }
                disabled={
                  updatingStatus
                }
                className="admin-consultation-detail-action admin-consultation-detail-action-blue"
              >

                <FontAwesomeIcon
                  icon={faCircleCheck}
                />

                <span>
                  {updatingStatus
                    ? "Đang cập nhật..."
                    : "Cập nhật trạng thái"}
                </span>

              </button>

              {/* NOTIFICATION */}

              <button
                type="button"
                onClick={
                  handleSendNotification
                }
                className="admin-consultation-detail-action admin-consultation-detail-action-blue"
              >

                <FontAwesomeIcon
                  icon={faPaperPlane}
                />

                <span>
                  Gửi thông báo cho khách hàng
                </span>

              </button>

              {/* NOTE */}

              <button
                type="button"
                onClick={
                  handleAddNote
                }
                disabled={
                  savingNote ||
                  !note.trim()
                }
                className="admin-consultation-detail-action admin-consultation-detail-action-purple"
              >

                <FontAwesomeIcon
                  icon={faNoteSticky}
                />

                <span>
                  Lưu ghi chú nội bộ
                </span>

              </button>

              {/* CANCEL */}

              <button
                type="button"
                onClick={
                  handleCancelRequest
                }
                disabled={
                  closingRequest
                }
                className="admin-consultation-detail-action admin-consultation-detail-action-danger"
              >

                <FontAwesomeIcon
                  icon={faBan}
                />

                <span>
                  {closingRequest
                    ? "Đang đóng..."
                    : "Đóng yêu cầu"}
                </span>

              </button>

            </div>
          </section>

          {/* =================================================
              INTERNAL NOTE
          ================================================= */}

          <section className="admin-consultation-detail-card">

            <div className="admin-consultation-detail-card-title">

              <FontAwesomeIcon
                icon={faNoteSticky}
              />

              <h2>
                Ghi chú nội bộ
              </h2>

            </div>

            <textarea
              value={note}
              onChange={(event) =>
                setNote(
                  event.target.value
                )
              }
              className="admin-consultation-detail-note-input"
              placeholder="Nhập ghi chú nội bộ về yêu cầu này..."
              maxLength={500}
            />

            <div className="admin-consultation-detail-note-footer">

              <span>
                {note.length}/500
              </span>

              <button
                type="button"
                onClick={
                  handleAddNote
                }
                disabled={
                  !note.trim() ||
                  savingNote
                }
                className="admin-consultation-detail-save-note"
              >

                <FontAwesomeIcon
                  icon={faNoteSticky}
                />

                Lưu ghi chú

              </button>

            </div>

          </section>

          {/* =================================================
              CASE NOTICE
          ================================================= */}

          <section className="admin-consultation-detail-card">

            <div className="admin-consultation-detail-card-title">

              <FontAwesomeIcon
                icon={faBriefcase}
              />

              <h2>
                Quy trình hồ sơ
              </h2>

            </div>

            <div
              style={{
                padding: "15px",
                lineHeight: "1.7",
                color: "#555",
              }}
            >

              <div>
                <strong>1.</strong>{" "}
                Khách hàng đặt lịch/chọn luật sư.
              </div>

              <div>
                <strong>2.</strong>{" "}
                Yêu cầu tư vấn được tạo.
              </div>

              <div>
                <strong>3.</strong>{" "}
                Luật sư tiếp nhận yêu cầu.
              </div>

              <div>
                <strong>4.</strong>{" "}
                Luật sư tạo hồ sơ vụ án.
              </div>

              <div>
                <strong>5.</strong>{" "}
                Hồ sơ được gắn với khách hàng và luật sư.
              </div>

              <div>
                <strong>6.</strong>{" "}
                Lawyer chỉ được thao tác trên hồ sơ
                được phân công.
              </div>

            </div>

          </section>

        </aside>

      </div>
    </div>
  );
};

export default AdminConsultationDetail;
