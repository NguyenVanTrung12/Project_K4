
import { useEffect, useState } from "react";
import { api } from "../../api/api";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faBriefcase,
  faUsers,
  faHouse,
  faUserGroup,
  faGavel,
  faFileLines,
  faFilePen,
  faGlobe,
  faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/homepage/legalServicesSection.css";
import { NavLink } from "react-router-dom";

function LegalServicesSection() {
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);

  // Map tên icon từ API sang FontAwesome Icon
  // const iconMap = {
  //   faUserGroup: faUserGroup,
  //   faBuilding: faBuilding,
  //   faHouse: faHouse,
  //   faHeart: faHeart,
  //   faScaleBalanced: faScaleBalanced,
  //   faCar: faCar,
  //   faPersonDigging: faPersonDigging,
  //   faEllipsis: faEllipsis,
  // };

  useEffect(() => {
    const fetchServices = async () => {
      try {
        const data = await api.get("/services");

        setServices(data);
      } catch (error) {
        console.error("Lỗi:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchServices();
  }, []);

  if (loading) {
    return <p>Đang tải dịch vụ...</p>;
  }

  return (
    <section className="legal-services-section">
      <div className="legal-services-container">

        {/* HEADER */}
        <div className="services-header">
          <div className="services-header-left">
            <span className="services-label">
              DỊCH VỤ PHÁP LÝ
            </span>

            <div className="services-title-row">
              <h2>
                Các lĩnh vực pháp lý phổ biến
              </h2>

              <NavLink
                to="/services"
                className="view-all-services"
                style={{ 'font-size': '20px' }}
              >
                Xem tất cả dịch vụ

                <FontAwesomeIcon
                  icon={faArrowRight}
                />
              </NavLink>
            </div>

            <p>
              Chúng tôi cung cấp đa dạng các dịch vụ pháp lý,
              đáp ứng mọi nhu cầu của cá nhân và doanh nghiệp.
            </p>
          </div>
        </div>

        {/* SERVICES GRID */}
        <div className="services-grid">
          {services.map((service) => (
            <div
              className="service-card"
              key={service.id}
            >
              {/* ICON */}
              <div
                className={`service-icon ${service.iconClass}`}
              >

                <FontAwesomeIcon
                  icon={service.practiceAreaId === 1 ? faGavel : service.practiceAreaId === 2 ? faUsers : service.practiceAreaId === 3 ? faBriefcase : service.practiceAreaId === 4 ? faUserGroup : service.practiceAreaId === 5 ? faHouse : faGlobe}
                />

              </div>

              {/* CONTENT */}
              <div className="service-content">
                <h3>
                  {service.title}
                </h3>

                <p>
                  {service.description}
                </p>
              </div>

              {/* ARROW */}
              <div className="service-arrow">
                <FontAwesomeIcon
                  icon={faArrowRight}
                />
              </div>
            </div>
          ))}
        </div>

      </div>
    </section>
  );
}

export default LegalServicesSection;
