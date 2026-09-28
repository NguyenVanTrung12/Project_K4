import { useEffect, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { api } from "../../api/api";

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

import { NavLink } from "react-router-dom";

import "../../assets/css/servicepage/LegalServicesSection.css";


/* =========================================================
   DANH SÁCH DỊCH VỤ
   ---------------------------------------------------------
   id dùng để chuyển trang:
   /services/:id
========================================================= */


/* =========================================================
   COMPONENT
========================================================= */

const LegalServicesSection = () => {
  const [services,setServices]=useState([]);
  useEffect(()=>{api.get("/services").then(setServices).catch(console.error)},[]);

  return (
    <section className="legal-services">

      <div className="legal-services-container">


        {/* =================================================
            SECTION HEADER
        ================================================= */}

        <div className="services-header">

          <div className="services-heading">


            {/* LABEL */}

            <span className="services-label">
              LĨNH VỰC HOẠT ĐỘNG
            </span>


            {/* TITLE + VIEW ALL */}

            <div className="services-title-row">

              <h2>
                Các dịch vụ pháp lý của chúng tôi
              </h2>


              {/* =========================================
                  XEM TẤT CẢ DỊCH VỤ
              ========================================== */}

              <NavLink
                to="/services"
                className="view-all-services"
              >

                <span>
                  Xem tất cả dịch vụ
                </span>

                <FontAwesomeIcon
                  icon={faArrowRight}
                />

              </NavLink>

            </div>


            {/* DESCRIPTION */}

            <p>
              THEMIS TRUST cung cấp giải pháp pháp lý toàn diện,
              đáp ứng nhu cầu đa dạng của cá nhân, tổ chức và doanh nghiệp.
            </p>

          </div>

        </div>


        {/* =================================================
            SERVICE GRID
        ================================================= */}

        <div className="services-grid">

          {services.map((service) => (

            <div
              className="service-card"
              key={service.id}
            >


              {/* =========================================
                  ICON
              ========================================== */}

              <div
                className={`service-icon ${service.iconClass}`}
              >

                <FontAwesomeIcon
                  icon={service.practiceAreaId === 1 ? faGavel : service.practiceAreaId === 2 ? faUsers : service.practiceAreaId === 3 ? faBriefcase : service.practiceAreaId === 4 ? faUserGroup : service.practiceAreaId === 5 ? faHouse : faGlobe}
                />

              </div>


              {/* =========================================
                  TITLE
              ========================================== */}

              <h3>
                {service.title}
              </h3>


              {/* =========================================
                  DESCRIPTION
              ========================================== */}

              <p>
                {service.description}
              </p>


              {/* =========================================
                  DETAIL
                  /services/:id
              ========================================== */}

              <NavLink
                to={`/services/${service.id}`}
                className="service-detail"
              >

                <span>
                  Xem chi tiết
                </span>

                <FontAwesomeIcon
                  icon={faArrowRight}
                />

              </NavLink>

            </div>

          ))}

        </div>

      </div>

    </section>
  );
};


export default LegalServicesSection;