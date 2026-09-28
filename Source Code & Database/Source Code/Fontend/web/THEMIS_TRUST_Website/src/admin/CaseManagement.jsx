import { useEffect, useMemo, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faFolderOpen,
  faMagnifyingGlass,
  faEye,
  faFilter,
  faRotate,
  faUser,
  faCalendarDays,
  faCircleCheck,
  faClock,
  faGavel,
  faFileCircleCheck,
  faXmark,
  faPen,
  faTrash,
  faPlus,
  faUpload,
  faDownload,
  faFile,
  faCheck,
  faCircle,
} from "@fortawesome/free-solid-svg-icons";

import { api, getCurrentUser } from "../api/api";
import "../assets/css/admin/AdminPage.css";

const API_BASE =
  import.meta.env.VITE_API_URL ||
  "https://localhost:5001/api";

const API_ROOT =
  API_BASE.replace(/\/api\/?$/, "");

// =========================================================
// HIỂN THỊ LĨNH VỰC PHÁP LÝ
// =========================================================

const LEGAL_AREA_LABELS = {
  civil: "Dân sự",
  criminal: "Hình sự",
  land: "Đất đai",
  marriage: "Hôn nhân và gia đình",
  labor: "Lao động",
  business: "Kinh doanh thương mại",
  commercial: "Kinh doanh thương mại",
  administrative: "Hành chính",
  intellectual: "Sở hữu trí tuệ",
  inheritance: "Thừa kế",
  tax: "Thuế",
  traffic: "Giao thông",
  insurance: "Bảo hiểm",
};

// =========================================================
// FORMAT LĨNH VỰC
// =========================================================

const formatLegalArea = (value) => {
  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  let text = String(value).trim();

  if (!text) {
    return "";
  }

  // [civil] -> civil
  text = text
    .replace(/^\[\s*/, "")
    .replace(/\s*\]$/, "")
    .trim();

  // [Lĩnh vực: civil] -> civil
  text = text
    .replace(
      /^lĩnh\s*vực\s*:\s*/i,
      ""
    )
    .trim();

  const key =
    text
      .toLowerCase()
      .trim();

  return (
    LEGAL_AREA_LABELS[key] ||
    text
  );
};

// =========================================================
// LÀM SẠCH NỘI DUNG HIỂN THỊ
//
// Ví dụ:
//
// [civil] Tranh chấp đất đai
// -> Tranh chấp đất đai
//
// [Lĩnh vực: civil] [Hình thức: Trực tiếp] Tranh chấp
// -> Tranh chấp
// =========================================================

const cleanCaseDisplayText = (value) => {
  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  let text =
    String(value).trim();

  if (!text) {
    return "";
  }

  // Xóa [civil], [land], [criminal]...
  text = text.replace(
    /\[\s*(?:lĩnh\s*vực\s*:\s*)?(civil|criminal|land|marriage|labor|business|commercial|administrative|intellectual|inheritance|tax|traffic|insurance)\s*\]\s*/gi,
    ""
  );

  // Xóa [Lĩnh vực: civil]
  text = text.replace(
    /\[\s*lĩnh\s*vực\s*:\s*[^\]]+\]\s*/gi,
    ""
  );

  // Xóa [Hình thức: Trực tiếp]
  text = text.replace(
    /\[\s*hình\s*thức\s*:\s*[^\]]+\]\s*/gi,
    ""
  );

  // Xóa [Hình thức: Online]
  text = text.replace(
    /\[\s*hình\s*thức\s*:\s*[^\]]+\]\s*/gi,
    ""
  );

  // Xóa khoảng trắng thừa
  text =
    text.replace(
      /\s{2,}/g,
      " "
    );

  return text.trim();
};

// =========================================================
// LẤY TEXT VỤ ÁN ĐỂ HIỂN THỊ
// =========================================================

const getCaseTitle = (item) => {
  if (!item) {
    return "Vụ án chưa đặt tên";
  }

  const value =
    item.title ||
    item.Title ||
    "";

  const cleaned =
    cleanCaseDisplayText(
      value
    );

  return (
    cleaned ||
    "Vụ án chưa đặt tên"
  );
};

// =========================================================
// LẤY TÊN LĨNH VỰC
// =========================================================

const getCaseLegalArea = (item) => {
  if (!item) {
    return "—";
  }

  const value =
    item.practiceAreaName ||
    item.PracticeAreaName ||
    item.practiceArea ||
    item.PracticeArea ||
    "";

  if (!value) {
    return "—";
  }

  return (
    formatLegalArea(value) ||
    "—"
  );
};

// =========================================================
// LẤY DANH SÁCH TÀI LIỆU CỦA VỤ ÁN
//
// Backend có thể trả về field tên khác nhau tùy API
// (files / Files / documents / Documents / attachments...),
// nên chuẩn hoá về 1 mảng duy nhất để tránh trường hợp
// upload xong nhưng không hiển thị vì đọc sai field.
// =========================================================

const getCaseFiles = (item) => {
  if (!item) {
    return [];
  }

  const value =
    item.files ||
    item.Files ||
    item.documents ||
    item.Documents ||
    item.attachments ||
    item.Attachments ||
    [];

  return Array.isArray(value)
    ? value
    : [];
};

// =========================================================
// COMPONENT
// =========================================================

export default function CaseManagement() {
  const currentUser =
    getCurrentUser();

  const userRole =
    String(
      currentUser?.role ||
        currentUser?.Role ||
        ""
    )
      .trim()
      .toLowerCase();

  const isAdmin =
    userRole === "admin";

  const isLawyer =
    userRole === "lawyer";

  const [cases, setCases] =
    useState([]);

  const [loading, setLoading] =
    useState(true);

  const [error, setError] =
    useState("");

  const [search, setSearch] =
    useState("");

  const [status, setStatus] =
    useState("all");

  const [selectedCase, setSelectedCase] =
    useState(null);

  const [showCreate, setShowCreate] =
    useState(false);

  const [showEdit, setShowEdit] =
    useState(false);

  const [showEventForm, setShowEventForm] =
    useState(false);

  const [editingEvent, setEditingEvent] =
    useState(null);

  const [showFileViewer, setShowFileViewer] =
    useState(false);

  const [selectedFile, setSelectedFile] =
    useState(null);

  const [saving, setSaving] =
    useState(false);

  // =========================================================
  // LOAD CASES
  // =========================================================

  const loadCases = async () => {
    try {
      setLoading(true);
      setError("");

      const data =
        await api.get(
          "/cases"
        );

      const list =
        Array.isArray(data)
          ? data
          : data?.items ||
            data?.data ||
            data?.cases ||
            [];

      setCases(list);
    } catch (err) {
      console.error(
        "Load cases error:",
        err
      );

      setCases([]);

      setError(
        err?.message ||
          "Không thể tải danh sách hồ sơ vụ án."
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCases();
  }, []);

  // =========================================================
  // FILTER
  // =========================================================

  const filteredCases =
    useMemo(() => {
      const keyword =
        search
          .trim()
          .toLowerCase();

      return cases.filter(
        (item) => {
          const docket =
            String(
              item.docketNo ||
                item.DocketNo ||
                ""
            ).toLowerCase();

          const title =
            cleanCaseDisplayText(
              item.title ||
                item.Title ||
                ""
            ).toLowerCase();

          const client =
            String(
              item.clientName ||
                item.ClientName ||
                ""
            ).toLowerCase();

          const lawyer =
            String(
              item.lawyerName ||
                item.LawyerName ||
                ""
            ).toLowerCase();

          const legalArea =
            getCaseLegalArea(
              item
            ).toLowerCase();

          const currentStatus =
            String(
              item.status ||
                item.Status ||
                ""
            )
              .trim()
              .toLowerCase();

          const matchesSearch =
            !keyword ||
            docket.includes(
              keyword
            ) ||
            title.includes(
              keyword
            ) ||
            client.includes(
              keyword
            ) ||
            lawyer.includes(
              keyword
            ) ||
            legalArea.includes(
              keyword
            );

          const matchesStatus =
            status === "all" ||
            currentStatus ===
              status;

          return (
            matchesSearch &&
            matchesStatus
          );
        }
      );
    }, [
      cases,
      search,
      status,
    ]);

  // =========================================================
  // STATUS
  // =========================================================

  const getStatusText = (
    value
  ) => {
    switch (
      String(value || "")
        .trim()
        .toLowerCase()
    ) {
      case "filed":
        return "Đã nộp";

      case "in_review":
        return "Đang thụ lý";

      case "hearing":
        return "Đang xét xử";

      case "resolved":
        return "Đã giải quyết";

      default:
        return "Chưa xác định";
    }
  };

  const getStatusClass = (
    value
  ) => {
    switch (
      String(value || "")
        .trim()
        .toLowerCase()
    ) {
      case "resolved":
        return "lawyer-status lawyer-status-success";

      case "hearing":
        return "lawyer-status lawyer-status-info";

      case "in_review":
        return "lawyer-status lawyer-status-warning";

      default:
        return "lawyer-status lawyer-status-warning";
    }
  };

  const getStatusIcon = (
    value
  ) => {
    switch (
      String(value || "")
        .trim()
        .toLowerCase()
    ) {
      case "resolved":
        return faCircleCheck;

      case "hearing":
        return faGavel;

      case "in_review":
        return faClock;

      default:
        return faFileCircleCheck;
    }
  };

  // =========================================================
  // DATE
  // =========================================================

  const formatDate = (
    value
  ) => {
    if (!value) {
      return "—";
    }

    const date =
      new Date(value);

    if (
      Number.isNaN(
        date.getTime()
      )
    ) {
      return "—";
    }

    return date.toLocaleDateString(
      "vi-VN"
    );
  };

  const formatDateTime = (
    value
  ) => {
    if (!value) {
      return "—";
    }

    const date =
      new Date(value);

    if (
      Number.isNaN(
        date.getTime()
      )
    ) {
      return "—";
    }

    return date.toLocaleString(
      "vi-VN"
    );
  };

  // =========================================================
  // VIEW DETAIL
  // =========================================================

  const handleView =
    async (id) => {
      try {
        setError("");

        const data =
          await api.get(
            `/cases/${id}`
          );

        setSelectedCase(
          data
        );
      } catch (err) {
        console.error(
          "View case error:",
          err
        );

        setError(
          err?.message ||
            "Không thể tải chi tiết hồ sơ."
        );
      }
    };

  // =========================================================
  // DELETE CASE
  // =========================================================

  const handleDeleteCase =
    async () => {
      if (!selectedCase) {
        return;
      }

      const title =
        getCaseTitle(
          selectedCase
        );

      const ok =
        window.confirm(
          `Bạn có chắc muốn xóa hồ sơ "${title}" không?`
        );

      if (!ok) {
        return;
      }

      try {
        setSaving(true);

        await api.delete(
          `/cases/${selectedCase.id}`
        );

        setSelectedCase(
          null
        );

        await loadCases();
      } catch (err) {
        alert(
          err?.message ||
            "Không thể xóa hồ sơ."
        );
      } finally {
        setSaving(false);
      }
    };

  // =========================================================
  // DELETE EVENT
  // =========================================================

  const handleDeleteEvent =
    async (eventId) => {
      if (!selectedCase) {
        return;
      }

      const ok =
        window.confirm(
          "Bạn có chắc muốn xóa sự kiện này?"
        );

      if (!ok) {
        return;
      }

      try {
        await api.delete(
          `/cases/events/${eventId}`
        );

        await handleView(
          selectedCase.id
        );
      } catch (err) {
        alert(
          err?.message ||
            "Không thể xóa sự kiện."
        );
      }
    };

  // =========================================================
  // TOGGLE EVENT
  // =========================================================

  const handleToggleEvent =
    async (eventId) => {
      if (!selectedCase) {
        return;
      }

      try {
        await api.patch(
          `/cases/events/${eventId}/toggle-done`
        );

        await handleView(
          selectedCase.id
        );
      } catch (err) {
        alert(
          err?.message ||
            "Không thể cập nhật sự kiện."
        );
      }
    };

  // =========================================================
  // CREATE CASE
  // =========================================================

  const handleCreate =
    async (payload) => {
      try {
        setSaving(true);

        const created =
          await api.post(
            "/cases",
            payload
          );

        setShowCreate(
          false
        );

        await loadCases();

        const caseId =
          created?.id ||
          created?.Id;

        if (caseId) {
          await handleView(
            caseId
          );
        }
      } catch (err) {
        console.error(
          "Create case error:",
          err
        );

        alert(
          err?.message ||
            "Không thể tạo hồ sơ."
        );
      } finally {
        setSaving(false);
      }
    };

  // =========================================================
  // UPDATE CASE
  // =========================================================

  const handleUpdate =
    async (payload) => {
      if (!selectedCase) {
        return;
      }

      try {
        setSaving(true);

        await api.put(
          `/cases/${selectedCase.id}`,
          payload
        );

        setShowEdit(
          false
        );

        await loadCases();

        await handleView(
          selectedCase.id
        );
      } catch (err) {
        console.error(
          "Update case error:",
          err
        );

        alert(
          err?.message ||
            "Không thể cập nhật hồ sơ."
        );
      } finally {
        setSaving(false);
      }
    };

  // =========================================================
  // CREATE EVENT
  // =========================================================

  const handleCreateEvent =
    async (payload) => {
      if (!selectedCase) {
        return;
      }

      try {
        setSaving(true);

        await api.post(
          `/cases/${selectedCase.id}/events`,
          payload
        );

        setShowEventForm(
          false
        );

        await handleView(
          selectedCase.id
        );
      } catch (err) {
        console.error(
          "Create event error:",
          err
        );

        alert(
          err?.message ||
            "Không thể tạo sự kiện."
        );
      } finally {
        setSaving(false);
      }
    };

  // =========================================================
  // UPDATE EVENT
  // =========================================================

  const handleUpdateEvent =
    async (payload) => {
      if (
        !selectedCase ||
        !editingEvent
      ) {
        return;
      }

      try {
        setSaving(true);

        await api.put(
          `/cases/events/${editingEvent.id}`,
          payload
        );

        setEditingEvent(
          null
        );

        await handleView(
          selectedCase.id
        );
      } catch (err) {
        console.error(
          "Update event error:",
          err
        );

        alert(
          err?.message ||
            "Không thể cập nhật sự kiện."
        );
      } finally {
        setSaving(false);
      }
    };

  // =========================================================
  // UPLOAD FILE
  // =========================================================

  const handleUploadFile = async (event) => {
    if (!selectedCase) {
      return;
    }

    const file = event.target.files?.[0];

    if (!file) {
      return;
    }

    try {
      setSaving(true);

      const formData = new FormData();

      formData.append("file", file);

      console.log(
        "UPLOAD CASE DOCUMENT:",
        selectedCase.id,
        file.name
      );

      // Backend sử dụng:
      // POST /api/cases/{id}/documents
      //
      // LƯU Ý: khi gửi FormData, KHÔNG được tự set header
      // Content-Type: application/json (hoặc bất kỳ Content-Type
      // thủ công nào) trong hàm api.post, nếu không multipart
      // boundary sẽ bị hỏng và backend không nhận được file
      // đúng cách (upload "thành công" nhưng file rỗng/không lưu).
      await api.post(
        `/cases/${selectedCase.id}/documents`,
        formData
      );

      alert("Tải tài liệu lên thành công.");

      // Load lại hồ sơ để hiển thị tài liệu vừa upload
      await handleView(selectedCase.id);
    } catch (err) {
      console.error(
        "Upload file error:",
        err
      );

      alert(
        err?.message ||
          "Không thể tải tài liệu lên."
      );
    } finally {
      setSaving(false);

      event.target.value = "";
    }
  };

  // =========================================================
  // VIEW FILE
  // =========================================================

  const handleViewFile =
    (file) => {
      setSelectedFile(
        file
      );

      setShowFileViewer(
        true
      );
    };

  // =========================================================
  // DOWNLOAD FILE
  // =========================================================

  const handleDownloadFile =
    async (file) => {
      if (!file) {
        return;
      }

      const fileUrl =
        file.url ||
        file.fileUrl ||
        file.path ||
        file.filePath;

      if (!fileUrl) {
        alert(
          "Không tìm thấy đường dẫn file."
        );

        return;
      }

      window.open(
        fileUrl.startsWith("http")
          ? fileUrl
          : `${API_ROOT}${fileUrl}`,
        "_blank"
      );
    };

  // =========================================================
  // DELETE FILE
  //
  // Route dưới đây là giả định (DELETE /cases/documents/{id}).
  // Hãy đổi lại cho khớp với route thật của backend, ví dụ:
  // /cases/{caseId}/documents/{fileId}
  // =========================================================

  const handleDeleteFile =
    async (fileId) => {
      if (!selectedCase || !fileId) {
        return;
      }

      const ok = window.confirm(
        "Bạn có chắc muốn xóa tài liệu này?"
      );

      if (!ok) {
        return;
      }

      try {
        setSaving(true);

        await api.delete(
          `/cases/documents/${fileId}`
        );

        await handleView(
          selectedCase.id
        );
      } catch (err) {
        console.error(
          "Delete file error:",
          err
        );

        alert(
          err?.message ||
            "Không thể xóa tài liệu."
        );
      } finally {
        setSaving(false);
      }
    };

  // =========================================================
  // LOADING
  // =========================================================

  if (loading) {
    return (
      <div className="lawyer-page">
        <div className="lawyer-loading">
          Đang tải hồ sơ vụ án...
        </div>
      </div>
    );
  }

  // =========================================================
  // RETURN
  // =========================================================

  return (
    <div className="lawyer-page">

      {/* =====================================================
          HEADER
      ===================================================== */}

      <div className="lawyer-page-header">

        <div>

          <div className="lawyer-page-title">

            <FontAwesomeIcon
              icon={faFolderOpen}
            />

            <h1>
              Hồ sơ vụ án
            </h1>

          </div>

          <p>
            Quản lý và theo dõi hồ sơ vụ án
          </p>

        </div>

        <div
          style={{
            display: "flex",
            gap: "10px",
          }}
        >

          {isAdmin && (
            <button
              type="button"
              className="lawyer-primary-button"
              onClick={() =>
                setShowCreate(
                  true
                )
              }
            >

              <FontAwesomeIcon
                icon={faPlus}
              />

              Tạo hồ sơ

            </button>
          )}

          <button
            type="button"
            className="lawyer-refresh-button"
            onClick={
              loadCases
            }
            disabled={
              loading
            }
          >

            <FontAwesomeIcon
              icon={faRotate}
            />

            Làm mới

          </button>

        </div>

      </div>

      {/* =====================================================
          ERROR
      ===================================================== */}

      {error && (
        <div className="lawyer-message lawyer-message-error">
          {error}
        </div>
      )}

      {/* =====================================================
          TOOLBAR
      ===================================================== */}

      <div className="lawyer-toolbar">

        <div className="lawyer-search">

          <FontAwesomeIcon
            icon={
              faMagnifyingGlass
            }
          />

          <input
            value={search}
            onChange={(e) =>
              setSearch(
                e.target.value
              )
            }
            placeholder="Tìm số hồ sơ, tên vụ án, khách hàng..."
          />

        </div>

        <div className="lawyer-filter">

          <FontAwesomeIcon
            icon={faFilter}
          />

          <select
            value={status}
            onChange={(e) =>
              setStatus(
                e.target.value
              )
            }
          >

            <option value="all">
              Tất cả trạng thái
            </option>

            <option value="filed">
              Đã nộp
            </option>

            <option value="in_review">
              Đang thụ lý
            </option>

            <option value="hearing">
              Đang xét xử
            </option>

            <option value="resolved">
              Đã giải quyết
            </option>

          </select>

        </div>

      </div>

      {/* =====================================================
          CARD
      ===================================================== */}

      <div className="lawyer-card">

        <div className="lawyer-card-header">

          <div>

            <h2>
              Danh sách hồ sơ
            </h2>

            <span>
              {filteredCases.length} hồ sơ
            </span>

          </div>

        </div>

        {/* ===================================================
            TABLE
        =================================================== */}

        <div className="lawyer-table-wrapper">

          <table className="lawyer-table">

            <thead>

              <tr>

                <th>
                  SỐ HỒ SƠ
                </th>

                <th>
                  TÊN VỤ ÁN
                </th>

                {/* <th>
                  LĨNH VỰC
                </th> */}

                <th>
                  KHÁCH HÀNG
                </th>

                <th>
                  LUẬT SƯ
                </th>

                <th>
                  NGÀY MỞ
                </th>

                <th>
                  TRẠNG THÁI
                </th>

                <th>
                  THAO TÁC
                </th>

              </tr>

            </thead>

            <tbody>

              {filteredCases.map(
                (item, index) => {

                  const id =
                    item.id ||
                    item.Id ||
                    index;

                  return (
                    <tr key={id}>

                      {/* SỐ HỒ SƠ */}

                      <td>
                        <strong>
                          {item.docketNo ||
                            item.DocketNo ||
                            "—"}
                        </strong>
                      </td>

                      {/* TÊN VỤ ÁN */}

                      <td>

                        <div className="lawyer-main-cell">

                          <div className="lawyer-avatar-small">

                            <FontAwesomeIcon
                              icon={
                                faFolderOpen
                              }
                            />

                          </div>

                          <div>

                            <strong>
                              {getCaseTitle(
                                item
                              )}
                            </strong>

                          </div>

                        </div>

                      </td>

                      {/* LĨNH VỰC */}

                      {/* <td>

                        <span>
                          {getCaseLegalArea(
                            item
                          )}
                        </span>

                      </td> */}

                      {/* KHÁCH HÀNG */}

                      <td>

                        <div className="lawyer-main-cell">

                          <div className="lawyer-avatar-small">

                            <FontAwesomeIcon
                              icon={faUser}
                            />

                          </div>

                          <div>

                            <strong>
                              {item.clientName ||
                                item.ClientName ||
                                "—"}
                            </strong>

                          </div>

                        </div>

                      </td>

                      {/* LUẬT SƯ */}

                      <td>
                        {item.lawyerName ||
                          item.LawyerName ||
                          "—"}
                      </td>

                      {/* NGÀY MỞ */}

                      <td>
                        <span>
                    <FontAwesomeIcon
                      icon={faCalendarDays}
                    />


                  </span>
                        {formatDate(
                          item.openedAt ||
                            item.OpenedAt
                        )}
                      </td>

                      {/* STATUS */}

                      <td>

                        <span
                          className={getStatusClass(
                            item.status ||
                              item.Status
                          )}
                        >

                          <FontAwesomeIcon
                            icon={getStatusIcon(
                              item.status ||
                                item.Status
                            )}
                          />

                          {getStatusText(
                            item.status ||
                              item.Status
                          )}

                        </span>

                      </td>

                      {/* ACTION */}

                      <td>

                        <div
                          style={{
                            display: "flex",
                            gap: 8,
                            flexWrap: "wrap",
                          }}
                        >

                          <button
                            className="lawyer-action-button"
                            onClick={() =>
                              handleView(
                                item.id
                              )
                            }
                          >

                            <FontAwesomeIcon
                              icon={faEye}
                            />

                            Xem

                          </button>

                        </div>

                      </td>

                    </tr>
                  );
                }
              )}

            </tbody>

          </table>

          {!filteredCases.length && (
            <div className="lawyer-empty">

              <FontAwesomeIcon
                icon={
                  faFolderOpen
                }
              />

              <h3>
                Chưa có hồ sơ
              </h3>

              <p>
                Không tìm thấy hồ sơ phù hợp.
              </p>

            </div>
          )}

        </div>

      </div>

      {/* =====================================================
          DETAIL MODAL
      ===================================================== */}

      {selectedCase && (
        <div className="case-modal-overlay">

          <div
            className="case-modal"
            style={{
              maxWidth:
                "1000px",
            }}
          >

            <div className="case-modal-header">

              <div className="case-modal-title">

                <FontAwesomeIcon
                  icon={
                    faFolderOpen
                  }
                />

                <div>

                  <h2>
                    {getCaseTitle(
                      selectedCase
                    )}
                  </h2>

                  <small>
                    Số hồ sơ:{" "}
                    {selectedCase.docketNo ||
                      selectedCase.DocketNo ||
                      "—"}
                  </small>

                </div>

              </div>

              <button
                type="button"
                className="case-modal-close"
                onClick={() =>
                  setSelectedCase(
                    null
                  )
                }
              >

                <FontAwesomeIcon
                  icon={faXmark}
                />

              </button>

            </div>

            <div className="case-modal-body">

              {/* =================================================
                  BASIC INFORMATION
              ================================================= */}

              <div
                style={{
                  display: "grid",
                  gridTemplateColumns:
                    "repeat(2, minmax(0, 1fr))",
                  gap: "16px",
                  marginBottom:
                    "24px",
                }}
              >

                <div>

                  <strong>
                    Tên vụ án
                  </strong>

                  <p>
                    {getCaseTitle(
                      selectedCase
                    )}
                  </p>

                </div>

                <div>

                  <strong>
                    Lĩnh vực pháp lý
                  </strong>

                  <p>
                    {getCaseLegalArea(
                      selectedCase
                    )}
                  </p>

                </div>

                <div>

                  <strong>
                    Khách hàng
                  </strong>

                  <p>
                    {selectedCase.clientName ||
                      selectedCase.ClientName ||
                      "—"}
                  </p>

                </div>

                <div>

                  <strong>
                    Luật sư phụ trách
                  </strong>

                  <p>
                    {selectedCase.lawyerName ||
                      selectedCase.LawyerName ||
                      "—"}
                  </p>

                </div>

                <div>

                  <strong>
                    Tòa án
                  </strong>

                  <p>
                    {selectedCase.courtName ||
                      selectedCase.CourtName ||
                      "—"}
                  </p>

                </div>

                <div>

                  <strong>
                    Ngày mở hồ sơ
                  </strong>

                  <p>
                    {formatDate(
                      selectedCase.openedAt ||
                        selectedCase.OpenedAt
                    )}
                  </p>

                </div>

                <div>

                  <strong>
                    Trạng thái
                  </strong>

                  <p>

                    <span
                      className={getStatusClass(
                        selectedCase.status ||
                          selectedCase.Status
                      )}
                    >

                      <FontAwesomeIcon
                        icon={getStatusIcon(
                          selectedCase.status ||
                            selectedCase.Status
                        )}
                      />

                      {getStatusText(
                        selectedCase.status ||
                          selectedCase.Status
                      )}

                    </span>

                  </p>

                </div>

                <div>

                  <strong>
                    Bước xử lý tiếp theo
                  </strong>

                  <p>
                    {cleanCaseDisplayText(
                      selectedCase.nextStep ||
                        selectedCase.NextStep ||
                        ""
                    ) || "—"}
                  </p>

                </div>

              </div>

              {/* =================================================
                  EVENTS
              ================================================= */}

              <div
                style={{
                  marginBottom:
                    "24px",
                }}
              >

                <div
                  style={{
                    display:
                      "flex",
                    justifyContent:
                      "space-between",
                    alignItems:
                      "center",
                    marginBottom:
                      "12px",
                  }}
                >

                  <h3>
                    Tiến trình vụ án
                  </h3>

                  {isAdmin ||
                  isLawyer ? (
                    <button
                      type="button"
                      className="case-primary-button"
                      onClick={() => {
                        setEditingEvent(
                          null
                        );
                        setShowEventForm(
                          true
                        );
                      }}
                    >

                      <FontAwesomeIcon
                        icon={faPlus}
                      />

                      Thêm sự kiện

                    </button>
                  ) : null}

                </div>

                {selectedCase.events &&
                selectedCase.events.length ? (
                  <div>

                    {selectedCase.events.map(
                      (event) => (
                        <div
                          key={
                            event.id
                          }
                          style={{
                            display:
                              "flex",
                            alignItems:
                              "center",
                            gap:
                              "12px",
                            padding:
                              "12px",
                            borderBottom:
                              "1px solid #e5e7eb",
                          }}
                        >

                          <FontAwesomeIcon
                            icon={
                              event.isDone
                                ? faCircleCheck
                                : faCircle
                            }
                          />

                          <div
                            style={{
                              flex: 1,
                            }}
                          >

                            <strong>
                              {cleanCaseDisplayText(
                                event.title
                              )}
                            </strong>

                            <div>
                              {formatDateTime(
                                event.eventDate
                              )}
                            </div>

                            {event.note && (
                              <small>
                                {cleanCaseDisplayText(
                                  event.note
                                )}
                              </small>
                            )}

                          </div>

                          <button
                            type="button"
                            onClick={() =>
                              handleToggleEvent(
                                event.id
                              )
                            }
                          >
                            {event.isDone
                              ? "Bỏ hoàn thành"
                              : "Hoàn thành"}
                          </button>

                          <button
                            type="button"
                            onClick={() => {
                              setEditingEvent(
                                event
                              );
                              setShowEventForm(
                                true
                              );
                            }}
                          >
                            <FontAwesomeIcon
                              icon={
                                faPen
                              }
                            />
                          </button>

                          {isAdmin && (
                            <button
                              type="button"
                              onClick={() =>
                                handleDeleteEvent(
                                  event.id
                                )
                              }
                            >
                              <FontAwesomeIcon
                                icon={
                                  faTrash
                                }
                              />
                            </button>
                          )}

                        </div>
                      )
                    )}

                  </div>
                ) : (
                  <p>
                    Chưa có sự kiện.
                  </p>
                )}

              </div>

              {/* =================================================
                  FILES
              ================================================= */}

              <div>

                <div
                  style={{
                    display:
                      "flex",
                    justifyContent:
                      "space-between",
                    alignItems:
                      "center",
                    marginBottom:
                      "12px",
                  }}
                >

                  <h3>
                    Tài liệu hồ sơ
                  </h3>

                  {isAdmin ||
                  isLawyer ? (
                    <label className="case-primary-button">

                      <FontAwesomeIcon
                        icon={
                          faUpload
                        }
                      />

                      Tải tài liệu

                      <input
                        type="file"
                        hidden
                        disabled={saving}
                        onChange={
                          handleUploadFile
                        }
                      />

                    </label>
                  ) : null}

                </div>

                {(() => {
                  const caseFiles =
                    getCaseFiles(
                      selectedCase
                    );

                  if (!caseFiles.length) {
                    return (
                      <p>
                        Chưa có tài liệu.
                      </p>
                    );
                  }

                  return (
                    <div>

                      {caseFiles.map(
                        (file, fileIndex) => {

                          const fileId =
                            file.id ||
                            file.Id ||
                            fileIndex;

                          return (
                            <div
                              key={
                                fileId
                              }
                              style={{
                                display:
                                  "flex",
                                alignItems:
                                  "center",
                                gap:
                                  "12px",
                                padding:
                                  "10px",
                                borderBottom:
                                  "1px solid #e5e7eb",
                              }}
                            >

                              <FontAwesomeIcon
                                icon={faFile}
                              />

                              <div
                                style={{
                                  flex: 1,
                                }}
                              >

                                <strong>
                                  {cleanCaseDisplayText(
                                    file.fileName ||
                                      file.FileName ||
                                      file.name ||
                                      "Tài liệu"
                                  )}
                                </strong>

                                {(file.uploadedAt ||
                                  file.UploadedAt) && (
                                  <small>
                                    {" "}
                                    -{" "}
                                    {formatDateTime(
                                      file.uploadedAt ||
                                        file.UploadedAt
                                    )}
                                  </small>
                                )}

                              </div>

                              <button
                                type="button"
                                onClick={() =>
                                  handleViewFile(
                                    file
                                  )
                                }
                              >

                                <FontAwesomeIcon
                                  icon={
                                    faEye
                                  }
                                />

                                Xem

                              </button>

                              <button
                                type="button"
                                onClick={() =>
                                  handleDownloadFile(
                                    file
                                  )
                                }
                              >

                                <FontAwesomeIcon
                                  icon={
                                    faDownload
                                  }
                                />

                                Tải xuống

                              </button>

                              {(isAdmin ||
                                isLawyer) && (
                                <button
                                  type="button"
                                  disabled={saving}
                                  onClick={() =>
                                    handleDeleteFile(
                                      file.id ||
                                        file.Id
                                    )
                                  }
                                >

                                  <FontAwesomeIcon
                                    icon={
                                      faTrash
                                    }
                                  />

                                  Xóa

                                </button>
                              )}

                            </div>
                          );
                        }
                      )}

                    </div>
                  );
                })()}

              </div>

              {/* =================================================
                  ACTIONS
              ================================================= */}

              <div className="case-form-actions">

                <button
                  type="button"
                  className="case-secondary-button"
                  onClick={() =>
                    setSelectedCase(
                      null
                    )
                  }
                >
                  Đóng
                </button>

                {isAdmin ||
                isLawyer ? (
                  <button
                    type="button"
                    className="case-primary-button"
                    onClick={() =>
                      setShowEdit(
                        true
                      )
                    }
                  >

                    <FontAwesomeIcon
                      icon={
                        faPen
                      }
                    />

                    Chỉnh sửa

                  </button>
                ) : null}

                {isAdmin && (
                  <button
                    type="button"
                    className="case-danger-button"
                    onClick={
                      handleDeleteCase
                    }
                    disabled={
                      saving
                    }
                  >

                    <FontAwesomeIcon
                      icon={
                        faTrash
                      }
                    />

                    Xóa hồ sơ

                  </button>
                )}

              </div>

            </div>

          </div>

        </div>
      )}

      {/* =====================================================
          CREATE MODAL
      ===================================================== */}

      {showCreate && (
        <CaseFormModal
          title="Tạo hồ sơ vụ án"
          loading={saving}
          isAdmin={isAdmin}
          onClose={() =>
            setShowCreate(
              false
            )
          }
          onSubmit={
            handleCreate
          }
        />
      )}

      {/* =====================================================
          EDIT MODAL
      ===================================================== */}

      {showEdit &&
        selectedCase && (
          <CaseFormModal
            title="Chỉnh sửa hồ sơ"
            initialData={
              selectedCase
            }
            loading={saving}
            isAdmin={
              isAdmin
            }
            onClose={() =>
              setShowEdit(
                false
              )
            }
            onSubmit={
              handleUpdate
            }
          />
        )}

      {/* =====================================================
          EVENT MODAL
      ===================================================== */}

      {showEventForm && (
        <EventFormModal
          event={
            editingEvent
          }
          loading={saving}
          onClose={() => {
            setShowEventForm(
              false
            );
            setEditingEvent(
              null
            );
          }}
          onSubmit={
            editingEvent
              ? handleUpdateEvent
              : handleCreateEvent
          }
        />
      )}

      {/* =====================================================
          FILE VIEWER
      ===================================================== */}

      {showFileViewer &&
        selectedFile && (
          <div className="case-modal-overlay">

            <div className="case-modal">

              <div className="case-modal-header">

                <div className="case-modal-title">

                  <FontAwesomeIcon
                    icon={
                      faFile
                    }
                  />

                  <h2>
                    {cleanCaseDisplayText(
                      selectedFile.fileName ||
                        selectedFile.FileName ||
                        selectedFile.name ||
                        "Tài liệu"
                    )}
                  </h2>

                </div>

                <button
                  type="button"
                  className="case-modal-close"
                  onClick={() =>
                    setShowFileViewer(
                      false
                    )
                  }
                >

                  <FontAwesomeIcon
                    icon={
                      faXmark
                    }
                  />

                </button>

              </div>

              <div className="case-modal-body">

                {(() => {
                  const url =
                    selectedFile.url ||
                    selectedFile.fileUrl ||
                    selectedFile.path ||
                    selectedFile.filePath;

                  if (!url) {
                    return (
                      <p>
                        Không tìm thấy đường dẫn tài liệu.
                      </p>
                    );
                  }

                  const finalUrl =
                    url.startsWith(
                      "http"
                    )
                      ? url
                      : `${API_ROOT}${url}`;

                  return (
                    <iframe
                      src={
                        finalUrl
                      }
                      title="Xem tài liệu"
                      style={{
                        width:
                          "100%",
                        height:
                          "600px",
                        border:
                          "none",
                      }}
                    />
                  );
                })()}

              </div>

            </div>

          </div>
        )}

    </div>
  );
}

// =============================================================
// CASE FORM MODAL
// =============================================================

function CaseFormModal({
  title,
  initialData,
  loading,
  isAdmin,
  onClose,
  onSubmit,
}) {
  const [form, setForm] =
    useState({
      docketNo:
        initialData?.docketNo ||
        "",

      title:
        cleanCaseDisplayText(
          initialData?.title ||
            ""
        ),

      status:
        initialData?.status ||
        "filed",

      clientId:
        initialData?.clientId ||
        "",

      lawyerId:
        initialData?.lawyerId ||
        "",

      practiceAreaId:
        initialData?.practiceAreaId ||
        "",

      courtName:
        initialData?.courtName ||
        "",

      openedAt:
        initialData?.openedAt
          ? String(
              initialData.openedAt
            ).slice(0, 10)
          : "",

      nextStep:
        cleanCaseDisplayText(
          initialData?.nextStep ||
            ""
        ),

      closedAt:
        initialData?.closedAt
          ? String(
              initialData.closedAt
            ).slice(0, 10)
          : "",
    });

  const change =
    (name) =>
    (e) => {
      setForm(
        (prev) => ({
          ...prev,
          [name]:
            e.target.value,
        })
      );
    };

  const submit =
    (e) => {
      e.preventDefault();

      if (
        !form.title.trim()
      ) {
        alert(
          "Vui lòng nhập tên vụ án."
        );

        return;
      }

      const payload = {
        docketNo:
          form.docketNo.trim(),

        title:
          cleanCaseDisplayText(
            form.title
          ),

        status:
          form.status,

        clientId:
          form.clientId ||
          null,

        lawyerId:
          form.lawyerId ||
          null,

        practiceAreaId:
          form.practiceAreaId
            ? Number(
                form.practiceAreaId
              )
            : null,

        courtName:
          form.courtName.trim() ||
          null,

        openedAt:
          form.openedAt ||
          null,

        nextStep:
          cleanCaseDisplayText(
            form.nextStep
          ) || null,

        closedAt:
          form.closedAt ||
          null,
      };

      if (initialData) {
        delete payload.docketNo;
      }

      onSubmit(
        payload
      );
    };

  return (
    <div className="case-modal-overlay">

      <div className="case-modal">

        <div className="case-modal-header">

          <div className="case-modal-title">

            <FontAwesomeIcon
              icon={
                initialData
                  ? faPen
                  : faPlus
              }
            />

            <h2>
              {title}
            </h2>

          </div>

          <button
            type="button"
            className="case-modal-close"
            onClick={onClose}
          >

            <FontAwesomeIcon
              icon={faXmark}
            />

          </button>

        </div>

        <div className="case-modal-body">

          <form
            className="case-form"
            onSubmit={
              submit
            }
          >

            {!initialData && (
              <>
                <label>
                  Số hồ sơ
                </label>

                <input
                  value={
                    form.docketNo
                  }
                  onChange={change(
                    "docketNo"
                  )}
                  placeholder="VD: HS-2026-001"
                />
              </>
            )}

            <label>
              Tên vụ án
            </label>

            <input
              value={
                form.title
              }
              onChange={change(
                "title"
              )}
              placeholder="Nhập tên vụ án"
            />

            <label>
              Trạng thái
            </label>

            <select
              value={
                form.status
              }
              onChange={change(
                "status"
              )}
            >

              <option value="filed">
                Đã nộp
              </option>

              <option value="in_review">
                Đang thụ lý
              </option>

              <option value="hearing">
                Đang xét xử
              </option>

              <option value="resolved">
                Đã giải quyết
              </option>

            </select>

            {isAdmin && (
              <>
                <label>
                  Client ID
                </label>

                <input
                  value={
                    form.clientId
                  }
                  onChange={change(
                    "clientId"
                  )}
                  placeholder="Guid khách hàng"
                />

                <label>
                  Lawyer ID
                </label>

                <input
                  value={
                    form.lawyerId
                  }
                  onChange={change(
                    "lawyerId"
                  )}
                  placeholder="Guid luật sư"
                />

                <label>
                  Practice Area ID
                </label>

                <input
                  type="number"
                  value={
                    form.practiceAreaId
                  }
                  onChange={change(
                    "practiceAreaId"
                  )}
                  placeholder="ID lĩnh vực"
                />
              </>
            )}

            <label>
              Tòa án
            </label>

            <input
              value={
                form.courtName
              }
              onChange={change(
                "courtName"
              )}
              placeholder="Tên tòa án"
            />

            <label>
              Ngày mở hồ sơ
            </label>

            <input
              type="date"
              value={
                form.openedAt
              }
              onChange={change(
                "openedAt"
              )}
            />

            <label>
              Bước xử lý tiếp theo
            </label>

            <textarea
              value={
                form.nextStep
              }
              onChange={change(
                "nextStep"
              )}
              placeholder="VD: Chờ lịch hòa giải..."
            />

            {form.status ===
              "resolved" && (
              <>
                <label>
                  Ngày giải quyết
                </label>

                <input
                  type="date"
                  value={
                    form.closedAt
                  }
                  onChange={change(
                    "closedAt"
                  )}
                />
              </>
            )}

            <div className="case-form-actions">

              <button
                type="button"
                className="case-secondary-button"
                onClick={onClose}
              >
                Hủy
              </button>

              <button
                type="submit"
                className="case-primary-button"
                disabled={
                  loading
                }
              >

                <FontAwesomeIcon
                  icon={
                    faCheck
                  }
                />

                {loading
                  ? "Đang lưu..."
                  : "Lưu"}

              </button>

            </div>

          </form>

        </div>

      </div>

    </div>
  );
}

// =============================================================
// EVENT FORM MODAL
// =============================================================

function EventFormModal({
  event,
  loading,
  onClose,
  onSubmit,
}) {
  const [form, setForm] =
    useState({
      title:
        cleanCaseDisplayText(
          event?.title ||
            ""
        ),

      eventDate:
        event?.eventDate
          ? String(
              event.eventDate
            ).slice(0, 16)
          : "",

      note:
        cleanCaseDisplayText(
          event?.note ||
            ""
        ),

      isDone:
        event?.isDone ||
        false,

      sortOrder:
        event?.sortOrder ||
        0,
    });

  const change =
    (name) =>
    (e) => {
      const value =
        name ===
        "isDone"
          ? e.target.checked
          : e.target.value;

      setForm(
        (prev) => ({
          ...prev,
          [name]:
            value,
        })
      );
    };

  const submit =
    (e) => {
      e.preventDefault();

      if (
        !form.title.trim()
      ) {
        alert(
          "Vui lòng nhập tên sự kiện."
        );

        return;
      }

      if (
        !form.eventDate
      ) {
        alert(
          "Vui lòng chọn ngày sự kiện."
        );

        return;
      }

      onSubmit({
        title:
          cleanCaseDisplayText(
            form.title
          ),

        eventDate:
          form.eventDate,

        note:
          cleanCaseDisplayText(
            form.note
          ) || null,

        isDone:
          form.isDone,

        sortOrder:
          Number(
            form.sortOrder
          ),
      });
    };

  return (
    <div className="case-modal-overlay">

      <div className="case-modal">

        <div className="case-modal-header">

          <div className="case-modal-title">

            <FontAwesomeIcon
              icon={
                event
                  ? faPen
                  : faPlus
              }
            />

            <h2>
              {event
                ? "Sửa sự kiện"
                : "Thêm sự kiện"}
            </h2>

          </div>

          <button
            type="button"
            className="case-modal-close"
            onClick={onClose}
          >

            <FontAwesomeIcon
              icon={
                faXmark
              }
            />

          </button>

        </div>

        <div className="case-modal-body">

          <form
            className="case-form"
            onSubmit={
              submit
            }
          >

            <label>
              Tên sự kiện
            </label>

            <input
              value={
                form.title
              }
              onChange={change(
                "title"
              )}
              placeholder="VD: Tòa tiếp nhận hồ sơ"
            />

            <label>
              Ngày giờ
            </label>

            <input
              type="datetime-local"
              value={
                form.eventDate
              }
              onChange={change(
                "eventDate"
              )}
            />

            <label>
              Ghi chú
            </label>

            <textarea
              value={
                form.note
              }
              onChange={change(
                "note"
              )}
              placeholder="Nhập ghi chú..."
            />

            <label>
              Thứ tự
            </label>

            <input
              type="number"
              value={
                form.sortOrder
              }
              onChange={change(
                "sortOrder"
              )}
            />

            <label
              style={{
                display:
                  "flex",
                gap: 8,
                alignItems:
                  "center",
              }}
            >

              <input
                type="checkbox"
                checked={
                  form.isDone
                }
                onChange={change(
                  "isDone"
                )}
              />

              Đã hoàn thành

            </label>

            <div className="case-form-actions">

              <button
                type="button"
                className="case-secondary-button"
                onClick={
                  onClose
                }
              >
                Hủy
              </button>

              <button
                type="submit"
                className="case-primary-button"
                disabled={
                  loading
                }
              >

                <FontAwesomeIcon
                  icon={
                    faCheck
                  }
                />

                {loading
                  ? "Đang lưu..."
                  : "Lưu sự kiện"}

              </button>

            </div>

          </form>

        </div>

      </div>

    </div>
  );
}
