import { useEffect, useState } from "react";
import { api } from "../../api/api";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faFileCircleCheck,
  faUser,
  faPhone,
  faEnvelope,
  faBookOpen,
  faPenToSquare,
  faFileLines,
  faUpload,
  faPaperPlane,
  faRotate,
  faShieldHalved,
  faBolt,
  faUsers,
  faFileContract,
  faHeadset,
  faChevronDown,
  faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/userpage/ConsultationRequestPage.css";


/* =========================================================
   DỮ LIỆU LĨNH VỰC
   Sau này có thể thay bằng dữ liệu gọi từ API
========================================================= */

const consultationFields = [];


/* =========================================================
   LÝ DO
========================================================= */

const reasons = [
  {
    icon: faShieldHalved,
    title: "Bảo mật tuyệt đối",
    description:
      "Thông tin của bạn được bảo mật theo chính sách nghiêm ngặt.",
  },
  {
    icon: faBolt,
    title: "Phản hồi nhanh chóng",
    description:
      "Chúng tôi sẽ liên hệ bạn trong thời gian sớm nhất.",
  },
  {
    icon: faUsers,
    title: "Đội ngũ luật sư giàu kinh nghiệm",
    description:
      "Tư vấn chính xác, thực tiễn và hiệu quả.",
  },
  {
    icon: faFileContract,
    title: "Hỗ trợ đa dạng hình thức",
    description:
      "Tư vấn trực tiếp, qua điện thoại hoặc trực tuyến.",
  },
];


const ConsultationRequestPage = () => {

  /* =======================================================
     FORM STATE
  ======================================================= */

  const [formData, setFormData] = useState({
    fullName: "",
    phone: "",
    email: "",
    fieldId: "",
    title: "",
    content: "",
    attachment: null,
  });


  const [isSubmitting, setIsSubmitting] =
    useState(false);


  /* =======================================================
     HANDLE INPUT
  ======================================================= */

  const handleChange = (event) => {

    const {
      name,
      value,
    } = event.target;


    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));

  };


  /* =======================================================
     HANDLE FILE
  ======================================================= */

  const handleFileChange = (event) => {

    const file =
      event.target.files?.[0] || null;


    setFormData((prev) => ({
      ...prev,
      attachment: file,
    }));

  };


  /* =======================================================
     SUBMIT
     Sau này thay bằng API POST
  ======================================================= */

  const handleSubmit = async (event) => {
    event.preventDefault(); setIsSubmitting(true); setMessage("");
    try {
      const body = new FormData();
      body.append("title", formData.title); body.append("practiceAreaId", formData.fieldId); body.append("description", formData.content); body.append("priority", "normal");
      if (formData.attachment) body.append("file", formData.attachment);
      await api.post("/consultation-requests/with-file", body);
      setMessage("Yêu cầu tư vấn đã được gửi thành công!"); handleReset();
    } catch (error) { setMessage(error.message || "Không thể gửi yêu cầu."); } finally { setIsSubmitting(false); }
  };


  /* =======================================================
     RESET
  ======================================================= */

  const handleReset = () => {

    setFormData({
      fullName: "",
      phone: "",
      email: "",
      fieldId: "",
      title: "",
      content: "",
      attachment: null,
    });

  };


  return (

    <main className="consultation-request-page">
      {message && <div className="consultation-message">{message}</div>}


      {/* ===================================================
          HERO
      =================================================== */}

      <section className="consultation-request-hero">

        <div className="consultation-request-hero__content">

          <h1>
            Yêu cầu tư vấn
          </h1>

          <p>
            Chúng tôi luôn sẵn sàng lắng nghe và hỗ trợ bạn
            <br />
            với những vấn đề pháp lý một cách nhanh chóng,
            bảo mật và hiệu quả.
          </p>

        </div>


        <div className="consultation-request-hero__quote">

          <span className="hero-quote-mark">
            “
          </span>

          <p>
            Mọi vấn đề pháp lý
            <br />
            đều có giải pháp,
            <br />
            chỉ cần bạn bắt đầu
            <br />
            bằng một câu hỏi.
          </p>

          <div className="hero-quote-line"></div>

        </div>

      </section>


      {/* ===================================================
          MAIN
      =================================================== */}

      <section className="consultation-request-content">


        {/* =================================================
            FORM
        ================================================= */}

        <form
          className="consultation-request-form"
          onSubmit={handleSubmit}
        >


          {/* FORM HEADER */}

          <div className="consultation-form-header">

            <div className="consultation-form-title">

              <div className="consultation-form-title__icon">

                <FontAwesomeIcon
                  icon={faFileCircleCheck}
                />

              </div>

              <h2>
                Thông tin yêu cầu tư vấn
              </h2>

            </div>


            <span className="required-note">

              Các trường có dấu
              <strong>*</strong>
              là bắt buộc

            </span>

          </div>


          {/* =================================================
              NAME + PHONE
          ================================================= */}

          <div className="form-row">


            {/* NAME */}

            <div className="form-group-consultation-request">

              <label htmlFor="fullName">

                Họ và tên
                <span>*</span>

              </label>


              <div className="input-wrapper">

                <FontAwesomeIcon
                  icon={faUser}
                />

                <input
                  id="fullName"
                  name="fullName"
                  type="text"
                  placeholder="Nhập họ và tên của bạn"
                  value={formData.fullName}
                  onChange={handleChange}
                  required
                />

              </div>

            </div>


            {/* PHONE */}

            <div className="form-group-consultation-request">

              <label htmlFor="phone">

                Số điện thoại
                <span>*</span>

              </label>


              <div className="input-wrapper">

                <FontAwesomeIcon
                  icon={faPhone}
                />

                <input
                  id="phone"
                  name="phone"
                  type="tel"
                  placeholder="Nhập số điện thoại"
                  value={formData.phone}
                  onChange={handleChange}
                  required
                />

              </div>

            </div>

          </div>


          {/* =================================================
              EMAIL + FIELD
          ================================================= */}

          <div className="form-row">


            {/* EMAIL */}

            <div className="form-group-consultation-request">

              <label htmlFor="email">
                Email
              </label>


              <div className="input-wrapper">

                <FontAwesomeIcon
                  icon={faEnvelope}
                />

                <input
                  id="email"
                  name="email"
                  type="email"
                  placeholder="Nhập email của bạn (nếu có)"
                  value={formData.email}
                  onChange={handleChange}
                />

              </div>

            </div>


            {/* FIELD */}

            <div className="form-group-consultation-request">

              <label htmlFor="fieldId">

                Lĩnh vực tư vấn
                <span>*</span>

              </label>


              <div className="select-wrapper">

                <FontAwesomeIcon
                  icon={faBookOpen}
                  className="select-icon"
                />


                <select
                  id="fieldId"
                  name="fieldId"
                  value={formData.fieldId}
                  onChange={handleChange}
                  required
                >

                  <option value="">
                    Chọn lĩnh vực tư vấn
                  </option>


                  {(fields.length ? fields : consultationFields).map(
                    (field) => (

                      <option
                        value={field.id}
                        key={field.id}
                      >
                        {field.name}
                      </option>

                    )
                  )}

                </select>


                <FontAwesomeIcon
                  icon={faChevronDown}
                  className="select-arrow"
                />

              </div>

            </div>

          </div>


          {/* =================================================
              TITLE
          ================================================= */}

          <div className="form-group-consultation-request full-width">

            <label htmlFor="title">

              Tiêu đề yêu cầu
              <span>*</span>

            </label>


            <div className="input-wrapper">

              <FontAwesomeIcon
                icon={faPenToSquare}
              />

              <input
                id="title"
                name="title"
                type="text"
                placeholder="Nhập tiêu đề ngắn gọn cho yêu cầu tư vấn"
                value={formData.title}
                onChange={handleChange}
                required
              />

            </div>

          </div>


          {/* =================================================
              CONTENT
          ================================================= */}

          <div className="form-group-consultation-request full-width">

            <label htmlFor="content">

              Nội dung chi tiết
              <span>*</span>

            </label>


            <div className="textarea-wrapper">

              <FontAwesomeIcon
                icon={faFileLines}
              />

              <textarea
                id="content"
                name="content"
                maxLength={1000}
                placeholder="Vui lòng mô tả chi tiết vấn đề pháp lý bạn đang gặp phải, các thông tin liên quan và mong muốn được tư vấn..."
                value={formData.content}
                onChange={handleChange}
                required
              />

              <span className="character-count">
                {formData.content.length}/1000
              </span>

            </div>

          </div>


          {/* =================================================
              ATTACHMENT
          ================================================= */}

          <div className="form-group-consultation-request full-width">

            <label>
              Tệp đính kèm
              <small>
                (nếu có)
              </small>
            </label>


            <label
              htmlFor="attachment"
              className="upload-area"
            >

              <input
                id="attachment"
                type="file"
                accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
                onChange={handleFileChange}
              />


              <FontAwesomeIcon
                icon={faUpload}
                className="upload-icon"
              />


              <span className="upload-title">

                {formData.attachment
                  ? formData.attachment.name
                  : "Kéo thả tệp vào đây hoặc nhấn để chọn"}

              </span>


              <span className="upload-description">

                Hỗ trợ định dạng: PDF, DOC, DOCX, JPG, PNG
                (Tối đa 10MB)

              </span>

            </label>

          </div>


          {/* =================================================
              ACTIONS
          ================================================= */}

          <div className="consultation-form-actions">


            <button
              type="button"
              className="reset-button"
              onClick={handleReset}
            >

              <FontAwesomeIcon
                icon={faRotate}
              />

              <span>
                Làm mới
              </span>

            </button>


            <button
              type="submit"
              className="submit-button"
              disabled={isSubmitting}
            >

              <FontAwesomeIcon
                icon={faPaperPlane}
              />

              <span>
                {isSubmitting
                  ? "Đang gửi..."
                  : "Gửi yêu cầu"}
              </span>

            </button>

          </div>

        </form>


        {/* =================================================
            RIGHT COLUMN
        ================================================= */}

        <aside className="consultation-request-sidebar">


          {/* =================================================
              REASONS
          ================================================= */}

          <div className="reasons-card">

            <h2>
              Vì sao nên gửi yêu cầu tư vấn tại Themis?
            </h2>


            <div className="reasons-list">

              {reasons.map(
                (reason, index) => (

                  <div
                    className="reason-item"
                    key={index}
                  >

                    <div className="reason-icon">

                      <FontAwesomeIcon
                        icon={reason.icon}
                      />

                    </div>


                    <div className="reason-content">

                      <h3>
                        {reason.title}
                      </h3>

                      <p>
                        {reason.description}
                      </p>

                    </div>

                  </div>

                )
              )}

            </div>

          </div>


          {/* =================================================
              QUOTE
          ================================================= */}

          <div className="request-quote-card">

            <div className="request-quote-content">

              <span>
                “
              </span>

              <p>
                Hãy đặt câu hỏi,
                <br />
                chúng tôi sẽ đồng hành
                <br />
                cùng bạn tìm ra giải pháp.
              </p>

              <div></div>

              <small>
                THEMIS TRUST
              </small>

            </div>

          </div>


          {/* =================================================
              SUPPORT
          ================================================= */}

          <div className="support-card">

            <div className="support-icon">

              <FontAwesomeIcon
                icon={faHeadset}
              />

            </div>


            <div className="support-content">

              <h3>
                Cần hỗ trợ?
              </h3>

              <p>
                Liên hệ với chúng tôi nếu bạn cần
                hỗ trợ gửi yêu cầu tư vấn.
              </p>

            </div>


            <button
              type="button"
              onClick={() =>
                console.log("Liên hệ ngay")
              }
            >

              Liên hệ ngay

              <FontAwesomeIcon
                icon={faArrowRight}
              />

            </button>

          </div>

        </aside>

      </section>

    </main>

  );
};


export default ConsultationRequestPage;