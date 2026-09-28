import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faFileLines,
  faMagnifyingGlass,
  faChevronDown,
  faCircleCheck,
  faClock,
  faXmark,
  faEye,
  faFolderPlus,
  faSpinner,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../api/api";
import "../../src/assets/css/admin/ConsultationManagement.css";

const LABELS = {
  new: "Mới",
  pending: "Chờ xử lý",
  processing: "Đang xử lý",
  assigned: "Đã phân công",
  completed: "Đã hoàn thành",
  cancelled: "Đã hủy",
};

const ITEMS_PER_PAGE = 8;

export default function ConsultationManagement() {
  const navigate = useNavigate();

  // =========================================================
  // STATE
  // =========================================================

  const [requests, setRequests] = useState([]);

  const [q, setQ] = useState("");

  const [status, setStatus] = useState("all");

  const [page, setPage] = useState(1);

  const [loading, setLoading] = useState(true);

  const [creatingCaseId, setCreatingCaseId] =
    useState(null);

  const [error, setError] = useState("");

  // =========================================================
  // CLEAN REQUEST CONTENT
  //
  // Xử lý các dữ liệu cũ đang bị lưu vào title / description
  //
  // Ví dụ:
  //
  // [civil] Tranh chấp đất đai
  //                 ↓
  // Tranh chấp đất đai
  //
  // [land] [Trực tiếp] Tranh chấp đất đai
  //                 ↓
  // Tranh chấp đất đai
  //
  // [Lĩnh vực: land] [Hình thức: Trực tiếp]
  // Nội dung: Tranh chấp đất đai
  //                 ↓
  // Tranh chấp đất đai
  // =========================================================

  const cleanRequestContent = (value) => {
    if (
      value === undefined ||
      value === null
    ) {
      return "";
    }

    let text = String(value).trim();

    if (!text) {
      return "";
    }

    // -------------------------------------------------------
    // Chuẩn hóa khoảng trắng / xuống dòng
    // -------------------------------------------------------

    text = text
      .replace(/\r\n/g, " ")
      .replace(/\n/g, " ")
      .replace(/\s+/g, " ")
      .trim();

    // -------------------------------------------------------
    // Xóa "Nội dung:" nếu nằm ở đầu
    // -------------------------------------------------------

    text = text.replace(
      /^\s*Nội dung\s*:\s*/i,
      ""
    );

    // -------------------------------------------------------
    // Xóa các block [] nằm ở đầu chuỗi
    //
    // Ví dụ:
    //
    // [civil]
    // [land]
    // [Lĩnh vực: land]
    // [Hình thức: Trực tiếp]
    // [Trực tiếp]
    //
    // đều được xóa.
    // -------------------------------------------------------

    while (
      /^\s*\[[^\]]+\]\s*/.test(text)
    ) {
      text = text.replace(
        /^\s*\[[^\]]+\]\s*/,
        ""
      );
    }

    // -------------------------------------------------------
    // Sau khi xóa block [] có thể còn:
    //
    // Nội dung: Tranh chấp đất đai
    //
    // -------------------------------------------------------

    text = text.replace(
      /^\s*Nội dung\s*:\s*/i,
      ""
    );

    // -------------------------------------------------------
    // Một số dữ liệu có thể có dạng:
    //
    // "Nội dung: [civil] Tranh chấp đất đai"
    //
    // Xóa tiếp nếu còn block [] ở đầu.
    // -------------------------------------------------------

    while (
      /^\s*\[[^\]]+\]\s*/.test(text)
    ) {
      text = text.replace(
        /^\s*\[[^\]]+\]\s*/,
        ""
      );
    }

    // -------------------------------------------------------
    // Xóa "Nội dung:" lần cuối nếu còn.
    // -------------------------------------------------------

    text = text.replace(
      /^\s*Nội dung\s*:\s*/i,
      ""
    );

    return text.trim();
  };

  // =========================================================
  // GET FIELD HELPER
  // =========================================================

  const getValue = (
    object,
    ...names
  ) => {
    for (const name of names) {
      if (
        object &&
        object[name] !== undefined &&
        object[name] !== null
      ) {
        return object[name];
      }
    }

    return null;
  };

  // =========================================================
  // LOAD DATA
  // =========================================================

  const load = async () => {
    try {
      setLoading(true);

      setError("");

      const data =
        await api.get(
          "/consultation-requests"
        );

      const list = Array.isArray(data)
        ? data
        : data?.items ||
          data?.data ||
          data?.requests ||
          [];

      setRequests(list);
    } catch (e) {
      console.error(
        "Lỗi lấy danh sách yêu cầu tư vấn:",
        e
      );

      setError(
        e?.message ||
          "Không thể tải danh sách yêu cầu tư vấn."
      );
    } finally {
      setLoading(false);
    }
  };

  // =========================================================
  // INITIAL LOAD
  // =========================================================

  useEffect(() => {
    load();
  }, []);

  // =========================================================
  // FILTER
  // =========================================================

  const filtered = useMemo(() => {
    return requests.filter((r) => {
      // -----------------------------------------------------
      // Làm sạch nội dung trước khi tìm kiếm
      // -----------------------------------------------------

      const cleanTitle =
        cleanRequestContent(
          r.title
        );

      const cleanDescription =
        cleanRequestContent(
          r.description
        );

      const searchText = [
        cleanTitle,
        cleanDescription,
        r.clientName,
        r.clientEmail,
        r.practiceAreaName,
        r.lawyerName,
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();

      const keyword =
        q.trim().toLowerCase();

      const matchesSearch =
        !keyword ||
        searchText.includes(keyword);

      // -----------------------------------------------------
      // STATUS
      // -----------------------------------------------------

      const itemStatus =
        String(
          r.status || ""
        )
          .trim()
          .toLowerCase();

      const matchesStatus =
        status === "all" ||
        itemStatus === status;

      return (
        matchesSearch &&
        matchesStatus
      );
    });
  }, [
    requests,
    q,
    status,
  ]);

  // =========================================================
  // PAGINATION
  // =========================================================

  const total = Math.max(
    1,
    Math.ceil(
      filtered.length /
        ITEMS_PER_PAGE
    )
  );

  const current =
    filtered.slice(
      (page - 1) *
        ITEMS_PER_PAGE,
      page *
        ITEMS_PER_PAGE
    );

  // =========================================================
  // RESET PAGE WHEN FILTER CHANGES
  // =========================================================

  useEffect(() => {
    setPage(1);
  }, [q, status]);

  // =========================================================
  // UPDATE CONSULTATION
  // =========================================================

  const update = async (
    id,
    newStatus
  ) => {
    try {
      await api.patch(
        `/consultation-requests/${id}`,
        {
          status: newStatus,
        }
      );

      await load();
    } catch (e) {
      console.error(
        "Lỗi cập nhật trạng thái:",
        e
      );

      alert(
        e?.message ||
          "Không thể cập nhật trạng thái."
      );
    }
  };

  // =========================================================
  // VIEW CONSULTATION DETAIL
  // =========================================================

  const handleViewDetail = (
    id
  ) => {
    navigate(
      `/admin/consultations/${id}`
    );
  };

  // =========================================================
  // GENERATE DOCKET NUMBER
  // =========================================================

  const generateDocketNo = () => {
    const now =
      new Date();

    const year =
      now.getFullYear();

    const month =
      String(
        now.getMonth() + 1
      ).padStart(2, "0");

    const day =
      String(
        now.getDate()
      ).padStart(2, "0");

    const random =
      Math.random()
        .toString(36)
        .substring(2, 8)
        .toUpperCase();

    return `HS-${year}${month}${day}-${random}`;
  };

  // =========================================================
  // CREATE CASE
  // =========================================================

  const handleCreateCase =
    async (request) => {
      if (!request?.id) {
        alert(
          "Không tìm thấy mã yêu cầu tư vấn."
        );

        return;
      }

      // -----------------------------------------------------
      // Chỉ tạo hồ sơ khi yêu cầu hoàn thành
      // -----------------------------------------------------

      if (
        request.status !==
        "completed"
      ) {
        alert(
          "Chỉ có thể tạo hồ sơ vụ án sau khi yêu cầu tư vấn đã hoàn thành."
        );

        return;
      }

      // -----------------------------------------------------
      // LAWYER
      // -----------------------------------------------------

      const lawyerId =
        getValue(
          request,
          "lawyerId",
          "LawyerId"
        );

      if (!lawyerId) {
        alert(
          "Yêu cầu tư vấn này chưa có luật sư phụ trách.\n\n" +
            "Vui lòng phân công luật sư trước khi tạo hồ sơ vụ án."
        );

        return;
      }

      // -----------------------------------------------------
      // CLIENT
      // -----------------------------------------------------

      const clientId =
        getValue(
          request,
          "clientId",
          "ClientId"
        );

      if (!clientId) {
        alert(
          "Không tìm thấy mã khách hàng của yêu cầu tư vấn."
        );

        return;
      }

      // -----------------------------------------------------
      // TITLE
      //
      // QUAN TRỌNG:
      // Dùng title đã làm sạch khi tạo hồ sơ.
      // -----------------------------------------------------

      const rawTitle =
        getValue(
          request,
          "title",
          "Title"
        );

      const title =
        cleanRequestContent(
          rawTitle
        ) ||
        "Hồ sơ vụ án";

      // -----------------------------------------------------
      // PRACTICE AREA
      // -----------------------------------------------------

      const practiceAreaId =
        getValue(
          request,
          "practiceAreaId",
          "PracticeAreaId"
        );

      // -----------------------------------------------------
      // CONFIRM
      // -----------------------------------------------------

      const confirmed =
        window.confirm(
          "Bạn có muốn tạo hồ sơ vụ án từ yêu cầu tư vấn này không?\n\n" +
            `Khách hàng: ${
              request.clientName ||
              "--"
            }\n` +
            `Luật sư: ${
              request.lawyerName ||
              "--"
            }\n` +
            `Yêu cầu: ${title}`
        );

      if (!confirmed) {
        return;
      }

      try {
        setCreatingCaseId(
          request.id
        );

        setError("");

        // ---------------------------------------------------
        // TẠO SỐ HỒ SƠ
        // ---------------------------------------------------

        const docketNo =
          generateDocketNo();

        // ---------------------------------------------------
        // REQUEST BODY
        // ---------------------------------------------------

        const payload = {
          docketNo,

          title:
            String(title).trim(),

          clientId,

          lawyerId,

          practiceAreaId:
            practiceAreaId ||
            null,

          courtName: null,

          openedAt:
            new Date().toISOString(),
        };

        console.log(
          "CREATE CASE PAYLOAD:",
          payload
        );

        // ---------------------------------------------------
        // POST CASE
        // ---------------------------------------------------

        const created =
          await api.post(
            "/cases",
            payload
          );

        console.log(
          "CASE CREATED:",
          created
        );

        // ---------------------------------------------------
        // LẤY ID HỒ SƠ
        // ---------------------------------------------------

        const caseId =
          getValue(
            created,
            "id",
            "Id"
          );

        if (!caseId) {
          alert(
            "Hồ sơ đã được tạo nhưng API không trả về mã hồ sơ."
          );

          await load();

          return;
        }

        // ---------------------------------------------------
        // THÔNG BÁO
        // ---------------------------------------------------

        alert(
          "Đã tạo hồ sơ vụ án thành công!\n\n" +
            `Số hồ sơ: ${docketNo}`
        );

        // ---------------------------------------------------
        // LOAD LẠI
        // ---------------------------------------------------

        await load();

        // ---------------------------------------------------
        // ĐI ĐẾN CHI TIẾT
        // ---------------------------------------------------

        navigate("/admin/cases");
      } catch (e) {
        console.error(
          "LỖI TẠO HỒ SƠ VỤ ÁN:",
          e
        );

        const message =
          e?.message ||
          "Không thể tạo hồ sơ vụ án.";

        alert(
          `${message}\n\n` +
            "Vui lòng kiểm tra API /cases và quyền tài khoản."
        );
      } finally {
        setCreatingCaseId(
          null
        );
      }
    };

  // =========================================================
  // CHECK CAN CREATE CASE
  // =========================================================

  const canCreateCase = (
    request
  ) => {
    if (!request) {
      return false;
    }

    // Phải hoàn thành
    if (
      request.status !==
      "completed"
    ) {
      return false;
    }

    // Phải có luật sư
    const lawyerId =
      getValue(
        request,
        "lawyerId",
        "LawyerId"
      );

    if (!lawyerId) {
      return false;
    }

    // Không tạo lại nếu đã có Case
    const caseId =
      getValue(
        request,
        "caseId",
        "CaseId"
      );

    if (caseId) {
      return false;
    }

    return true;
  };

  // =========================================================
  // LOADING
  // =========================================================

  if (loading) {
    return (
      <section className="consultation-management">

        <p>
          Đang tải yêu cầu tư vấn...
        </p>

      </section>
    );
  }

  // =========================================================
  // RETURN
  // =========================================================

  return (
    <section className="consultation-management">

      {/* ===================================================
          ERROR
      =================================================== */}

      {error && (
        <p
          style={{
            padding:
              "15px 20px",
            color:
              "#dc2626",
          }}
        >
          {error}
        </p>
      )}

      {/* ===================================================
          STATISTICS
      =================================================== */}

      <div className="consultation-statistics">

        {/* TOTAL */}

        <div className="consultation-stat-card">

          <div className="consultation-stat-icon blue">

            <FontAwesomeIcon
              icon={faFileLines}
            />

          </div>

          <div className="consultation-stat-content">

            <span className="consultation-stat-title">
              Tổng yêu cầu
            </span>

            <div className="consultation-stat-number-row">

              <strong>
                {requests.length}
              </strong>

            </div>

          </div>

        </div>

        {/* PROCESSING */}

        <div className="consultation-stat-card">

          <div className="consultation-stat-icon orange">

            <FontAwesomeIcon
              icon={faClock}
            />

          </div>

          <div className="consultation-stat-content">

            <span className="consultation-stat-title">
              Đang xử lý
            </span>

            <div className="consultation-stat-number-row">

              <strong>
                {
                  requests.filter(
                    (r) =>
                      r.status ===
                      "processing"
                  ).length
                }
              </strong>

            </div>

          </div>

        </div>

        {/* COMPLETED */}

        <div className="consultation-stat-card">

          <div className="consultation-stat-icon green">

            <FontAwesomeIcon
              icon={
                faCircleCheck
              }
            />

          </div>

          <div className="consultation-stat-content">

            <span className="consultation-stat-title">
              Hoàn thành
            </span>

            <div className="consultation-stat-number-row">

              <strong>
                {
                  requests.filter(
                    (r) =>
                      r.status ===
                      "completed"
                  ).length
                }
              </strong>

            </div>

          </div>

        </div>

        {/* CANCELLED */}

        <div className="consultation-stat-card">

          <div className="consultation-stat-icon red">

            <FontAwesomeIcon
              icon={faXmark}
            />

          </div>

          <div className="consultation-stat-content">

            <span className="consultation-stat-title">
              Đã hủy
            </span>

            <div className="consultation-stat-number-row">

              <strong>
                {
                  requests.filter(
                    (r) =>
                      r.status ===
                      "cancelled"
                  ).length
                }
              </strong>

            </div>

          </div>

        </div>

      </div>

      {/* ===================================================
          LIST CARD
      =================================================== */}

      <div className="consultation-list-card">

        {/* HEADER */}

        <div className="consultation-list-header">

          <div className="consultation-list-title">

            <div className="consultation-list-title-icon">

              <FontAwesomeIcon
                icon={faFileLines}
              />

            </div>

            <div>

              <h1>
                Danh sách yêu cầu tư vấn
              </h1>

              <p>
                Quản lý yêu cầu từ khách
                hàng và cập nhật trạng thái.
              </p>

            </div>

          </div>

        </div>

        {/* =================================================
            FILTER
        ================================================= */}

        <div className="consultation-filter-bar">

          {/* SEARCH */}

          <div className="consultation-search">

            <FontAwesomeIcon
              icon={
                faMagnifyingGlass
              }
            />

            <input
              value={q}
              onChange={(e) =>
                setQ(
                  e.target.value
                )
              }
              placeholder="Tìm khách hàng, tiêu đề, email..."
            />

          </div>

          {/* STATUS */}

          <div className="consultation-select">

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

              <option value="new">
                Mới
              </option>

              <option value="pending">
                Chờ xử lý
              </option>

              <option value="processing">
                Đang xử lý
              </option>

              <option value="assigned">
                Đã phân công
              </option>

              <option value="completed">
                Đã hoàn thành
              </option>

              <option value="cancelled">
                Đã hủy
              </option>

            </select>

            <FontAwesomeIcon
              icon={
                faChevronDown
              }
            />

          </div>

        </div>

        {/* =================================================
            TABLE
        ================================================= */}

        <div className="consultation-table-wrapper">

          <table className="consultation-table">

            <thead>

              <tr>

                <th>
                  Khách hàng
                </th>

                <th>
                  Yêu cầu
                </th>

                {/* <th>
                  Lĩnh vực
                </th> */}

                <th>
                  Ngày gửi
                </th>

                <th>
                  Luật sư
                </th>

                <th>
                  Trạng thái
                </th>

                <th>
                  Thao tác
                </th>

              </tr>

            </thead>

            <tbody>

              {current.map(
                (r) => {

                  const isCreating =
                    creatingCaseId ===
                    r.id;

                  // -------------------------------------------------
                  // LÀM SẠCH TITLE
                  // -------------------------------------------------

                  const cleanTitle =
                    cleanRequestContent(
                      r.title
                    );

                  // -------------------------------------------------
                  // LÀM SẠCH DESCRIPTION
                  // -------------------------------------------------

                  const cleanDescription =
                    cleanRequestContent(
                      r.description
                    );

                  return (
                    <tr
                      key={r.id}
                    >

                      {/* =========================================
                          CLIENT
                      ========================================= */}

                      <td>

                        <div className="consultation-user">

                          <div className="consultation-avatar">

                            {r.clientName
                              ?.charAt(
                                0
                              )
                              ?.toUpperCase() ||
                              "K"}

                          </div>

                          <div className="consultation-user-info">

                            <strong>
                              {r.clientName ||
                                "--"}
                            </strong>

                            <span>
                              {r.clientEmail ||
                                "--"}
                            </span>

                          </div>

                        </div>

                      </td>

                      {/* =========================================
                          REQUEST
                      ========================================= */}

                      <td>

                        <div className="consultation-content">

                          {/* TITLE ĐÃ LÀM SẠCH */}

                          <strong>

                            {cleanTitle ||
                              cleanDescription ||
                              "--"}

                          </strong>

                          {/* DESCRIPTION ĐÃ LÀM SẠCH */}

                          {cleanDescription &&
                            cleanTitle &&
                            cleanDescription !==
                              cleanTitle && (
                              <span>
                                {
                                  cleanDescription
                                }
                              </span>
                            )}

                        </div>

                      </td>

                      {/* =========================================
                          PRACTICE AREA
                      ========================================= */}

                      {/* <td>

                        <span className="consultation-field">

                          {r.practiceAreaName ||
                            "—"}

                        </span>

                      </td> */}

                      {/* =========================================
                          DATE
                      ========================================= */}

                      <td>

                        <div className="consultation-date-admin">

                          <strong>

                            {r.createdAt
                              ? new Date(
                                  r.createdAt
                                ).toLocaleDateString(
                                  "vi-VN"
                                )
                              : "--"}

                          </strong>

                        </div>

                      </td>

                      {/* =========================================
                          LAWYER
                      ========================================= */}

                      <td>

                        <div className="consultation-lawyer">

                          {r.lawyerName ? (
                            r.lawyerName
                          ) : (
                            <span className="not-assigned">
                              Chưa phân công
                            </span>
                          )}

                        </div>

                      </td>

                      {/* =========================================
                          STATUS
                      ========================================= */}

                      <td>

                        <span
                          className={`consultation-status-admin ${
                            r.status ||
                            ""
                          }`}
                        >

                          {LABELS[
                            r.status
                          ] ||
                            r.status ||
                            "--"}

                        </span>

                      </td>

                      {/* =========================================
                          ACTIONS
                      ========================================= */}

                      <td>

                        <div className="consultation-actions-admin">

                          {/* XEM */}

                          <button
                            type="button"
                            onClick={() =>
                              handleViewDetail(
                                r.id
                              )
                            }
                            title="Xem chi tiết yêu cầu"
                          >

                            <FontAwesomeIcon
                              icon={faEye}
                            />

                            <span>
                              Xem
                            </span>

                          </button>

                          {/* XỬ LÝ */}

                          {r.status !==
                            "processing" &&
                            r.status !==
                              "completed" &&
                            r.status !==
                              "cancelled" && (

                              <button
                                type="button"
                                onClick={() =>
                                  update(
                                    r.id,
                                    "processing"
                                  )
                                }
                              >
                                Xử lý
                              </button>

                            )}

                          {/* HOÀN THÀNH */}

                          {r.status ===
                            "processing" && (

                            <button
                              type="button"
                              onClick={() =>
                                update(
                                  r.id,
                                  "completed"
                                )
                              }
                            >
                              Hoàn thành
                            </button>

                          )}

                          {/* TẠO HỒ SƠ */}

                          {canCreateCase(
                            r
                          ) && (

                            <button
                              type="button"
                              onClick={() =>
                                handleCreateCase(
                                  r
                                )
                              }
                              disabled={
                                isCreating
                              }
                              title="Tạo hồ sơ vụ án"
                              className="consultation-create-case-button"
                            >

                              <FontAwesomeIcon
                                icon={
                                  isCreating
                                    ? faSpinner
                                    : faFolderPlus
                                }
                                spin={
                                  isCreating
                                }
                              />

                              <span>

                                {isCreating
                                  ? "Đang tạo..."
                                  : "Tạo hồ sơ"}

                              </span>

                            </button>

                          )}

                          {/* HỦY */}

                          {r.status !==
                            "cancelled" &&
                            r.status !==
                              "completed" && (

                            <button
                              type="button"
                              onClick={() =>
                                update(
                                  r.id,
                                  "cancelled"
                                )
                              }
                            >
                              Hủy
                            </button>

                          )}

                        </div>

                      </td>

                    </tr>
                  );
                }
              )}

            </tbody>

          </table>

          {/* =================================================
              EMPTY
          ================================================= */}

          {!current.length && (

            <div className="consultation-empty">

              Không có yêu cầu phù hợp.

            </div>

          )}

        </div>

        {/* =================================================
            PAGINATION
        ================================================= */}

        <div className="consultation-pagination">

          <button
            disabled={
              page <= 1
            }
            onClick={() =>
              setPage(
                (p) =>
                  p - 1
              )
            }
          >
            ‹
          </button>

          <span>
            Trang {page}/
            {total}
          </span>

          <button
            disabled={
              page >= total
            }
            onClick={() =>
              setPage(
                (p) =>
                  p + 1
              )
            }
          >
            ›
          </button>

        </div>

      </div>

    </section>
  );
}