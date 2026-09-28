import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faLandmark,
  faQuoteLeft,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/aboutpage/DevelopmentTimeline.css";

const milestones = [
  {
    year: "2018",
    title: "Thành lập",
    description: "THEMIS TRUST",
  },
  {
    year: "2020",
    title: "Mở rộng đội ngũ",
    description: "và lĩnh vực hoạt động",
  },
  {
    year: "2022",
    title: "Đạt mốc 2.000+",
    description: "khách hàng tin tưởng",
  },
  {
    year: "2024",
    title: "Khẳng định vị thế",
    description: "trong ngành luật",
  },
  {
    year: "Hiện tại",
    title: "Tiếp tục đồng hành",
    description: "vì một xã hội tốt đẹp hơn",
    current: true,
  },
];

const DevelopmentTimeline = () => {
  return (
    <section className="development-section">
      <div className="development-container">

        {/* HEADER */}
        <div className="development-header">
          <span className="development-label">
            DẤU MỐC PHÁT TRIỂN
          </span>

          <h2 className="development-title">
            Những bước tiến vững chắc
          </h2>
        </div>

        {/* TIMELINE */}
        <div className="timeline">

          <div className="timeline-line"></div>

          {milestones.map((item, index) => (
            <div
              className={`timeline-item ${
                item.current ? "timeline-current" : ""
              }`}
              key={index}
            >
              <div className="timeline-dot">
                {item.current && (
                  <span className="timeline-dot-inner"></span>
                )}
              </div>

              <div className="timeline-content">

                <div className="timeline-year">
                  {item.year}
                </div>

                <div className="timeline-text">
                  <strong>{item.title}</strong>

                  <span>{item.description}</span>
                </div>

              </div>
            </div>
          ))}

        </div>

        {/* RIGHT QUOTE */}
        <div className="development-quote">

          <div className="quote-background-icon">
            <FontAwesomeIcon icon={faLandmark} />
          </div>

          <div className="quote-content">

            <FontAwesomeIcon
              icon={faQuoteLeft}
              className="quote-icon"
            />

            <p>
              “Niềm tin của bạn
              <br />
              là động lực để chúng tôi
              <br />
              phát triển.”
            </p>

            <div className="quote-line"></div>

          </div>

        </div>

      </div>
    </section>
  );
};

export default DevelopmentTimeline;