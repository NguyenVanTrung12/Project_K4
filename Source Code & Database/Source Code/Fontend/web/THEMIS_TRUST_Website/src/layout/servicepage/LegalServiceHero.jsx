import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faShieldHalved,
  faUsers,
  faLock,
  faArrowRight,
  faPlay,
  faUserCheck,
  faHeart,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/servicepage/LegalServiceHero.css";

const LegalServiceHero = () => {
  return (
    <section className="legal-hero">

      {/* Background image */}
      <div className="legal-hero-background"></div>

      {/* Dark overlay */}
      <div className="legal-hero-overlay"></div>

      <div className="legal-hero-container">

        {/* =========================================
            LEFT CONTENT
        ========================================= */}

        <div className="legal-hero-content">

          {/* Label */}
          <div className="legal-hero-label">
            <span>DỊCH VỤ PHÁP LÝ</span>
            <div className="label-line"></div>
          </div>


          {/* Title */}
          <h1>
            Giải pháp pháp lý toàn diện
            <br />
            cho cá nhân và doanh nghiệp
          </h1>


          {/* Description */}
          <p className="legal-hero-description">
            Đồng hành cùng bạn trong mọi vấn đề pháp lý với sự tận tâm,
            chuyên nghiệp và bảo mật tuyệt đối.
          </p>


          {/* =========================================
              FEATURES
          ========================================= */}

          <div className="legal-features">

            {/* Feature 1 */}
            <div className="legal-feature">

              <div className="legal-hero-feature-icon">
                <FontAwesomeIcon icon={faShieldHalved} />
              </div>

              <div className="feature-text">
                <strong>Tư vấn</strong>
                <span>chuyên sâu</span>
              </div>

            </div>


            {/* Feature 2 */}
            <div className="legal-feature">

              <div className="legal-hero-feature-icon">
                <FontAwesomeIcon icon={faUsers} />
              </div>

              <div className="feature-text">
                <strong>Đội ngũ luật sư</strong>
                <span>giàu kinh nghiệm</span>
              </div>

            </div>


            {/* Feature 3 */}
            <div className="legal-feature">

              <div className="legal-hero-feature-icon">
                <FontAwesomeIcon icon={faLock} />
              </div>

              <div className="feature-text">
                <strong>Bảo mật</strong>
                <span>thông tin</span>
              </div>

            </div>

          </div>


          {/* =========================================
              BUTTONS
          ========================================= */}

          <div className="legal-hero-actions">

            {/* Primary button */}
            <button className="legal-primary-btn">
              <span>Đặt lịch tư vấn ngay</span>

              <FontAwesomeIcon icon={faArrowRight} />
            </button>


            {/* Secondary button */}
            <button className="legal-secondary-btn">

              <span className="play-icon">
                <FontAwesomeIcon icon={faPlay} />
              </span>

              <span>Tìm hiểu thêm</span>

            </button>

          </div>

        </div>


        {/* =========================================
            RIGHT INFORMATION
        ========================================= */}

        <aside className="legal-hero-stats">

          {/* Quote */}
          <div className="legal-quote">

            <div className="quote-mark">
              “
            </div>

            <p>
              Pháp luật
              <br />
              là nền tảng của một
              <br />
              xã hội công bằng
              <br />
              và thịnh vượng.
            </p>

            <div className="quote-line"></div>

          </div>


          {/* =========================================
              STAT 1
          ========================================= */}

          <div className="legal-stat">

            <div className="legal-hero-stat-icon">
              <FontAwesomeIcon icon={faShieldHalved} />
            </div>

            <div className="stat-content">

              <strong>120+</strong>

              <span>
                Dự án thành công
              </span>

            </div>

          </div>


          {/* =========================================
              STAT 2
          ========================================= */}

          <div className="legal-stat">

            <div className="legal-hero-stat-icon">
              <FontAwesomeIcon icon={faUserCheck} />
            </div>

            <div className="stat-content">

              <strong>2.500+</strong>

              <span>
                Khách hàng tin tưởng
              </span>

            </div>

          </div>


          {/* =========================================
              STAT 3
          ========================================= */}

          <div className="legal-stat">

            <div className="legal-hero-stat-icon">
              <FontAwesomeIcon icon={faHeart} />
            </div>

            <div className="stat-content">

              <strong>98%</strong>

              <span>
                Tỷ lệ hài lòng
              </span>

            </div>

          </div>

        </aside>

      </div>

    </section>
  );
};

export default LegalServiceHero;