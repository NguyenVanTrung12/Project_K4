
import { useEffect, useState } from "react";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faBuildingColumns,
  faLocationDot,
  faEnvelope,
  faPhone,
  faGlobe,
  faImage,
  faUpload,
  faFloppyDisk,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../api/api";

import "../assets/css/admin/AdminSystemSettings.css";


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
// BUILD IMAGE URL
// =========================================================

const buildImageUrl = (imageUrl) => {

  if (!imageUrl) {
    return "";
  }

  // URL tuyệt đối
  if (
    imageUrl.startsWith("http://") ||
    imageUrl.startsWith("https://")
  ) {
    return imageUrl;
  }

  const serverBaseUrl = getServerBaseUrl();

  // URL bắt đầu bằng /
  if (imageUrl.startsWith("/")) {
    return `${serverBaseUrl}${imageUrl}`;
  }

  return `${serverBaseUrl}/${imageUrl}`;
};


// =========================================================
// DEFAULT DATA
// =========================================================

const DEFAULT_FORM_DATA = {
  systemName: "",
  description: "",
  address: "",
  email: "",
  phone: "",
  website: "",
};


// =========================================================
// DEFAULT IMAGE
// =========================================================

const DEFAULT_LOGO =
  "/assets/images/logo/logo-themis.png";

const DEFAULT_FAVICON =
  "/assets/images/logo/favicon.png";


// =========================================================
// COMPONENT
// =========================================================

const AdminSystemSettings = () => {

  // =======================================================
  // STATE
  // =======================================================

  const [formData, setFormData] =
    useState(DEFAULT_FORM_DATA);

  const [logoUrl, setLogoUrl] =
    useState("");

  const [faviconUrl, setFaviconUrl] =
    useState("");

  const [logoPreview, setLogoPreview] =
    useState(DEFAULT_LOGO);

  const [faviconPreview, setFaviconPreview] =
    useState(DEFAULT_FAVICON);

  const [logoFile, setLogoFile] =
    useState(null);

  const [faviconFile, setFaviconFile] =
    useState(null);

  const [loading, setLoading] =
    useState(true);

  const [saving, setSaving] =
    useState(false);

  const [uploadingLogo, setUploadingLogo] =
    useState(false);

  const [uploadingFavicon, setUploadingFavicon] =
    useState(false);

  const [error, setError] =
    useState("");

  const [success, setSuccess] =
    useState("");


  // =========================================================
  // LOAD SETTINGS
  // =========================================================

  useEffect(() => {

    loadSettings();

  }, []);


  // =========================================================
  // GET SETTINGS
  // =========================================================

  const loadSettings = async () => {

    try {

      setLoading(true);
      setError("");

      const data =
        await api.get("/system-settings");

      // Backend có thể trả:
      // {
      //    systemName: "...",
      //    description: "...",
      //    ...
      // }
      //
      // hoặc:
      //
      // {
      //    settings: {...}
      // }

      const settings =
        data?.settings || data;

      if (!settings) {
        throw new Error(
          "Không nhận được dữ liệu cài đặt."
        );
      }


      // =====================================================
      // FORM
      // =====================================================

      setFormData({

        systemName:
          settings.systemName || "",

        description:
          settings.description || "",

        address:
          settings.address || "",

        email:
          settings.email || "",

        phone:
          settings.phone || "",

        website:
          settings.website || "",

      });


      // =====================================================
      // LOGO
      // =====================================================

      const serverLogo =
        settings.logoUrl ||
        settings.logo ||
        "";

      setLogoUrl(serverLogo);

      setLogoPreview(
        buildImageUrl(serverLogo) ||
        DEFAULT_LOGO
      );


      // =====================================================
      // FAVICON
      // =====================================================

      const serverFavicon =
        settings.faviconUrl ||
        settings.favicon ||
        "";

      setFaviconUrl(serverFavicon);

      setFaviconPreview(
        buildImageUrl(serverFavicon) ||
        DEFAULT_FAVICON
      );


    } catch (err) {

      console.error(
        "LOAD SYSTEM SETTINGS ERROR:",
        err
      );

      setError(
        err?.message ||
        "Không thể tải thông tin website."
      );

    } finally {

      setLoading(false);

    }

  };


  // =========================================================
  // HANDLE INPUT
  // =========================================================

  const handleChange = (event) => {

    const {
      name,
      value,
    } = event.target;

    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));

    // Xóa message khi người dùng chỉnh sửa
    setError("");
    setSuccess("");

  };


  // =========================================================
  // VALIDATE IMAGE
  // =========================================================

  const validateImage = (
    file,
    type
  ) => {

    if (!file) {
      return false;
    }


    // =====================================================
    // LOGO
    // =====================================================

    if (type === "logo") {

      const allowedTypes = [
        "image/png",
        "image/jpeg",
        "image/jpg",
      ];

      if (!allowedTypes.includes(file.type)) {

        setError(
          "Logo chỉ chấp nhận PNG hoặc JPG."
        );

        return false;
      }


      if (
        file.size >
        2 * 1024 * 1024
      ) {

        setError(
          "Logo không được vượt quá 2MB."
        );

        return false;
      }

    }


    // =====================================================
    // FAVICON
    // =====================================================

    if (type === "favicon") {

      const allowedTypes = [
        "image/png",
        "image/x-icon",
        "image/vnd.microsoft.icon",
      ];

      const extension =
        file.name
          .split(".")
          .pop()
          ?.toLowerCase();

      const validExtension =
        extension === "png" ||
        extension === "ico";

      if (
        !allowedTypes.includes(file.type) &&
        !validExtension
      ) {

        setError(
          "Favicon chỉ chấp nhận PNG hoặc ICO."
        );

        return false;
      }


      if (
        file.size >
        1 * 1024 * 1024
      ) {

        setError(
          "Favicon không được vượt quá 1MB."
        );

        return false;
      }

    }


    return true;

  };


  // =========================================================
  // LOGO CHANGE
  // =========================================================

  const handleLogoChange = async (event) => {

    const file =
      event.target.files?.[0];

    if (!file) {
      return;
    }


    setError("");
    setSuccess("");


    if (
      !validateImage(
        file,
        "logo"
      )
    ) {

      event.target.value = "";
      return;

    }


    // =====================================================
    // PREVIEW LOCAL
    // =====================================================

    const imageUrl =
      URL.createObjectURL(file);

    setLogoPreview(imageUrl);

    setLogoFile(file);


    // =====================================================
    // UPLOAD NGAY
    // =====================================================

    try {

      setUploadingLogo(true);


      const formDataUpload =
        new FormData();

      formDataUpload.append(
        "file",
        file
      );


      const data =
        await api.post(
          "/system-settings/logo",
          formDataUpload
        );


      const newLogoUrl =
        data?.logoUrl ||
        data?.url ||
        data?.settings?.logoUrl;


      if (!newLogoUrl) {

        throw new Error(
          "Backend không trả về logoUrl."
        );

      }


      setLogoUrl(newLogoUrl);

      setLogoPreview(
        buildImageUrl(
          newLogoUrl
        )
      );


      setSuccess(
        "Cập nhật logo thành công."
      );


    } catch (err) {

      console.error(
        "UPLOAD LOGO ERROR:",
        err
      );

      setError(
        err?.message ||
        "Không thể cập nhật logo."
      );

      // Nếu upload lỗi thì trả preview về ảnh cũ
      setLogoPreview(
        buildImageUrl(
          logoUrl
        ) || DEFAULT_LOGO
      );

    } finally {

      setUploadingLogo(false);

      event.target.value = "";

    }

  };


  // =========================================================
  // FAVICON CHANGE
  // =========================================================

  const handleFaviconChange = async (event) => {

    const file =
      event.target.files?.[0];

    if (!file) {
      return;
    }


    setError("");
    setSuccess("");


    if (
      !validateImage(
        file,
        "favicon"
      )
    ) {

      event.target.value = "";
      return;

    }


    // =====================================================
    // PREVIEW LOCAL
    // =====================================================

    const imageUrl =
      URL.createObjectURL(file);

    setFaviconPreview(imageUrl);

    setFaviconFile(file);


    // =====================================================
    // UPLOAD
    // =====================================================

    try {

      setUploadingFavicon(true);


      const formDataUpload =
        new FormData();

      formDataUpload.append(
        "file",
        file
      );


      const data =
        await api.post(
          "/system-settings/favicon",
          formDataUpload
        );


      const newFaviconUrl =
        data?.faviconUrl ||
        data?.url ||
        data?.settings?.faviconUrl;


      if (!newFaviconUrl) {

        throw new Error(
          "Backend không trả về faviconUrl."
        );

      }


      setFaviconUrl(
        newFaviconUrl
      );

      setFaviconPreview(
        buildImageUrl(
          newFaviconUrl
        )
      );


      setSuccess(
        "Cập nhật favicon thành công."
      );


    } catch (err) {

      console.error(
        "UPLOAD FAVICON ERROR:",
        err
      );

      setError(
        err?.message ||
        "Không thể cập nhật favicon."
      );


      setFaviconPreview(
        buildImageUrl(
          faviconUrl
        ) || DEFAULT_FAVICON
      );

    } finally {

      setUploadingFavicon(false);

      event.target.value = "";

    }

  };


  // =========================================================
  // SAVE SETTINGS
  // =========================================================

  const handleSubmit = async (event) => {

    event.preventDefault();

    setError("");
    setSuccess("");


    // =====================================================
    // VALIDATION
    // =====================================================

    if (
      !formData.systemName.trim()
    ) {

      setError(
        "Tên hệ thống không được để trống."
      );

      return;

    }


    if (
      formData.email.trim()
    ) {

      const emailRegex =
        /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

      if (
        !emailRegex.test(
          formData.email.trim()
        )
      ) {

        setError(
          "Email không hợp lệ."
        );

        return;

      }

    }


    // =====================================================
    // SAVE
    // =====================================================

    try {

      setSaving(true);


      const payload = {

        systemName:
          formData.systemName.trim(),

        description:
          formData.description.trim(),

        address:
          formData.address.trim(),

        email:
          formData.email.trim(),

        phone:
          formData.phone.trim(),

        website:
          formData.website.trim(),

        logoUrl:
          logoUrl || null,

        faviconUrl:
          faviconUrl || null,

      };


      const data =
        await api.put(
          "/system-settings",
          payload
        );


      const updatedSettings =
        data?.settings ||
        data;


      // =====================================================
      // UPDATE STATE
      // =====================================================

      if (updatedSettings) {

        setFormData({

          systemName:
            updatedSettings.systemName ??
            formData.systemName,

          description:
            updatedSettings.description ??
            formData.description,

          address:
            updatedSettings.address ??
            formData.address,

          email:
            updatedSettings.email ??
            formData.email,

          phone:
            updatedSettings.phone ??
            formData.phone,

          website:
            updatedSettings.website ??
            formData.website,

        });


        if (
          updatedSettings.logoUrl
        ) {

          setLogoUrl(
            updatedSettings.logoUrl
          );

          setLogoPreview(
            buildImageUrl(
              updatedSettings.logoUrl
            )
          );

        }


        if (
          updatedSettings.faviconUrl
        ) {

          setFaviconUrl(
            updatedSettings.faviconUrl
          );

          setFaviconPreview(
            buildImageUrl(
              updatedSettings.faviconUrl
            )
          );

        }

      }


      // Không còn file chưa xử lý
      setLogoFile(null);
      setFaviconFile(null);


      setSuccess(
        "Lưu thông tin website thành công."
      );


    } catch (err) {

      console.error(
        "SAVE SYSTEM SETTINGS ERROR:",
        err
      );

      setError(
        err?.message ||
        "Không thể lưu thông tin website."
      );

    } finally {

      setSaving(false);

    }

  };


  // =========================================================
  // IMAGE ERROR
  // =========================================================

  const handleLogoError = (event) => {

    if (
      event.currentTarget.dataset.fallback === "true"
    ) {
      return;
    }

    event.currentTarget.dataset.fallback = "true";

    event.currentTarget.src =
      DEFAULT_LOGO;

  };


  const handleFaviconError = (event) => {

    if (
      event.currentTarget.dataset.fallback === "true"
    ) {
      return;
    }

    event.currentTarget.dataset.fallback = "true";

    event.currentTarget.src =
      DEFAULT_FAVICON;

  };


  // =========================================================
  // LOADING
  // =========================================================

  if (loading) {

    return (

      <section className="admin-system-setting-page">

        <div className="admin-system-setting-card">

          <div
            style={{
              padding: "40px",
              textAlign: "center",
            }}
          >
            Đang tải thông tin website...
          </div>

        </div>

      </section>

    );

  }


  // =========================================================
  // RENDER
  // =========================================================

  return (

    <section className="admin-system-setting-page">

      <form
        className="admin-system-setting-card"
        onSubmit={handleSubmit}
      >

        {/* =================================================
            HEADER
        ================================================= */}

        <div className="admin-system-setting-header">

          <div className="admin-system-setting-header-icon">

            <FontAwesomeIcon
              icon={faBuildingColumns}
            />

          </div>

          <div>

            <h2>
              Thông tin website
            </h2>

            <p>
              Quản lý thông tin hiển thị của hệ thống
            </p>

          </div>

        </div>


        {/* =================================================
            MESSAGE
        ================================================= */}

        {error && (

          <div
            className="admin-system-setting-message admin-system-setting-message-error"
          >
            {error}
          </div>

        )}


        {success && (

          <div
            className="admin-system-setting-message admin-system-setting-message-success"
          >
            {success}
          </div>

        )}


        {/* =================================================
            SYSTEM NAME
        ================================================= */}

        <div className="admin-system-setting-field">

          <label htmlFor="systemName">

            Tên hệ thống

            <span className="admin-system-setting-required">
              *
            </span>

          </label>


          <div className="admin-system-setting-control">

            <input
              id="systemName"
              type="text"
              name="systemName"
              value={formData.systemName}
              onChange={handleChange}
              placeholder="Nhập tên hệ thống"
              required
            />

          </div>

        </div>


        {/* =================================================
            DESCRIPTION
        ================================================= */}

        <div className="admin-system-setting-field">

          <label htmlFor="description">
            Mô tả hệ thống
          </label>


          <div className="admin-system-setting-control">

            <textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleChange}
              placeholder="Nhập mô tả hệ thống"
              rows="3"
            />

          </div>

        </div>


        {/* =================================================
            LOGO
        ================================================= */}

        <div className="admin-system-setting-field">

          <label>
            Logo
          </label>


          <div className="admin-system-setting-upload-row">

            <div className="admin-system-setting-logo-preview">

              {logoPreview ? (

                <img
                  src={logoPreview}
                  alt="Logo THEMIS"
                  onError={handleLogoError}
                />

              ) : (

                <div className="admin-system-setting-logo-placeholder">

                  <FontAwesomeIcon
                    icon={faImage}
                  />

                </div>

              )}

            </div>


            <label className="admin-system-setting-upload-box">

              <FontAwesomeIcon
                icon={faUpload}
              />

              <span>

                {uploadingLogo
                  ? "Đang tải logo..."
                  : "Thay đổi logo"
                }

              </span>

              <small>
                PNG, JPG tối đa 2MB
              </small>


              <input
                type="file"
                accept=".png,.jpg,.jpeg"
                onChange={handleLogoChange}
                disabled={uploadingLogo}
              />

            </label>

          </div>

        </div>


        {/* =================================================
            FAVICON
        ================================================= */}

        <div className="admin-system-setting-field">

          <label>
            Favicon
          </label>


          <div className="admin-system-setting-upload-row">

            <div className="admin-system-setting-favicon-preview">

              {faviconPreview ? (

                <img
                  src={faviconPreview}
                  alt="Favicon THEMIS"
                  onError={handleFaviconError}
                />

              ) : (

                <FontAwesomeIcon
                  icon={faBuildingColumns}
                />

              )}

            </div>


            <label className="admin-system-setting-upload-box admin-system-setting-favicon-upload">

              <FontAwesomeIcon
                icon={faUpload}
              />

              <span>

                {uploadingFavicon
                  ? "Đang tải favicon..."
                  : "Thay đổi favicon"
                }

              </span>

              <small>
                PNG, ICO tối đa 1MB
              </small>


              <input
                type="file"
                accept=".png,.ico"
                onChange={handleFaviconChange}
                disabled={uploadingFavicon}
              />

            </label>

          </div>

        </div>


        {/* =================================================
            ADDRESS
        ================================================= */}

        <div className="admin-system-setting-field">

          <label htmlFor="address">
            Địa chỉ liên hệ
          </label>


          <div className="admin-system-setting-control admin-system-setting-control-icon">

            <FontAwesomeIcon
              icon={faLocationDot}
            />

            <input
              id="address"
              type="text"
              name="address"
              value={formData.address}
              onChange={handleChange}
              placeholder="Nhập địa chỉ"
            />

          </div>

        </div>


        {/* =================================================
            EMAIL
        ================================================= */}

        <div className="admin-system-setting-field">

          <label htmlFor="email">
            Email liên hệ
          </label>


          <div className="admin-system-setting-control admin-system-setting-control-icon">

            <FontAwesomeIcon
              icon={faEnvelope}
            />

            <input
              id="email"
              type="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              placeholder="Nhập email"
            />

          </div>

        </div>


        {/* =================================================
            PHONE
        ================================================= */}

        <div className="admin-system-setting-field">

          <label htmlFor="phone">
            Số điện thoại
          </label>


          <div className="admin-system-setting-control admin-system-setting-control-icon">

            <FontAwesomeIcon
              icon={faPhone}
            />

            <input
              id="phone"
              type="text"
              name="phone"
              value={formData.phone}
              onChange={handleChange}
              placeholder="Nhập số điện thoại"
            />

          </div>

        </div>


        {/* =================================================
            WEBSITE
        ================================================= */}

        <div className="admin-system-setting-field">

          <label htmlFor="website">
            Website
          </label>


          <div className="admin-system-setting-control admin-system-setting-control-icon">

            <FontAwesomeIcon
              icon={faGlobe}
            />

            <input
              id="website"
              type="url"
              name="website"
              value={formData.website}
              onChange={handleChange}
              placeholder="https://example.com"
            />

          </div>

        </div>


        {/* =================================================
            SAVE
        ================================================= */}

        <div className="admin-system-setting-actions">

          <button
            type="submit"
            className="admin-system-setting-save-button"
            disabled={
              saving ||
              uploadingLogo ||
              uploadingFavicon
            }
          >

            <FontAwesomeIcon
              icon={faFloppyDisk}
            />

            <span>

              {saving
                ? "Đang lưu..."
                : "Lưu thay đổi"
              }

            </span>

          </button>

        </div>

      </form>

    </section>

  );

};


export default AdminSystemSettings;

