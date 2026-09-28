import React from "react";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faHouse,
  faChevronRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/detailService/ServiceBusinessBanner.css";


/* =========================================================
   DATA MẶC ĐỊNH
   ---------------------------------------------------------
   Chỉ dùng để test giao diện.
   Khi gọi API, truyền dữ liệu thông qua props.
========================================================= */

const defaultData = {
  breadcrumbs: [
    {
      label: "Trang chủ",
      href: "/",
    },
    {
      label: "Dịch vụ pháp lý",
      href: "/dich-vu-phap-ly",
    },
    {
      label: "Doanh nghiệp",
      href: "#",
    },
  ],

  title: "Doanh nghiệp",

  description:
    "Đồng hành cùng doanh nghiệp trong suốt quá trình hình thành, phát triển và mở rộng, chúng tôi cung cấp giải pháp pháp lý toàn diện, hiệu quả và bền vững.",
};


/* =========================================================
   COMPONENT
========================================================= */

const ServiceBusinessBanner = ({
  data = defaultData,
}) => {

  /* =======================================================
     DATA
     -------------------------------------------------------
     API sau này có thể truyền vào đây.
  ======================================================= */

  const bannerData = {
    ...defaultData,
    ...data,
  };


  return (
    <section className="business-banner">

      {/* =================================================
          BACKGROUND
      ================================================= */}

      <div className="business-banner__background" />

      {/* =================================================
          DARK OVERLAY
      ================================================= */}

      <div className="business-banner__overlay" />


      {/* =================================================
          CONTENT
      ================================================= */}

      <div className="business-banner__container">

        <div className="business-banner__content">


          {/* =================================================
              BREADCRUMB
          ================================================= */}

          <nav
            className="business-banner__breadcrumb"
            aria-label="Breadcrumb"
          >

            {bannerData.breadcrumbs?.map(
              (item, index) => (

                <React.Fragment
                  key={`${item.label}-${index}`}
                >

                  <a
                    href={item.href || "#"}
                    className={`
                      business-banner__breadcrumb-item
                      ${
                        index ===
                        bannerData.breadcrumbs.length - 1
                          ? "business-banner__breadcrumb-item--current"
                          : ""
                      }
                    `}
                  >

                    {/* Icon trang chủ */}

                    {index === 0 && (
                      <FontAwesomeIcon
                        icon={faHouse}
                        className="business-banner__home-icon"
                      />
                    )}

                    <span>
                      {item.label}
                    </span>

                  </a>


                  {/* Chevron */}

                  {index <
                    bannerData.breadcrumbs.length - 1 && (
                    <FontAwesomeIcon
                      icon={faChevronRight}
                      className="business-banner__breadcrumb-arrow"
                    />
                  )}

                </React.Fragment>

              )
            )}

          </nav>


          {/* =================================================
              TITLE
          ================================================= */}

          <h1 className="business-banner__title">
            {bannerData.title}
          </h1>


          {/* =================================================
              DESCRIPTION
          ================================================= */}

          <p className="business-banner__description">
            {bannerData.description}
          </p>

        </div>

      </div>

    </section>
  );
};


export default ServiceBusinessBanner;