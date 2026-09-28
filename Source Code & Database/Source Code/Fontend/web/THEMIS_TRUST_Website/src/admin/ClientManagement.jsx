import { useEffect, useMemo, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUsers,
  faMagnifyingGlass,
  faRotate,
  faUser,
  faEnvelope,
  faPhone,
  faFolderOpen,
} from "@fortawesome/free-solid-svg-icons";

import { api, getCurrentUser } from "../api/api";
import "../assets/css/admin/AdminPage.css";

export default function ClientManagement() {
  const currentUser = getCurrentUser();

  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");

  /**
   * ============================================================
   * XÁC ĐỊNH ROLE HIỆN TẠI
   * ============================================================
   *
   * Một số nơi trong project có thể lưu:
   *   user.role
   *
   * hoặc:
   *   user.Role
   *
   * nên xử lý cả hai.
   */
  const currentRole = String(
    currentUser?.role ||
      currentUser?.Role ||
      ""
  ).toLowerCase();

  /**
   * ============================================================
   * LOAD CLIENTS
   * ============================================================
   *
   * ADMIN:
   *   GET /clients
   *   => xem toàn bộ khách hàng
   *
   * LAWYER:
   *   GET /lawyers/{lawyerId}/clients
   *   => chỉ xem khách hàng liên quan đến lawyer hiện tại
   */
  const loadClients = async () => {
    try {
      setLoading(true);
      setError("");

      if (!currentUser?.id) {
        throw new Error(
          "Không xác định được tài khoản hiện tại."
        );
      }

      let data;

      if (currentRole === "admin") {
        /**
         * ADMIN:
         * Được phép xem toàn bộ khách hàng.
         */
        data = await api.get("/clients");
      } else if (currentRole === "lawyer") {
        /**
         * LAWYER:
         * Chỉ lấy khách hàng của chính Lawyer đang đăng nhập.
         *
         * Tuyệt đối không gọi /clients ở đây.
         */
        data = await api.get(
          `/lawyers/${currentUser.id}/clients`
        );
      } else {
        throw new Error(
          "Bạn không có quyền xem danh sách khách hàng."
        );
      }

      /**
       * API có thể trả về nhiều dạng:
       *
       * [
       *   ...
       * ]
       *
       * hoặc:
       *
       * {
       *   items: [...]
       * }
       *
       * hoặc:
       *
       * {
       *   data: [...]
       * }
       */
      const list = Array.isArray(data)
        ? data
        : data?.items ||
          data?.data ||
          data?.clients ||
          [];

      setClients(
        Array.isArray(list)
          ? list
          : []
      );
    } catch (err) {
      console.error(
        "Load clients error:",
        err
      );

      setClients([]);

      setError(
        err?.message ||
          "Không thể tải danh sách khách hàng."
      );
    } finally {
      setLoading(false);
    }
  };

  /**
   * Load danh sách khi mở trang
   */
  useEffect(() => {
    loadClients();
  }, []);

  /**
   * ============================================================
   * SEARCH CLIENT
   * ============================================================
   */
  const filteredClients = useMemo(() => {
    const keyword =
      search.trim().toLowerCase();

    if (!keyword) {
      return clients;
    }

    return clients.filter((client) => {
      const name = String(
        client.fullName ||
          client.name ||
          client.clientName ||
          client.user?.fullName ||
          client.user?.name ||
          ""
      ).toLowerCase();

      const email = String(
        client.email ||
          client.user?.email ||
          ""
      ).toLowerCase();

      const phone = String(
        client.phone ||
          client.user?.phone ||
          ""
      ).toLowerCase();

      return (
        name.includes(keyword) ||
        email.includes(keyword) ||
        phone.includes(keyword)
      );
    });
  }, [clients, search]);

  /**
   * ============================================================
   * RENDER
   * ============================================================
   */
  return (
    <div className="lawyer-page">

      {/* ======================================================
          HEADER
      ====================================================== */}
      <div className="lawyer-page-header">

        <div>
          <div className="lawyer-page-title">

            <FontAwesomeIcon
              icon={faUsers}
            />

            <h1>Khách hàng</h1>

          </div>

          <p>
            {currentRole === "admin"
              ? "Quản lý thông tin tất cả khách hàng trong hệ thống"
              : "Quản lý thông tin các khách hàng đang làm việc với bạn"}
          </p>
        </div>

        <button
          className="lawyer-refresh-button"
          onClick={loadClients}
          disabled={loading}
        >
          <FontAwesomeIcon
            icon={faRotate}
          />

          Làm mới
        </button>

      </div>

      {/* ======================================================
          ERROR
      ====================================================== */}
      {error && (
        <div className="lawyer-message lawyer-message-error">
          {error}
        </div>
      )}

      {/* ======================================================
          TOOLBAR
      ====================================================== */}
      <div className="lawyer-toolbar">

        <div className="lawyer-search">

          <FontAwesomeIcon
            icon={faMagnifyingGlass}
          />

          <input
            type="text"
            placeholder="Tìm khách hàng..."
            value={search}
            onChange={(e) =>
              setSearch(e.target.value)
            }
          />

        </div>

      </div>

      {/* ======================================================
          CLIENT CARD CONTAINER
      ====================================================== */}
      <div className="lawyer-card">

        <div className="lawyer-card-header">

          <div>

            <h2>
              Danh sách khách hàng
            </h2>

            <span>
              {filteredClients.length} khách hàng
            </span>

          </div>

        </div>

        {/* ====================================================
            LOADING
        ==================================================== */}
        {loading ? (
          <div className="lawyer-loading">
            Đang tải danh sách khách hàng...
          </div>
        ) : filteredClients.length === 0 ? (

          /* ==================================================
             EMPTY
             ================================================== */
          <div className="lawyer-empty">

            <FontAwesomeIcon
              icon={faUsers}
            />

            <h3>
              {search
                ? "Không tìm thấy khách hàng"
                : "Chưa có khách hàng"}
            </h3>

            <p>
              {search
                ? "Không có khách hàng nào phù hợp với từ khóa tìm kiếm."
                : currentRole === "lawyer"
                ? "Bạn chưa có khách hàng nào đang làm việc."
                : "Chưa có khách hàng nào trong hệ thống."}
            </p>

          </div>

        ) : (

          /* ==================================================
             CLIENT LIST
             ================================================== */
          <div className="client-grid">

            {filteredClients.map(
              (client, index) => {

                /**
                 * ID CLIENT
                 */
                const id =
                  client.id ||
                  client.userId ||
                  client.clientId ||
                  client.user?.id ||
                  index;

                /**
                 * TÊN
                 */
                const name =
                  client.fullName ||
                  client.name ||
                  client.clientName ||
                  client.user?.fullName ||
                  client.user?.name ||
                  "Khách hàng";

                /**
                 * EMAIL
                 */
                const email =
                  client.email ||
                  client.user?.email ||
                  "Chưa cập nhật";

                /**
                 * PHONE
                 */
                const phone =
                  client.phone ||
                  client.user?.phone ||
                  "Chưa cập nhật";

                /**
                 * SỐ HỒ SƠ VỤ ÁN
                 */
                const cases =
                  client.caseCount ??
                  client.casesCount ??
                  client.totalCases ??
                  client.caseFilesCount ??
                  0;

                /**
                 * AVATAR
                 */
                const avatarUrl =
                  client.avatarUrl ||
                  client.avatar ||
                  client.user?.avatarUrl ||
                  client.user?.avatar ||
                  "";

                return (
                  <div
                    className="client-card"
                    key={id}
                  >

                    {/* ========================================
                        CLIENT TOP
                    ======================================== */}
                    <div className="client-card-top">

                      <div className="client-avatar">

                        {avatarUrl ? (
                          <img
                            src={avatarUrl}
                            alt={name}
                            onError={(e) => {
                              e.currentTarget.style.display =
                                "none";
                            }}
                          />
                        ) : (
                          <FontAwesomeIcon
                            icon={faUser}
                          />
                        )}

                      </div>

                      <div>

                        <h3>
                          {name}
                        </h3>

                        <span>
                          Khách hàng
                        </span>

                      </div>

                    </div>

                    {/* ========================================
                        CLIENT INFO
                    ======================================== */}
                    <div className="client-info">

                      {/* EMAIL */}
                      <div>

                        <FontAwesomeIcon
                          icon={faEnvelope}
                        />

                        <span>
                          {email}
                        </span>

                      </div>

                      {/* PHONE */}
                      <div>

                        <FontAwesomeIcon
                          icon={faPhone}
                        />

                        <span>
                          {phone}
                        </span>

                      </div>

                      {/* CASES */}
                      <div>

                        <FontAwesomeIcon
                          icon={faFolderOpen}
                        />

                        <span>
                          {cases} hồ sơ vụ án
                        </span>

                      </div>

                    </div>

                    {/* ========================================
                        VIEW BUTTON
                    ======================================== */}
                    <button
                      className="client-view-button"
                      onClick={() =>
                        console.log(
                          "View client:",
                          id,
                          client
                        )
                      }
                    >
                      Xem thông tin
                    </button>

                  </div>
                );
              }
            )}

          </div>
        )}

      </div>

    </div>
  );
}