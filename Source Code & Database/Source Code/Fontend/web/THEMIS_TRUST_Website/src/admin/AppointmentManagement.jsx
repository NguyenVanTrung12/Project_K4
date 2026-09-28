import { useEffect, useMemo, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faCalendarDays,
  faMagnifyingGlass,
  faFilter,
  faRotate,
  faUser,
  faClock,
  faCircleCheck,
  faClockRotateLeft,
  faCircleXmark,
  faLocationDot,
  faFloppyDisk,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../api/api";
import "../assets/css/admin/AdminPage.css";

export default function AppointmentManagement() {
  // =========================================================
  // STATE
  // =========================================================

  const [appointments, setAppointments] = useState([]);

  const [loading, setLoading] = useState(true);

  const [error, setError] = useState("");

  const [search, setSearch] = useState("");

  const [status, setStatus] = useState("all");

  // ID lịch hẹn đang cập nhật
  const [updatingId, setUpdatingId] = useState(null);

  // Trạng thái đang được chọn trên UI
  const [editingStatuses, setEditingStatuses] = useState({});

  // =========================================================
  // LOAD APPOINTMENTS
  // =========================================================

  const loadAppointments = async () => {
    try {
      setLoading(true);
      setError("");

      const data = await api.get("/appointments");

      const list = Array.isArray(data)
        ? data
        : data?.items ||
          data?.data ||
          data?.appointments ||
          [];

      setAppointments(list);

      // Đồng bộ trạng thái hiện tại vào editingStatuses
      const statusMap = {};

      list.forEach((item) => {
        if (item?.id) {
          statusMap[item.id] = String(
            item.status || "pending"
          )
            .trim()
            .toLowerCase();
        }
      });

      setEditingStatuses(statusMap);
    } catch (err) {
      console.error("Load appointments error:", err);

      setAppointments([]);

      setError(
        err?.message ||
          "Không thể tải danh sách lịch hẹn."
      );
    } finally {
      setLoading(false);
    }
  };

  // =========================================================
  // INITIAL LOAD
  // =========================================================

  useEffect(() => {
    loadAppointments();
  }, []);

  // =========================================================
  // LÀM SẠCH NỘI DUNG LỊCH HẸN
  //
  // Ví dụ:
  //
  // [civil] [Trực tiếp] Tranh chấp đất đai
  //             ↓
  // Tranh chấp đất đai
  //
  // [Lĩnh vực: civil] [Hình thức: Trực tiếp]
  // Nội dung: Tranh chấp đất đai
  //             ↓
  // Tranh chấp đất đai
  // =========================================================

  const cleanAppointmentDescription = (value) => {
    if (!value) {
      return "Tư vấn pháp lý";
    }

    let text = String(value).trim();

    // -------------------------------------------------------
    // Xóa các cụm [....] ở đầu nội dung
    //
    // Ví dụ:
    // [civil] [Trực tiếp] Tranh chấp đất đai
    // [Lĩnh vực: civil] [Hình thức: Trực tiếp] Nội dung...
    // -------------------------------------------------------

    text = text.replace(
      /^\s*(?:\[[^\]]*\]\s*)+/,
      ""
    );

    // -------------------------------------------------------
    // Xóa "Nội dung:" nếu backend/frontend có thêm
    // -------------------------------------------------------

    text = text.replace(
      /^\s*Nội dung\s*:\s*/i,
      ""
    );

    // -------------------------------------------------------
    // Một số trường hợp text có:
    //
    // Lĩnh vực: civil
    // Hình thức: Trực tiếp
    // Nội dung: ...
    //
    // thì lấy phần sau "Nội dung:"
    // -------------------------------------------------------

    const contentMatch = text.match(
      /(?:^|\s)Nội dung\s*:\s*(.+)$/i
    );

    if (contentMatch?.[1]) {
      text = contentMatch[1].trim();
    }

    // -------------------------------------------------------
    // Nếu sau khi làm sạch vẫn còn [xxx] ở đầu
    // thì tiếp tục xóa
    // -------------------------------------------------------

    text = text.replace(
      /^\s*(?:\[[^\]]*\]\s*)+/,
      ""
    );

    // -------------------------------------------------------
    // Xóa khoảng trắng thừa
    // -------------------------------------------------------

    text = text
      .replace(/\s+/g, " ")
      .trim();

    return text || "Tư vấn pháp lý";
  };

  // =========================================================
  // FILTER
  // =========================================================

  const filteredAppointments = useMemo(() => {
    return appointments.filter((item) => {
      const keyword = search
        .trim()
        .toLowerCase();

      // -----------------------------------------------------
      // CLIENT
      // -----------------------------------------------------

      const client = String(
        item.clientName || ""
      ).toLowerCase();

      // -----------------------------------------------------
      // DESCRIPTION
      //
      // Dùng nội dung đã làm sạch để tìm kiếm
      // -----------------------------------------------------

      const subject = cleanAppointmentDescription(
        item.description
      ).toLowerCase();

      // -----------------------------------------------------
      // STATUS
      // -----------------------------------------------------

      const itemStatus = String(
        item.status || ""
      )
        .trim()
        .toLowerCase();

      // -----------------------------------------------------
      // SEARCH
      // -----------------------------------------------------

      const matchesSearch =
        !keyword ||
        client.includes(keyword) ||
        subject.includes(keyword);

      // -----------------------------------------------------
      // STATUS FILTER
      // -----------------------------------------------------

      const matchesStatus =
        status === "all" ||
        itemStatus === status;

      return (
        matchesSearch &&
        matchesStatus
      );
    });
  }, [
    appointments,
    search,
    status,
  ]);

  // =========================================================
  // STATUS TEXT
  // =========================================================

  const getStatusText = (value) => {
    const s = String(value || "")
      .trim()
      .toLowerCase();

    switch (s) {
      case "confirmed":
        return "Đã xác nhận";

      case "completed":
        return "Hoàn thành";

      case "cancelled":
        return "Đã hủy";

      case "pending":
      default:
        return "Chờ xác nhận";
    }
  };

  // =========================================================
  // STATUS CLASS
  // =========================================================

  const getStatusClass = (value) => {
    const s = String(value || "")
      .trim()
      .toLowerCase();

    switch (s) {
      case "confirmed":
        return "lawyer-status lawyer-status-info";

      case "completed":
        return "lawyer-status lawyer-status-success";

      case "cancelled":
        return "lawyer-status lawyer-status-danger";

      case "pending":
      default:
        return "lawyer-status lawyer-status-warning";
    }
  };

  // =========================================================
  // STATUS ICON
  // =========================================================

  const getStatusIcon = (value) => {
    const s = String(value || "")
      .trim()
      .toLowerCase();

    switch (s) {
      case "confirmed":
        return faCircleCheck;

      case "completed":
        return faCircleCheck;

      case "cancelled":
        return faCircleXmark;

      case "pending":
      default:
        return faClockRotateLeft;
    }
  };

  // =========================================================
  // FORMAT DATE
  // =========================================================

  const formatDate = (value) => {
    if (!value) {
      return "—";
    }

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
      return "—";
    }

    return date.toLocaleDateString("vi-VN");
  };

  // =========================================================
  // FORMAT TIME
  // =========================================================

  const formatTime = (value) => {
    if (!value) {
      return "—";
    }

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
      return "—";
    }

    return date.toLocaleTimeString("vi-VN", {
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  // =========================================================
  // CHANGE STATUS ON UI
  // =========================================================

  const handleStatusChange = (
    appointmentId,
    newStatus
  ) => {
    setEditingStatuses((prev) => ({
      ...prev,
      [appointmentId]: newStatus,
    }));
  };

  // =========================================================
  // UPDATE APPOINTMENT STATUS
  // =========================================================

  const handleUpdateStatus = async (
    appointment
  ) => {
    if (!appointment?.id) {
      alert("Không tìm thấy mã lịch hẹn.");
      return;
    }

    const id = appointment.id;

    const currentStatus = String(
      appointment.status || "pending"
    )
      .trim()
      .toLowerCase();

    const newStatus = String(
      editingStatuses[id] ||
        currentStatus
    )
      .trim()
      .toLowerCase();

    // -------------------------------------------------------
    // Không thay đổi
    // -------------------------------------------------------

    if (newStatus === currentStatus) {
      alert("Trạng thái chưa thay đổi.");
      return;
    }

    // -------------------------------------------------------
    // Validate
    // -------------------------------------------------------

    const validStatuses = [
      "pending",
      "confirmed",
      "completed",
      "cancelled",
    ];

    if (!validStatuses.includes(newStatus)) {
      alert(
        "Trạng thái lịch hẹn không hợp lệ."
      );
      return;
    }

    try {
      setUpdatingId(id);
      setError("");

      await api.patch(
        `/appointments/${id}/status`,
        {
          status: newStatus,
        }
      );

      // -----------------------------------------------------
      // UPDATE LOCAL DATA
      // -----------------------------------------------------

      setAppointments((prev) =>
        prev.map((item) =>
          item.id === id
            ? {
                ...item,
                status: newStatus,
              }
            : item
        )
      );

      // -----------------------------------------------------
      // Đồng bộ editing status
      // -----------------------------------------------------

      setEditingStatuses((prev) => ({
        ...prev,
        [id]: newStatus,
      }));

      alert(
        `Đã cập nhật trạng thái lịch hẹn thành "${getStatusText(
          newStatus
        )}".`
      );
    } catch (err) {
      console.error(
        "Update appointment status error:",
        err
      );

      const message =
        err?.message ||
        "Không thể cập nhật trạng thái lịch hẹn.";

      setError(message);

      alert(
        `Không thể cập nhật trạng thái.\n\n${message}`
      );

      // Nếu lỗi thì đưa dropdown về trạng thái cũ
      setEditingStatuses((prev) => ({
        ...prev,
        [id]: currentStatus,
      }));
    } finally {
      setUpdatingId(null);
    }
  };

  // =========================================================
  // RENDER
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
              icon={faCalendarDays}
            />

            <h1>Lịch hẹn</h1>

          </div>

          <p>
            Theo dõi lịch tư vấn và lịch làm việc
            với khách hàng
          </p>

        </div>

        <button
          type="button"
          className="lawyer-refresh-button"
          onClick={loadAppointments}
          disabled={loading}
        >

          <FontAwesomeIcon
            icon={faRotate}
          />

          {loading
            ? "Đang tải..."
            : "Làm mới"}

        </button>

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

        {/* SEARCH */}

        <div className="lawyer-search">

          <FontAwesomeIcon
            icon={faMagnifyingGlass}
          />

          <input
            type="text"
            placeholder="Tìm theo tên khách hàng hoặc nội dung..."
            value={search}
            onChange={(e) =>
              setSearch(e.target.value)
            }
          />

        </div>

        {/* FILTER STATUS */}

        <div className="lawyer-filter">

          <FontAwesomeIcon
            icon={faFilter}
          />

          <select
            value={status}
            onChange={(e) =>
              setStatus(e.target.value)
            }
          >

            <option value="all">
              Tất cả trạng thái
            </option>

            <option value="pending">
              Chờ xác nhận
            </option>

            <option value="confirmed">
              Đã xác nhận
            </option>

            <option value="completed">
              Hoàn thành
            </option>

            <option value="cancelled">
              Đã hủy
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
              Lịch tư vấn
            </h2>

            <span>
              {filteredAppointments.length} lịch hẹn
            </span>

          </div>

        </div>

        {/* ===================================================
            LOADING
        =================================================== */}

        {loading ? (

          <div className="lawyer-loading">
            Đang tải lịch hẹn...
          </div>

        ) : filteredAppointments.length === 0 ? (

          <div className="lawyer-empty">

            <FontAwesomeIcon
              icon={faCalendarDays}
            />

            <h3>
              Chưa có lịch hẹn
            </h3>

            <p>
              Hiện tại chưa có lịch hẹn phù hợp.
            </p>

          </div>

        ) : (

          <div className="lawyer-table-wrapper">

            <table className="lawyer-table">

              <thead>

                <tr>

                  <th>
                    KHÁCH HÀNG
                  </th>

                  <th>
                    NỘI DUNG
                  </th>

                  <th>
                    NGÀY
                  </th>

                  <th>
                    THỜI GIAN
                  </th>

                  <th>
                    HÌNH THỨC
                  </th>

                  <th>
                    THAO TÁC
                  </th>

                </tr>

              </thead>

              <tbody>

                {filteredAppointments.map(
                  (item, index) => {

                    const id =
                      item.id || index;

                    // ---------------------------------------
                    // Trạng thái hiện tại trong database
                    // ---------------------------------------

                    const currentStatus =
                      String(
                        item.status ||
                          "pending"
                      )
                        .trim()
                        .toLowerCase();

                    // ---------------------------------------
                    // Trạng thái đang chọn
                    // ---------------------------------------

                    const selectedStatus =
                      editingStatuses[id] ||
                      currentStatus;

                    // ---------------------------------------
                    // Kiểm tra thay đổi
                    // ---------------------------------------

                    const hasChanged =
                      selectedStatus !==
                      currentStatus;

                    // ---------------------------------------
                    // Đang cập nhật
                    // ---------------------------------------

                    const isUpdating =
                      updatingId === id;

                    // ---------------------------------------
                    // CLIENT
                    // ---------------------------------------

                    const client =
                      item.clientName ||
                      "Khách hàng";

                    // ---------------------------------------
                    // SUBJECT
                    //
                    // QUAN TRỌNG:
                    // Dùng hàm cleanAppointmentDescription
                    // để loại bỏ [civil], [Trực tiếp]...
                    // ---------------------------------------

                    const subject =
                      cleanAppointmentDescription(
                        item.description
                      );

                    return (

                      <tr key={id}>

                        {/* =================================
                            KHÁCH HÀNG
                        ================================= */}

                        <td>

                          <div className="lawyer-main-cell">

                            <div className="lawyer-avatar-small">

                              <FontAwesomeIcon
                                icon={faUser}
                              />

                            </div>

                            <div>

                              <strong>
                                {client}
                              </strong>

                              <small>
                                {item.clientEmail ||
                                  item.email ||
                                  "—"}
                              </small>

                            </div>

                          </div>

                        </td>

                        {/* =================================
                            NỘI DUNG
                        ================================= */}

                        <td>
                          {subject}
                        </td>

                        {/* =================================
                            NGÀY
                        ================================= */}

                        <td>

                          {formatDate(
                            item.scheduledAt
                          )}

                        </td>

                        {/* =================================
                            THỜI GIAN
                        ================================= */}

                        <td>

                          <div className="lawyer-date-cell">

                            <FontAwesomeIcon
                              icon={faClock}
                            />

                            {formatTime(
                              item.scheduledAt
                            )}

                          </div>

                        </td>

                        {/* =================================
                            HÌNH THỨC
                        ================================= */}

                        <td>

                          <div className="lawyer-date-cell">

                            <FontAwesomeIcon
                              icon={faLocationDot}
                            />

                            {item.meetingType ||
                              item.type ||
                              "Trực tiếp"}

                          </div>

                        </td>

                        {/* =================================
                            THAO TÁC
                        ================================= */}

                        <td>

                          <div
                            style={{
                              display:
                                "flex",
                              alignItems:
                                "center",
                              gap: "8px",
                              minWidth:
                                "230px",
                            }}
                          >

                            {/* SELECT STATUS */}

                            <select
                              value={
                                selectedStatus
                              }
                              disabled={
                                isUpdating
                              }
                              onChange={(e) =>
                                handleStatusChange(
                                  id,
                                  e.target.value
                                )
                              }
                              style={{
                                minWidth:
                                  "145px",
                                height:
                                  "36px",
                                padding:
                                  "0 10px",
                                border:
                                  "1px solid #d1d5db",
                                borderRadius:
                                  "6px",
                                background:
                                  "#fff",
                                cursor:
                                  isUpdating
                                    ? "not-allowed"
                                    : "pointer",
                                outline:
                                  "none",
                              }}
                            >

                              <option value="pending">
                                Chờ xác nhận
                              </option>

                              <option value="confirmed">
                                Đã xác nhận
                              </option>

                              <option value="completed">
                                Hoàn thành
                              </option>

                              <option value="cancelled">
                                Đã hủy
                              </option>

                            </select>

                            {/* UPDATE BUTTON */}

                            <button
                              type="button"
                              disabled={
                                !hasChanged ||
                                isUpdating
                              }
                              onClick={() =>
                                handleUpdateStatus(
                                  item
                                )
                              }
                              title={
                                hasChanged
                                  ? "Cập nhật trạng thái"
                                  : "Chưa có thay đổi"
                              }
                              style={{
                                height:
                                  "36px",
                                padding:
                                  "0 12px",
                                border:
                                  "none",
                                borderRadius:
                                  "6px",
                                background:
                                  hasChanged &&
                                  !isUpdating
                                    ? "#2563eb"
                                    : "#d1d5db",
                                color:
                                  "#fff",
                                cursor:
                                  hasChanged &&
                                  !isUpdating
                                    ? "pointer"
                                    : "not-allowed",
                                display:
                                  "inline-flex",
                                alignItems:
                                  "center",
                                justifyContent:
                                  "center",
                                gap:
                                  "6px",
                                whiteSpace:
                                  "nowrap",
                              }}
                            >

                              <FontAwesomeIcon
                                icon={
                                  faFloppyDisk
                                }
                              />

                              {isUpdating
                                ? "Đang lưu..."
                                : "Cập nhật"}

                            </button>

                          </div>

                        </td>

                      </tr>

                    );
                  }
                )}

              </tbody>

            </table>

          </div>

        )}

      </div>

    </div>
  );
}