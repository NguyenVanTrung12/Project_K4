import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faArrowRight,
  faEnvelope,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/newspage/FeaturedArticles.css";

const FeaturedArticles = () => {
  return (
    <section className="featured-section">
      <div className="featured-container">

        {/* =========================
            LEFT - FEATURED ARTICLE
        ========================== */}
        <div className="featured-main">

          <h2 className="featured-title">
            Bài viết nổi bật
          </h2>

          <article className="featured-card">

            {/* Image */}
            <div className="featured-image-wrapper">
              <img
                src="https://baodongnai.com.vn/file/e7837c02876411cd0187645a2551379f/012024/luat_thumb_20240120144313.jpg"
                alt="Những điểm mới quan trọng của Luật Đất đai 2025"
                className="featured-image" 
              />
            </div>

            {/* Content */}
            <div className="featured-content">

              <span className="featured-category">
                Cập nhật pháp luật
              </span>

              <span className="featured-date">
                12 Tháng 8, 2025
              </span>

              <h3 className="featured-article-title">
                Những điểm mới quan trọng của
                <br />
                Luật Đất đai 2025
              </h3>

              <p className="featured-description">
                Luật Đất đai 2025 mang đến nhiều thay đổi đáng chú ý,
                tác động trực tiếp đến quyền và nghĩa vụ của người dân,
                doanh nghiệp. Bài viết phân tích những nội dung cốt lõi
                và lưu ý khi áp dụng.
              </p>

              <a href="#" className="featured-read-more">
                <span>Xem chi tiết</span>

                <FontAwesomeIcon icon={faArrowRight} />
              </a>

            </div>

          </article>

        </div>


        {/* =========================
            RIGHT SIDEBAR
        ========================== */}
        <aside className="featured-sidebar">

          {/* Quote */}
          <div className="legal-quote">

            <div className="quote-decoration"></div>

            <p>
              “Pháp luật không chỉ là quy tắc,
              mà còn là nền tảng của một
              xã hội công bằng và nhân văn.”
            </p>

            <span className="quote-line"></span>

          </div>


          {/* Newsletter */}
          <div className="newsletter-card">

            <div className="newsletter-content">

              <h3>
                Đăng ký nhận tin
              </h3>

              <p>
                Cập nhật những bài viết pháp lý mới nhất
                từ THEMIS TRUST.
              </p>

              <form className="newsletter-form">

                <div className="newsletter-input">

                  <FontAwesomeIcon icon={faEnvelope} />

                  <input
                    type="email"
                    placeholder="Nhập email của bạn..."
                  />

                </div>

                <button type="submit">
                  Đăng ký

                  <FontAwesomeIcon icon={faArrowRight} />
                </button>

              </form>

            </div>

          </div>

        </aside>

      </div>
    </section>
  );
};

export default FeaturedArticles;