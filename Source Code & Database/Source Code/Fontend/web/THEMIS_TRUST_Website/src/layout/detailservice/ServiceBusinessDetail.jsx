import React, { useEffect, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faBuilding,
  faUsers,
  faHouse,
  faUserGroup,
  faGavel,
  faFileLines,
  faBriefcase,
  faChartLine,
  faArrowRight,
  faFileContract,
  faHandshake,
  faScaleBalanced,
  faClipboardList,
  faMagnifyingGlass,
  faPenToSquare,
  faFlagCheckered,
  faShieldHalved,
  faLock,
  faUserTie,
} from "@fortawesome/free-solid-svg-icons";

import { NavLink } from "react-router-dom";

import "../../assets/css/detailService/ServiceBusinessDetail.css";


/* =========================================================
   DANH MỤC DỊCH VỤ
   ---------------------------------------------------------
   id:
   Đây là ID bạn sẽ dùng để gọi API.

   Ví dụ:
   /api/categories/1
   /api/categories/2
   ...
========================================================= */

const categories = [
  {
    id: 1,
    title: "Doanh nghiệp",
    icon: faBuilding,
  },
  {
    id: 2,
    title: "Dân sự",
    icon: faUsers,
  },
  {
    id: 3,
    title: "Đất đai",
    icon: faHouse,
  },
  {
    id: 4,
    title: "Hôn nhân & Gia đình",
    icon: faUserGroup,
  },
  {
    id: 5,
    title: "Hình sự",
    icon: faGavel,
  },
  {
    id: 6,
    title: "Hành chính",
    icon: faFileLines,
  },
  {
    id: 7,
    title: "Lao động",
    icon: faUserTie,
  },
  {
    id: 8,
    title: "Đầu tư & Giấy phép",
    icon: faChartLine,
  },
];


/* =========================================================
   DỮ LIỆU MẪU
   ---------------------------------------------------------
   Chỉ dùng để dựng giao diện.

   SAU NÀY CÓ THỂ THAY BẰNG DATA TỪ API.
========================================================= */

const defaultData = {

  overview: {
    title: "Tổng quan dịch vụ",

    description:
      "Dịch vụ tư vấn pháp lý doanh nghiệp của THEMIS TRUST bao gồm tư vấn thành lập, tái cấu trúc, hợp đồng thương mại, tuân thủ pháp luật, M&A và giải quyết tranh chấp. Chúng tôi giúp doanh nghiệp xây dựng nền tảng pháp lý vững chắc, tối ưu hoạt động và giảm thiểu rủi ro.",
  },


  contentTitle: "Nội dung dịch vụ",


  services: [
    {
      id: 1,
      title: "Thành lập doanh nghiệp",
      description:
        "Tư vấn loại hình, ngành nghề, hồ sơ và thủ tục pháp lý.",
      icon: faBuilding,
    },
    {
      id: 2,
      title: "Tư vấn hợp đồng",
      description:
        "Soạn thảo, rà soát, đàm phán các loại hợp đồng thương mại.",
      icon: faFileContract,
    },
    {
      id: 3,
      title: "Quản trị doanh nghiệp",
      description:
        "Tư vấn cơ cấu tổ chức, quy chế nội bộ và thủ tục pháp lý.",
      icon: faUsers,
    },
    {
      id: 4,
      title: "M&A và tái cấu trúc",
      description:
        "Tư vấn mua bán – sáp nhập, chuyển nhượng, tái cấu trúc doanh nghiệp.",
      icon: faHandshake,
    },
    {
      id: 5,
      title: "Giải quyết tranh chấp",
      description:
        "Đại diện, thương lượng và bảo vệ quyền lợi trong tranh chấp kinh doanh.",
      icon: faGavel,
    },
    {
      id: 6,
      title: "Tư vấn thường xuyên",
      description:
        "Đồng hành pháp lý và tư vấn doanh nghiệp trong suốt quá trình hoạt động.",
      icon: faScaleBalanced,
    },
  ],


  processTitle: "Quy trình thực hiện",


  process: [
    {
      id: 1,
      number: "01",
      title: "Tiếp nhận yêu cầu",
      description:
        "Lắng nghe và phân tích nhu cầu của khách hàng.",
      icon: faClipboardList,
    },
    {
      id: 2,
      number: "02",
      title: "Phân tích & đề xuất",
      description:
        "Đánh giá rủi ro và đưa ra phương án phù hợp.",
      icon: faMagnifyingGlass,
    },
    {
      id: 3,
      number: "03",
      title: "Ký kết hợp đồng",
      description:
        "Thống nhất phạm vi và ký kết hợp đồng dịch vụ.",
      icon: faPenToSquare,
    },
    {
      id: 4,
      number: "04",
      title: "Triển khai thực hiện",
      description:
        "Thực hiện công việc theo kế hoạch đã thống nhất.",
      icon: faBriefcase,
    },
    {
      id: 5,
      number: "05",
      title: "Báo cáo & đồng hành",
      description:
        "Báo cáo kết quả và tiếp tục hỗ trợ khách hàng.",
      icon: faFlagCheckered,
    },
  ],


  relatedTitle: "Dịch vụ liên quan",


  relatedServices: [
    {
      id: 2,
      title: "Dân sự",
      description:
        "Giải quyết tranh chấp dân sự nhanh chóng, hiệu quả.",
      icon: faUsers,
    },
    {
      id: 3,
      title: "Đất đai",
      description:
        "Tư vấn pháp lý đất đai toàn diện.",
      icon: faHouse,
    },
    {
      id: 4,
      title: "Hôn nhân & Gia đình",
      description:
        "Bảo vệ quyền và lợi ích gia đình.",
      icon: faUserGroup,
    },
    {
      id: 5,
      title: "Hình sự",
      description:
        "Bảo vệ quyền lợi, bào chữa trong vụ án.",
      icon: faGavel,
    },
  ],


  quote:
    "Chúng tôi đồng hành để xây dựng nền tảng pháp lý vững chắc cho doanh nghiệp.",

};


/* =========================================================
   COMPONENT
========================================================= */

const ServiceBusinessDetail = ({
  data = defaultData,

  /*
    Callback để component cha nhận ID.

    Ví dụ:
    onCategoryChange={(id) => {
      fetch(`/api/categories/${id}`)
    }}
  */
  onCategoryChange,

  /*
    Callback khi click dịch vụ.
  */
  onServiceClick,
}) => {


  /* =======================================================
     STATE CATEGORY
  ======================================================= */

  const [selectedCategoryId, setSelectedCategoryId] =
    useState(categories[0].id);


  /* =======================================================
     STATE DATA
  ======================================================= */

  const [serviceData, setServiceData] =
    useState(data);


  /* =======================================================
     Khi data từ API thay đổi
  ======================================================= */

  useEffect(() => {

    setServiceData(data);

  }, [data]);


  /* =======================================================
     CLICK CATEGORY
  ======================================================= */

  const handleCategoryClick = (category) => {

    const id = category.id;

    setSelectedCategoryId(id);


    /*
      Gửi ID lên component cha.

      Component cha có thể dùng ID này
      để gọi API.
    */

    if (onCategoryChange) {
      onCategoryChange(id);
    }


    console.log(
      "Danh mục được chọn:",
      id
    );
  };


  /* =======================================================
     CLICK SERVICE
  ======================================================= */

  const handleServiceClick = (service) => {

    if (onServiceClick) {
      onServiceClick(service);
    }

    console.log(
      "Dịch vụ được chọn:",
      service.id
    );
  };


  return (

    <section className="service-overview">


      {/* =================================================
          CATEGORY NAVIGATION
      ================================================= */}

      <div className="service-overview__categories">

        <div className="service-overview__categories-inner">

          {categories.map((category) => (

            <button
              type="button"

              key={category.id}

              className={`
                service-overview__category
                ${
                  selectedCategoryId === category.id
                    ? "service-overview__category--active"
                    : ""
                }
              `}

              onClick={() =>
                handleCategoryClick(category)
              }
            >

              <span className="service-overview__category-icon">

                <FontAwesomeIcon
                  icon={category.icon}
                />

              </span>

              <span className="service-overview__category-title">

                {category.title}

              </span>

            </button>

          ))}

        </div>

      </div>


      {/* =================================================
          MAIN LAYOUT
      ================================================= */}

      <div className="service-overview__container">


        {/* =================================================
            MAIN CONTENT
        ================================================= */}

        <main className="service-overview__main">


          {/* =================================================
              OVERVIEW
          ================================================= */}

          <section className="service-overview__overview">


            <div className="service-overview__section-title">

              <h2>
                {serviceData.overview?.title}
              </h2>

              <span></span>

            </div>


            <div className="service-overview__overview-grid">


              {/* IMAGE */}

              <div className="service-overview__overview-image">

                <img
                  src="/assets/images/service/business-service.png"
                  alt="Dịch vụ pháp lý doanh nghiệp"
                />

              </div>


              {/* TEXT */}

              <div className="service-overview__overview-content">

                <p>
                  {serviceData.overview?.description}
                </p>


                {/* QUOTE */}

                <div className="service-overview__quote">

                  <div className="service-overview__quote-mark">
                    “
                  </div>

                  <p>
                    {serviceData.quote}
                  </p>

                  <span>
                    — THEMIS TRUST
                  </span>

                </div>

              </div>

            </div>

          </section>


          {/* =================================================
              SERVICE CONTENT
          ================================================= */}

          <section className="service-overview__content">


            <div className="service-overview__section-title">

              <h2>
                {serviceData.contentTitle}
              </h2>

              <span></span>

            </div>


            <div className="service-overview__service-grid">

              {serviceData.services?.map(
                (service) => (

                  <button
                    type="button"

                    key={service.id}

                    className="service-overview__service-card"

                    onClick={() =>
                      handleServiceClick(service)
                    }
                  >

                    <div className="service-overview__service-icon">

                      <FontAwesomeIcon
                        icon={
                          service.icon ||
                          faBriefcase
                        }
                      />

                    </div>


                    <div className="service-overview__service-text">

                      <h3>
                        {service.title}
                      </h3>

                      <p>
                        {service.description}
                      </p>

                    </div>


                    <FontAwesomeIcon
                      icon={faArrowRight}
                      className="service-overview__service-arrow"
                    />

                  </button>

                )
              )}

            </div>

          </section>


          {/* =================================================
              PROCESS
          ================================================= */}

          <section className="service-overview__process">


            <div className="service-overview__section-title">

              <h2>
                {serviceData.processTitle}
              </h2>

              <span></span>

            </div>


            <div className="service-overview__process-list">

              {serviceData.process?.map(
                (item, index) => (

                  <React.Fragment
                    key={item.id}
                  >

                    <div className="service-overview__process-item">

                      <div className="service-overview__process-icon">

                        <FontAwesomeIcon
                          icon={item.icon}
                        />

                      </div>


                      <span className="service-overview__process-number">

                        {item.number}

                      </span>


                      <h3>
                        {item.title}
                      </h3>


                      <p>
                        {item.description}
                      </p>

                    </div>


                    {index <
                      serviceData.process.length - 1 && (

                      <div className="service-overview__process-arrow">

                        <FontAwesomeIcon
                          icon={faArrowRight}
                        />

                      </div>

                    )}

                  </React.Fragment>

                )
              )}

            </div>

          </section>


          {/* =================================================
              RELATED SERVICES
          ================================================= */}

          <section className="service-overview__related">


            <div className="service-overview__related-header">

              <div className="service-overview__section-title">

                <h2>
                  {serviceData.relatedTitle}
                </h2>

                <span></span>

              </div>


              <NavLink
                to="/services"
                className="service-overview__view-all"
              >

                <span>
                  Xem tất cả
                </span>

                <FontAwesomeIcon
                  icon={faArrowRight}
                />

              </NavLink>

            </div>


            <div className="service-overview__related-grid">

              {serviceData.relatedServices?.map(
                (service) => (

                  <NavLink
                    key={service.id}

                    to={`/services/${service.id}`}

                    className="service-overview__related-card"

                    onClick={() =>
                      handleServiceClick(service)
                    }
                  >

                    <div className="service-overview__related-image">

                      <div className="service-overview__related-placeholder">

                        <FontAwesomeIcon
                          icon={service.icon}
                        />

                      </div>

                    </div>


                    <div className="service-overview__related-content">

                      <h3>
                        {service.title}
                      </h3>

                      <p>
                        {service.description}
                      </p>

                    </div>


                    <FontAwesomeIcon
                      icon={faArrowRight}
                      className="service-overview__related-arrow"
                    />

                  </NavLink>

                )
              )}

            </div>

          </section>

        </main>


        {/* =================================================
            RIGHT SIDEBAR
        ================================================= */}

        <aside className="service-overview__sidebar">


          {/* =================================================
              CONSULTATION FORM
          ================================================= */}

          <div className="service-overview__consultation">

            <h2>
              Bạn cần tư vấn?
            </h2>

            <p>
              Hãy để thông tin, chúng tôi sẽ liên hệ
              ngay trong vòng 24 giờ.
            </p>


            <form
              className="service-overview__form"

              onSubmit={(event) => {
                event.preventDefault();

                console.log(
                  "Gửi yêu cầu tư vấn"
                );
              }}
            >

              <input
                type="text"
                placeholder="Họ và tên *"
              />


              <input
                type="tel"
                placeholder="Số điện thoại *"
              />


              <input
                type="email"
                placeholder="Email"
              />


              <select defaultValue="">

                <option
                  value=""
                  disabled
                >
                  Chọn nhu cầu tư vấn
                </option>

                <option value="1">
                  Thành lập doanh nghiệp
                </option>

                <option value="2">
                  Tư vấn hợp đồng
                </option>

                <option value="3">
                  Tranh chấp doanh nghiệp
                </option>

              </select>


              <textarea
                placeholder="Nội dung yêu cầu"
                rows="4"
              />


              <button
                type="submit"
              >

                Gửi yêu cầu tư vấn

                <FontAwesomeIcon
                  icon={faArrowRight}
                />

              </button>

            </form>


            <div className="service-overview__privacy">

              <FontAwesomeIcon
                icon={faLock}
              />

              <span>
                Thông tin của bạn được bảo mật tuyệt đối
              </span>

            </div>

          </div>


          {/* =================================================
              WHY US
          ================================================= */}

          <div className="service-overview__why">

            <h2>
              Tại sao chọn chúng tôi?
            </h2>


            <div className="service-overview__why-list">


              <div className="service-overview__why-item">

                <div className="service-overview__why-icon">

                  <FontAwesomeIcon
                    icon={faBriefcase}
                  />

                </div>

                <div>

                  <h3>
                    Kinh nghiệm thực tiễn
                  </h3>

                  <p>
                    Hơn 10 năm đồng hành cùng hàng trăm doanh nghiệp.
                  </p>

                </div>

              </div>


              <div className="service-overview__why-item">

                <div className="service-overview__why-icon">

                  <FontAwesomeIcon
                    icon={faScaleBalanced}
                  />

                </div>

                <div>

                  <h3>
                    Giải pháp tối ưu
                  </h3>

                  <p>
                    Phù hợp với từng ngành nghề và giai đoạn phát triển.
                  </p>

                </div>

              </div>


              <div className="service-overview__why-item">

                <div className="service-overview__why-icon">

                  <FontAwesomeIcon
                    icon={faShieldHalved}
                  />

                </div>

                <div>

                  <h3>
                    Bảo mật tuyệt đối
                  </h3>

                  <p>
                    Cam kết bảo vệ thông tin và quyền lợi khách hàng.
                  </p>

                </div>

              </div>


              <div className="service-overview__why-item">

                <div className="service-overview__why-icon">

                  <FontAwesomeIcon
                    icon={faUsers}
                  />

                </div>

                <div>

                  <h3>
                    Đồng hành dài hạn
                  </h3>

                  <p>
                    Đồng hành cùng khách hàng trong mọi vấn đề pháp lý.
                  </p>

                </div>

              </div>

            </div>

          </div>


          {/* =================================================
              BOTTOM BANNER
          ================================================= */}

          <div className="service-overview__banner">

            <div className="service-overview__banner-content">

              <h3>
                Đồng hành pháp lý
              </h3>

              <p>
                Kiến tạo giá trị
                <br />
                doanh nghiệp
              </p>

              <span></span>

            </div>

          </div>

        </aside>

      </div>

    </section>
  );
};


export default ServiceBusinessDetail;