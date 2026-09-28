import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faHeadset,
  faShieldHalved,
  faUsers,
  faHandshake,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/contact/ContactFeatures.css";

const ContactFeatures = () => {
  const features = [
    {
      icon: faHeadset,
      title: "Tư vấn nhanh chóng",
      description: "Phản hồi trong 24 giờ",
    },
    {
      icon: faShieldHalved,
      title: "Bảo mật tuyệt đối",
      description: "Thông tin của bạn luôn được bảo vệ an toàn",
    },
    {
      icon: faUsers,
      title: "Luật sư giàu kinh nghiệm",
      description: "Đồng hành trong mọi vấn đề pháp lý",
    },
    {
      icon: faHandshake,
      title: "Giải pháp hiệu quả",
      description: "Tối ưu quyền lợi của bạn",
    },
  ];

  return (
    <section className="contact-features">
      <div className="contact-features-container">

        {features.map((feature, index) => (
          <div
            className={`contact-feature-item ${
              index !== features.length - 1
                ? "contact-feature-divider"
                : ""
            }`}
            key={index}
          >

            {/* Icon */}
            <div className="contact-feature-icon">
              <FontAwesomeIcon icon={feature.icon} />
            </div>

            {/* Content */}
            <div className="contact-feature-content">
              <h3>{feature.title}</h3>
              <p>{feature.description}</p>
            </div>

          </div>
        ))}

      </div>
    </section>
  );
};

export default ContactFeatures;