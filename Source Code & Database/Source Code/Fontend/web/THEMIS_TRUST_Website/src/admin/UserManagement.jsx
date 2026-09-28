import { useEffect, useMemo, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUsers,
  faPlus,
  faMagnifyingGlass,
  faChevronDown,
  faFilter,
  faEye,
  faPenToSquare,
  faEllipsis,
  faUser,
  faChevronLeft,
  faChevronRight,
} from "@fortawesome/free-solid-svg-icons";

import "../assets/css/admin/UserManagement.css";

import { NavLink, useNavigate } from "react-router-dom";
import { api } from "../api/api";
import { toAvatarUrl } from "../utils/avatar";

/* =========================================================
   AVATAR
   Tự quay về icon người nếu ảnh không tải được
========================================================= */

const UserAvatar = ({ src, name }) => {
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
   COMPONENT
========================================================= */

const UserManagement = () => {
  const navigate = useNavigate();

  const [users, setUsers] = useState([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [roleFilter, setRoleFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [sortBy, setSortBy] = useState("newest");
  const [currentPage, setCurrentPage] = useState(1);
  const [showFilter, setShowFilter] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const usersPerPage = 8;

  /* =========================================================
     FORMAT
  ========================================================= */

  const formatDate = (date) => {
    if (!date) return "--";

    const d = new Date(date);

    if (Number.isNaN(d.getTime())) return "--";

    return d.toLocaleDateString("vi-VN");
  };

  const formatTimeAgo = (date) => {
    if (!date) return "--";

    const d = new Date(date);

    if (Number.isNaN(d.getTime())) return "--";

    const diffMinutes = Math.floor((new Date() - d) / 60000);

    if (diffMinutes < 1) return "Vừa xong";
    if (diffMinutes < 60) return `${diffMinutes} phút trước`;

    const diffHours = Math.floor(diffMinutes / 60);

    if (diffHours < 24) return `${diffHours} giờ trước`;

    const diffDays = Math.floor(diffHours / 24);

    if (diffDays === 1) return "1 ngày trước";
    if (diffDays < 30) return `${diffDays} ngày trước`;

    const diffMonths = Math.floor(diffDays / 30);

    if (diffMonths < 12) return `${diffMonths} tháng trước`;

    return `${Math.floor(diffMonths / 12)} năm trước`;
  };

  /* =========================================================
     ROLE / STATUS
  ========================================================= */

  const getRoleType = (role) => {
    const value = String(role || "").toLowerCase();

    if (value === "lawyer") return "lawyer";
    if (value === "admin") return "admin";
    if (value === "staff") return "staff";

    return "user";
  };

  const getRoleName = (role) => {
    const value = String(role || "").toLowerCase();

    switch (value) {
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
        return role || "Không xác định";
    }
  };

  const getStatusName = (isActive) =>
    isActive === true ? "Hoạt động" : "Đã khóa";

  /* =========================================================
     LOAD USERS
  ========================================================= */

  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError("");

      const data = await api.get("/users");

      const rawUsers = Array.isArray(data)
        ? data
        : Array.isArray(data?.data)
          ? data.data
          : Array.isArray(data?.items)
            ? data.items
            : [];

      const mappedUsers = rawUsers.map((item) => {
        const role = item.role || item.Role || "client";
        const isActive = item.isActive ?? item.IsActive ?? true;
        const createdAt = item.createdAt ?? item.CreatedAt ?? null;

        return {
          id: item.id ?? item.Id,

          name:
            item.fullName ??
            item.FullName ??
            item.name ??
            item.Name ??
            "Chưa cập nhật",

          email: item.email ?? item.Email ?? "",

          phone: item.phone ?? item.Phone ?? "--",

          // Ghép địa chỉ backend vào đường dẫn ảnh
          avatar: toAvatarUrl(
            item.avatarUrl ??
              item.AvatarUrl ??
              item.avatar ??
              item.Avatar ??
              null
          ),

          role: getRoleName(role),
          roleType: getRoleType(role),
          registeredAt: formatDate(createdAt),
          createdAt,
          status: getStatusName(isActive),
          isActive,
          activity: formatTimeAgo(createdAt),
        };
      });

      setUsers(mappedUsers);
    } catch (err) {
      console.error("Lỗi lấy danh sách người dùng:", err);

      setError(err?.message || "Không thể tải danh sách người dùng.");

      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  /* =========================================================
     SEARCH + FILTER + SORT
  ========================================================= */

  const filteredUsers = useMemo(() => {
    let result = [...users];

    if (searchTerm.trim()) {
      const keyword = searchTerm.toLowerCase().trim();

      result = result.filter((user) => {
        const name = String(user.name || "").toLowerCase();
        const email = String(user.email || "").toLowerCase();
        const phone = String(user.phone || "").toLowerCase();

        return (
          name.includes(keyword) ||
          email.includes(keyword) ||
          phone.includes(keyword)
        );
      });
    }

    if (roleFilter !== "all") {
      result = result.filter((user) => user.roleType === roleFilter);
    }

    if (statusFilter !== "all") {
      result = result.filter((user) => user.status === statusFilter);
    }

    if (sortBy === "newest") {
      result.sort(
        (a, b) =>
          new Date(b.createdAt || 0).getTime() -
          new Date(a.createdAt || 0).getTime()
      );
    }

    if (sortBy === "oldest") {
      result.sort(
        (a, b) =>
          new Date(a.createdAt || 0).getTime() -
          new Date(b.createdAt || 0).getTime()
      );
    }

    if (sortBy === "name") {
      result.sort((a, b) =>
        String(a.name || "").localeCompare(String(b.name || ""), "vi")
      );
    }

    return result;
  }, [users, searchTerm, roleFilter, statusFilter, sortBy]);

  /* =========================================================
     PAGINATION
  ========================================================= */

  const totalPages = Math.max(
    1,
    Math.ceil(filteredUsers.length / usersPerPage)
  );

  const startIndex = (currentPage - 1) * usersPerPage;

  const currentUsers = filteredUsers.slice(
    startIndex,
    startIndex + usersPerPage
  );

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, roleFilter, statusFilter, sortBy]);

  /* =========================================================
     STATISTICS
  ========================================================= */

  const roleStatistics = useMemo(
    () => ({ total: users.length }),
    [users]
  );

  /* =========================================================
     EVENTS
  ========================================================= */

  const handleAddUser = () => {
    // Chưa có trang tạo user.
    //
    // Khi làm trang này, chỉ cho chọn vai trò: client, staff, admin.
    // KHÔNG cho chọn "lawyer": luật sư phải tạo ở /admin/lawyers/add
    // vì cần tạo cả tài khoản (Users) lẫn hồ sơ nghề nghiệp (Lawyers).
    console.log("Thêm người dùng");
  };

  const handleEditUser = (user) => {
    // Luật sư có hồ sơ nghề nghiệp riêng (chức danh, giấy phép, lĩnh vực...)
    // nên phải sửa ở trang quản lý luật sư.
    if (user.roleType === "lawyer") {
      navigate(`/admin/lawyers/edit?id=${user.id}`);
      return;
    }

    navigate(`/admin/users/${user.id}`);
  };

  const handleMoreUser = (user) => {
    console.log("Thao tác khác:", user);
  };

  /* =========================================================
     RENDER
  ========================================================= */

  return (
    <section className="user-management">
      <div className="user-management__main">
        {/* HEADER */}

        <div className="user-management__header">
          <div className="user-management__title-wrap">
            <div className="user-management__title-icon">
              <FontAwesomeIcon icon={faUsers} />
            </div>

            <div>
              <h1>Danh sách người dùng</h1>

              <p>
                Quản lý thông tin người dùng, trạng thái tài khoản và lịch sử
                hoạt động.
              </p>
            </div>
          </div>

          <button
            type="button"
            className="user-management__add-btn"
            onClick={handleAddUser}
          >
            <FontAwesomeIcon icon={faPlus} />
            <span>Thêm người dùng</span>
          </button>
        </div>

        {/* ERROR */}

        {error && (
          <div
            style={{
              padding: "12px 16px",
              marginBottom: "16px",
              borderRadius: "8px",
              background: "#fff1f0",
              color: "#cf1322",
            }}
          >
            {error}
          </div>
        )}

        {/* FILTER BAR */}

        <div className="user-management__filter-bar">
          <div className="user-management__search">
            <FontAwesomeIcon icon={faMagnifyingGlass} />

            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Tìm kiếm theo tên, email, số điện thoại..."
            />
          </div>

          <div className="user-management__select">
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
            >
              <option value="all">Tất cả vai trò</option>
              <option value="user">Người dùng</option>
              <option value="lawyer">Luật sư</option>
              <option value="staff">Nhân viên</option>
              <option value="admin">Quản trị viên</option>
            </select>

            <FontAwesomeIcon icon={faChevronDown} />
          </div>

          <div className="user-management__select">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="Hoạt động">Hoạt động</option>
              <option value="Đã khóa">Đã khóa</option>
            </select>

            <FontAwesomeIcon icon={faChevronDown} />
          </div>

          <div className="user-management__select">
            <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
              <option value="newest">Sắp xếp: Mới nhất</option>
              <option value="oldest">Sắp xếp: Cũ nhất</option>
              <option value="name">Sắp xếp: Tên</option>
            </select>

            <FontAwesomeIcon icon={faChevronDown} />
          </div>

          <button
            type="button"
            className={`user-management__filter-btn ${
              showFilter ? "active" : ""
            }`}
            onClick={() => setShowFilter(!showFilter)}
          >
            <FontAwesomeIcon icon={faFilter} />
            <span>Lọc</span>
          </button>
        </div>

        {/* EXTRA FILTER */}

        {showFilter && (
          <div className="user-management__extra-filter">
            <span>Bộ lọc nâng cao</span>

            <button
              type="button"
              onClick={() => {
                setSearchTerm("");
                setRoleFilter("all");
                setStatusFilter("all");
                setSortBy("newest");
              }}
            >
              Xóa bộ lọc
            </button>
          </div>
        )}

        {/* LOADING / TABLE */}

        {loading ? (
          <div className="user-management__empty">
            <FontAwesomeIcon icon={faUsers} />
            <h3>Đang tải dữ liệu...</h3>
            <p>Đang lấy danh sách người dùng từ hệ thống.</p>
          </div>
        ) : (
          <>
            <div className="user-management__table-wrap">
              <table className="user-management__table">
                <thead>
                  <tr>
                    <th className="checkbox-col">
                      <input type="checkbox" />
                    </th>
                    <th className="number-col">#</th>
                    <th>Thông tin người dùng</th>
                    <th>Liên hệ</th>
                    <th>Vai trò</th>
                    <th>Ngày đăng ký</th>
                    <th>Trạng thái</th>
                    <th>Hoạt động</th>
                    <th>Thao tác</th>
                  </tr>
                </thead>

                <tbody>
                  {currentUsers.map((user, index) => (
                    <tr key={user.id}>
                      <td className="checkbox-col">
                        <input type="checkbox" />
                      </td>

                      <td className="number-col">{startIndex + index + 1}</td>

                      {/* USER */}

                      <td>
                        <div className="user-management__user">
                          <div className="user-management__avatar">
                            <UserAvatar src={user.avatar} name={user.name} />
                          </div>

                          <div className="user-management__user-text">
                            <strong>{user.name}</strong>
                            <span>{user.email}</span>
                          </div>
                        </div>
                      </td>

                      {/* CONTACT */}

                      <td>
                        <span className="user-management__phone">
                          {user.phone}
                        </span>
                      </td>

                      {/* ROLE */}

                      <td>
                        <span
                          className={`user-management__role ${
                            user.roleType === "lawyer" ? "lawyer" : "user"
                          }`}
                        >
                          {user.role}
                        </span>
                      </td>

                      {/* DATE */}

                      <td>
                        <span className="user-management__date">
                          {user.registeredAt}
                        </span>
                      </td>

                      {/* STATUS */}

                      <td>
                        <span
                          className={`user-management__status ${
                            user.status === "Hoạt động" ? "active" : "locked"
                          }`}
                        >
                          {user.status}
                        </span>
                      </td>

                      {/* ACTIVITY */}

                      <td>
                        <span className="user-management__activity">
                          {user.activity}
                        </span>
                      </td>

                      {/* ACTION */}

                      <td>
                        <div className="user-management__actions">
                          <NavLink
                            to={`/admin/users/${user.id}`}
                            title="Xem chi tiết"
                          >
                            <FontAwesomeIcon icon={faEye} />
                          </NavLink>

                          <button
                            type="button"
                            title={
                              user.roleType === "lawyer"
                                ? "Chỉnh sửa hồ sơ luật sư"
                                : "Chỉnh sửa"
                            }
                            onClick={() => handleEditUser(user)}
                          >
                            <FontAwesomeIcon icon={faPenToSquare} />
                          </button>

                          <button
                            type="button"
                            title="Thêm"
                            onClick={() => handleMoreUser(user)}
                          >
                            <FontAwesomeIcon icon={faEllipsis} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {currentUsers.length === 0 && (
                <div className="user-management__empty">
                  <FontAwesomeIcon icon={faUsers} />
                  <h3>Không tìm thấy người dùng</h3>
                  <p>Hãy thử thay đổi từ khóa hoặc bộ lọc.</p>
                </div>
              )}
            </div>

            {/* FOOTER */}

            <div className="user-management__table-footer">
              <span>
                Hiển thị{" "}
                <strong>
                  {filteredUsers.length === 0 ? 0 : startIndex + 1}
                </strong>
                {" - "}
                <strong>
                  {Math.min(startIndex + usersPerPage, filteredUsers.length)}
                </strong>{" "}
                của{" "}
                <strong>
                  {roleStatistics.total.toLocaleString("vi-VN")}
                </strong>{" "}
                người dùng
              </span>

              <div className="user-management__pagination">
                <button
                  type="button"
                  disabled={currentPage === 1}
                  onClick={() =>
                    setCurrentPage((page) => Math.max(1, page - 1))
                  }
                >
                  <FontAwesomeIcon icon={faChevronLeft} />
                </button>

                {Array.from({ length: totalPages }, (_, index) => index + 1)
                  .slice(0, 5)
                  .map((page) => (
                    <button
                      type="button"
                      key={page}
                      className={currentPage === page ? "active" : ""}
                      onClick={() => setCurrentPage(page)}
                    >
                      {page}
                    </button>
                  ))}

                <button
                  type="button"
                  disabled={currentPage === totalPages}
                  onClick={() =>
                    setCurrentPage((page) => Math.min(totalPages, page + 1))
                  }
                >
                  <FontAwesomeIcon icon={faChevronRight} />
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </section>
  );
};

export default UserManagement;
