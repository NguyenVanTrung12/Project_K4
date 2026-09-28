import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faMagnifyingGlass,
  faCalendarDays,
  faCommentDots,
  faFileLines,
  faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/homepage/HowItWorksSection.css";
import { NavLink } from "react-router-dom";

function HowItWorksSection() {
  const steps = [
    {
      number: "1",
      title: "Tìm kiếm luật sư",
      description:
        "Lọc theo lĩnh vực, kinh nghiệm, đánh giá...",
      icon: faMagnifyingGlass,
    },
    {
      number: "2",
      title: "Đặt lịch tư vấn",
      description:
        "Chọn thời gian và hình thức tư vấn phù hợp.",
      icon: faCalendarDays,
    },
    {
      number: "3",
      title: "Trao đổi & tư vấn",
      description:
        "Nhận tư vấn trực tiếp từ luật sư qua chat hoặc cuộc gọi.",
      icon: faCommentDots,
    },
    {
      number: "4",
      title: "Theo dõi hồ sơ",
      description:
        "Cập nhật tiến độ và đánh giá dịch vụ.",
      icon: faFileLines,
    },
  ];

  return (
    <section className="how-it-works-section">
      <div className="how-it-works-container">

        {/* LEFT CONTENT */}
        <div className="how-it-works-intro">

          <span className="how-it-works-label">
            QUY TRÌNH SỬ DỤNG
          </span>

          <h2>
            Chỉ 4 bước đơn giản
          </h2>

          <p>
            Từ tìm kiếm luật sư đến nhận tư vấn,
            mọi thứ đều trở nên dễ dàng và nhanh chóng
            với THEMIS TRUST.
          </p>

          <NavLink
            to="/lawyers"
            className="start-now-button"
          >
            Bắt đầu ngay

            <FontAwesomeIcon
              icon={faArrowRight}
            />
          </NavLink>

        </div>


        {/* STEPS */}
        <div className="steps-container">

          {steps.map((step, index) => (
            <div
              className="step-wrapper"
              key={step.number}
            >

              <div className="step-item">

                <div className="step-icon">
                  <FontAwesomeIcon
                    icon={step.icon}
                  />
                </div>

                <h3>
                  {step.number}. {step.title}
                </h3>

                <p>
                  {step.description}
                </p>

              </div>


              {/* ARROW BETWEEN STEPS */}

              {index < steps.length - 1 && (
                <div className="step-arrow">
                  <FontAwesomeIcon
                    icon={faArrowRight}
                  />
                </div>
              )}

            </div>
          ))}

        </div>

      </div>
    </section>
  );
}

export default HowItWorksSection;