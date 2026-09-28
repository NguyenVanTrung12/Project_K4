import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faPhone,
  faShieldHalved,
  faUserGroup,
  faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/aboutpage/ContactCTA.css";
import { NavLink } from "react-router-dom";

const ContactCTA = () => {
  return (
    <section className="contact-cta">
      <div className="contact-overlay"></div>

      <div className="contact-container">

        {/* LABEL */}
        <div className="contact-label">
          ĐỒNG HÀNH CÙNG CHÚNG TÔI
        </div>

        {/* TITLE */}
        <h2 className="contact-title">
          Hãy để chúng tôi lắng nghe và đồng hành
          trong mọi vấn đề pháp lý của bạn
        </h2>

        {/* BOTTOM ROW */}
        <div className="contact-bottom">

          {/* BUTTON */}
          <NavLink  to="/contact" className="contact-button">
            <span>Liên hệ ngay</span>

            <FontAwesomeIcon
              icon={faArrowRight}
              className="contact-button-icon"
            />
            </NavLink>

          {/* FEATURES */}
          <div className="contact-features-CTA">

            {/* FEATURE 1 */}
            <div className="contact-feature">
              <div className="feature-icon">
                <FontAwesomeIcon icon={faPhone} />
              </div>

              <div className="feature-text">
                <span>Tư vấn nhanh chóng</span>
              </div>
            </div>

            {/* FEATURE 2 */}
            <div className="contact-feature">
              <div className="feature-icon">
                <FontAwesomeIcon icon={faShieldHalved} />
              </div>

              <div className="feature-text">
                <span>Bảo mật tuyệt đối</span>
              </div>
            </div>

            {/* FEATURE 3 */}
            <div className="contact-feature">
              <div className="feature-icon">
                <FontAwesomeIcon icon={faUserGroup} />
              </div>

              <div className="feature-text">
                <span>Đội ngũ chuyên nghiệp</span>
              </div>
            </div>

          </div>

        </div>

      </div>
    </section>
  );
};

export default ContactCTA;