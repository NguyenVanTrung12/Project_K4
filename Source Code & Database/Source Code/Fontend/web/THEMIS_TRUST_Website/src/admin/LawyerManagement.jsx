import { useEffect, useMemo, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUserTie,
  faPlus,
  faMagnifyingGlass,
  faChevronDown,
  faFilter,
  faEye,
  faPenToSquare,
  faStar,
  faChevronLeft,
  faChevronRight,
  faLock,
  faLockOpen,
} from "@fortawesome/free-solid-svg-icons";

import "../assets/css/admin/LawyerManagement.css";
import { NavLink, useNavigate } from "react-router-dom";
import { toAvatarUrl } from "../utils/avatar";

/* =========================================================
   API
   =========================================================

   Console của bạn đang gọi:
   https://localhost:5001/api/...

   Vì vậy dùng đúng port 5001.
========================================================= */

const API_URL =
  import.meta.env.VITE_API_URL || "https://localhost:5001/api";

/* =========================================================
   LẤY TOKEN
========================================================= */

const getAuthToken = () => {
  /* -------------------------------------------------------
     1. token
  ------------------------------------------------------- */

  const token = localStorage.getItem("token");

  if (token && token.trim()) {
    return token.trim();
  }

  /* -------------------------------------------------------
     2. accessToken
  ------------------------------------------------------- */

  const accessToken = localStorage.getItem("accessToken");

  if (accessToken && accessToken.trim()) {
    return accessToken.trim();
  }

  /* -------------------------------------------------------
     3. themis_token
  ------------------------------------------------------- */

  const themisToken = localStorage.getItem("themis_token");

  if (themisToken && themisToken.trim()) {
    return themisToken.trim();
  }

  /* -------------------------------------------------------
     4. themis_user
  ------------------------------------------------------- */

  const storedUser = localStorage.getItem("themis_user");

  if (storedUser) {
    try {
      const user = JSON.parse(storedUser);

      const userToken =
        user?.token ||
        user?.Token ||
        user?.accessToken ||
        user?.AccessToken ||
        user?.jwt ||
        user?.Jwt ||
        user?.access_token ||
        user?.access_token?.token ||
        null;

      if (userToken && String(userToken).trim()) {
        return String(userToken).trim();
      }
    } catch (error) {
      console.warn(
        "Không thể đọc dữ liệu themis_user:",
        error
      );
    }
  }

  return null;
};

/* =========================================================
   AVATAR
   Tự quay về icon nếu ảnh không tải được
========================================================= */

const LawyerAvatar = ({ src, name }) => {
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setFailed(false);
  }, [src]);

  if (!src || failed) {
    return <FontAwesomeIcon icon={faUserTie} />;
  }

  return (
    <img
      src={src}
      alt={name}
      onError={() => {
        console.warn(
          "Không tải được ảnh đại diện:",
          src
        );

        setFailed(true);
      }}
    />
  );
};

/* =========================================================
   COMPONENT
========================================================= */

const LawyerManagement = () => {
  const navigate = useNavigate();

  const [lawyers, setLawyers] = useState([]);
  const [practiceAreas, setPracticeAreas] = useState([]);

  const [loading, setLoading] = useState(true);

  const [searchTerm, setSearchTerm] = useState("");

  const [specialtyFilter, setSpecialtyFilter] =
    useState("all");

  const [statusFilter, setStatusFilter] =
    useState("all");

  const [showFilter, setShowFilter] = useState(false);

  const [currentPage, setCurrentPage] = useState(1);

  const lawyersPerPage = 8;

  /* =======================================================
     LOAD LAWYERS
  ======================================================= */

  const loadLawyers = async () => {
    try {
      setLoading(true);

      const response = await fetch(
        `${API_URL}/lawyers`
      );

      if (!response.ok) {
        throw new Error(
          "Không thể lấy danh sách luật sư"
        );
      }

      const data = await response.json();

      const lawyerData = Array.isArray(data)
        ? data
        : data?.items ||
          data?.data ||
          [];

      setLawyers(lawyerData);
    } catch (error) {
      console.error(
        "Lỗi lấy danh sách luật sư:",
        error
      );

      setLawyers([]);
    } finally {
      setLoading(false);
    }
  };

  /* =======================================================
     LOAD PRACTICE AREAS
  ======================================================= */

  const loadPracticeAreas = async () => {
    try {
      const response = await fetch(
        `${API_URL}/practiceareas`
      );

      if (!response.ok) {
        throw new Error(
          "Không thể lấy danh sách lĩnh vực"
        );
      }

      const data = await response.json();

      const areaData = Array.isArray(data)
        ? data
        : data?.items ||
          data?.data ||
          [];

      setPracticeAreas(areaData);
    } catch (error) {
      console.error(
        "Lỗi lấy lĩnh vực:",
        error
      );

      setPracticeAreas([]);
    }
  };

  /* =======================================================
     INITIAL LOAD
  ======================================================= */

  useEffect(() => {
    loadLawyers();
    loadPracticeAreas();
  }, []);

  /* =========================================================
     NORMALIZE LAWYER
  ========================================================= */

  const normalizeLawyer = (lawyer) => {
    const id =
      lawyer.id ??
      lawyer.Id;

    const name =
      lawyer.fullName ||
      lawyer.FullName ||
      lawyer.name ||
      lawyer.Name ||
      lawyer.user?.fullName ||
      lawyer.User?.FullName ||
      "Chưa cập nhật";

    const email =
      lawyer.email ||
      lawyer.Email ||
      lawyer.user?.email ||
      lawyer.User?.Email ||
      "";

    const phone =
      lawyer.phone ||
      lawyer.Phone ||
      lawyer.user?.phone ||
      lawyer.User?.Phone ||
      "";

    /* -------------------------------------------------------
       AVATAR
    ------------------------------------------------------- */

    const avatar = toAvatarUrl(
      lawyer.avatarUrl ||
        lawyer.AvatarUrl ||
        lawyer.avatar ||
        lawyer.Avatar ||
        lawyer.user?.avatarUrl ||
        lawyer.User?.AvatarUrl ||
        ""
    );

    /* -------------------------------------------------------
       EXPERIENCE
    ------------------------------------------------------- */

    const yearsExp =
      lawyer.yearsExp ??
      lawyer.YearsExp ??
      lawyer.experience ??
      lawyer.Experience ??
      0;

    /* -------------------------------------------------------
       RATING
    ------------------------------------------------------- */

    const rating =
      lawyer.ratingAvg ??
      lawyer.RatingAvg ??
      lawyer.rating ??
      lawyer.Rating ??
      0;

    const reviews =
      lawyer.reviewCount ??
      lawyer.ReviewCount ??
      lawyer.reviews ??
      lawyer.Reviews ??
      0;

    /* -------------------------------------------------------
       CREATED AT
    ------------------------------------------------------- */

    const createdAt =
      lawyer.createdAt ||
      lawyer.CreatedAt ||
      lawyer.createdDate ||
      lawyer.CreatedDate ||
      null;

    /* -------------------------------------------------------
       IS AVAILABLE
    -------------------------------------------------------

       Backend:
       Lawyers.IsAvailable
    ------------------------------------------------------- */

    const isAvailable =
      lawyer.isAvailable ??
      lawyer.IsAvailable ??
      true;

    /* -------------------------------------------------------
       STATUS
    ------------------------------------------------------- */

    const status = isAvailable
      ? "Hoạt động"
      : "Tạm ngưng";

    /* -------------------------------------------------------
       PRACTICE AREAS
    ------------------------------------------------------- */

    let specialties = [];

    const areas =
      lawyer.practiceAreas ||
      lawyer.PracticeAreas ||
      [];

    if (Array.isArray(areas)) {
      specialties = areas
        .map((item) => {
          if (typeof item === "string") {
            return item;
          }

          return (
            item.practiceAreaName ||
            item.PracticeAreaName ||
            item.name ||
            item.Name ||
            item.practiceArea?.name ||
            item.practiceArea?.Name ||
            item.PracticeArea?.Name ||
            ""
          );
        })
        .filter(Boolean);
    }

    if (
      specialties.length === 0 &&
      Array.isArray(
        lawyer.practiceAreaNames
      )
    ) {
      specialties =
        lawyer.practiceAreaNames;
    }

    if (
      specialties.length === 0 &&
      lawyer.practiceAreaName
    ) {
      specialties = [
        lawyer.practiceAreaName,
      ];
    }

    if (
      specialties.length === 0 &&
      lawyer.PracticeAreaName
    ) {
      specialties = [
        lawyer.PracticeAreaName,
      ];
    }

    /* -------------------------------------------------------
       TỐI ĐA 3 TAG
    ------------------------------------------------------- */

    const displayedSpecialties =
      specialties.length > 3
        ? [
            ...specialties.slice(0, 2),
            `+${specialties.length - 2}`,
          ]
        : specialties;

    /* -------------------------------------------------------
       RETURN
    ------------------------------------------------------- */

    return {
      id,
      name,
      email,
      phone,
      avatar,

      specialties:
        displayedSpecialties,

      experience:
        `${yearsExp} năm`,

      rating:
        Number(
          rating || 0
        ).toFixed(1),

      reviews:
        Number(
          reviews || 0
        ),

      status,

      isAvailable,

      createdAt,
    };
  };

  /* =========================================================
     NORMALIZED LAWYERS
  ========================================================= */

  const normalizedLawyers = useMemo(() => {
    const list =
      lawyers.map(
        normalizeLawyer
      );

    /* -------------------------------------------------------
       LUẬT SƯ MỚI TẠO LÊN ĐẦU
    ------------------------------------------------------- */

    return [...list].sort(
      (a, b) => {
        if (
          a.createdAt &&
          b.createdAt
        ) {
          return (
            new Date(
              b.createdAt
            ) -
            new Date(
              a.createdAt
            )
          );
        }

        /* ---------------------------------------------------
           FALLBACK ID
        --------------------------------------------------- */

        return String(
          b.id ?? ""
        ).localeCompare(
          String(
            a.id ?? ""
          )
        );
      }
    );
  }, [lawyers]);

  /* =========================================================
     FILTER
  ========================================================= */

  const filteredLawyers =
    useMemo(() => {
      let result = [
        ...normalizedLawyers,
      ];

      /* -----------------------------------------------------
         SEARCH
      ----------------------------------------------------- */

      if (
        searchTerm.trim()
      ) {
        const keyword =
          searchTerm
            .toLowerCase()
            .trim();

        result =
          result.filter(
            (lawyer) =>
              lawyer.name
                .toLowerCase()
                .includes(
                  keyword
                ) ||
              lawyer.email
                .toLowerCase()
                .includes(
                  keyword
                ) ||
              lawyer.phone
                .toLowerCase()
                .includes(
                  keyword
                )
          );
      }

      /* -----------------------------------------------------
         SPECIALTY
      ----------------------------------------------------- */

      if (
        specialtyFilter !==
        "all"
      ) {
        result =
          result.filter(
            (lawyer) =>
              lawyer.specialties.some(
                (specialty) =>
                  specialty
                    .toLowerCase()
                    .includes(
                      specialtyFilter.toLowerCase()
                    )
              )
          );
      }

      /* -----------------------------------------------------
         STATUS
      ----------------------------------------------------- */

      if (
        statusFilter !==
        "all"
      ) {
        result =
          result.filter(
            (lawyer) =>
              lawyer.status ===
              statusFilter
          );
      }

      return result;
    }, [
      normalizedLawyers,
      searchTerm,
      specialtyFilter,
      statusFilter,
    ]);

  /* =========================================================
     PAGINATION
  ========================================================= */

  const totalPages =
    Math.max(
      1,
      Math.ceil(
        filteredLawyers.length /
          lawyersPerPage
      )
    );

  const startIndex =
    (currentPage - 1) *
    lawyersPerPage;

  const currentLawyers =
    filteredLawyers.slice(
      startIndex,
      startIndex +
        lawyersPerPage
    );

  /* ---------------------------------------------------------
     RESET PAGE KHI FILTER
  --------------------------------------------------------- */

  useEffect(() => {
    setCurrentPage(1);
  }, [
    searchTerm,
    specialtyFilter,
    statusFilter,
  ]);

  const changePage = (
    page
  ) => {
    if (
      page < 1 ||
      page > totalPages
    ) {
      return;
    }

    setCurrentPage(page);
  };

  /* =========================================================
     EDIT
  ========================================================= */

  const handleEdit = (
    lawyer
  ) => {
    if (!lawyer.id) {
      alert(
        "Không xác định được ID luật sư."
      );

      return;
    }

    navigate(
      `/admin/lawyers/edit?id=${lawyer.id}`
    );
  };

  /* =========================================================
     LOCK LAWYER
  ========================================================= */

  const handleLock = async (
    lawyer
  ) => {
    const id =
      lawyer.id;

    if (!id) {
      alert(
        "Không xác định được ID luật sư."
      );

      return;
    }

    /* -------------------------------------------------------
       ĐÃ KHÓA THÌ KHÔNG KHÓA LẠI
    ------------------------------------------------------- */

    if (
      lawyer.status ===
      "Tạm ngưng"
    ) {
      alert(
        "Luật sư này đã bị khóa."
      );

      return;
    }

    const confirmed =
      window.confirm(
        `Bạn có chắc muốn khóa tài khoản luật sư "${lawyer.name}" không?\n\n` +
          `Sau khi khóa:\n` +
          `- Luật sư không thể đăng nhập.\n` +
          `- Luật sư không còn trạng thái hoạt động.\n` +
          `- Dữ liệu lịch hẹn, vụ án và lịch sử vẫn được giữ nguyên.`
      );

    if (!confirmed) {
      return;
    }

    try {
      /* -----------------------------------------------------
         TOKEN
      ----------------------------------------------------- */

      const token =
        getAuthToken();

      console.log(
        "LOCK LAWYER - TOKEN:",
        token
          ? "Có token"
          : "Không có token"
      );

      /* -----------------------------------------------------
         KHÔNG CÓ TOKEN
      ----------------------------------------------------- */

      if (!token) {
        alert(
          "Không tìm thấy thông tin đăng nhập. Vui lòng đăng nhập lại."
        );

        navigate("/login");

        return;
      }

      /* -----------------------------------------------------
         API
      ----------------------------------------------------- */

      const response =
        await fetch(
          `${API_URL}/lawyers/${id}/lock`,
          {
            method: "PUT",

            headers: {
              Authorization:
                `Bearer ${token}`,

              Accept:
                "application/json",
            },
          }
        );

      /* -----------------------------------------------------
         RESPONSE ERROR
      ----------------------------------------------------- */

      if (!response.ok) {
        let message =
          "Không thể khóa tài khoản luật sư.";

        try {
          const data =
            await response.json();

          message =
            data?.message ||
            data?.title ||
            data?.detail ||
            message;
        } catch {
          // Không có JSON
        }

        console.error(
          "Lock lawyer failed:",
          response.status,
          message
        );

        /* ---------------------------------------------------
           401
        --------------------------------------------------- */

        if (
          response.status ===
          401
        ) {
          alert(
            "Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại."
          );

          localStorage.removeItem(
            "token"
          );

          localStorage.removeItem(
            "accessToken"
          );

          return;
        }

        /* ---------------------------------------------------
           403
        --------------------------------------------------- */

        if (
          response.status ===
          403
        ) {
          alert(
            "Bạn không có quyền khóa tài khoản luật sư."
          );

          return;
        }

        /* ---------------------------------------------------
           404
        --------------------------------------------------- */

        if (
          response.status ===
          404
        ) {
          alert(
            "Không tìm thấy tài khoản luật sư."
          );

          return;
        }

        throw new Error(
          message
        );
      }

      /* -----------------------------------------------------
         THÀNH CÔNG
      ----------------------------------------------------- */

      const result =
        await response
          .json()
          .catch(
            () => null
          );

      console.log(
        "Lock lawyer success:",
        result
      );

      /* -----------------------------------------------------
         UPDATE STATE
      ----------------------------------------------------- */

      setLawyers(
        (prev) =>
          prev.map(
            (item) => {
              const itemId =
                item.id ??
                item.Id;

              if (
                itemId !== id
              ) {
                return item;
              }

              return {
                ...item,

                /* -------------------------------------------
                   LAWYER
                ------------------------------------------- */

                isAvailable:
                  false,

                IsAvailable:
                  false,

                /* -------------------------------------------
                   USER
                ------------------------------------------- */

                user:
                  item.user
                    ? {
                        ...item.user,

                        isActive:
                          false,

                        IsActive:
                          false,
                      }
                    : item.user,

                User:
                  item.User
                    ? {
                        ...item.User,

                        isActive:
                          false,

                        IsActive:
                          false,
                      }
                    : item.User,
              };
            }
          )
      );

      alert(
        `Đã khóa tài khoản luật sư "${lawyer.name}" thành công.`
      );
    } catch (error) {
      console.error(
        "Lỗi khóa luật sư:",
        error
      );

      alert(
        error.message ||
          "Có lỗi xảy ra khi khóa tài khoản luật sư."
      );
    }
  };

  /* =========================================================
     UNLOCK LAWYER
  ========================================================= */

  const handleUnlock =
    async (
      lawyer
    ) => {
      const id =
        lawyer.id;

      if (!id) {
        alert(
          "Không xác định được ID luật sư."
        );

        return;
      }

      /* -----------------------------------------------------
         ĐANG HOẠT ĐỘNG
      ----------------------------------------------------- */

      if (
        lawyer.status ===
        "Hoạt động"
      ) {
        alert(
          "Luật sư này đang hoạt động."
        );

        return;
      }

      const confirmed =
        window.confirm(
          `Bạn có chắc muốn mở khóa tài khoản luật sư "${lawyer.name}" không?\n\n` +
            `Sau khi mở khóa:\n` +
            `- Luật sư có thể đăng nhập lại.\n` +
            `- Luật sư được hoạt động trở lại.\n` +
            `- Toàn bộ dữ liệu cũ vẫn được giữ nguyên.`
        );

      if (!confirmed) {
        return;
      }

      try {
        /* ---------------------------------------------------
           TOKEN
        --------------------------------------------------- */

        const token =
          getAuthToken();

        console.log(
          "UNLOCK LAWYER - TOKEN:",
          token
            ? "Có token"
            : "Không có token"
        );

        if (!token) {
          alert(
            "Không tìm thấy thông tin đăng nhập. Vui lòng đăng nhập lại."
          );

          navigate("/login");

          return;
        }

        /* ---------------------------------------------------
           API
        --------------------------------------------------- */

        const response =
          await fetch(
            `${API_URL}/lawyers/${id}/unlock`,
            {
              method: "PUT",

              headers: {
                Authorization:
                  `Bearer ${token}`,

                Accept:
                  "application/json",
              },
            }
          );

        /* ---------------------------------------------------
           ERROR
        --------------------------------------------------- */

        if (!response.ok) {
          let message =
            "Không thể mở khóa tài khoản luật sư.";

          try {
            const data =
              await response.json();

            message =
              data?.message ||
              data?.title ||
              data?.detail ||
              message;
          } catch {
            // Không có JSON
          }

          console.error(
            "Unlock lawyer failed:",
            response.status,
            message
          );

          /* -----------------------------------------------
             401
          ----------------------------------------------- */

          if (
            response.status ===
            401
          ) {
            alert(
              "Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại."
            );

            localStorage.removeItem(
              "token"
            );

            localStorage.removeItem(
              "accessToken"
            );

            return;
          }

          /* -----------------------------------------------
             403
          ----------------------------------------------- */

          if (
            response.status ===
            403
          ) {
            alert(
              "Bạn không có quyền mở khóa tài khoản luật sư."
            );

            return;
          }

          /* -----------------------------------------------
             404
          ----------------------------------------------- */

          if (
            response.status ===
            404
          ) {
            alert(
              "Không tìm thấy tài khoản luật sư."
            );

            return;
          }

          throw new Error(
            message
          );
        }

        /* ---------------------------------------------------
           SUCCESS
        --------------------------------------------------- */

        const result =
          await response
            .json()
            .catch(
              () => null
            );

        console.log(
          "Unlock lawyer success:",
          result
        );

        /* ---------------------------------------------------
           UPDATE STATE
        --------------------------------------------------- */

        setLawyers(
          (prev) =>
            prev.map(
              (item) => {
                const itemId =
                  item.id ??
                  item.Id;

                if (
                  itemId !== id
                ) {
                  return item;
                }

                return {
                  ...item,

                  /* -----------------------------------------
                     LAWYER
                  ----------------------------------------- */

                  isAvailable:
                    true,

                  IsAvailable:
                    true,

                  /* -----------------------------------------
                     USER
                  ----------------------------------------- */

                  user:
                    item.user
                      ? {
                          ...item.user,

                          isActive:
                            true,

                          IsActive:
                            true,
                        }
                      : item.user,

                  User:
                    item.User
                      ? {
                          ...item.User,

                          isActive:
                            true,

                          IsActive:
                            true,
                        }
                      : item.User,
                };
              }
            )
        );

        alert(
          `Đã mở khóa tài khoản luật sư "${lawyer.name}" thành công.`
        );
      } catch (error) {
        console.error(
          "Lỗi mở khóa luật sư:",
          error
        );

        alert(
          error.message ||
            "Có lỗi xảy ra khi mở khóa tài khoản luật sư."
        );
      }
    };

  /* =========================================================
     RENDER
  ========================================================= */

  return (
    <section className="lawyer-management">
      <div className="lawyer-management__main">

        {/* =================================================
            HEADER
        ================================================= */}

        <div className="lawyer-management__header">

          <div className="lawyer-management__title">

            <div className="lawyer-management__title-icon">
              <FontAwesomeIcon
                icon={faUserTie}
              />
            </div>

            <div>

              <h1>
                Danh sách luật sư
              </h1>

              <p>
                Quản lý thông tin,
                chuyên môn và trạng
                thái hoạt động của
                luật sư.
              </p>

            </div>

          </div>

          <NavLink
            to="/admin/lawyers/add"
            className="lawyer-management__add"
          >
            <FontAwesomeIcon
              icon={faPlus}
            />

            <span>
              Thêm luật sư
            </span>
          </NavLink>

        </div>

        {/* =================================================
            FILTER
        ================================================= */}

        <div className="lawyer-management__filters">

          {/* SEARCH */}

          <div className="lawyer-management__search">

            <FontAwesomeIcon
              icon={
                faMagnifyingGlass
              }
            />

            <input
              type="text"
              placeholder="Tìm kiếm theo tên, email, số điện thoại..."
              value={
                searchTerm
              }
              onChange={(e) =>
                setSearchTerm(
                  e.target.value
                )
              }
            />

          </div>

          {/* SPECIALTY */}

          <div className="lawyer-management__select">

            <select
              value={
                specialtyFilter
              }
              onChange={(e) =>
                setSpecialtyFilter(
                  e.target.value
                )
              }
            >

              <option value="all">
                Tất cả lĩnh vực hành nghề
              </option>

              {practiceAreas.map(
                (area) => {
                  const id =
                    area.id ??
                    area.Id;

                  const name =
                    area.name ??
                    area.Name;

                  return (
                    <option
                      key={id}
                      value={
                        name?.toLowerCase()
                      }
                    >
                      {name}
                    </option>
                  );
                }
              )}

            </select>

            <FontAwesomeIcon
              icon={
                faChevronDown
              }
            />

          </div>

          {/* STATUS */}

          <div className="lawyer-management__select">

            <select
              value={
                statusFilter
              }
              onChange={(e) =>
                setStatusFilter(
                  e.target.value
                )
              }
            >

              <option value="all">
                Tất cả trạng thái
              </option>

              <option value="Hoạt động">
                Hoạt động
              </option>

              <option value="Tạm ngưng">
                Tạm ngưng
              </option>

            </select>

            <FontAwesomeIcon
              icon={
                faChevronDown
              }
            />

          </div>

          {/* FILTER BUTTON */}

          <button
            type="button"
            className={`lawyer-management__filter ${
              showFilter
                ? "active"
                : ""
            }`}
            onClick={() =>
              setShowFilter(
                !showFilter
              )
            }
          >

            <FontAwesomeIcon
              icon={faFilter}
            />

            <span>
              Lọc
            </span>

          </button>

        </div>

        {/* =================================================
            TABLE
        ================================================= */}

        <div className="lawyer-management__table-wrapper">

          <table className="lawyer-management__table">

            <thead>

              <tr>

                <th className="check-column">
                  <input
                    type="checkbox"
                  />
                </th>

                <th className="number-column">
                  #
                </th>

                <th>
                  Thông tin luật sư
                </th>

                <th>
                  Lĩnh vực hành nghề
                </th>

                <th>
                  Kinh nghiệm
                </th>

                <th>
                  Đánh giá
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

              {loading ? (

                <tr>

                  <td
                    colSpan="8"
                    style={{
                      textAlign:
                        "center",
                      padding:
                        "40px",
                    }}
                  >
                    Đang tải danh sách
                    luật sư...
                  </td>

                </tr>

              ) : (

                currentLawyers.map(
                  (
                    lawyer,
                    index
                  ) => (

                    <tr
                      key={
                        lawyer.id
                      }
                    >

                      {/* CHECKBOX */}

                      <td className="check-column">

                        <input
                          type="checkbox"
                        />

                      </td>

                      {/* NUMBER */}

                      <td className="number-column">

                        {
                          startIndex +
                          index +
                          1
                        }

                      </td>

                      {/* LAWYER */}

                      <td>

                        <div className="lawyer-user">

                          <div className="lawyer-avatar">

                            <LawyerAvatar
                              src={
                                lawyer.avatar
                              }
                              name={
                                lawyer.name
                              }
                            />

                          </div>

                          <div className="lawyer-user-info">

                            <strong>
                              {
                                lawyer.name
                              }
                            </strong>

                            <span>
                              {
                                lawyer.email
                              }
                            </span>

                          </div>

                        </div>

                      </td>

                      {/* SPECIALTIES */}

                      <td>

                        <div className="lawyer-specialties">

                          {lawyer
                            .specialties
                            .length >
                          0 ? (

                            lawyer.specialties.map(
                              (
                                specialty,
                                specialtyIndex
                              ) => (

                                <span
                                  className={
                                    specialty.startsWith(
                                      "+"
                                    )
                                      ? "specialty-more"
                                      : "specialty-tag"
                                  }
                                  key={
                                    specialtyIndex
                                  }
                                >
                                  {
                                    specialty
                                  }
                                </span>

                              )
                            )

                          ) : (

                            <span className="specialty-tag">
                              Chưa cập nhật
                            </span>

                          )}

                        </div>

                      </td>

                      {/* EXPERIENCE */}

                      <td>

                        <span className="lawyer-experience">
                          {
                            lawyer.experience
                          }
                        </span>

                      </td>

                      {/* RATING */}

                      <td>

                        <div className="lawyer-rating">

                          <FontAwesomeIcon
                            icon={
                              faStar
                            }
                          />

                          <span>
                            {
                              lawyer.rating
                            }
                          </span>

                          <small>
                            (
                            {
                              lawyer.reviews
                            }
                            )
                          </small>

                        </div>

                      </td>

                      {/* STATUS */}

                      <td>

                        <span
                          className={`lawyer-status ${
                            lawyer.status ===
                            "Hoạt động"
                              ? "active"
                              : lawyer.status ===
                                "Tạm ngưng"
                              ? "paused"
                              : "stopped"
                          }`}
                        >
                          {
                            lawyer.status
                          }
                        </span>

                      </td>

                      {/* ACTIONS */}

                      <td>

                        <div className="lawyer-actions">

                          {/* VIEW */}

                          <NavLink
                            to={`/admin/lawyers/${lawyer.id}`}
                            title="Xem"
                          >
                            <FontAwesomeIcon
                              icon={
                                faEye
                              }
                            />
                          </NavLink>

                          {/* EDIT */}

                          <button
                            type="button"
                            title="Chỉnh sửa"
                            onClick={() =>
                              handleEdit(
                                lawyer
                              )
                            }
                          >
                            <FontAwesomeIcon
                              icon={
                                faPenToSquare
                              }
                            />
                          </button>

                          {/* =================================================
                              LOCK / UNLOCK
                          ================================================= */}

                          {lawyer.status ===
                          "Hoạt động" ? (

                            <button
                              type="button"
                              className="delete"
                              title="Khóa tài khoản"
                              onClick={() =>
                                handleLock(
                                  lawyer
                                )
                              }
                            >

                              <FontAwesomeIcon
                                icon={
                                  faLock
                                }
                              />

                            </button>

                          ) : (

                            <button
                              type="button"
                              title="Mở khóa tài khoản"
                              onClick={() =>
                                handleUnlock(
                                  lawyer
                                )
                              }
                            >

                              <FontAwesomeIcon
                                icon={
                                  faLockOpen
                                }
                              />

                            </button>

                          )}

                        </div>

                      </td>

                    </tr>

                  )
                )

              )}

            </tbody>

          </table>

          {/* =================================================
              EMPTY
          ================================================= */}

          {!loading &&
            currentLawyers.length ===
              0 && (

              <div className="lawyer-management__empty">

                <FontAwesomeIcon
                  icon={
                    faUserTie
                  }
                />

                <h3>
                  Không tìm thấy luật sư
                </h3>

                <p>
                  Hãy thử thay đổi từ khóa
                  hoặc bộ lọc.
                </p>

              </div>

            )}

        </div>

        {/* =================================================
            FOOTER
        ================================================= */}

        <div className="lawyer-management__footer">

          <span>

            Hiển thị{" "}

            <strong>
              {
                filteredLawyers.length ===
                0
                  ? 0
                  : startIndex +
                    1
              }
            </strong>

            {" - "}

            <strong>
              {
                Math.min(
                  startIndex +
                    lawyersPerPage,
                  filteredLawyers.length
                )
              }
            </strong>

            {" "}của{" "}

            <strong>
              {
                filteredLawyers.length
              }
            </strong>

            {" "}luật sư

          </span>

          <div className="lawyer-pagination">

            {/* PREVIOUS */}

            <button
              type="button"
              disabled={
                currentPage ===
                1
              }
              onClick={() =>
                changePage(
                  currentPage -
                    1
                )
              }
            >
              <FontAwesomeIcon
                icon={
                  faChevronLeft
                }
              />
            </button>

            {/* PAGE NUMBERS */}

            {Array.from(
              {
                length:
                  totalPages,
              },
              (
                _,
                index
              ) =>
                index + 1
            )
              .slice(
                0,
                Math.min(
                  totalPages,
                  5
                )
              )
              .map(
                (page) => (

                  <button
                    type="button"
                    key={
                      page
                    }
                    className={
                      currentPage ===
                      page
                        ? "active"
                        : ""
                    }
                    onClick={() =>
                      changePage(
                        page
                      )
                    }
                  >
                    {
                      page
                    }
                  </button>

                )
              )}

            {/* MORE */}

            {totalPages >
              5 && (
              <>

                <span>
                  ...
                </span>

                <button
                  type="button"
                  onClick={() =>
                    changePage(
                      totalPages
                    )
                  }
                >
                  {
                    totalPages
                  }
                </button>

              </>
            )}

            {/* NEXT */}

            <button
              type="button"
              disabled={
                currentPage ===
                totalPages
              }
              onClick={() =>
                changePage(
                  currentPage +
                    1
                )
              }
            >
              <FontAwesomeIcon
                icon={
                  faChevronRight
                }
              />
            </button>

          </div>

        </div>

      </div>
    </section>
  );
};

export default LawyerManagement;