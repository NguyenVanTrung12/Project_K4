import { useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { api, saveAuth } from "../api/api";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
    faUser,
    faEnvelope,
    faPhone,
    faLock,
    faEye,
    faEyeSlash,
    faShieldHalved,
    faUsers,
    faArrowRight,
    faUserPlus,
    faScaleBalanced,
    faFileLines,
    faClock,
} from "@fortawesome/free-solid-svg-icons";

import "../assets/css/register.css";


const Register = () => {

    /* =====================================================
       STATE
    ===================================================== */

    const [showPassword, setShowPassword] =
        useState(false);

    const [showConfirmPassword, setShowConfirmPassword] =
        useState(false);

    const [agreeTerms, setAgreeTerms] = useState(false);
    const [form, setForm] = useState({ fullName: "", email: "", phone: "", password: "" });
    const [confirmPassword, setConfirmPassword] = useState("");
    const [error, setError] = useState("");
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();


    /* =====================================================
       REGISTER
    ===================================================== */

    const handleSubmit = async (event) => {
        event.preventDefault();
        setError("");
        if (!agreeTerms) return setError("Vui lòng đồng ý với điều khoản sử dụng.");
        if (form.password !== confirmPassword) return setError("Mật khẩu xác nhận không khớp.");
        setLoading(true);
        try {
            const data = await api.post("/auth/register", { ...form, role: "client" });
            saveAuth(data, true);
            navigate("/");
        } catch (err) { setError(err.message || "Đăng ký thất bại."); }
        finally { setLoading(false); }
    };


    return (

        <div className="register-page">


            {/* =================================================
          LEFT SIDE
      ================================================= */}

            <section className="register-page__left">


                {/* =================================================
            BACKGROUND
        ================================================= */}

                <div className="register-page__background"></div>


                {/* =================================================
            OVERLAY
        ================================================= */}

                <div className="register-page__overlay"></div>


                {/* =================================================
            LEFT CONTENT
        ================================================= */}

                <div className="register-page__content">


                    {/* =================================================
              BRAND
          ================================================= */}

                    <div className="register-brand">

                        <div className="register-brand__icon">

                            <FontAwesomeIcon
                                icon={faScaleBalanced}
                            />

                        </div>


                        <div className="register-brand__text">

                            <strong>
                                THEMIS TRUST
                            </strong>
                            <span>
                                LAW &amp; JUSTICE
                            </span>
                        </div>

                    </div>


                    {/* =================================================
              HERO
          ================================================= */}

                    <div className="register-hero">

                        <h1>

                            Đồng hành

                            <br />

                            <span>
                                cùng bạn
                            </span>

                            <br />

                            <strong>
                                trên mọi hành trình pháp lý
                            </strong>

                        </h1>


                        <div className="register-hero__line"></div>


                        <p>
                            Tham gia cộng đồng khách hàng của Themis Trust để nhận
                            <br />
                            được sự hỗ trợ pháp lý nhanh chóng, an toàn và hiệu quả.
                        </p>

                    </div>


                    {/* =================================================
              FEATURES
          ================================================= */}

                    <div className="register-features">


                        {/* =================================================
                FEATURE 01
            ================================================= */}

                        <div className="register-feature">

                            <div className="register-feature__icon">

                                <FontAwesomeIcon
                                    icon={faShieldHalved}
                                />

                            </div>


                            <div className="register-feature__text">

                                <span>
                                    Bảo mật thông tin
                                </span>

                                <span>
                                    tuyệt đối
                                </span>

                            </div>

                        </div>


                        {/* =================================================
                FEATURE 02
            ================================================= */}

                        <div className="register-feature">

                            <div className="register-feature__icon">

                                <FontAwesomeIcon
                                    icon={faUsers}
                                />

                            </div>


                            <div className="register-feature__text">

                                <span>
                                    Kết nối với luật sư
                                </span>

                                <span>
                                    chuyên nghiệp
                                </span>

                            </div>

                        </div>


                        {/* =================================================
                FEATURE 03
            ================================================= */}

                        <div className="register-feature">

                            <div className="register-feature__icon">

                                <FontAwesomeIcon
                                    icon={faFileLines}
                                />

                            </div>


                            <div className="register-feature__text">

                                <span>
                                    Tiếp cận dịch vụ pháp lý
                                </span>

                                <span>
                                    toàn diện
                                </span>

                            </div>

                        </div>


                        {/* =================================================
                FEATURE 04
            ================================================= */}

                        <div className="register-feature">

                            <div className="register-feature__icon">

                                <FontAwesomeIcon
                                    icon={faClock}
                                />

                            </div>


                            <div className="register-feature__text">

                                <span>
                                    Hỗ trợ nhanh chóng
                                </span>

                                <span>
                                    mọi lúc, mọi nơi
                                </span>

                            </div>

                        </div>

                    </div>


                    {/* =================================================
              BOTTOM QUOTE
          ================================================= */}

                    <div className="register-bottom-quote">

                        <p>
                            “Pháp luật không chỉ bảo vệ quyền lợi,
                            <br />
                            mà còn kiến tạo một xã hội công bằng hơn.”
                        </p>


                        <div className="register-bottom-quote__footer">

                            <span></span>

                            <small>
                                THEMIS TRUST
                            </small>

                        </div>

                    </div>

                </div>

            </section>


            {/* =================================================
          RIGHT SIDE
      ================================================= */}

            <section className="register-page__right">


                {/* =================================================
            REGISTER CARD
        ================================================= */}

                <div className="register-card">


                    {/* =================================================
              CARD LOGO
          ================================================= */}

                    <div className="register-card__brand">

                        <div className="register-card__brand-icon">

                            <FontAwesomeIcon
                                icon={faScaleBalanced}
                            />

                        </div>


                        <div className="register-card__brand-name">

                            <strong>
                                THEMIS TRUST
                            </strong>

                            <span>
                                LAW &amp; JUSTICE
                            </span>

                        </div>

                    </div>


                    {/* =================================================
              CARD HEADING
          ================================================= */}

                    <div className="register-card__heading">

                        <h2>
                            Đăng ký
                        </h2>

                        <p>
                            Tạo tài khoản để bắt đầu
                        </p>

                        <div className="register-card__line"></div>

                    </div>


                    {/* =================================================
              REGISTER FORM
          ================================================= */}

                    {error && <div className="register-error">{error}</div>}

                        <form
                        className="register-form"
                        onSubmit={handleSubmit}
                    >


                        {/* =================================================
                FULL NAME
            ================================================= */}

                        <div className="register-input">

                            <FontAwesomeIcon
                                icon={faUser}
                                className="register-input__icon"
                            />


                            <input
                                type="text"
                                name="fullName"
                                placeholder="Họ và tên"
                                autoComplete="name"
                                required
                                                            value={form.fullName}
                                onChange={(e) => setForm({ ...form, fullName: e.target.value })}
/>

                        </div>


                        {/* =================================================
                EMAIL
            ================================================= */}

                        <div className="register-input">

                            <FontAwesomeIcon
                                icon={faEnvelope}
                                className="register-input__icon"
                            />


                            <input
                                type="email"
                                name="email"
                                placeholder="Email"
                                autoComplete="email"
                                required
                                                            value={form.email}
                                onChange={(e) => setForm({ ...form, email: e.target.value })}
/>

                        </div>


                        {/* =================================================
                PHONE
            ================================================= */}

                        <div className="register-input">

                            <FontAwesomeIcon
                                icon={faPhone}
                                className="register-input__icon"
                            />


                            <input
                                type="tel"
                                name="phone"
                                placeholder="Số điện thoại"
                                autoComplete="tel"
                                required
                                                            value={form.phone}
                                onChange={(e) => setForm({ ...form, phone: e.target.value })}
/>

                        </div>

                        {/* =================================================
                PASSWORD
            ================================================= */}

                        <div className="register-input">

                            <FontAwesomeIcon
                                icon={faLock}
                                className="register-input__icon"
                            />


                            <input
                                type={
                                    showPassword
                                        ? "text"
                                        : "password"
                                }
                                name="password"
                                placeholder="Mật khẩu"
                                autoComplete="new-password"
                                required
                                                            value={form.password}
                                onChange={(e) => setForm({ ...form, password: e.target.value })}
/>


                            <button
                                type="button"
                                className="register-input__toggle"
                                onClick={() =>
                                    setShowPassword(
                                        !showPassword
                                    )
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
                CONFIRM PASSWORD
            ================================================= */}

                        <div className="register-input">

                            <FontAwesomeIcon
                                icon={faLock}
                                className="register-input__icon"
                            />


                            <input
                                type={
                                    showConfirmPassword
                                        ? "text"
                                        : "password"
                                }
                                name="confirmPassword"
                                placeholder="Nhập lại mật khẩu"
                                autoComplete="new-password"
                                required
                                                            value={confirmPassword}
                                onChange={(e) => setConfirmPassword(e.target.value)}
/>


                            <button
                                type="button"
                                className="register-input__toggle"
                                onClick={() =>
                                    setShowConfirmPassword(
                                        !showConfirmPassword
                                    )
                                }
                                aria-label={
                                    showConfirmPassword
                                        ? "Ẩn mật khẩu"
                                        : "Hiện mật khẩu"
                                }
                            >

                                <FontAwesomeIcon
                                    icon={
                                        showConfirmPassword
                                            ? faEyeSlash
                                            : faEye
                                    }
                                />

                            </button>

                        </div>


                        {/* =================================================
                TERMS
            ================================================= */}

                        <label className="register-terms">

                            <input
                                type="checkbox"
                                checked={agreeTerms}
                                onChange={(event) =>
                                    setAgreeTerms(
                                        event.target.checked
                                    )
                                }
                                required
                            />


                            <span className="register-checkbox"></span>


                            <span className="register-terms__text">

                                Tôi đồng ý với{" "}

                                <NavLink
                                    to="/terms"
                                    className="register-terms__link"
                                    onClick={(event) =>
                                        event.stopPropagation()
                                    }
                                >
                                    Điều khoản sử dụng
                                </NavLink>

                                {" "}và{" "}

                                <NavLink
                                    to="/privacy"
                                    className="register-terms__link"
                                    onClick={(event) =>
                                        event.stopPropagation()
                                    }
                                >
                                    Chính sách bảo mật
                                </NavLink>

                            </span>

                        </label>


                        {/* =================================================
                REGISTER BUTTON
            ================================================= */}

                        <button
                            type="submit"
                            className="register-submit"
                            disabled={!agreeTerms}
                        >

                            <FontAwesomeIcon
                                icon={faUserPlus}
                            />


                            <span>
                                Tạo tài khoản
                            </span>


                            <FontAwesomeIcon
                                icon={faArrowRight}
                                className="register-submit__arrow"
                            />

                        </button>


                        {/* =================================================
                LOGIN
            ================================================= */}

                        <div className="register-login">

                            <span>
                                Đã có tài khoản?
                            </span>


                            <NavLink
                                to="/login"
                                className="register-login__link"
                            >
                                Đăng nhập
                            </NavLink>

                        </div>

                    </form>

                </div>

            </section>

        </div>
    );
};


export default Register;