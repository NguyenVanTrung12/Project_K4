import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUser,
  faBuildingColumns,
  faClock,
  faScaleBalanced,
  faEnvelope,
  faPhone,
  faLocationDot,
  faCalendarDays,
  faGraduationCap,
  faIdCard,
  faBriefcase,
  faCircleCheck,
  faArrowLeft,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../api/api";

import "../assets/css/admin/AdminLawyerDetail.css";


// =========================================================
// CONSTANTS
// =========================================================

const NOT_UPDATED = "Chưa cập nhật";

const DEFAULT_LAWYER_AVATAR =
  "/src/assets/images/lawyers/lawyer1.png";


// =========================================================
// API SERVER
// =========================================================

const getServerBaseUrl = () => {
  const apiUrl =
    import.meta.env.VITE_API_URL ||
    "https://localhost:7139/api";

  return apiUrl.replace(/\/api\/?$/, "");
};


// =========================================================
// BUILD AVATAR URL
// =========================================================

const buildAvatarUrl = (avatarUrl) => {
  if (!avatarUrl) {
    return "";
  }

  if (
    avatarUrl.startsWith("http://") ||
    avatarUrl.startsWith("https://")
  ) {
    return avatarUrl;
  }

  const serverBaseUrl = getServerBaseUrl();

  if (avatarUrl.startsWith("/")) {
    return `${serverBaseUrl}${avatarUrl}`;
  }

  return `${serverBaseUrl}/${avatarUrl}`;
};


// =========================================================
// HELPERS
// =========================================================

/**
 * Lấy giá trị đầu tiên khác rỗng theo danh sách tên field.
 * Hỗ trợ đường dẫn lồng nhau: "user.fullName", "barAssociation.name"
 */
const pick = (source, keys) => {
  for (const key of keys) {
    const value = key
      .split(".")
      .reduce(
        (acc, part) => (acc == null ? acc : acc[part]),
        source
      );

    if (
      value !== undefined &&
      value !== null &&
      value !== ""
    ) {
      return value;
    }
  }

  return undefined;
};


/**
 * Lấy text từ một giá trị có thể là string hoặc object.
 */
const toText = (value) => {
  if (value === undefined || value === null) {
    return "";
  }

  if (typeof value === "string") {
    return value.trim();
  }

  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  if (typeof value === "object") {
    return String(
      value.name ??
        value.Name ??
        value.title ??
        value.Title ??
        value.label ??
        value.areaName ??
        value.AreaName ??
        value.practiceArea ??
        value.PracticeArea ??
        value.school ??
        value.School ??
        value.degree ??
        value.Degree ??
        value.value ??
        ""
    ).trim();
  }

  return "";
};


/**
 * Chuẩn hoá mọi kiểu dữ liệu về mảng string.
 * Nhận: mảng string, mảng object, chuỗi JSON,
 * chuỗi ngăn cách bằng dấu phẩy / chấm phẩy / xuống dòng.
 */
const toStringList = (input) => {
  if (input === undefined || input === null) {
    return [];
  }

  if (typeof input === "string") {
    const text = input.trim();

    if (!text) {
      return [];
    }

    if (text.startsWith("[") || text.startsWith("{")) {
      try {
        return toStringList(JSON.parse(text));
      } catch {
        // Không phải JSON hợp lệ, xử lý như chuỗi thường
      }
    }

    return text
      .split(/[,;\n|]/)
      .map((item) => item.trim())
      .filter(Boolean);
  }

  if (Array.isArray(input)) {
    return input.map(toText).filter(Boolean);
  }

  if (typeof input === "object") {
    return Object.values(input).map(toText).filter(Boolean);
  }

  return [];
};


/**
 * Định dạng ngày về dd/MM/yyyy.
 */
const formatDate = (value) => {
  if (!value) {
    return NOT_UPDATED;
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return String(value);
  }

  // Backend trả 0001-01-01 khi chưa có dữ liệu
  if (date.getFullYear() <= 1900) {
    return NOT_UPDATED;
  }

  return date.toLocaleDateString("vi-VN");
};


/**
 * Chuẩn hoá giới tính về tiếng Việt.
 */
const formatGender = (value) => {
  const text = toText(value);

  if (!text) {
    return NOT_UPDATED;
  }

  const normalized = text.toLowerCase();

  if (["male", "m", "nam", "1", "true"].includes(normalized)) {
    return "Nam";
  }

  if (["female", "f", "nu", "nữ", "0", "false"].includes(normalized)) {
    return "Nữ";
  }

  return text;
};


// =========================================================
// COMPONENT
// =========================================================

const AdminLawyerDetail = () => {

  const { id } = useParams();
  const navigate = useNavigate();

  const [lawyer, setLawyer] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");


  // =========================================================
  // GET LAWYER DETAIL
  // =========================================================

  useEffect(() => {

    const fetchLawyerDetail = async () => {

      try {

        setLoading(true);
        setError("");

        const data = await api.get(`/lawyers/${id}`);

        const lawyerData =
          data?.lawyer ||
          data?.data ||
          data;

        if (!lawyerData) {
          throw new Error(
            "Không tìm thấy thông tin luật sư."
          );
        }

        // Debug: xem chính xác backend trả về những field nào
        console.log(
          "Lawyer keys:",
          Object.keys(lawyerData)
        );

        console.log(
          "Lawyer raw:",
          lawyerData
        );

        setLawyer(lawyerData);

      } catch (err) {

        console.error(
          "Không thể lấy thông tin luật sư:",
          err
        );

        setError(
          err?.message ||
          "Không thể tải thông tin luật sư."
        );

      } finally {

        setLoading(false);

      }

    };


    if (id) {
      fetchLawyerDetail();
    }

  }, [id]);


  // =========================================================
  // LOADING
  // =========================================================

  if (loading) {

    return (

      <div className="admin-lawyer-detail-loading">

        Đang tải thông tin luật sư...

      </div>

    );

  }


  // =========================================================
  // ERROR
  // =========================================================

  if (error) {

    return (

      <div className="admin-lawyer-detail-empty">

        <h3>
          Không thể tải thông tin luật sư
        </h3>

        <p>
          {error}
        </p>

        <button
          type="button"
          className="admin-lawyer-detail-back"
          onClick={() => navigate("/admin/lawyers")}
        >

          <FontAwesomeIcon icon={faArrowLeft} />

          <span>
            Quay lại
          </span>

        </button>

      </div>

    );

  }


  // =========================================================
  // NOT FOUND
  // =========================================================

  if (!lawyer) {

    return (

      <div className="admin-lawyer-detail-empty">

        Không tìm thấy thông tin luật sư.

        <br />

        <button
          type="button"
          className="admin-lawyer-detail-back"
          onClick={() => navigate("/admin/lawyers")}
        >

          <FontAwesomeIcon icon={faArrowLeft} />

          <span>
            Quay lại
          </span>

        </button>

      </div>

    );

  }


  // =========================================================
  // DATA MAPPING
  // =========================================================

  const fullName =
    toText(
      pick(lawyer, [
        "fullName",
        "FullName",
        "user.fullName",
        "user.FullName",
        "name",
        "Name",
      ])
    ) || NOT_UPDATED;


  const email =
    toText(
      pick(lawyer, [
        "email",
        "Email",
        "user.email",
        "user.Email",
      ])
    ) || NOT_UPDATED;


  const phone =
    toText(
      pick(lawyer, [
        "phone",
        "Phone",
        "phoneNumber",
        "PhoneNumber",
        "user.phone",
        "user.phoneNumber",
      ])
    ) || NOT_UPDATED;


  const title =
    toText(
      pick(lawyer, [
        "title",
        "Title",
        "position",
        "Position",
        "role",
        "Role",
      ])
    ) || "Luật sư";


  const barLicenseNo =
    toText(
      pick(lawyer, [
        "barLicenseNo",
        "BarLicenseNo",
        "lawyerCode",
        "LawyerCode",
        "licenseNo",
        "LicenseNumber",
        "code",
      ])
    ) || NOT_UPDATED;


  const yearsExp =
    pick(lawyer, [
      "yearsExp",
      "YearsExp",
      "yearsOfExperience",
      "YearsOfExperience",
      "experience",
      "Experience",
    ]) ?? 0;


  const bio =
    toText(
      pick(lawyer, [
        "bio",
        "Bio",
        "description",
        "Description",
        "about",
        "introduction",
      ])
    ) || "Chưa có thông tin giới thiệu.";


  const ratingAvg =
    pick(lawyer, [
      "ratingAvg",
      "RatingAvg",
      "rating",
      "Rating",
      "averageRating",
    ]) ?? 0;


  const casesWon =
    pick(lawyer, [
      "casesWon",
      "CasesWon",
      "wonCases",
      "totalCasesWon",
    ]) ?? 0;


  const isAvailable =
    pick(lawyer, [
      "isAvailable",
      "IsAvailable",
      "available",
      "isActive",
      "IsActive",
    ]) ?? true;


  // ---------------------------------------------------------
  // LĨNH VỰC CHUYÊN MÔN
  // ---------------------------------------------------------

  const practiceAreas = toStringList(
    pick(lawyer, [
      "practiceAreas",
      "PracticeAreas",
      "practiceAreaNames",
      "PracticeAreaNames",
      "lawyerPracticeAreas",
      "LawyerPracticeAreas",
      "specialties",
      "Specialties",
      "specialization",
      "Specialization",
      "areas",
      "Areas",
      "fields",
    ])
  );


  // ---------------------------------------------------------
  // HỌC VẤN
  // ---------------------------------------------------------

  const education = toStringList(
    pick(lawyer, [
      "education",
      "Education",
      "educations",
      "Educations",
      "educationList",
      "EducationList",
      "degrees",
      "Degrees",
      "qualifications",
      "Qualifications",
      "school",
      "School",
    ])
  );


  // ---------------------------------------------------------
  // ĐOÀN LUẬT SƯ
  // ---------------------------------------------------------

  const barAssociation =
    toText(
      pick(lawyer, [
        "barAssociation.name",
        "BarAssociation.Name",
        "barAssociation",
        "BarAssociation",
        "barAssociationName",
        "BarAssociationName",
        "barName",
        "bar",
        "Bar",
      ])
    ) || NOT_UPDATED;


  // ---------------------------------------------------------
  // THÔNG TIN CÁ NHÂN
  // ---------------------------------------------------------

  const gender = formatGender(
    pick(lawyer, [
      "gender",
      "Gender",
      "sex",
      "user.gender",
      "user.Gender",
    ])
  );


  const birthday = formatDate(
    pick(lawyer, [
      "birthday",
      "Birthday",
      "dateOfBirth",
      "DateOfBirth",
      "birthDate",
      "BirthDate",
      "dob",
      "DOB",
      "user.dateOfBirth",
      "user.birthday",
    ])
  );


  const address =
    toText(
      pick(lawyer, [
        "address",
        "Address",
        "fullAddress",
        "user.address",
        "user.Address",
      ])
    ) || NOT_UPDATED;


  // =========================================================
  // AVATAR
  // =========================================================

  const rawAvatar =
    toText(
      pick(lawyer, [
        "avatarUrl",
        "AvatarUrl",
        "user.avatarUrl",
        "user.AvatarUrl",
        "avatar",
        "Avatar",
        "imageUrl",
        "photoUrl",
      ])
    );


  const avatar =
    buildAvatarUrl(rawAvatar) ||
    DEFAULT_LAWYER_AVATAR;


  // =========================================================
  // AVATAR ERROR
  // =========================================================

  const handleAvatarError = (event) => {

    if (event.currentTarget.dataset.fallback === "true") {
      return;
    }

    event.currentTarget.dataset.fallback = "true";

    event.currentTarget.src = DEFAULT_LAWYER_AVATAR;

  };


  // =========================================================
  // RENDER
  // =========================================================

  return (

    <section className="admin-lawyer-detail-page">


      {/* =====================================================
          BACK
      ===================================================== */}

      <button
        type="button"
        className="admin-lawyer-detail-back"
        onClick={() => navigate("/admin/lawyers")}
      >

        <FontAwesomeIcon icon={faArrowLeft} />

        <span>
          Quay lại
        </span>

      </button>


      {/* =====================================================
          LAWYER HEADER
      ===================================================== */}

      <section className="admin-lawyer-detail-header">


        {/* ===================================================
            AVATAR
        =================================================== */}

        <div className="admin-lawyer-detail-avatar-wrapper">

          <img
            src={avatar}
            alt={fullName}
            className="admin-lawyer-detail-avatar"
            onError={handleAvatarError}
          />

          <div className="admin-lawyer-detail-status">

            <span className="admin-lawyer-detail-status-dot"></span>

            {isAvailable ? "Đang hoạt động" : "Tạm ngưng"}

          </div>

        </div>


        {/* ===================================================
            MAIN INFORMATION
        =================================================== */}

        <div className="admin-lawyer-detail-main-info">


          <div className="admin-lawyer-detail-name-row">

            <h1>
              {fullName}
            </h1>

            <span className="admin-lawyer-detail-verified">

              <FontAwesomeIcon icon={faCircleCheck} />

            </span>

          </div>


          <p className="admin-lawyer-detail-role">
            {title}
          </p>


          <div className="admin-lawyer-detail-summary">


            {/* BAR ASSOCIATION */}

            <div className="admin-lawyer-detail-summary-item">

              <FontAwesomeIcon icon={faBuildingColumns} />

              <span>
                {barAssociation}
              </span>

            </div>


            {/* LAWYER CODE */}

            <div className="admin-lawyer-detail-summary-item">

              <FontAwesomeIcon icon={faIdCard} />

              <span>
                Mã luật sư: {barLicenseNo}
              </span>

            </div>


            {/* EXPERIENCE */}

            <div className="admin-lawyer-detail-summary-item">

              <FontAwesomeIcon icon={faClock} />

              <span>
                {yearsExp} năm kinh nghiệm
              </span>

            </div>


            {/* SPECIALTY */}

            <div className="admin-lawyer-detail-summary-item">

              <FontAwesomeIcon icon={faScaleBalanced} />

              <span>

                Chuyên môn:{" "}

                {practiceAreas.length > 0
                  ? practiceAreas.join(", ")
                  : NOT_UPDATED}

              </span>

            </div>


            {/* EMAIL */}

            <div className="admin-lawyer-detail-summary-item">

              <FontAwesomeIcon icon={faEnvelope} />

              <span>
                Email: {email}
              </span>

            </div>


            {/* PHONE */}

            <div className="admin-lawyer-detail-summary-item">

              <FontAwesomeIcon icon={faPhone} />

              <span>
                Số điện thoại: {phone}
              </span>

            </div>


            {/* ADDRESS */}

            <div className="admin-lawyer-detail-summary-item">

              <FontAwesomeIcon icon={faLocationDot} />

              <span>
                Địa chỉ: {address}
              </span>

            </div>


          </div>

        </div>

      </section>


      {/* =====================================================
          PERSONAL INFORMATION
      ===================================================== */}

      <section className="admin-lawyer-detail-card">


        <div className="admin-lawyer-detail-section-title">

          <FontAwesomeIcon icon={faUser} />

          <h2>
            Thông tin cá nhân
          </h2>

        </div>


        <div className="admin-lawyer-detail-information-grid">


          {/* =================================================
              LEFT COLUMN
          ================================================= */}

          <div className="admin-lawyer-detail-column">


            {/* FULL NAME */}

            <div className="admin-lawyer-detail-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faUser} />

                <span>
                  Họ và tên
                </span>

              </div>

              <div className="admin-lawyer-detail-value">
                {fullName}
              </div>

            </div>


            {/* GENDER */}

            <div className="admin-lawyer-detail-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faUser} />

                <span>
                  Giới tính
                </span>

              </div>

              <div className="admin-lawyer-detail-value">
                {gender}
              </div>

            </div>


            {/* BIRTHDAY */}

            <div className="admin-lawyer-detail-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faCalendarDays} />

                <span>
                  Ngày sinh
                </span>

              </div>

              <div className="admin-lawyer-detail-value">
                {birthday}
              </div>

            </div>


            {/* EMAIL */}

            <div className="admin-lawyer-detail-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faEnvelope} />

                <span>
                  Email
                </span>

              </div>

              <div className="admin-lawyer-detail-value">
                {email}
              </div>

            </div>


            {/* PHONE */}

            <div className="admin-lawyer-detail-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faPhone} />

                <span>
                  Số điện thoại
                </span>

              </div>

              <div className="admin-lawyer-detail-value">
                {phone}
              </div>

            </div>


            {/* ADDRESS */}

            <div className="admin-lawyer-detail-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faLocationDot} />

                <span>
                  Địa chỉ
                </span>

              </div>

              <div className="admin-lawyer-detail-value">
                {address}
              </div>

            </div>


          </div>


          {/* =================================================
              RIGHT COLUMN
          ================================================= */}

          <div className="admin-lawyer-detail-column">


            {/* LAWYER CODE */}

            <div className="admin-lawyer-detail-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faIdCard} />

                <span>
                  Mã luật sư
                </span>

              </div>

              <div className="admin-lawyer-detail-value">
                {barLicenseNo}
              </div>

            </div>


            {/* BAR ASSOCIATION */}

            <div className="admin-lawyer-detail-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faBuildingColumns} />

                <span>
                  Đoàn luật sư
                </span>

              </div>

              <div className="admin-lawyer-detail-value">
                {barAssociation}
              </div>

            </div>


            {/* EXPERIENCE */}

            <div className="admin-lawyer-detail-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faClock} />

                <span>
                  Năm kinh nghiệm
                </span>

              </div>

              <div className="admin-lawyer-detail-value">
                {yearsExp} năm
              </div>

            </div>


            {/* SPECIALTIES */}

            <div className="admin-lawyer-detail-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faBriefcase} />

                <span>
                  Lĩnh vực chuyên môn
                </span>

              </div>

              {practiceAreas.length > 0 ? (

                <div className="admin-lawyer-detail-specialties">

                  {practiceAreas.map((specialty, index) => (

                    <span
                      key={`${specialty}-${index}`}
                      className="admin-lawyer-detail-specialty"
                    >
                      {specialty}
                    </span>

                  ))}

                </div>

              ) : (

                <div className="admin-lawyer-detail-value">
                  {NOT_UPDATED}
                </div>

              )}

            </div>


            {/* EDUCATION */}

            <div className="admin-lawyer-detail-row admin-lawyer-detail-education-row">

              <div className="admin-lawyer-detail-label">

                <FontAwesomeIcon icon={faGraduationCap} />

                <span>
                  Học vấn
                </span>

              </div>

              {education.length > 0 ? (

                <div className="admin-lawyer-detail-education">

                  {education.map((item, index) => (

                    <span key={`${item}-${index}`}>
                      {item}
                    </span>

                  ))}

                </div>

              ) : (

                <div className="admin-lawyer-detail-value">
                  {NOT_UPDATED}
                </div>

              )}

            </div>


          </div>

        </div>

      </section>


      {/* =====================================================
          BIO
      ===================================================== */}

      <section className="admin-lawyer-detail-card">

        <div className="admin-lawyer-detail-section-title">

          <FontAwesomeIcon icon={faBriefcase} />

          <h2>
            Giới thiệu
          </h2>

        </div>

        <p>
          {bio}
        </p>

      </section>


      {/* =====================================================
          STATISTICS
      ===================================================== */}

      <section className="admin-lawyer-detail-card">

        <div className="admin-lawyer-detail-section-title">

          <FontAwesomeIcon icon={faCircleCheck} />

          <h2>
            Thống kê
          </h2>

        </div>

        <div>

          <p>

            <strong>
              Đánh giá:
            </strong>{" "}

            {ratingAvg}

          </p>

          <p>

            <strong>
              Số vụ thắng:
            </strong>{" "}

            {casesWon}

          </p>

        </div>

      </section>


    </section>

  );

};


export default AdminLawyerDetail;
