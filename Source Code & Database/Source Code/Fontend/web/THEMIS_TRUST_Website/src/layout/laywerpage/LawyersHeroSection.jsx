import { useEffect, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faScaleBalanced,
  faUserShield,
  faLock,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../../api/api";

import "../../assets/css/lawyerpage/LawyersHeroSection.css";

/* =====================================================
   TÍNH SỐ LIỆU TỪ DANH SÁCH LUẬT SƯ
===================================================== */

const calculateStats = (rawLawyers) => {
  // Chỉ tính luật sư đang hoạt động
  const activeLawyers = rawLawyers.filter(
    (lawyer) => (lawyer.isAvailable ?? lawyer.IsAvailable ?? true) === true
  );

  const totalYears = activeLawyers.reduce(
    (sum, lawyer) =>
      sum + Number(lawyer.yearsExp ?? lawyer.YearsExp ?? 0),
    0
  );

  return {
    lawyerCount: activeLawyers.length,

    avgYears:
      activeLawyers.length > 0
        ? Math.round(totalYears / activeLawyers.length)
        : 0,
  };
};

/* =====================================================
   COMPONENT
===================================================== */

function LawyersHeroSection() {
  // null = đang tải hoặc lỗi -> hiển thị nội dung mặc định
  const [stats, setStats] = useState(null);

  useEffect(() => {
    let cancelled = false;

    const loadStats = async () => {
      try {
        const data = await api.get("/lawyers");

        const rawLawyers = Array.isArray(data)
          ? data
          : data?.data || data?.items || [];

        if (!cancelled) {
          setStats(calculateStats(rawLawyers));
        }
      } catch (err) {
        // Lỗi thì giữ nguyên nội dung mặc định, không làm hỏng trang
        console.error("Không thể tải số liệu luật sư:", err);
      }
    };

    loadStats();

    return () => {
      cancelled = true;
    };
  }, []);

  /* ===================================================
     NỘI DUNG (động nếu có dữ liệu, mặc định nếu chưa có)
  =================================================== */

  const hasLawyers = Boolean(stats && stats.lawyerCount > 0);

  const description = hasLawyers
    ? `Với đội ngũ ${stats.lawyerCount} luật sư giàu kinh nghiệm, chuyên môn cao và tận tâm, chúng tôi cam kết mang đến cho bạn những giải pháp pháp lý tối ưu nhất.`
    : "Với đội ngũ luật sư giàu kinh nghiệm, chuyên môn cao và tận tâm, chúng tôi cam kết mang đến cho bạn những giải pháp pháp lý tối ưu nhất.";

  const experienceText =
    stats && stats.avgYears > 0
      ? `Trung bình ${stats.avgYears} năm kinh nghiệm`
      : "Nhiều năm kinh nghiệm";

  const teamText = hasLawyers
    ? `${stats.lawyerCount} luật sư đồng hành cùng bạn`
    : "Đồng hành cùng bạn";

  return (
    <section className="lawyers-hero">
      {/* Background overlay */}
      <div className="lawyers-hero-overlay"></div>

      <div className="lawyers-hero-container">
        {/* Breadcrumb */}
        <div className="lawyers-breadcrumb">
          <span>Trang chủ</span>
          <span className="breadcrumb-arrow">›</span>
          <span>Luật sư</span>
        </div>

        {/* Main content */}
        <div className="lawyers-hero-content">
          <div className="lawyers-hero-left">
            <span className="hero-line"></span>

            <h1>Đội ngũ luật sư chuyên nghiệp</h1>

            <p>{description}</p>

            {/* Features */}
            <div className="lawyers-hero-features">
              {/* Feature 1 */}
              <div className="hero-feature">
                <div className="hero-feature-icon">
                  <FontAwesomeIcon icon={faScaleBalanced} />
                </div>

                <div>
                  <h3>Chuyên môn cao</h3>

                  <span>{experienceText}</span>
                </div>
              </div>

              {/* Feature 2 */}
              <div className="hero-feature">
                <div className="hero-feature-icon">
                  <FontAwesomeIcon icon={faUserShield} />
                </div>

                <div>
                  <h3>Tận tâm</h3>

                  <span>{teamText}</span>
                </div>
              </div>

              {/* Feature 3 */}
              <div className="hero-feature">
                <div className="hero-feature-icon">
                  <FontAwesomeIcon icon={faLock} />
                </div>

                <div>
                  <h3>Bảo mật</h3>

                  <span>Thông tin tuyệt đối</span>
                </div>
              </div>
            </div>
          </div>

          {/* Quote */}
          <div className="lawyers-hero-quote">
            <span className="quote-mark">“</span>

            <p>
              Công lý không chỉ là một mục tiêu, mà là cam kết của chúng tôi.
            </p>

            <span className="quote-line"></span>
          </div>
        </div>
      </div>
    </section>
  );
}

export default LawyersHeroSection;
