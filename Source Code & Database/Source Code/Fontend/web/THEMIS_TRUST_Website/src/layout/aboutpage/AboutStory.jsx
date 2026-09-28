import React, { useEffect, useState } from "react";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faScaleBalanced,
  faBullseye,
  faGem,
  faUsers,
  faFileLines,
  faGavel,
  faShieldHalved,
  faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/aboutpage/AboutStory.css";


// =========================================================
// API
// =========================================================

const API_BASE =
  import.meta.env.VITE_API_URL ||
  import.meta.env.VITE_API_BASE_URL ||
  "https://localhost:7139/api";


// =========================================================
// COMPONENT
// =========================================================

const AboutStory = () => {

  // =======================================================
  // SỨ MỆNH - TẦM NHÌN - GIÁ TRỊ CỐT LÕI
  // GIỮ NGUYÊN DỮ LIỆU CỨNG
  // =======================================================

  const values = [
    {
      icon: faScaleBalanced,

      title: "Sứ mệnh",

      description:
        "Bảo vệ quyền và lợi ích hợp pháp của khách hàng, góp phần xây dựng xã hội công bằng.",
    },

    {
      icon: faBullseye,

      title: "Tầm nhìn",

      description:
        "Trở thành hãng luật uy tín hàng đầu tại Việt Nam, được khách hàng tin tưởng lựa chọn.",
    },

    {
      icon: faGem,

      title: "Giá trị cốt lõi",

      description:
        "Chính trực – Chuyên nghiệp – Tận tâm – Hiệu quả – Hướng đến con người.",
    },
  ];


  // =======================================================
  // STATISTICS
  // LẤY DỮ LIỆU ĐỘNG TỪ /dashboard/public-stats
  // =======================================================

  const [statistics, setStatistics] = useState([
    {
      icon: faUsers,

      number: "0+",

      text: "Luật sư & chuyên gia",
    },

    {
      icon: faFileLines,

      number: "0+",

      text: "Khách hàng tin tưởng",
    },

    {
      icon: faGavel,

      number: "0+",

      text: "Vụ việc thành công",
    },

    {
      icon: faShieldHalved,

      number: "0/5",

      text: "Điểm đánh giá trung bình",
    },
  ]);


  // =======================================================
  // LOADING
  // =======================================================

  const [loading, setLoading] = useState(true);


  // =======================================================
  // LẤY THỐNG KÊ
  //
  // DÙNG CHUNG API VỚI PHẦN THỐNG KÊ Ở TRANG TRÊN
  //
  // GET /api/dashboard/public-stats
  //
  // Expected:
  //
  // {
  //   lawyers: 7,
  //   clients: 6,
  //   cases: 9,
  //   rating: 5
  // }
  //
  // =======================================================

  useEffect(() => {

    let cancelled = false;


    const fetchStatistics = async () => {

      try {

        setLoading(true);


        const response = await fetch(
          `${API_BASE}/dashboard/public-stats`,
          {
            method: "GET",

            headers: {
              Accept: "application/json",
            },
          }
        );


        if (!response.ok) {

          throw new Error(
            `HTTP ${response.status}`
          );

        }


        const result = await response.json();


        console.log(
          "ABOUT - PUBLIC STATS:",
          result
        );


        // =================================================
        // HỖ TRỢ RESPONSE:
        //
        // {
        //   lawyers: 7,
        //   clients: 6,
        //   cases: 9,
        //   rating: 5
        // }
        //
        // hoặc:
        //
        // {
        //   data: {
        //     lawyers: 7,
        //     clients: 6,
        //     cases: 9,
        //     rating: 5
        //   }
        // }
        // =================================================

        const data =
          result?.data ??
          result?.Data ??
          result;


        // =================================================
        // LUẬT SƯ
        // =================================================

        const lawyers =
          Number(
            data?.lawyers ??
            data?.Lawyers ??
            0
          );


        // =================================================
        // KHÁCH HÀNG
        // =================================================

        const clients =
          Number(
            data?.clients ??
            data?.Clients ??
            0
          );


        // =================================================
        // VỤ VIỆC
        // =================================================

        const cases =
          Number(
            data?.cases ??
            data?.Cases ??
            0
          );


        // =================================================
        // ĐIỂM ĐÁNH GIÁ
        // =================================================

        const rating =
          Number(
            data?.rating ??
            data?.Rating ??
            0
          );


        // =================================================
        // KIỂM TRA DỮ LIỆU
        // =================================================

        const safeLawyers =
          Number.isFinite(lawyers)
            ? lawyers
            : 0;


        const safeClients =
          Number.isFinite(clients)
            ? clients
            : 0;


        const safeCases =
          Number.isFinite(cases)
            ? cases
            : 0;


        const safeRating =
          Number.isFinite(rating)
            ? rating
            : 0;


        // =================================================
        // FORMAT SỐ
        // =================================================

        const formatNumber = (number) => {

          return Number(number).toLocaleString(
            "vi-VN"
          );

        };


        // =================================================
        // CẬP NHẬT STATISTICS
        // =================================================

        if (!cancelled) {

          setStatistics([
            {
              icon: faUsers,

              number:
                `${formatNumber(
                  safeLawyers
                )}+`,

              text:
                "Luật sư & chuyên gia",
            },

            {
              icon: faFileLines,

              number:
                `${formatNumber(
                  safeClients
                )}+`,

              text:
                "Khách hàng tin tưởng",
            },

            {
              icon: faGavel,

              number:
                `${formatNumber(
                  safeCases
                )}+`,

              text:
                "Vụ việc thành công",
            },

            {
              icon: faShieldHalved,

              number:
                `${safeRating}/5`,

              text:
                "Điểm đánh giá trung bình",
            },
          ]);

        }

      } catch (error) {

        console.error(
          "Lỗi lấy thống kê AboutStory:",
          error
        );

      } finally {

        if (!cancelled) {

          setLoading(false);

        }

      }

    };


    fetchStatistics();


    return () => {

      cancelled = true;

    };

  }, []);


  // =======================================================
  // RENDER
  // =======================================================

  return (
    <section className="about-story">


      {/* =================================================
          STORY SECTION
      ================================================= */}

      <div className="about-story-container">


        {/* =================================================
            LEFT CONTENT
        ================================================= */}

        <div className="about-story-intro">


          <span className="about-story-label">

            CÂU CHUYỆN CỦA CHÚNG TÔI

          </span>


          <h2>

            Hành trình kiến tạo niềm tin

          </h2>


          <p>

            THEMIS TRUST được thành lập với sứ mệnh mang
            đến dịch vụ pháp lý chất lượng cao, lấy khách
            hàng làm trung tâm. Chúng tôi tin rằng pháp
            luật không chỉ giải quyết vấn đề, mà còn góp
            phần xây dựng một xã hội công bằng, minh bạch
            và nhân văn hơn.

          </p>


          <button
            type="button"
            className="about-story-button"
          >

            Tìm hiểu thêm

            <FontAwesomeIcon
              icon={faArrowRight}
            />

          </button>


        </div>


        {/* =================================================
            RIGHT VALUES
        ================================================= */}

        <div className="about-story-values">


          {values.map(
            (item, index) => (

              <div
                className="about-value-card"
                key={index}
              >


                <div className="about-value-icon">

                  <FontAwesomeIcon
                    icon={item.icon}
                  />

                </div>


                <h3>

                  {item.title}

                </h3>


                <p>

                  {item.description}

                </p>


              </div>

            )
          )}


        </div>


      </div>


      {/* =================================================
          STATISTICS
      ================================================= */}

      <div className="about-statistics">


        <div className="about-statistics-container">


          {statistics.map(
            (item, index) => (

              <React.Fragment
                key={index}
              >


                {/* =========================================
                    STAT ITEM
                ========================================= */}

                <div className="about-stat-item">


                  <div className="about-stat-icon">

                    <FontAwesomeIcon
                      icon={item.icon}
                    />

                  </div>


                  <div className="about-stat-content">


                    <strong>

                      {loading
                        ? "..."
                        : item.number}

                    </strong>


                    <span>

                      {item.text}

                    </span>


                  </div>


                </div>


                {/* =========================================
                    DIVIDER
                ========================================= */}

                {index <
                  statistics.length - 1 && (

                  <div className="about-stat-divider"></div>

                )}


              </React.Fragment>

            )
          )}


        </div>


      </div>


    </section>
  );
};


export default AboutStory;