
import { useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { api, saveAuth } from "../api/api";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUser,
  faLock,
  faEye,
  faEyeSlash,
  faShieldHalved,
  faUsers,
  faHandshake,
  faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../assets/css/login.css";

const Login = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [rememberLogin, setRememberLogin] = useState(true);

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const navigate = useNavigate();

  /* =====================================================
     LOGIN
  ===================================================== */

  const handleSubmit = async (event) => {
    event.preventDefault();

    setError("");
    setLoading(true);

    try {
      // Gọi API đăng nhập
      const data = await api.post("/auth/login", {
        email: email.trim(),
        password,
      });

      // Kiểm tra dữ liệu trả về
      if (!data) {
        throw new Error("Không nhận được dữ liệu từ máy chủ.");
      }

      if (!data.token) {
        throw new Error("Đăng nhập thất bại: API không trả về token.");
      }

      if (!data.user) {
        throw new Error("Đăng nhập thất bại: API không trả về thông tin người dùng.");
      }

      // Lưu token + thông tin user
      saveAuth(data, rememberLogin);

      /*
       * =================================================
       * PHÂN QUYỀN ĐĂNG NHẬP
       *
       * ADMIN
       *   -> giao diện quản trị
       *
       * LAWYER
       *   -> giao diện quản trị
       *   -> nhưng sau này sẽ giới hạn menu/chức năng
       *
       * CLIENT
       *   -> giao diện người dùng bên ngoài
       * =================================================
       */

      const role = String(
        data.user.role ||
        data.user.Role ||
        ""
      )
        .trim()
        .toLowerCase();

      console.log("Đăng nhập thành công:", data.user);
      console.log("Role:", role);

      // ADMIN
      if (role === "admin") {
        navigate("/admin/dashboard", { replace: true });
        return;
      }

      // LAWYER
      if (role === "lawyer") {
        navigate("/admin/dashboard", { replace: true });
        return;
      }

      // CLIENT
      if (role === "client") {
        navigate("/", { replace: true });
        return;
      }

      // STAFF nếu hệ thống của bạn vẫn còn sử dụng
      if (role === "staff") {
        navigate("/admin/dashboard", { replace: true });
        return;
      }

      // Role không xác định
      throw new Error(
        `Tài khoản không có quyền truy cập. Role hiện tại: ${
          data.user.role || data.user.Role || "không xác định"
        }`
      );
    } catch (err) {
      console.error("LOGIN ERROR:", err);

      setError(
        err?.message ||
          "Đăng nhập thất bại. Vui lòng kiểm tra lại tài khoản và mật khẩu."
      );
    } finally {
      setLoading(false);
    }
  };

  /* =====================================================
     FORGOT PASSWORD
  ===================================================== */

  const handleForgotPassword = () => {
    console.log("Quên mật khẩu");

    // Khi có trang quên mật khẩu thì mở dòng dưới:
    // navigate("/forgot-password");
  };

  /* =====================================================
     RENDER
  ===================================================== */

  return (
    <div className="login-page">

      {/* =================================================
          LEFT SIDE
      ================================================= */}

      <div className="login-page__left">

        {/* Background */}
        <div className="login-page__background"></div>

        {/* Overlay */}
        <div className="login-page__overlay"></div>

        {/* Content */}
        <div className="login-page__content">

          {/* =================================================
              LOGO
          ================================================= */}

          <div className="login-brand">

            <div className="login-brand__icon">
              <i className="fa-solid fa-scale-balanced"></i>
            </div>

            <div className="login-brand__text">
              <strong>
                THEMIS TRUST
              </strong>

              <span>
                LAW & JUSTICE
              </span>
            </div>

          </div>

          {/* =================================================
              HERO TITLE
          ================================================= */}

          <div className="login-hero">

            <h1>
              Công lý
              <br />

              <span>
                luôn đồng hành
              </span>

              <br />

              cùng bạn
            </h1>

            <div className="login-hero__line"></div>

            <p>
              Chúng tôi tin rằng, mọi vấn đề pháp lý
              <br />
              đều có giải pháp. Hãy để đội ngũ chuyên gia
              <br />
              của chúng tôi đồng hành cùng bạn.
            </p>

          </div>

          {/* =================================================
              FEATURES
          ================================================= */}

          <div className="login-features">

            {/* Feature 1 */}
            <div className="login-feature">

              <div className="login-feature__icon">

                <FontAwesomeIcon
                  icon={faShieldHalved}
                />

              </div>

              <div className="login-feature__text">

                <span>
                  Bảo mật thông tin
                </span>

                <span>
                  tuyệt đối
                </span>

              </div>

            </div>

            {/* Feature 2 */}
            <div className="login-feature">

              <div className="login-feature__icon">

                <FontAwesomeIcon
                  icon={faUsers}
                />

              </div>

              <div className="login-feature__text">

                <span>
                  Đội ngũ luật sư
                </span>

                <span>
                  chuyên nghiệp
                </span>

              </div>

            </div>

            {/* Feature 3 */}
            <div className="login-feature">

              <div className="login-feature__icon">

                <FontAwesomeIcon
                  icon={faHandshake}
                />

              </div>

              <div className="login-feature__text">

                <span>
                  Giải pháp pháp lý
                </span>

                <span>
                  toàn diện
                </span>

              </div>

            </div>

          </div>

          {/* =================================================
              BOTTOM QUOTE
          ================================================= */}

          <div className="login-bottom-quote">

            <p>
              “Pháp luật không chỉ là những điều khoản,
              <br />
              mà là nền tảng cho một xã hội công bằng hơn.”
            </p>

            <div className="login-bottom-quote__footer">

              <span></span>

              <small>
                THEMIS TRUST
              </small>

            </div>

          </div>

        </div>

      </div>

      {/* =================================================
          RIGHT SIDE
      ================================================= */}

      <div className="login-page__right">

        {/* =================================================
            LOGIN CARD
        ================================================= */}

        <div className="login-card">

          {/* =================================================
              LOGO
          ================================================= */}

          <div className="login-card__brand">

            <div className="login-card__brand-icon">

              <i className="fa-solid fa-scale-balanced"></i>

            </div>

            <div className="login-card__brand-name">

              <strong>
                THEMIS TRUST
              </strong>

            </div>

          </div>

          {/* =================================================
              TITLE
          ================================================= */}

          <div className="login-card__heading">

            <h2>
              Đăng nhập
            </h2>

            <p>
              Chào mừng bạn trở lại
            </p>

            <div className="login-card__line"></div>

          </div>

          {/* =================================================
              ERROR
          ================================================= */}

          {error && (
            <div className="login-error">
              {error}
            </div>
          )}

          {/* =================================================
              FORM
          ================================================= */}

          <form
            className="login-form"
            onSubmit={handleSubmit}
          >

            {/* =================================================
                USERNAME / EMAIL
            ================================================= */}

            <div className="login-input">

              <FontAwesomeIcon
                icon={faUser}
                className="login-input__icon"
              />

              <input
                type="text"
                name="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Tên đăng nhập hoặc Email"
                autoComplete="username"
                required
              />

            </div>

            {/* =================================================
                PASSWORD
            ================================================= */}

            <div className="login-input">

              <FontAwesomeIcon
                icon={faLock}
                className="login-input__icon"
              />

              <input
                type={showPassword ? "text" : "password"}
                name="password"
                placeholder="Mật khẩu"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />

              <button
                type="button"
                className="login-input__toggle"
                onClick={() =>
                  setShowPassword((prev) => !prev)
                }
                aria-label={
                  showPassword
                    ? "Ẩn mật khẩu"
                    : "Hiện mật khẩu"
                }
              >

                <FontAwesomeIcon
                  icon={
                    showPassword
                      ? faEyeSlash
                      : faEye
                  }
                />

              </button>

            </div>

            {/* =================================================
                OPTIONS
            ================================================= */}

            <div className="login-options">

              <label className="login-remember">

                <input
                  type="checkbox"
                  checked={rememberLogin}
                  onChange={(event) =>
                    setRememberLogin(
                      event.target.checked
                    )
                  }
                />

                <span className="login-checkbox"></span>

                <span>
                  Ghi nhớ đăng nhập
                </span>

              </label>

              <button
                type="button"
                className="login-forgot"
                onClick={handleForgotPassword}
              >
                Quên mật khẩu?
              </button>

            </div>

            {/* =================================================
                LOGIN BUTTON
            ================================================= */}

            <button
              type="submit"
              className="login-submit"
              disabled={loading}
            >

              <span>
                {loading
                  ? "Đang đăng nhập..."
                  : "Đăng nhập"}
              </span>

              {!loading && (
                <FontAwesomeIcon
                  icon={faArrowRight}
                />
              )}

            </button>

            {/* =================================================
                REGISTER
            ================================================= */}

            <div className="login-register">

              <span>
                Chưa có tài khoản?
              </span>

              <NavLink
                to="/register"
                className="login-register__link"
              >
                Đăng ký ngay
              </NavLink>

            </div>

          </form>

        </div>

      </div>

    </div>
  );
};

export default Login;

