import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faArrowRight } from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/contact/ContactHero.css";
import { NavLink } from "react-router-dom";

const ContactHero = () => {
  return (
    <section className="contact-hero">

      {/* Background overlay */}
      <div className="contact-hero-overlay"></div>

      <div className="contact-hero-container">

        {/* ================= LEFT CONTENT ================= */}
        <div className="contact-hero-content">

          {/* Label */}
          <div className="contact-hero-label">
            <span>LIÊN HỆ VỚI CHÚNG TÔI</span>
            <span className="contact-hero-label-line"></span>
          </div>

          {/* Heading */}
          <h1 className="contact-hero-title">
            Chúng tôi luôn sẵn sàng
            <br />
            lắng nghe và đồng hành
            <br />
            cùng bạn
          </h1>

          {/* Description */}
          <p className="contact-hero-description">
            Mọi câu hỏi, thắc mắc hay nhu cầu tư vấn pháp lý của bạn
            đều được đội ngũ luật sư của THEMIS TRUST tiếp nhận
            và phản hồi nhanh chóng, chuyên nghiệp.
          </p>

          {/* Button */}
          <NavLink to="/booking" className="contact-hero-button">
            <span>Đặt lịch tư vấn ngay</span>

            <FontAwesomeIcon
              icon={faArrowRight}
              className="contact-hero-button-icon"
            />
          </NavLink>

        </div>


        {/* ================= RIGHT QUOTE ================= */}
        <div className="contact-hero-quote">

          <p>
            “Công lý bắt đầu
            <br />
            từ một cuộc trò chuyện.”
          </p>

          <div className="contact-quote-line"></div>

        </div>

      </div>
    </section>
  );
};

export default ContactHero;