import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUser,
  faPhone,
  faEnvelope,
  faTableCellsLarge,
  faFileLines,
  faChevronDown,
  faArrowRight,
  faCommentDots,
  faLocationDot,
  faClock,
} from "@fortawesome/free-solid-svg-icons";

import {
  faFacebookF,
  faLinkedinIn,
  faYoutube,
} from "@fortawesome/free-brands-svg-icons";

import "../../assets/css/contact/ContactForm.css";

const ContactForm = () => {
  return (
    <section className="contact-form-section">
      <div className="contact-form-container">

        {/* ================= LEFT - FORM ================= */}
        <div className="contact-form-left">

          <div className="contact-label">
            LIÊN HỆ TRỰC TIẾP
          </div>

          <h2>
            Gửi cho chúng tôi
            <br />
            thông tin của bạn
          </h2>

          <p className="contact-description">
            Hãy để lại thông tin, chúng tôi sẽ liên hệ lại trong thời gian sớm nhất
            để tư vấn và hỗ trợ bạn. Mọi thông tin đều được bảo mật theo quy định
            của nghề luật sư.
          </p>

          <form className="contact-form">

            {/* Row 1 */}
            <div className="form-row">

              <div className="form-group">
                <FontAwesomeIcon
                  icon={faUser}
                  className="form-icon"
                />

                <input
                  type="text"
                  placeholder="Họ và tên *"
                />
              </div>

              <div className="form-group">
                <FontAwesomeIcon
                  icon={faPhone}
                  className="form-icon"
                />

                <input
                  type="text"
                  placeholder="Số điện thoại *"
                />
              </div>

            </div>


            {/* Email */}
            <div className="form-group full-width">

              <FontAwesomeIcon
                icon={faEnvelope}
                className="form-icon"
              />

              <input
                type="email"
                placeholder="Email"
              />

            </div>


            {/* Select */}
            <div className="form-group full-width select-group">

              <FontAwesomeIcon
                icon={faTableCellsLarge}
                className="form-icon"
              />

              <select defaultValue="">
                <option value="" disabled>
                  Chọn lĩnh vực quan tâm
                </option>

                <option value="dan-su">
                  Dân sự
                </option>

                <option value="hinh-su">
                  Hình sự
                </option>

                <option value="doanh-nghiep">
                  Doanh nghiệp
                </option>

                <option value="dat-dai">
                  Đất đai
                </option>

                <option value="hon-nhan">
                  Hôn nhân & Gia đình
                </option>

                <option value="lao-dong">
                  Lao động
                </option>
              </select>

              <FontAwesomeIcon
                icon={faChevronDown}
                className="select-arrow"
              />

            </div>


            {/* Message */}
            <div className="form-group message-group">

              <FontAwesomeIcon
                icon={faFileLines}
                className="form-icon message-icon"
              />

              <textarea
                placeholder="Nội dung tin nhắn *"
              ></textarea>

            </div>


            {/* Checkbox */}
            <label className="privacy-check">

              <input type="checkbox" />

              <span>
                Tôi đồng ý với chính sách bảo mật thông tin của THEMIS TRUST.
              </span>

            </label>


            {/* Submit */}
            <button
              type="submit"
              className="contact-submit-btn"
            >
              <span>
                Gửi yêu cầu tư vấn
              </span>

              <FontAwesomeIcon
                icon={faArrowRight}
              />

            </button>

          </form>

        </div>


        {/* ================= RIGHT - CONTACT INFO ================= */}
        <div className="contact-info">

          <div className="contact-info-content">

            <div className="contact-label">
              THÔNG TIN LIÊN HỆ
            </div>

            <h3>
              Themis &amp; Cộng sự
            </h3>

            <p className="contact-info-subtitle">
              Luôn bên bạn, vì một xã hội công bằng hơn.
            </p>


            {/* Phone */}
            <div className="contact-info-item">

              <div className="contact-info-icon">
                <FontAwesomeIcon icon={faPhone} />
              </div>

              <div className="contact-info-text">

                <strong>
                  1900 1234
                </strong>

                <span>
                  Tư vấn và hỗ trợ khách hàng (8:00 – 17:30, Thứ 2 – Thứ 6)
                </span>

              </div>

            </div>


            {/* Email */}
            <div className="contact-info-item">

              <div className="contact-info-icon">
                <FontAwesomeIcon icon={faEnvelope} />
              </div>

              <div className="contact-info-text">

                <strong>
                  support@themis.vn
                </strong>

                <span>
                  Phản hồi trong vòng 24 giờ
                </span>

              </div>

            </div>


            {/* Address */}
            <div className="contact-info-item">

              <div className="contact-info-icon">
                <FontAwesomeIcon icon={faLocationDot} />
              </div>

              <div className="contact-info-text">

                <strong>
                  Tầng 4, 66 Cốm Vòng, Dịch Vọng Hậu,
                  <br />
                  Cầu Giấy, Hà Nội.
                </strong>

                <span>
                  Văn phòng giao dịch
                </span>

              </div>

            </div>


            {/* Time */}
            <div className="contact-info-item">

              <div className="contact-info-icon">
                <FontAwesomeIcon icon={faClock} />
              </div>

              <div className="contact-info-text">

                <strong>
                  Thứ 2 – Thứ 6: 8:00 – 17:30
                  <br />
                  Thứ 7: 8:00 – 12:00
                </strong>

                <span>
                  Làm việc ngoài giờ theo lịch hẹn
                </span>

              </div>

            </div>


            {/* Social */}
            <div className="contact-social">

              <div className="social-title">
                KẾT NỐI VỚI CHÚNG TÔI
              </div>

              <div className="social-list">

                <a href="#" aria-label="Facebook">
                  <FontAwesomeIcon icon={faFacebookF} />
                </a>

                <a href="#" aria-label="LinkedIn">
                  <FontAwesomeIcon icon={faLinkedinIn} />
                </a>

                <a href="#" aria-label="Youtube">
                  <FontAwesomeIcon icon={faYoutube} />
                </a>

                <a href="#" aria-label="Messenger">
                  <FontAwesomeIcon icon={faCommentDots} />
                </a>

              </div>

            </div>

          </div>


          {/* Decorative text */}
          <div className="contact-decoration">
            Kết nối
            <br />
            để kiến tạo công lý
          </div>

        </div>

      </div>
    </section>
  );
};

export default ContactForm;