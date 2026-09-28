import { useEffect, useMemo, useState } from "react";
import { NavLink } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faMagnifyingGlass,
  faScaleBalanced,
  faClock,
  faStar,
  faEye,
  faCalendarCheck,
  faChevronLeft,
  faChevronRight,
  faChevronDown,
  faSliders,
  faRotateLeft,
  faUserTie,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../../api/api";
import "../../assets/css/lawyerpage/LawyerListSection.css";

/* =====================================================
   CONFIG
===================================================== */

const PER_PAGE = 6;

// Luật sư có điểm từ mức này trở lên được đánh dấu "Nổi bật"
const FEATURED_MIN_RATING = 4.5;

const EXPERIENCE_OPTIONS = [
  { value: "all", label: "Tất cả" },
  { value: "5", label: "Từ 5 năm" },
  { value: "10", label: "Từ 10 năm" },
  { value: "15", label: "Từ 15 năm" },
];

const SORT_OPTIONS = [
  {
    key: "rating",
    label: "Đánh giá cao",
    compare: (a, b) => b.rating - a.rating || b.years - a.years,
  },
  {
    key: "experience",
    label: "Kinh nghiệm",
    compare: (a, b) => b.years - a.years || b.rating - a.rating,
  },
  {
    key: "name",
    label: "Tên A-Z",
    compare: (a, b) => a.name.localeCompare(b.name, "vi"),
  },
];

/* =====================================================
   HELPERS
===================================================== */

const API_ORIGIN = (
  import.meta.env.VITE_API_URL || "https://localhost:5001/api"
).replace(/\/api\/?$/, "");

// Backend trả "/uploads/avatars/abc.jpg" nên cần ghép địa chỉ backend
const toAvatarUrl = (url) => {
  if (!url) return "";

  const value = String(url).trim();

  if (/^(https?:|data:|blob:)/i.test(value)) {
    return value;
  }

  return value.startsWith("/")
    ? `${API_ORIGIN}${value}`
    : `${API_ORIGIN}/${value}`;
};

const toList = (data) =>
  Array.isArray(data) ? data : data?.data || data?.items || [];

// Bỏ dấu để gõ "bao" ra được "Bảo", "dan su" ra được "Dân sự"
const normalizeText = (value) =>
  String(value || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d");

const normalizeLawyer = (item) => {
  const rawAreas = item.practiceAreas ?? item.PracticeAreas ?? [];

  return {
    id: item.id ?? item.Id,
    name: item.fullName ?? item.FullName ?? "Chưa cập nhật",
    title: item.title ?? item.Title ?? "Luật sư",
    avatar: toAvatarUrl(item.avatarUrl ?? item.AvatarUrl ?? ""),
    years: Number(item.yearsExp ?? item.YearsExp ?? 0),
    rating: Number(item.ratingAvg ?? item.RatingAvg ?? 0),
    isAvailable: item.isAvailable ?? item.IsAvailable ?? true,
    areas: Array.isArray(rawAreas)
      ? rawAreas
          .map((area) =>
            typeof area === "string" ? area : area?.name || area?.Name || ""
          )
          .filter(Boolean)
      : [],
  };
};

const getPageNumbers = (current, total) => {
  const size = 5;

  let end = Math.min(total, Math.max(1, current - 2) + size - 1);
  const start = Math.max(1, end - size + 1);

  end = Math.min(total, start + size - 1);

  return Array.from({ length: end - start + 1 }, (_, i) => start + i);
};

/* =====================================================
   ẢNH LUẬT SƯ
   Hiện icon nếu chưa có ảnh hoặc ảnh lỗi
===================================================== */

const LawyerAvatar = ({ src, name }) => {
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setFailed(false);
  }, [src]);

  if (!src || failed) {
    return (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: "#a9b6c4",
          fontSize: "34px",
        }}
      >
        <FontAwesomeIcon icon={faUserTie} />
      </div>
    );
  }

  return (
    <img
      className="lls-avatar"
      src={src}
      alt={name}
      onError={() => {
        console.warn("Không tải được ảnh luật sư:", src);
        setFailed(true);
      }}
    />
  );
};

/* =====================================================
   COMPONENT
===================================================== */

export default function LawyerListSection() {
  const [lawyers, setLawyers] = useState([]);
  const [areas, setAreas] = useState([]);

  const [keyword, setKeyword] = useState("");
  const [selectedAreas, setSelectedAreas] = useState([]);
  const [experience, setExperience] = useState("all");
  const [sortIndex, setSortIndex] = useState(0);

  const [mobileFilterOpen, setMobileFilterOpen] = useState(false);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [page, setPage] = useState(1);

  /* ===================================================
     LOAD DATA
     Lỗi lĩnh vực không làm mất danh sách luật sư
  =================================================== */

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      const [lawyerResult, areaResult] = await Promise.allSettled([
        api.get("/lawyers"),
        api.get("/practiceareas"),
      ]);

      if (cancelled) return;

      if (lawyerResult.status === "fulfilled") {
        setLawyers(toList(lawyerResult.value).map(normalizeLawyer));
      } else {
        console.error("Lỗi lấy danh sách luật sư:", lawyerResult.reason);
        setError("Không thể tải danh sách luật sư.");
      }

      if (areaResult.status === "fulfilled") {
        setAreas(toList(areaResult.value));
      } else {
        console.error("Lỗi lấy lĩnh vực:", areaResult.reason);
      }

      setLoading(false);
    };

    load();

    return () => {
      cancelled = true;
    };
  }, []);

  /* ===================================================
     FILTER + SORT
  =================================================== */

  const filtered = useMemo(() => {
    const kw = normalizeText(keyword.trim());
    const minYears = experience === "all" ? 0 : Number(experience);

    return lawyers
      .filter((lawyer) => {
        // Chỉ hiện luật sư đang hoạt động
        if (!lawyer.isAvailable) return false;

        const text = normalizeText(
          [lawyer.name, lawyer.title, ...lawyer.areas].join(" ")
        );

        const matchKeyword = !kw || text.includes(kw);

        const matchArea =
          selectedAreas.length === 0 ||
          lawyer.areas.some((area) => selectedAreas.includes(area));

        const matchExperience = lawyer.years >= minYears;

        return matchKeyword && matchArea && matchExperience;
      })
      .sort(SORT_OPTIONS[sortIndex].compare);
  }, [lawyers, keyword, selectedAreas, experience, sortIndex]);

  /* ===================================================
     PAGINATION
  =================================================== */

  useEffect(() => {
    setPage(1);
  }, [keyword, selectedAreas, experience, sortIndex]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PER_PAGE));

  const currentPage = Math.min(page, totalPages);

  const startIndex = (currentPage - 1) * PER_PAGE;

  const currentLawyers = filtered.slice(startIndex, startIndex + PER_PAGE);

  /* ===================================================
     EVENTS
  =================================================== */

  const toggleArea = (name) => {
    setSelectedAreas((prev) =>
      prev.includes(name) ? prev.filter((item) => item !== name) : [...prev, name]
    );
  };

  const resetFilters = () => {
    setKeyword("");
    setSelectedAreas([]);
    setExperience("all");
  };

  /* ===================================================
     LOADING
  =================================================== */

  if (loading) {
    return (
      <section className="lls-section">
        <div className="lls-container">
          <p style={{ gridColumn: "1 / -1", textAlign: "center" }}>
            Đang tải danh sách luật sư...
          </p>
        </div>
      </section>
    );
  }

  /* ===================================================
     RENDER
  =================================================== */

  return (
    <section className="lls-section">
      <div className="lls-container">
        {/* =============================================
            SIDEBAR: BỘ LỌC
        ============================================= */}

        <aside
          className="lls-filter"
          style={mobileFilterOpen ? { display: "block" } : undefined}
        >
          {/* SEARCH */}

          <div className="lls-search">
            <input
              type="text"
              value={keyword}
              onChange={(e) => setKeyword(e.target.value)}
              placeholder="Tìm tên luật sư, chuyên môn..."
            />

            <FontAwesomeIcon icon={faMagnifyingGlass} />
          </div>

          {/* PRACTICE AREAS */}

          {areas.length > 0 && (
            <div className="lls-filter-group">
              <h3>
                <FontAwesomeIcon icon={faScaleBalanced} />
                Lĩnh vực hành nghề
              </h3>

              <div className="lls-checkbox-list">
                {areas.map((area) => (
                  <label className="lls-checkbox-item" key={area.id}>
                    <input
                      type="checkbox"
                      checked={selectedAreas.includes(area.name)}
                      onChange={() => toggleArea(area.name)}
                    />

                    <span className="lls-custom-checkbox"></span>

                    {area.name}
                  </label>
                ))}
              </div>
            </div>
          )}

          {/* EXPERIENCE */}

          <div className="lls-filter-group">
            <h3>
              <FontAwesomeIcon icon={faClock} />
              Kinh nghiệm
            </h3>

            <div className="lls-radio-list">
              {EXPERIENCE_OPTIONS.map((option) => (
                <label className="lls-radio-item" key={option.value}>
                  <input
                    type="radio"
                    name="experience"
                    value={option.value}
                    checked={experience === option.value}
                    onChange={() => setExperience(option.value)}
                  />

                  <span className="lls-custom-radio"></span>

                  {option.label}
                </label>
              ))}
            </div>
          </div>

          {/* RESET */}

          <button
            type="button"
            className="lls-reset-button"
            onClick={resetFilters}
          >
            <FontAwesomeIcon icon={faRotateLeft} />
            Đặt lại bộ lọc
          </button>
        </aside>

        {/* =============================================
            KẾT QUẢ
        ============================================= */}

        <div className="lls-results">
          {/* HEADER */}

          <div className="lls-results-header">
            <div className="lls-count">
              {filtered.length === 0 ? (
                "Không có kết quả"
              ) : (
                <>
                  Hiển thị{" "}
                  <strong>
                    {startIndex + 1}-{startIndex + currentLawyers.length}
                  </strong>{" "}
                  trong <strong>{filtered.length}</strong> luật sư
                </>
              )}
            </div>

            <div className="lls-actions">
              <button
                type="button"
                className="lls-sort"
                title="Bấm để đổi cách sắp xếp"
                onClick={() =>
                  setSortIndex((index) => (index + 1) % SORT_OPTIONS.length)
                }
              >
                <span>Sắp xếp:</span>

                <strong>{SORT_OPTIONS[sortIndex].label}</strong>

                <FontAwesomeIcon icon={faChevronDown} />
              </button>

              <button
                type="button"
                className="lls-mobile-filter"
                title="Bộ lọc"
                onClick={() => setMobileFilterOpen((open) => !open)}
              >
                <FontAwesomeIcon icon={faSliders} />
              </button>
            </div>
          </div>

          {error && (
            <p style={{ color: "#cf1322", marginBottom: "16px" }}>{error}</p>
          )}

          {/* GRID */}

          <div className="lls-grid">
            {currentLawyers.map((lawyer) => {
              const isFeatured = lawyer.rating >= FEATURED_MIN_RATING;

              return (
                <article
                  className={`lls-card ${isFeatured ? "lls-card--featured" : ""}`}
                  key={lawyer.id}
                >
                  {isFeatured && (
                    <span className="lls-badge">Nổi bật</span>
                  )}

                  <span className="lls-status">
                    <span className="lls-status-dot"></span>
                    Đang hoạt động
                  </span>

                  <div className="lls-card-top">
                    <div className="lls-avatar-box">
                      <LawyerAvatar src={lawyer.avatar} name={lawyer.name} />
                    </div>

                    <div className="lls-info">
                      <h3>{lawyer.name}</h3>

                      <p>{lawyer.title}</p>

                      <div className="lls-rating">
                        <FontAwesomeIcon icon={faStar} />

                        <strong>
                          {lawyer.rating > 0 ? lawyer.rating.toFixed(1) : "Mới"}
                        </strong>
                      </div>

                      <div className="lls-experience">
                        <FontAwesomeIcon icon={faClock} />

                        {lawyer.years} năm kinh nghiệm
                      </div>
                    </div>
                  </div>

                  <div className="lls-tags">
                    {lawyer.areas.slice(0, 3).map((area) => (
                      <span className="lls-tag" key={area}>
                        {area}
                      </span>
                    ))}

                    {lawyer.areas.length > 3 && (
                      <span className="lls-tag">
                        +{lawyer.areas.length - 3}
                      </span>
                    )}
                  </div>

                  <div className="lls-card-actions">
                    <NavLink
                      to={`/lawyers/${lawyer.id}`}
                      className="lls-btn lls-btn--outline"
                    >
                      <FontAwesomeIcon icon={faEye} />
                      Xem hồ sơ
                    </NavLink>

                    <NavLink
                      to={`/booking?lawyerId=${lawyer.id}`}
                      className="lls-btn lls-btn--primary"
                    >
                      <FontAwesomeIcon icon={faCalendarCheck} />
                      Đặt lịch
                    </NavLink>
                  </div>
                </article>
              );
            })}
          </div>

          {!error && currentLawyers.length === 0 && (
            <p style={{ padding: "40px 0", textAlign: "center" }}>
              Không tìm thấy luật sư phù hợp.
            </p>
          )}

          {/* PAGINATION */}

          {totalPages > 1 && (
            <div className="lls-pagination">
              <button
                type="button"
                disabled={currentPage <= 1}
                onClick={() => setPage(currentPage - 1)}
              >
                <FontAwesomeIcon icon={faChevronLeft} />
              </button>

              {getPageNumbers(currentPage, totalPages).map((number) => (
                <button
                  type="button"
                  key={number}
                  className={`lls-page-number ${
                    number === currentPage ? "is-active" : ""
                  }`}
                  onClick={() => setPage(number)}
                >
                  {number}
                </button>
              ))}

              <button
                type="button"
                disabled={currentPage >= totalPages}
                onClick={() => setPage(currentPage + 1)}
              >
                <FontAwesomeIcon icon={faChevronRight} />
              </button>
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
