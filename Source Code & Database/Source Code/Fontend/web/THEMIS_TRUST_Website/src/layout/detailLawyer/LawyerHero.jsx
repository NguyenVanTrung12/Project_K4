import { useMemo } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faCalendarDays,
  faEnvelope,
  faBriefcase,
  faScaleBalanced,
  faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/detailLawyer/LawyerHero.css";

const API_BASE =
  import.meta.env.VITE_API_URL ||
  import.meta.env.VITE_API_BASE_URL ||
  "https://localhost:7139/api";

const DEFAULT_BANNER = "/images/banner/banner1.png";
const DEFAULT_AVATAR = "/images/lawyers/ls1.png";

const firstValue = (...values) =>
  values.find(
    (value) =>
      value !== null &&
      value !== undefined &&
      value !== "" &&
      !(Array.isArray(value) && value.length === 0)
  );

const toText = (value) => {
  if (value === null || value === undefined) return "";

  if (Array.isArray(value)) {
    return value
      .map((item) => {
        if (typeof item === "string") return item;

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

const normalizeUrl = (url, fallback) => {
  if (!url) return fallback;

  const value = String(url).trim();

  if (!value || value === "#") return fallback;

  if (
    /^https?:\/\//i.test(value) ||
    /^(data:|blob:)/i.test(value)
  ) {
    return value;
  }

  if (value.startsWith("/")) {
    if (value.startsWith("/api/")) {
      return `${API_BASE.replace(/\/$/, "")}${value.substring(4)}`;
    }

    return value;
  }

  return `${API_BASE.replace(/\/$/, "")}/${value.replace(/^\/+/, "")}`;
};

/*
 * Chuẩn hóa dữ liệu để Hero có thể dùng được nhiều kiểu response
 * từ backend.
 */
const normalizeLawyer = (lawyer) => {
  if (!lawyer) return null;

  const user = lawyer.user || lawyer.User || {};
  const profile = lawyer.profile || lawyer.Profile || {};

  const id = firstValue(
    lawyer.id,
    lawyer.Id,
    lawyer.lawyerId,
    lawyer.LawyerId,
    profile.id,
    profile.Id
  );

  const fullName = toText(
    firstValue(
      lawyer.fullName,
      lawyer.FullName,
      lawyer.name,
      lawyer.Name,
      lawyer.fullname,
      lawyer.Fullname,
      user.fullName,
      user.FullName,
      user.name,
      user.Name,
      profile.fullName,
      profile.FullName
    )
  );

  const title = toText(
    firstValue(
      lawyer.title,
      lawyer.Title,
      lawyer.position,
      lawyer.Position,
      lawyer.jobTitle,
      lawyer.JobTitle,
      profile.title,
      profile.Title,
      profile.position,
      profile.Position,
      "Luật sư"
    )
  );

  const yearsExp = firstValue(
    lawyer.yearsExp,
    lawyer.YearsExp,
    lawyer.experienceYears,
    lawyer.ExperienceYears,
    lawyer.yearsOfExperience,
    lawyer.YearsOfExperience,
    lawyer.experience,
    lawyer.Experience,
    profile.yearsExp,
    profile.YearsExp,
    0
  );

  let practiceAreas = firstValue(
    lawyer.practiceAreas,
    lawyer.PracticeAreas,
    lawyer.practiceArea,
    lawyer.PracticeArea,
    lawyer.specialties,
    lawyer.Specialties,
    lawyer.specialty,
    lawyer.Specialty,
    lawyer.legalFields,
    lawyer.LegalFields,
    lawyer.fields,
    lawyer.Fields,
    profile.practiceAreas,
    profile.PracticeAreas
  );

  /*
   * Backend có thể trả:
   * ["Doanh nghiệp", "Đầu tư"]
   *
   * hoặc:
   * [{ name: "Doanh nghiệp" }, { name: "Đầu tư" }]
   *
   * hoặc chỉ trả string.
   */
  if (Array.isArray(practiceAreas)) {
    practiceAreas = practiceAreas
      .map((item) => {
        if (typeof item === "string") return item;

        return toText(
          firstValue(
            item?.name,
            item?.Name,
            item?.title,
            item?.Title,
            item?.fieldName,
            item?.FieldName
          )
        );
      })
      .filter(Boolean);
  } else if (practiceAreas) {
    practiceAreas = String(practiceAreas)
      .split(/[,;|]/)
      .map((item) => item.trim())
      .filter(Boolean);
  } else {
    practiceAreas = [];
  }

  const avatarUrl = normalizeUrl(
    firstValue(
      lawyer.avatarUrl,
      lawyer.AvatarUrl,
      lawyer.avatar,
      lawyer.Avatar,
      lawyer.imageUrl,
      lawyer.ImageUrl,
      lawyer.image,
      lawyer.Image,
      user.avatarUrl,
      user.AvatarUrl,
      user.avatar,
      user.Avatar,
      profile.avatarUrl,
      profile.AvatarUrl,
      profile.avatar,
      profile.Avatar
    ),
    DEFAULT_AVATAR
  );

  return {
    ...lawyer,
    id,
    fullName: fullName || "Luật sư",
    title,
    yearsExp: Number(yearsExp) || 0,
    practiceAreas,
    avatarUrl,
  };
};

const LawyerHero = ({ lawyer }) => {
  const data = useMemo(
    () => normalizeLawyer(lawyer),
    [lawyer]
  );

  const handleBooking = () => {
    if (!data?.id) {
      console.error("Không xác định được lawyerId.");
      return;
    }

    window.location.href = `/booking?lawyerId=${encodeURIComponent(
      data.id
    )}`;
  };

  const handleContact = () => {
    if (!data?.id) {
      console.error("Không xác định được lawyerId.");
      return;
    }

    /*
     * Giữ lawyerId để trang liên hệ/chat sau này biết
     * client đang muốn liên hệ luật sư nào.
     */
    window.location.href = `/contact?lawyerId=${encodeURIComponent(
      data.id
    )}`;
  };

  if (!data) {
    return (
      <section className="lawyer-hero">
        <div className="lawyer-hero__background">
          <img src={DEFAULT_BANNER} alt="" />
        </div>

        <div className="lawyer-hero__overlay"></div>

        <div className="lawyer-hero__container">
          <div className="lawyer-information">
            <div className="lawyer-information__label">
              LUẬT SƯ
            </div>

            <h1 className="lawyer-information__name">
              Đang tải thông tin...
            </h1>
          </div>
        </div>
      </section>
    );
  }

  const displayedPracticeAreas = data.practiceAreas
    .slice(0, 2)
    .join(" & ");

  return (
    <section className="lawyer-hero">
      {/* BACKGROUND IMAGE */}
      <div className="lawyer-hero__background">
        <img
          src={DEFAULT_BANNER}
          alt=""
          onError={(event) => {
            event.currentTarget.style.display = "none";
          }}
        />
      </div>

      {/* DARK OVERLAY */}
      <div className="lawyer-hero__overlay"></div>

      {/* LAWYER IMAGE */}
      <div className="lawyer-hero__lawyer">
        <img
          src={data.avatarUrl}
          alt={data.fullName}
          onError={(event) => {
            event.currentTarget.src = DEFAULT_AVATAR;
          }}
        />
      </div>

      {/* CONTENT */}
      <div className="lawyer-hero__container">
        {/* QUOTE */}
        <div className="lawyer-quote">
          <p>
            {data.quote ? (
              <>
                “{data.quote}”
              </>
            ) : (
              <>
                “Công lý
                <br />
                không chỉ là
                <br />
                mục tiêu,
                <br />
                mà là trách nhiệm
                <br />
                được theo đuổi
                <br />
                mỗi ngày.”
              </>
            )}
          </p>

          <div className="lawyer-quote__line"></div>
        </div>

        {/* LAWYER INFORMATION */}
        <div className="lawyer-information">
          <div className="lawyer-information__label">
            LUẬT SƯ
          </div>

          <h1 className="lawyer-information__name">
            {data.fullName}
          </h1>

          <h2 className="lawyer-information__position">
            {data.title}
          </h2>

          <div className="lawyer-information__details">
            {/* EXPERIENCE */}
            <div className="lawyer-detail">
              <div className="lawyer-detail__icon">
                <FontAwesomeIcon icon={faBriefcase} />
              </div>

              <div className="lawyer-detail__text">
                <span>
                  {data.yearsExp > 0
                    ? `${data.yearsExp}+ năm kinh nghiệm`
                    : "Kinh nghiệm đang cập nhật"}
                </span>
              </div>
            </div>

            {/* SPECIALTY */}
            <div className="lawyer-detail">
              <div className="lawyer-detail__icon">
                <FontAwesomeIcon icon={faScaleBalanced} />
              </div>

              <div className="lawyer-detail__text">
                <span>
                  Chuyên gia trong lĩnh vực
                  <br />
                  {displayedPracticeAreas ||
                    "Đang cập nhật"}
                </span>
              </div>
            </div>
          </div>

          {/* ACTIONS */}
          <div className="lawyer-information__actions">
            {/* BOOKING */}
            <button
              type="button"
              className="lawyer-btn lawyer-btn--primary"
              onClick={handleBooking}
            >
              <FontAwesomeIcon icon={faCalendarDays} />

              <span>Đặt lịch tư vấn</span>

              <FontAwesomeIcon
                icon={faArrowRight}
                className="lawyer-btn__arrow"
              />
            </button>

            {/* CONTACT */}
            <button
              type="button"
              className="lawyer-btn lawyer-btn--outline"
              onClick={handleContact}
            >
              <FontAwesomeIcon icon={faEnvelope} />

              <span>Liên hệ ngay</span>
            </button>
          </div>
        </div>
      </div>
    </section>
  );
};

export default LawyerHero;
