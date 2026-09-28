import { useEffect, useMemo, useState } from "react";
import { useParams } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUser,
  faBriefcase,
  faShieldHalved,
  faLanguage,
  faEnvelope,
  faPhone,
  faLocationDot,
  faFileLines,
  faDownload,
  faComments,
  faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/detailLawyer/LawyerIntroduction.css";

const API_BASE =
  import.meta.env.VITE_API_URL ||
  import.meta.env.VITE_API_BASE_URL ||
  "https://localhost:7139/api";

const DEFAULT_IMAGE = "/images/lawyers/lawyer-consultation.jpg";
const DEFAULT_BANNER = "/images/banner/banner1.png";

/*
 * Component này không còn dùng dữ liệu luật sư hard-code.
 *
 * Dữ liệu được lấy động từ:
 * GET /api/lawyers/{id}
 *
 * id được lấy từ URL /lawyers/:id.
 *
 * Component vẫn nhận prop lawyer để có thể dùng lại ở nơi khác.
 * Nếu prop lawyer có dữ liệu thì component sẽ ưu tiên dữ liệu đó,
 * sau đó mới gọi API nếu có lawyerId.
 */

const getId = (value) => {
  if (value === null || value === undefined || value === "") return null;
  return String(value);
};

const firstValue = (...values) => {
  return values.find(
    (value) =>
      value !== null &&
      value !== undefined &&
      value !== "" &&
      !(Array.isArray(value) && value.length === 0)
  );
};

const toText = (value) => {
  if (value === null || value === undefined) return "";

  if (Array.isArray(value)) {
    return value
      .map((item) => {
        if (typeof item === "string") return item;
        if (item?.name) return item.name;
        if (item?.Name) return item.Name;
        if (item?.title) return item.title;
        if (item?.Title) return item.Title;
        return "";
      })
      .filter(Boolean)
      .join(", ");
  }

  return String(value);
};

const normalizeUrl = (url, fallback = "#") => {
  if (!url) return fallback;

  const value = String(url).trim();

  if (!value || value === "#") return fallback;

  // URL tuyệt đối
  if (/^https?:\/\//i.test(value)) {
    return value;
  }

  // data/blob URL
  if (/^(data:|blob:)/i.test(value)) {
    return value;
  }

  // Nếu backend trả về đường dẫn /uploads/...
  if (value.startsWith("/")) {
    if (value.startsWith("/api/")) {
      return `${API_BASE.replace(/\/$/, "")}${value.substring(4)}`;
    }

    return value;
  }

  // Nếu backend trả về uploads/... hoặc images/...
  return `${API_BASE.replace(/\/$/, "")}/${value.replace(/^\/+/, "")}`;
};

const normalizeIntroduction = (value, lawyer) => {
  if (Array.isArray(value)) {
    return value.filter(Boolean);
  }

  if (typeof value === "string" && value.trim()) {
    return [value];
  }

  const description = firstValue(
    lawyer?.description,
    lawyer?.Description,
    lawyer?.bio,
    lawyer?.Bio,
    lawyer?.about,
    lawyer?.About,
    lawyer?.introduction,
    lawyer?.Introduction
  );

  if (typeof description === "string" && description.trim()) {
    return description
      .split(/\n+/)
      .map((item) => item.trim())
      .filter(Boolean);
  }

  return [];
};

const normalizeLawyer = (lawyer) => {
  if (!lawyer) return null;

  const user = lawyer.user || lawyer.User || {};
  const profile = lawyer.profile || lawyer.Profile || {};

  const id = getId(
    firstValue(
      lawyer.id,
      lawyer.Id,
      lawyer.lawyerId,
      lawyer.LawyerId,
      profile.id,
      profile.Id
    )
  );

  const name = toText(
    firstValue(
      lawyer.name,
      lawyer.Name,
      lawyer.fullName,
      lawyer.FullName,
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

  const position = toText(
    firstValue(
      lawyer.position,
      lawyer.Position,
      lawyer.title,
      lawyer.Title,
      lawyer.jobTitle,
      lawyer.JobTitle,
      profile.position,
      profile.Position,
      "Luật sư"
    )
  );

  const specialty = toText(
    firstValue(
      lawyer.specialty,
      lawyer.Specialty,
      lawyer.specialties,
      lawyer.Specialties,
      lawyer.practiceArea,
      lawyer.PracticeArea,
      lawyer.practiceAreas,
      lawyer.PracticeAreas,
      lawyer.legalField,
      lawyer.LegalField,
      lawyer.fields,
      lawyer.Fields,
      profile.specialty,
      profile.Specialty
    )
  );

  const languages = toText(
    firstValue(
      lawyer.languages,
      lawyer.Languages,
      lawyer.language,
      lawyer.Language,
      profile.languages,
      profile.Languages,
      "Tiếng Việt"
    )
  );

  const email = toText(
    firstValue(
      lawyer.email,
      lawyer.Email,
      user.email,
      user.Email,
      profile.email,
      profile.Email
    )
  );

  const phone = toText(
    firstValue(
      lawyer.phone,
      lawyer.Phone,
      lawyer.phoneNumber,
      lawyer.PhoneNumber,
      user.phone,
      user.Phone,
      user.phoneNumber,
      user.PhoneNumber,
      profile.phone,
      profile.Phone
    )
  );

  const location = toText(
    firstValue(
      lawyer.location,
      lawyer.Location,
      lawyer.address,
      lawyer.Address,
      lawyer.workLocation,
      lawyer.WorkLocation,
      lawyer.region,
      lawyer.Region,
      profile.location,
      profile.Location,
      profile.address,
      profile.Address
    )
  );

  const image = normalizeUrl(
    firstValue(
      lawyer.image,
      lawyer.Image,
      lawyer.avatar,
      lawyer.Avatar,
      lawyer.avatarUrl,
      lawyer.AvatarUrl,
      lawyer.imageUrl,
      lawyer.ImageUrl,
      user.avatar,
      user.Avatar,
      user.avatarUrl,
      user.AvatarUrl,
      profile.avatar,
      profile.Avatar
    ),
    DEFAULT_IMAGE
  );

  const profileFile = normalizeUrl(
    firstValue(
      lawyer.profileFile,
      lawyer.ProfileFile,
      lawyer.profileUrl,
      lawyer.ProfileUrl,
      lawyer.cvUrl,
      lawyer.CvUrl,
      lawyer.resumeUrl,
      lawyer.ResumeUrl,
      lawyer.fileUrl,
      lawyer.FileUrl,
      profile.profileFile,
      profile.ProfileFile
    ),
    "#"
  );

  const linkedin = toText(
    firstValue(
      lawyer.linkedin,
      lawyer.LinkedIn,
      lawyer.linkedinUrl,
      lawyer.LinkedInUrl,
      profile.linkedin,
      profile.LinkedIn
    )
  );

  const messenger = toText(
    firstValue(
      lawyer.messenger,
      lawyer.Messenger,
      lawyer.messengerUrl,
      lawyer.MessengerUrl,
      profile.messenger,
      profile.Messenger
    )
  );

  const introduction = normalizeIntroduction(
    firstValue(
      lawyer.introduction,
      lawyer.Introduction,
      lawyer.introductions,
      lawyer.Introductions
    ),
    lawyer
  );

  const quote = toText(
    firstValue(
      lawyer.quote,
      lawyer.Quote,
      lawyer.slogan,
      lawyer.Slogan,
      profile.quote,
      profile.Quote
    )
  );

  const quoteAuthor = toText(
    firstValue(
      lawyer.quoteAuthor,
      lawyer.QuoteAuthor,
      profile.quoteAuthor,
      profile.QuoteAuthor,
      name
    )
  );

  return {
    ...lawyer,
    id,
    name: name || "Luật sư",
    fullName: name || "Luật sư",
    position,
    introduction,
    quote,
    quoteAuthor,
    specialty: specialty || "Chưa cập nhật",
    languages: languages || "Tiếng Việt",
    email: email || "Chưa cập nhật",
    phone: phone || "Chưa cập nhật",
    location: location || "Chưa cập nhật",
    image,
    profileFile,
    linkedin,
    messenger,
  };
};

const LawyerIntroduction = ({
  lawyer: lawyerProp = null,
  lawyerId: lawyerIdProp = null,
  onBooking,
  onDownloadProfile,
}) => {
  const { id: routeId } = useParams();

  const lawyerId = useMemo(
    () =>
      getId(
        firstValue(
          lawyerIdProp,
          lawyerProp?.id,
          lawyerProp?.Id,
          lawyerProp?.lawyerId,
          lawyerProp?.LawyerId,
          routeId
        )
      ),
    [lawyerIdProp, lawyerProp, routeId]
  );

  const [lawyer, setLawyer] = useState(() =>
    normalizeLawyer(lawyerProp)
  );
  const [loading, setLoading] = useState(!lawyerProp);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    const loadLawyer = async () => {
      /*
       * Nếu parent đã truyền đầy đủ dữ liệu thì vẫn gọi API để
       * lấy dữ liệu mới nhất từ database.
       */
      if (!lawyerId) {
        setLoading(false);
        setError("Không xác định được luật sư.");
        return;
      }

      setLoading(true);
      setError("");

      try {
        const response = await fetch(
          `${API_BASE.replace(/\/$/, "")}/lawyers/${encodeURIComponent(
            lawyerId
          )}`,
          {
            method: "GET",
            headers: {
              Accept: "application/json",
            },
          }
        );

        if (!response.ok) {
          const message = await response.text();

          throw new Error(
            message || `Không thể tải thông tin luật sư (${response.status}).`
          );
        }

        const result = await response.json();

        /*
         * Hỗ trợ nhiều kiểu response:
         * { ...lawyer }
         * { data: { ...lawyer } }
         * { lawyer: { ...lawyer } }
         * { result: { ...lawyer } }
         */
        const apiLawyer =
          result?.data ||
          result?.lawyer ||
          result?.Lawyer ||
          result?.result ||
          result;

        if (!apiLawyer || typeof apiLawyer !== "object") {
          throw new Error("API không trả về dữ liệu luật sư hợp lệ.");
        }

        if (!cancelled) {
          setLawyer(normalizeLawyer(apiLawyer));
        }
      } catch (err) {
        console.error("Load lawyer detail error:", err);

        if (!cancelled) {
          /*
           * Nếu đã có lawyerProp thì giữ dữ liệu đang có thay vì
           * làm trang trắng.
           */
          if (lawyerProp) {
            setLawyer(normalizeLawyer(lawyerProp));
            setError("");
          } else {
            setLawyer(null);
            setError(
              err?.message ||
                "Không thể tải thông tin luật sư. Vui lòng thử lại."
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
  }, [lawyerId, lawyerProp]);

  const handleBooking = () => {
    if (!lawyer) return;

    if (onBooking) {
      /*
       * Trả về toàn bộ lawyer, đặc biệt giữ lawyerId.
       * Trang Booking có thể dùng lawyer.id để tạo appointment.
       */
      onBooking(lawyer);
      return;
    }

    console.log("Đặt lịch tư vấn với luật sư:", lawyer);
  };

  const handleDownloadProfile = () => {
    if (!lawyer) return;

    if (onDownloadProfile) {
      onDownloadProfile(lawyer);
      return;
    }

    if (lawyer.profileFile && lawyer.profileFile !== "#") {
      window.open(lawyer.profileFile, "_blank", "noopener,noreferrer");
      return;
    }

    console.log("Luật sư chưa có file hồ sơ năng lực.");
  };

  if (loading) {
    return (
      <section className="lawyer-introduction">
        <div className="lawyer-introduction__container">
          <div className="lawyer-introduction__main">
            <h2 className="lawyer-introduction__title">
              Đang tải thông tin luật sư...
            </h2>
          </div>
        </div>
      </section>
    );
  }

  if (error || !lawyer) {
    return (
      <section className="lawyer-introduction">
        <div className="lawyer-introduction__container">
          <div className="lawyer-introduction__main">
            <h2 className="lawyer-introduction__title">
              Không thể tải thông tin luật sư
            </h2>

            <p>{error || "Không tìm thấy dữ liệu luật sư."}</p>
          </div>
        </div>
      </section>
    );
  }

  return (
    <section className="lawyer-introduction">
      <div className="lawyer-introduction__container">
        {/* LEFT */}
        <div className="lawyer-introduction__main">
          <h2 className="lawyer-introduction__title">
            Giới thiệu
          </h2>

          <div className="lawyer-introduction__description">
            {lawyer.introduction?.length > 0 ? (
              lawyer.introduction.map((paragraph, index) => (
                <p key={index}>{paragraph}</p>
              ))
            ) : (
              <p>
                Thông tin giới thiệu của luật sư hiện chưa được cập nhật.
              </p>
            )}
          </div>

          {lawyer.quote && (
            <div className="lawyer-introduction__quote">
              <div className="lawyer-introduction__quote-mark">
                “
              </div>

              <div className="lawyer-introduction__quote-content">
                <p>{lawyer.quote}</p>

                <span>
                  – {lawyer.quoteAuthor || lawyer.name}
                </span>
              </div>
            </div>
          )}
        </div>

        {/* RIGHT */}
        <div className="lawyer-introduction__right">
          {/* INFORMATION CARD */}
          <div className="lawyer-profile-card">
            <div className="lawyer-profile-item">
              <div className="lawyer-profile-item__icon">
                <FontAwesomeIcon icon={faUser} />
              </div>

              <div className="lawyer-profile-item__content">
                <span className="lawyer-profile-item__label">
                  Họ và tên
                </span>

                <strong>{lawyer.fullName || lawyer.name}</strong>
              </div>
            </div>

            <div className="lawyer-profile-item">
              <div className="lawyer-profile-item__icon">
                <FontAwesomeIcon icon={faBriefcase} />
              </div>

              <div className="lawyer-profile-item__content">
                <span className="lawyer-profile-item__label">
                  Vị trí
                </span>

                <strong>{lawyer.position}</strong>
              </div>
            </div>

            <div className="lawyer-profile-item">
              <div className="lawyer-profile-item__icon">
                <FontAwesomeIcon icon={faShieldHalved} />
              </div>

              <div className="lawyer-profile-item__content">
                <span className="lawyer-profile-item__label">
                  Lĩnh vực chuyên môn
                </span>

                <strong>{lawyer.specialty}</strong>
              </div>
            </div>

            <div className="lawyer-profile-item">
              <div className="lawyer-profile-item__icon">
                <FontAwesomeIcon icon={faLanguage} />
              </div>

              <div className="lawyer-profile-item__content">
                <span className="lawyer-profile-item__label">
                  Ngôn ngữ
                </span>

                <strong>{lawyer.languages}</strong>
              </div>
            </div>

            <div className="lawyer-profile-item">
              <div className="lawyer-profile-item__icon">
                <FontAwesomeIcon icon={faEnvelope} />
              </div>

              <div className="lawyer-profile-item__content">
                <span className="lawyer-profile-item__label">
                  Email
                </span>

                <strong>{lawyer.email}</strong>
              </div>
            </div>

            <div className="lawyer-profile-item">
              <div className="lawyer-profile-item__icon">
                <FontAwesomeIcon icon={faPhone} />
              </div>

              <div className="lawyer-profile-item__content">
                <span className="lawyer-profile-item__label">
                  Điện thoại
                </span>

                <strong>{lawyer.phone}</strong>
              </div>
            </div>

            <div className="lawyer-profile-item">
              <div className="lawyer-profile-item__icon">
                <FontAwesomeIcon icon={faLocationDot} />
              </div>

              <div className="lawyer-profile-item__content">
                <span className="lawyer-profile-item__label">
                  Địa điểm làm việc
                </span>

                <strong>{lawyer.location}</strong>
              </div>
            </div>

            <div className="lawyer-profile-card__social">
              {lawyer.linkedin && lawyer.linkedin !== "#" && (
                <a
                  href={lawyer.linkedin}
                  target="_blank"
                  rel="noreferrer"
                  className="lawyer-social lawyer-social--linkedin"
                  aria-label="LinkedIn"
                >
                  in
                </a>
              )}

              {lawyer.messenger && lawyer.messenger !== "#" && (
                <a
                  href={lawyer.messenger}
                  target="_blank"
                  rel="noreferrer"
                  className="lawyer-social"
                  aria-label="Messenger"
                >
                  <FontAwesomeIcon icon={faComments} />
                </a>
              )}
            </div>
          </div>

          {/* CONSULTATION CARD */}
          <div className="lawyer-consultation">
            <div className="lawyer-consultation__image">
              <img
                src={DEFAULT_BANNER}
                alt={`Tư vấn với ${lawyer.name}`}
                onError={(event) => {
                  event.currentTarget.src = DEFAULT_IMAGE;
                }}
              />
            </div>

            <div className="lawyer-consultation__overlay"></div>

            <div className="lawyer-consultation__content">
              <h3>
                Bạn cần tư vấn
                <br />
                trực tiếp với luật sư?
              </h3>

              <p>
                Chúng tôi luôn sẵn sàng lắng nghe
                <br />
                và đồng hành cùng bạn.
              </p>

              <button
                type="button"
                onClick={handleBooking}
                className="lawyer-consultation__button"
              >
                <span>Đặt lịch tư vấn ngay</span>

                <FontAwesomeIcon icon={faArrowRight} />
              </button>
            </div>
          </div>

          {/* PROFILE DOWNLOAD */}
          <button
            type="button"
            className="lawyer-profile-download"
            onClick={handleDownloadProfile}
          >
            <div className="lawyer-profile-download__icon">
              <FontAwesomeIcon icon={faFileLines} />
            </div>

            <div className="lawyer-profile-download__text">
              <span>Hồ sơ năng lực</span>

              <strong>của {lawyer.name}</strong>
            </div>

            <div className="lawyer-profile-download__arrow">
              <FontAwesomeIcon icon={faDownload} />
            </div>
          </button>
        </div>
      </div>
    </section>
  );
};

export default LawyerIntroduction;
