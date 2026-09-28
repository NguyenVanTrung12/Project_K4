import { useEffect, useMemo, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faGraduationCap,
  faAward,
  faBriefcase,
  faCertificate,
  faBuilding,
  faGlobe,
  faFileContract,
  faScaleBalanced,
  faPeopleArrows,
  faShieldHalved,
  faArrowRight,
  faStar,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/detailLawyer/LawyerCareer.css";


// =========================================================
// API
// =========================================================

const API_BASE =
  import.meta.env.VITE_API_URL ||
  import.meta.env.VITE_API_BASE_URL ||
  "https://localhost:7139/api";


// =========================================================
// HÀM HỖ TRỢ
// =========================================================

const firstValue = (...values) =>
  values.find(
    (value) =>
      value !== null &&
      value !== undefined &&
      value !== "" &&
      !(Array.isArray(value) && value.length === 0)
  );


const toText = (value) => {
  if (value === null || value === undefined) {
    return "";
  }

  if (Array.isArray(value)) {
    return value
      .map((item) => {
        if (typeof item === "string") {
          return item;
        }

        return firstValue(
          item?.name,
          item?.Name,
          item?.title,
          item?.Title,
          item?.fieldName,
          item?.FieldName
        );
      })
      .filter(Boolean)
      .join(", ");
  }

  return String(value);
};


const getId = (value) => {
  if (
    value === null ||
    value === undefined ||
    value === ""
  ) {
    return null;
  }

  return String(value);
};


// =========================================================
// URL ẢNH
// =========================================================

const normalizeUrl = (
  url,
  fallback = "/images/lawyers/ls1.png"
) => {
  if (!url) {
    return fallback;
  }

  const value = String(url).trim();

  if (!value || value === "#") {
    return fallback;
  }

  if (
    /^https?:\/\//i.test(value) ||
    /^(data:|blob:)/i.test(value)
  ) {
    return value;
  }

  if (value.startsWith("/")) {
    if (value.startsWith("/api/")) {
      return `${API_BASE.replace(
        /\/$/,
        ""
      )}${value.substring(4)}`;
    }

    const apiOrigin = API_BASE
      .replace(/\/api\/?$/, "")
      .replace(/\/$/, "");

    return `${apiOrigin}${value}`;
  }

  return `${API_BASE.replace(
    /\/$/,
    ""
  )}/${value.replace(/^\/+/, "")}`;
};


// =========================================================
// DATA CỨNG
// CHỈ GIỮ CỨNG 3 PHẦN:
// - Kinh nghiệm
// - Học vấn
// - Chứng chỉ & Giải thưởng
// =========================================================

const STATIC_CAREER_DATA = {

  // =======================================================
  // KINH NGHIỆM
  // =======================================================

  experiences: [
    {
      period: "2020 – nay",

      position: "Luật sư thành viên",

      company: "THEMIS TRUST",

      description:
        "Tư vấn pháp lý cho doanh nghiệp trong nước và quốc tế, tham gia giải quyết nhiều vụ việc tranh chấp thương mại phức tạp.",
    },

    {
      period: "2015 – 2020",

      position: "Luật sư cấp cao",

      company: "Công ty Luật ABC",

      description:
        "Tư vấn và đại diện khách hàng trong các vụ việc về đầu tư, hợp đồng, mua bán – sáp nhập (M&A).",
    },

    {
      period: "2010 – 2015",

      position: "Luật sư",

      company: "Công ty Luật XYZ",

      description:
        "Tham gia tư vấn pháp lý thường xuyên cho doanh nghiệp, hỗ trợ xây dựng hệ thống quản trị rủi ro pháp lý.",
    },
  ],


  // =======================================================
  // HỌC VẤN
  // =======================================================

  education: [
    {
      period: "2006 – 2010",

      degree: "Cử nhân Luật",

      school:
        "Trường Đại học Luật TP. Hồ Chí Minh",
    },

    {
      period: "2011 – 2013",

      degree: "Thạc sĩ Luật Kinh tế",

      school:
        "Đại học Quốc gia Singapore (NUS)",
    },
  ],


  // =======================================================
  // CHỨNG CHỈ & GIẢI THƯỞNG
  // =======================================================

  awards: [
    {
      title:
        "Chứng chỉ hành nghề luật sư",

      organization:
        "Liên đoàn Luật sư Việt Nam",
    },

    {
      title:
        "Top 10 Luật sư tiêu biểu năm 2023",

      organization:
        "Tạp chí Pháp luật & Doanh nghiệp",
    },

    {
      title:
        "Chứng chỉ tư vấn đầu tư quốc tế",

      organization:
        "International Legal Association",
    },
  ],
};


// =========================================================
// ICON LĨNH VỰC
// =========================================================

const SPECIALTY_ICONS = [
  faBuilding,
  faGlobe,
  faFileContract,
  faScaleBalanced,
  faPeopleArrows,
  faShieldHalved,
];


// =========================================================
// CHUẨN HÓA LĨNH VỰC
// =========================================================

const normalizeSpecialties = (items) => {
  if (!items) {
    return [];
  }

  let list = [];

  if (Array.isArray(items)) {
    list = items;
  } else if (typeof items === "string") {
    list = items
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);
  }

  return list
    .map((item, index) => {

      if (typeof item === "string") {
        return {
          name: item,
          icon:
            SPECIALTY_ICONS[
              index %
                SPECIALTY_ICONS.length
            ],
        };
      }

      const name = toText(
        firstValue(
          item?.name,
          item?.Name,
          item?.title,
          item?.Title,
          item?.fieldName,
          item?.FieldName,
          item?.practiceAreaName,
          item?.PracticeAreaName
        )
      );

      return {
        name,

        icon:
          SPECIALTY_ICONS[
            index %
              SPECIALTY_ICONS.length
          ],
      };
    })
    .filter((item) => item.name);
};


// =========================================================
// CHUẨN HÓA LUẬT SƯ
// =========================================================

const normalizeOtherLawyer = (
  item,
  index
) => {

  if (!item) {
    return null;
  }

  const user =
    item?.user ||
    item?.User ||
    {};

  const id = getId(
    firstValue(
      item?.id,
      item?.Id,
      item?.lawyerId,
      item?.LawyerId
    )
  );

  const name = toText(
    firstValue(
      item?.name,
      item?.Name,
      item?.fullName,
      item?.FullName,

      user?.name,
      user?.Name,
      user?.fullName,
      user?.FullName
    )
  );

  const position = toText(
    firstValue(
      item?.position,
      item?.Position,
      item?.title,
      item?.Title,
      item?.jobTitle,
      item?.JobTitle,

      "Luật sư"
    )
  );

  const yearsExp = firstValue(
    item?.yearsExp,
    item?.YearsExp,

    item?.experienceYears,
    item?.ExperienceYears,

    item?.yearsOfExperience,
    item?.YearsOfExperience,

    item?.experience,
    item?.Experience,

    0
  );

  let experience = "";

  if (
    typeof yearsExp === "number" ||
    !isNaN(Number(yearsExp))
  ) {
    experience =
      `${Number(yearsExp)} năm kinh nghiệm`;
  } else {
    experience = toText(yearsExp);
  }


  const specialty = toText(
    firstValue(
      item?.specialty,
      item?.Specialty,

      item?.specialties,
      item?.Specialties,

      item?.practiceArea,
      item?.PracticeArea,

      item?.practiceAreas,
      item?.PracticeAreas,

      "Chưa cập nhật"
    )
  );


  const image = normalizeUrl(
    firstValue(
      item?.image,
      item?.Image,

      item?.imageUrl,
      item?.ImageUrl,

      item?.avatar,
      item?.Avatar,

      item?.avatarUrl,
      item?.AvatarUrl,

      user?.avatar,
      user?.Avatar,

      user?.avatarUrl,
      user?.AvatarUrl
    )
  );


  return {
    ...item,

    id: id || `lawyer-${index}`,

    name:
      name ||
      "Luật sư",

    position:
      position ||
      "Luật sư",

    experience,

    specialty,

    image,
  };
};


// =========================================================
// COMPONENT
// =========================================================

const LawyerCareer = ({
  lawyerData = null,

  lawyerId = null,

  onLawyerClick,
}) => {

  const {
    id: routeLawyerId,
  } = useParams();

  const navigate = useNavigate();


  const [activeTab, setActiveTab] =
    useState("experience");


  const resolvedLawyerId =
    useMemo(
      () =>
        getId(
          firstValue(
            lawyerId,

            routeLawyerId,

            lawyerData?.id,
            lawyerData?.Id,

            lawyerData?.lawyerId,
            lawyerData?.LawyerId
          )
        ),

      [
        lawyerId,
        routeLawyerId,
        lawyerData,
      ]
    );


  const [lawyer, setLawyer] =
    useState(lawyerData);


  const [otherLawyers, setOtherLawyers] =
    useState([]);


  const [loading, setLoading] =
    useState(false);


  const [error, setError] =
    useState("");



  // =======================================================
  // LẤY THÔNG TIN LUẬT SƯ HIỆN TẠI
  // =======================================================

  useEffect(() => {

    let cancelled = false;


    const loadLawyer = async () => {

      if (!resolvedLawyerId) {
        return;
      }


      try {

        setLoading(true);

        setError("");


        const response =
          await fetch(
            `${API_BASE.replace(
              /\/$/,
              ""
            )}/lawyers/${encodeURIComponent(
              resolvedLawyerId
            )}`,
            {
              method: "GET",

              headers: {
                Accept:
                  "application/json",
              },
            }
          );


        if (!response.ok) {

          throw new Error(
            `Không thể tải thông tin luật sư (${response.status}).`
          );
        }


        const result =
          await response.json();


        if (!cancelled) {

          const raw =
            result?.data ||
            result?.lawyer ||
            result?.Lawyer ||
            result?.result ||
            result;


          setLawyer(raw);
        }

      } catch (err) {

        console.error(
          "Load lawyer error:",
          err
        );


        if (!cancelled) {

          setError(
            err?.message ||
              "Không thể tải thông tin luật sư."
          );

          // Nếu parent đã truyền lawyerData
          // thì vẫn giữ dữ liệu đó
          if (lawyerData) {
            setLawyer(
              lawyerData
            );
          }
        }

      } finally {

        if (!cancelled) {
          setLoading(false);
        }

      }
    };


    loadLawyer();


    return () => {
      cancelled = true;
    };

  }, [
    resolvedLawyerId,
    lawyerData,
  ]);



  // =======================================================
  // LẤY DANH SÁCH LUẬT SƯ KHÁC
  //
  // QUAN TRỌNG:
  // CHỈ LẤY 2 NGƯỜI
  // =======================================================

  useEffect(() => {

    let cancelled = false;


    const loadOtherLawyers =
      async () => {

        try {

          const response =
            await fetch(
              `${API_BASE.replace(
                /\/$/,
                ""
              )}/lawyers`,
              {
                method: "GET",

                headers: {
                  Accept:
                    "application/json",
                },
              }
            );


          if (!response.ok) {
            throw new Error(
              `HTTP ${response.status}`
            );
          }


          const result =
            await response.json();


          const list =
            Array.isArray(result)
              ? result
              : (
                  result?.data ||
                  result?.lawyers ||
                  result?.Lawyers ||
                  result?.result ||
                  []
                );


          if (!Array.isArray(list)) {
            return;
          }


          // =============================================
          // LOẠI LUẬT SƯ HIỆN TẠI
          // =============================================

          const currentId =
            resolvedLawyerId
              ? String(
                  resolvedLawyerId
                )
              : null;


          const filtered =
            list.filter(
              (item) => {

                const id =
                  getId(
                    firstValue(
                      item?.id,
                      item?.Id,
                      item?.lawyerId,
                      item?.LawyerId
                    )
                  );


                if (
                  currentId &&
                  id === currentId
                ) {
                  return false;
                }


                return true;
              }
            );


          // =============================================
          // CHỈ LẤY 2 LUẬT SƯ
          // =============================================

          const normalized =
            filtered
              .map(
                (
                  item,
                  index
                ) =>
                  normalizeOtherLawyer(
                    item,
                    index
                  )
              )
              .filter(Boolean)
              .slice(0, 2);


          if (!cancelled) {
            setOtherLawyers(
              normalized
            );
          }

        } catch (err) {

          console.error(
            "Load other lawyers error:",
            err
          );


          if (!cancelled) {
            setOtherLawyers([]);
          }

        }
      };


    loadOtherLawyers();


    return () => {
      cancelled = true;
    };

  }, [
    resolvedLawyerId,
  ]);



  // =======================================================
  // TAB
  // =======================================================

  const tabs = [
    {
      id: "experience",

      label: "Kinh nghiệm",
    },

    {
      id: "education",

      label: "Học vấn",
    },

    {
      id: "awards",

      label:
        "Chứng chỉ & Giải thưởng",
    },

    {
      id: "specialty",

      label:
        "Lĩnh vực chuyên môn",
    },
  ];



  // =======================================================
  // LĨNH VỰC CHUYÊN MÔN
  //
  // PHẦN NÀY VẪN LẤY ĐỘNG
  // =======================================================

  const specialties =
    normalizeSpecialties(
      firstValue(
        lawyer?.specialties,
        lawyer?.Specialties,

        lawyer?.practiceAreas,
        lawyer?.PracticeAreas,

        lawyer?.practiceArea,
        lawyer?.PracticeArea,

        lawyer?.legalFields,
        lawyer?.LegalFields,

        lawyer?.fields,
        lawyer?.Fields
      )
    );



  // =======================================================
  // CLICK LUẬT SƯ
  // =======================================================

  const handleLawyerClick =
    (selectedLawyer) => {

      if (onLawyerClick) {

        onLawyerClick(
          selectedLawyer
        );

        return;
      }


      if (
        selectedLawyer?.id
      ) {

        navigate(
          `/lawyers/${selectedLawyer.id}`
        );

        window.scrollTo({
          top: 0,

          behavior: "smooth",
        });

        return;
      }


      console.log(
        "Không xác định được lawyerId:",
        selectedLawyer
      );
    };



  // =======================================================
  // XEM TẤT CẢ
  // =======================================================

  const handleViewAllLawyers =
    () => {

      navigate(
        "/lawyers"
      );

    };



  // =======================================================
  // LOADING
  // =======================================================

  if (
    loading &&
    !lawyer
  ) {

    return (
      <section className="lawyer-career">

        <div className="lawyer-career__container">

          <div className="lawyer-career__main">

            <div className="lawyer-section-title">

              <div className="lawyer-section-title__icon">

                <FontAwesomeIcon
                  icon={
                    faBriefcase
                  }
                />

              </div>

              <h2>
                Đang tải thông tin...
              </h2>

            </div>

          </div>

        </div>

      </section>
    );
  }



  // =======================================================
  // RENDER
  // =======================================================

  return (

    <section className="lawyer-career">

      <div className="lawyer-career__container">


        {/* =================================================
            LEFT
        ================================================= */}

        <div className="lawyer-career__main">


          {/* =================================================
              TABS
          ================================================= */}

          <div className="lawyer-career__tabs">

            {tabs.map(
              (tab) => (

                <button
                  key={tab.id}

                  type="button"

                  className={`
                    lawyer-career__tab
                    ${
                      activeTab ===
                      tab.id
                        ? "lawyer-career__tab--active"
                        : ""
                    }
                  `}

                  onClick={() =>
                    setActiveTab(
                      tab.id
                    )
                  }
                >

                  {tab.label}

                </button>

              )
            )}

          </div>



          {/* =================================================
              KINH NGHIỆM
              DỮ LIỆU CỨNG
          ================================================= */}

          {activeTab ===
            "experience" && (

            <div className="lawyer-career__section">

              <div className="lawyer-section-title">

                <div className="lawyer-section-title__icon">

                  <FontAwesomeIcon
                    icon={
                      faBriefcase
                    }
                  />

                </div>

                <h2>
                  Kinh nghiệm làm việc
                </h2>

              </div>


              <div className="lawyer-timeline">

                {STATIC_CAREER_DATA
                  .experiences
                  .map(
                    (
                      item,
                      index
                    ) => (

                      <div
                        className="lawyer-timeline__item"

                        key={`${item.period}-${index}`}
                      >

                        <div
                          className={`
                            lawyer-timeline__dot
                            ${
                              index === 0
                                ? "lawyer-timeline__dot--active"
                                : ""
                            }
                          `}
                        ></div>


                        <div className="lawyer-timeline__period">

                          {
                            item.period
                          }

                        </div>


                        <div className="lawyer-timeline__content">

                          <h3>
                            {
                              item.position
                            }
                          </h3>

                          <span>
                            {
                              item.company
                            }
                          </span>

                          <p>
                            {
                              item.description
                            }
                          </p>

                        </div>

                      </div>

                    )
                  )}

              </div>

            </div>

          )}



          {/* =================================================
              HỌC VẤN
              DỮ LIỆU CỨNG
          ================================================= */}

          {activeTab ===
            "education" && (

            <div className="lawyer-career__section">

              <div className="lawyer-section-title">

                <div className="lawyer-section-title__icon">

                  <FontAwesomeIcon
                    icon={
                      faGraduationCap
                    }
                  />

                </div>

                <h2>
                  Học vấn
                </h2>

              </div>


              <div className="lawyer-education">

                {STATIC_CAREER_DATA
                  .education
                  .map(
                    (
                      item,
                      index
                    ) => (

                      <div
                        className="lawyer-education__item"

                        key={`${item.period}-${index}`}
                      >

                        <div className="lawyer-education__period">

                          {
                            item.period
                          }

                        </div>


                        <div className="lawyer-education__content">

                          <h3>
                            {
                              item.degree
                            }
                          </h3>

                          <p>
                            {
                              item.school
                            }
                          </p>

                        </div>

                      </div>

                    )
                  )}

              </div>

            </div>

          )}



          {/* =================================================
              CHỨNG CHỈ
              DỮ LIỆU CỨNG
          ================================================= */}

          {activeTab ===
            "awards" && (

            <div className="lawyer-career__section">

              <div className="lawyer-section-title">

                <div className="lawyer-section-title__icon">

                  <FontAwesomeIcon
                    icon={
                      faAward
                    }
                  />

                </div>

                <h2>
                  Chứng chỉ & Giải thưởng
                </h2>

              </div>


              <div className="lawyer-awards">

                {STATIC_CAREER_DATA
                  .awards
                  .map(
                    (
                      item,
                      index
                    ) => (

                      <div
                        className="lawyer-award"

                        key={`${item.title}-${index}`}
                      >

                        <div className="lawyer-award__icon">

                          <FontAwesomeIcon
                            icon={
                              faCertificate
                            }
                          />

                        </div>


                        <div className="lawyer-award__content">

                          <h3>
                            {
                              item.title
                            }
                          </h3>

                          <p>
                            {
                              item.organization
                            }
                          </p>

                        </div>

                      </div>

                    )
                  )}

              </div>

            </div>

          )}



          {/* =================================================
              LĨNH VỰC CHUYÊN MÔN
              VẪN LẤY ĐỘNG
          ================================================= */}

          {activeTab ===
            "specialty" && (

            <div className="lawyer-career__section">

              <div className="lawyer-section-title">

                <div className="lawyer-section-title__icon">

                  <FontAwesomeIcon
                    icon={
                      faScaleBalanced
                    }
                  />

                </div>

                <h2>
                  Lĩnh vực chuyên môn
                </h2>

              </div>


              <div className="lawyer-specialty-grid">

                {specialties.length >
                0 ? (

                  specialties.map(
                    (
                      item,
                      index
                    ) => (

                      <div
                        className="lawyer-specialty-item"

                        key={`${item.name}-${index}`}
                      >

                        <FontAwesomeIcon
                          icon={
                            item.icon ||
                            faScaleBalanced
                          }
                        />

                        <span>
                          {
                            item.name
                          }
                        </span>

                      </div>

                    )
                  )

                ) : (

                  <p>
                    Chưa có dữ liệu lĩnh vực chuyên môn.
                  </p>

                )}

              </div>

            </div>

          )}

        </div>



        {/* =================================================
            RIGHT SIDEBAR
        ================================================= */}

        <aside className="lawyer-career__sidebar">


          {/* =================================================
              LĨNH VỰC CHUYÊN MÔN
          ================================================= */}

          <div className="lawyer-sidebar-section">

            <div className="lawyer-sidebar-title">

              <FontAwesomeIcon
                icon={
                  faScaleBalanced
                }
              />

              <h2>
                Lĩnh vực chuyên môn
              </h2>

            </div>


            <div className="lawyer-sidebar-specialties">

              {specialties.length >
              0 ? (

                specialties.map(
                  (
                    item,
                    index
                  ) => (

                    <div
                      className="lawyer-sidebar-specialty"

                      key={`${item.name}-${index}`}
                    >

                      <div className="lawyer-sidebar-specialty__icon">

                        <FontAwesomeIcon
                          icon={
                            item.icon ||
                            faScaleBalanced
                          }
                        />

                      </div>


                      <span>
                        {
                          item.name
                        }
                      </span>

                    </div>

                  )
                )

              ) : (

                <p>
                  Chưa cập nhật.
                </p>

              )}

            </div>

          </div>



          {/* =================================================
              CÁC LUẬT SƯ KHÁC
              CHỈ HIỂN THỊ 2
          ================================================= */}

          <div className="lawyer-sidebar-section lawyer-sidebar-lawyers">

            <div className="lawyer-sidebar-title lawyer-sidebar-title--lawyers">

              <h2>
                Các luật sư khác
              </h2>


              <button
                type="button"

                onClick={
                  handleViewAllLawyers
                }
              >

                Xem tất cả

                <FontAwesomeIcon
                  icon={
                    faArrowRight
                  }
                />

              </button>

            </div>



            <div className="lawyer-other-grid">

              {otherLawyers.length >
              0 ? (

                otherLawyers.map(
                  (lawyer) => (

                    <button
                      type="button"

                      className="lawyer-other-card"

                      key={
                        lawyer.id ||
                        lawyer.name
                      }

                      onClick={() =>
                        handleLawyerClick(
                          lawyer
                        )
                      }
                    >


                      {/* ẢNH */}

                      <div className="lawyer-other-card__image">

                        <img
                          src={
                            lawyer.image
                          }

                          alt={
                            lawyer.name
                          }

                          onError={(
                            event
                          ) => {

                            event.currentTarget.src =
                              "/images/lawyers/ls1.png";

                          }}
                        />

                      </div>



                      {/* TÊN */}

                      <h3>
                        {
                          lawyer.name
                        }
                      </h3>



                      {/* CHỨC DANH */}

                      <p className="lawyer-other-card__position">

                        {
                          lawyer.position
                        }

                      </p>



                      {/* KINH NGHIỆM */}

                      <div className="lawyer-other-card__meta">

                        <FontAwesomeIcon
                          icon={
                            faStar
                          }
                        />

                        <span>
                          {
                            lawyer.experience
                          }
                        </span>

                      </div>



                      {/* CHUYÊN MÔN */}

                      <div className="lawyer-other-card__meta">

                        <FontAwesomeIcon
                          icon={
                            faBriefcase
                          }
                        />

                        <span>
                          {
                            lawyer.specialty
                          }
                        </span>

                      </div>

                    </button>

                  )
                )

              ) : (

                <p>
                  Chưa có dữ liệu luật sư khác.
                </p>

              )}

            </div>

          </div>

        </aside>

      </div>

    </section>
  );
};


export default LawyerCareer;