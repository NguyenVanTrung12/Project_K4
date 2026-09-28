import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faPhone,
  faEnvelope,
  faLocationDot,
} from "@fortawesome/free-solid-svg-icons";

import {
  faFacebookF,
  faLinkedinIn,
  faYoutube,
} from "@fortawesome/free-brands-svg-icons";

import "../../assets/css/footer.css";

function Footer() {
  return (
    <footer className="footer">

      {/* MAIN FOOTER */}
      <div className="footer-main">

        {/* BRAND */}
        <div className="footer-brand">

          <div className="footer-logo">

            <div className="logo-icon"><i class="fa-solid fa-scale-balanced"></i></div>

            <div className="footer-logo-text">
              <h2>THEMIS TRUST</h2>
            </div>

          </div>

          <p className="footer-slogan">
            Vì công lý, vì quyền lợi của bạn
          </p>

        </div>


        {/* QUICK LINKS */}
        <div className="footer-column">

          <h3>Liên kết nhanh</h3>

          <a href="/">Trang chủ</a>
          <a href="/lawyers">Luật sư</a>
          <a href="/services">Dịch vụ pháp lý</a>
          <a href="/about">Về chúng tôi</a>

        </div>


        {/* SUPPORT */}
        <div className="footer-column">

          <h3>Hỗ trợ</h3>

          <a href="/faq">Câu hỏi thường gặp</a>
          <a href="/privacy">Chính sách bảo mật</a>
          <a href="/terms">Điều khoản sử dụng</a>
          <a href="/contact">Liên hệ</a>

        </div>


        {/* CONTACT */}
        <div className="footer-column footer-contact">

          <h3>Thông tin liên hệ</h3>

          <div className="contact-item">

            <FontAwesomeIcon icon={faPhone} />

            <span>1900 1234</span>

          </div>


          <div className="contact-item">

            <FontAwesomeIcon icon={faEnvelope} />

            <span>support@themis.vn</span>

          </div>


          <div className="contact-item">

            <FontAwesomeIcon icon={faLocationDot} />

            <span>
              238 Hoàng Quốc Việt, Cầu Giấy, Hà Nội
            </span>

          </div>

        </div>


        {/* SOCIAL */}
        <div className="footer-social">

          <a href="#">
            <FontAwesomeIcon icon={faFacebookF} />
          </a>

          <a href="#">
            <FontAwesomeIcon icon={faLinkedinIn} />
          </a>

          <a href="#">
            <FontAwesomeIcon icon={faYoutube} />
          </a>

        </div>

      </div>


      {/* FOOTER BOTTOM */}
      <div className="footer-bottom">

        <p>
          © 2026 Themis Trust. Tất cả quyền được bảo lưu.
        </p>


        <div className="footer-bottom-links">

          <a href="/privacy">
            Chính sách bảo mật
          </a>

          <span>•</span>

          <a href="/terms">
            Điều khoản sử dụng
          </a>

        </div>

      </div>

    </footer>
  );
}

export default Footer;