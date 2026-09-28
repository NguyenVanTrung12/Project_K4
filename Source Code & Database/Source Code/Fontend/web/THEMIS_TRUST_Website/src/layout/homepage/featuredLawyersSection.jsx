import { useEffect, useMemo, useState } from "react";
import { NavLink } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faArrowRight,
  faChevronRight,
  faStar,
  faClock,
  faUserTie,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../../api/api";
import { toAvatarUrl } from "../../utils/avatar";

import "../../assets/css/homepage/featuredLawyersSection.css";

/* =====================================================
   CONFIG
===================================================== */

// Số luật sư tối đa hiển thị ở trang chủ
const MAX_LAWYERS = 8;

/* =====================================================
   MAP DỮ LIỆU API -> DỮ LIỆU HIỂN THỊ
===================================================== */

const normalizeLawyer = (item) => {
  const yearsExp = Number(item.yearsExp ?? item.YearsExp ?? 0);

  const rating = Number(item.ratingAvg ?? item.RatingAvg ?? 0);

  // Backend hiện chưa trả số lượt đánh giá.
  // Không có thì ẩn, tránh hiện số 0 sai sự thật.
  const reviews = item.reviewCount ?? item.ReviewCount ?? null;

  const isAvailable = item.isAvailable ?? item.IsAvailable ?? true;

  const areas = item.practiceAreas ?? item.PracticeAreas ?? [];

  const allSpecialties = Array.isArray(areas)
    ? areas
        .map((area) =>
          typeof area === "string" ? area : area?.name || area?.Name || ""
        )
        .filter(Boolean)
    : [];

  // Tối đa 3 tag: 2 lĩnh vực + "+n"
  const specialties =
    allSpecialties.length > 3
      ? [...allSpecialties.slice(0, 2), `+${allSpecialties.length - 2}`]
      : allSpecialties;

  return {
    id: item.id ?? item.Id,

    name: item.fullName ?? item.FullName ?? item.name ?? "Chưa cập nhật",

    role: item.title ?? item.Title ?? "Luật sư",

    image: toAvatarUrl(item.avatarUrl ?? item.AvatarUrl ?? ""),

    rating: rating.toFixed(1),

    ratingValue: rating,

    reviews,

    yearsExp,

    experience: yearsExp > 0 ? `${yearsExp} năm kinh nghiệm` : "Mới hành nghề",

    specialties,

    isAvailable,

    status: isAvailable ? "Đang hoạt động" : "Tạm ngưng",
  };
};

/* =====================================================
   ẢNH LUẬT SƯ
   Quay về icon nếu chưa có ảnh hoặc ảnh lỗi
===================================================== */

const LawyerImage = ({ src, name }) => {
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setFailed(false);
  }, [src]);

  if (!src || failed) {
    return (
      <div
        className="lawyer-image"
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "#e5e7eb",
          color: "#9ca3af",
          fontSize: "36px",
        }}
      >
        <FontAwesomeIcon icon={faUserTie} />
      </div>
    );
  }

  return (
    <img
      src={src}
      alt={name || "Luật sư"}
      className="lawyer-image"
      onError={() => {
        console.warn("Không tải được ảnh luật sư:", src);
        setFailed(true);
      }}
    />
  );
};

/* =====================================================
   HEADER
===================================================== */

const SectionHeader = ({ showViewAll = true }) => (
  <div className="lawyers-header">
    <div>
      <span className="lawyers-label">LUẬT SƯ NỔI BẬT</span>

      <h2>Đội ngũ luật sư giàu kinh nghiệm</h2>
    </div>

    {showViewAll && (
      <NavLink to="/lawyers" className="view-all-lawyers">
        Xem tất cả luật sư
        <FontAwesomeIcon icon={faArrowRight} />
      </NavLink>
    )}
  </div>
);

/* =====================================================
   COMPONENT
===================================================== */

const FeaturedLawyers = () => {
  const [lawyers, setLawyers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  /* ===================================================
     DỮ LIỆU HIỂN THỊ
  =================================================== */

  const displayLawyers = useMemo(() => {
    if (!Array.isArray(lawyers)) {
      return [];
    }

    return (
      lawyers
        .map(normalizeLawyer)
        // Trang chủ chỉ hiện luật sư đang hoạt động
        .filter((lawyer) => lawyer.isAvailable)
        // Đánh giá cao trước, cùng điểm thì nhiều kinh nghiệm trước
        .sort(
          (a, b) => b.ratingValue - a.ratingValue || b.yearsExp - a.yearsExp
        )
        .slice(0, MAX_LAWYERS)
    );
  }, [lawyers]);

  /* ===================================================
     API
  =================================================== */

  useEffect(() => {
    const fetchLawyers = async () => {
      try {
        setLoading(true);
        setError("");

        const data = await api.get("/lawyers");

        const rawLawyers = Array.isArray(data)
          ? data
          : data?.data || data?.items || [];

        // State chỉ giữ dữ liệu thô. Việc chuẩn hóa làm ở displayLawyers.
        setLawyers(rawLawyers);
      } catch (err) {
        console.error("Lỗi lấy danh sách luật sư:", err);

        setError("Không thể tải danh sách luật sư.");
      } finally {
        setLoading(false);
      }
    };

    fetchLawyers();
  }, []);

  /* ===================================================
     LOADING
  =================================================== */

  if (loading) {
    return (
      <section className="featured-lawyers-section">
        <div className="featured-lawyers-container">
          <SectionHeader showViewAll={false} />

          <div className="lawyers-loading">Đang tải danh sách luật sư...</div>
        </div>
      </section>
    );
  }

  /* ===================================================
     ERROR
  =================================================== */

  if (error) {
    return (
      <section className="featured-lawyers-section">
        <div className="featured-lawyers-container">
          <SectionHeader />

          <div className="lawyers-error">{error}</div>
        </div>
      </section>
    );
  }

  /* ===================================================
     RENDER
  =================================================== */

  return (
    <section className="featured-lawyers-section">
      <div className="featured-lawyers-container">
        <SectionHeader />

        <div className="lawyers-wrapper">
          <div className="lawyers-grid">
            {displayLawyers.length > 0 ? (
              displayLawyers.map((lawyer) => (
                <div className="lawyer-card" key={lawyer.id}>
                  {/* IMAGE + STATUS */}

                  <div className="lawyer-top">
                    <LawyerImage src={lawyer.image} name={lawyer.name} />

                    <span className="lawyer-status">
                      <span className="status-dot"></span>

                      {lawyer.status}
                    </span>
                  </div>

                  {/* INFORMATION */}

                  <div className="lawyer-info">
                    <h3>{lawyer.name}</h3>

                    <p className="lawyer-role">{lawyer.role}</p>

                    {/* RATING */}

                    <div className="lawyer-rating">
                      <FontAwesomeIcon icon={faStar} />

                      <span>{lawyer.rating}</span>

                      {lawyer.reviews !== null && (
                        <small>({lawyer.reviews})</small>
                      )}
                    </div>

                    {/* EXPERIENCE */}

                    <div className="lawyer-experience">
                      <FontAwesomeIcon icon={faClock} />

                      <span>{lawyer.experience}</span>
                    </div>

                    {/* SPECIALTIES */}

                    <div className="lawyer-specialties">
                      {(lawyer.specialties || []).map((specialty, index) => (
                        <span
                          className="specialty-tag"
                          key={`${lawyer.id}-${index}`}
                        >
                          {specialty}
                        </span>
                      ))}
                    </div>

                    {/* BUTTONS */}

                    <div className="lawyer-actions">
                      <NavLink
                        to={`/lawyer/${lawyer.id}`}
                        className="profile-button"
                      >
                        Xem hồ sơ
                      </NavLink>

                      <NavLink
                        to={`/booking?lawyerId=${lawyer.id}`}
                        className="booking-lawyer-button"
                      >
                        Đặt lịch tư vấn
                      </NavLink>
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="lawyers-empty">Chưa có thông tin luật sư.</div>
            )}
          </div>

          {displayLawyers.length > 0 && (
            <button type="button" className="lawyers-next-button">
              <FontAwesomeIcon icon={faChevronRight} />
            </button>
          )}
        </div>
      </div>
    </section>
  );
};

export default FeaturedLawyers;
