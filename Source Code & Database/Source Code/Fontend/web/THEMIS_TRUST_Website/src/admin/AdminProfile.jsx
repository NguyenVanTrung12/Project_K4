import { useEffect, useRef, useState } from "react";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
    faUser,
    faEnvelope,
    faPhone,
    faBriefcase,
    faIdCard,
    faAward,
    faCamera,
    faPen,
    faTrash,
    faSave,
    faXmark
} from "@fortawesome/free-solid-svg-icons";

import { api, getCurrentUser } from "../api/api";

import "../assets/css/admin/AdminProfile.css";


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
// AVATAR URL
// =========================================================

const buildAvatarUrl = (avatarUrl) => {

    if (!avatarUrl) {
        return "";
    }

    // URL tuyệt đối
    if (
        avatarUrl.startsWith("http://") ||
        avatarUrl.startsWith("https://")
    ) {
        return avatarUrl;
    }

    // URL tương đối
    const serverBaseUrl = getServerBaseUrl();

    if (avatarUrl.startsWith("/")) {
        return `${serverBaseUrl}${avatarUrl}`;
    }

    return `${serverBaseUrl}/${avatarUrl}`;
};


// =========================================================
// DEFAULT AVATAR
// =========================================================

const DEFAULT_AVATAR =
    "https://ui-avatars.com/api/?name=Themis&background=245986&color=fff&size=256";


// =========================================================
// COMPONENT
// =========================================================

export default function AdminProfile() {

    const currentUser = getCurrentUser();

    const fileInputRef = useRef(null);


    // =====================================================
    // STATE
    // =====================================================

    const [profile, setProfile] =
        useState(currentUser);

    const [loading, setLoading] =
        useState(true);

    const [saving, setSaving] =
        useState(false);

    const [uploadingAvatar, setUploadingAvatar] =
        useState(false);

    const [editing, setEditing] =
        useState(false);

    const [error, setError] =
        useState("");

    const [success, setSuccess] =
        useState("");

    const [form, setForm] = useState({
        fullName: "",
        email: "",
        phone: ""
    });


    // =========================================================
    // LOAD PROFILE
    // =========================================================

    useEffect(() => {

        const loadProfile = async () => {

            try {

                setLoading(true);
                setError("");

                if (!currentUser?.id) {

                    setError(
                        "Không tìm thấy thông tin tài khoản."
                    );

                    return;
                }


                const data = await api.get(
                    `/users/${currentUser.id}`
                );


                const userData =
                    data?.user || data;


                setProfile(userData);


                setForm({
                    fullName:
                        userData?.fullName || "",

                    email:
                        userData?.email || "",

                    phone:
                        userData?.phone || ""
                });


            } catch (err) {

                console.error(
                    "LOAD PROFILE ERROR:",
                    err
                );


                // Không làm mất dữ liệu hiện tại
                setProfile(currentUser);


                setForm({
                    fullName:
                        currentUser?.fullName || "",

                    email:
                        currentUser?.email || "",

                    phone:
                        currentUser?.phone || ""
                });


            } finally {

                setLoading(false);

            }
        };


        loadProfile();

    }, []);


    // =========================================================
    // FORM CHANGE
    // =========================================================

    const handleChange = (e) => {

        const {
            name,
            value
        } = e.target;


        setForm((prev) => ({
            ...prev,
            [name]: value
        }));

    };


    // =========================================================
    // OPEN EDIT
    // =========================================================

    const handleEdit = () => {

        setError("");
        setSuccess("");

        setForm({
            fullName:
                profile?.fullName || "",

            email:
                profile?.email || "",

            phone:
                profile?.phone || ""
        });

        setEditing(true);
    };


    // =========================================================
    // CANCEL EDIT
    // =========================================================

    const handleCancelEdit = () => {

        setForm({
            fullName:
                profile?.fullName || "",

            email:
                profile?.email || "",

            phone:
                profile?.phone || ""
        });

        setEditing(false);

        setError("");
    };


    // =========================================================
    // SAVE PROFILE
    // =========================================================

    const handleSave = async (e) => {

        e.preventDefault();

        setError("");
        setSuccess("");


        // Validation
        if (!form.fullName.trim()) {

            setError(
                "Họ và tên không được để trống."
            );

            return;
        }


        if (!form.email.trim()) {

            setError(
                "Email không được để trống."
            );

            return;
        }


        try {

            setSaving(true);


            const data = await api.patch(
                `/users/${currentUser.id}/profile`,
                {
                    fullName:
                        form.fullName.trim(),

                    email:
                        form.email.trim(),

                    phone:
                        form.phone.trim() || null
                }
            );


            const updatedProfile =
                data?.user || data;


            setProfile(updatedProfile);


            setForm({
                fullName:
                    updatedProfile?.fullName || "",

                email:
                    updatedProfile?.email || "",

                phone:
                    updatedProfile?.phone || ""
            });


            // =================================================
            // UPDATE THEMIS USER
            // =================================================

            const storedUser =
                getCurrentUser();


            if (storedUser) {

                const updatedUser = {
                    ...storedUser,
                    ...updatedProfile
                };


                localStorage.setItem(
                    "themis_user",
                    JSON.stringify(updatedUser)
                );


                sessionStorage.setItem(
                    "themis_user",
                    JSON.stringify(updatedUser)
                );
            }


            setEditing(false);


            setSuccess(
                "Cập nhật thông tin thành công."
            );


        } catch (err) {

            console.error(
                "SAVE PROFILE ERROR:",
                err
            );


            setError(
                err?.message ||
                "Không thể cập nhật thông tin."
            );


        } finally {

            setSaving(false);

        }
    };


    // =========================================================
    // CHOOSE AVATAR
    // =========================================================

    const handleChooseAvatar = () => {

        if (uploadingAvatar) {
            return;
        }

        fileInputRef.current?.click();
    };


    // =========================================================
    // UPLOAD AVATAR
    // =========================================================

    const handleAvatarChange = async (e) => {

        const file =
            e.target.files?.[0];


        if (!file) {
            return;
        }


        setError("");
        setSuccess("");


        // =====================================================
        // TYPE
        // =====================================================

        const allowedTypes = [
            "image/jpeg",
            "image/png",
            "image/webp"
        ];


        if (!allowedTypes.includes(file.type)) {

            setError(
                "Chỉ chấp nhận ảnh JPG, PNG hoặc WEBP."
            );

            e.target.value = "";

            return;
        }


        // =====================================================
        // SIZE
        // =====================================================

        if (file.size > 5 * 1024 * 1024) {

            setError(
                "Ảnh không được vượt quá 5MB."
            );

            e.target.value = "";

            return;
        }


        try {

            setUploadingAvatar(true);


            const formData =
                new FormData();


            formData.append(
                "file",
                file
            );


            const data = await api.post(
                `/users/${currentUser.id}/avatar`,
                formData
            );


            const newAvatarUrl =
                data?.avatarUrl ||
                data?.user?.avatarUrl;


            if (!newAvatarUrl) {

                throw new Error(
                    "Backend không trả về avatarUrl."
                );
            }


            // =================================================
            // UPDATE PROFILE
            // =================================================

            setProfile((prev) => ({
                ...prev,
                avatarUrl:
                    newAvatarUrl
            }));


            // =================================================
            // UPDATE LOCAL STORAGE
            // =================================================

            const storedUser =
                getCurrentUser();


            if (storedUser) {

                const updatedUser = {
                    ...storedUser,
                    avatarUrl:
                        newAvatarUrl
                };


                localStorage.setItem(
                    "themis_user",
                    JSON.stringify(updatedUser)
                );


                sessionStorage.setItem(
                    "themis_user",
                    JSON.stringify(updatedUser)
                );
            }


            setSuccess(
                "Cập nhật ảnh đại diện thành công."
            );


        } catch (err) {

            console.error(
                "UPLOAD AVATAR ERROR:",
                err
            );


            setError(
                err?.message ||
                "Không thể upload ảnh."
            );


        } finally {

            setUploadingAvatar(false);

            e.target.value = "";

        }
    };


    // =========================================================
    // DELETE AVATAR
    // =========================================================

    const handleDeleteAvatar = async () => {

        if (!profile?.avatarUrl) {
            return;
        }


        const confirmed =
            window.confirm(
                "Bạn có chắc muốn xóa ảnh đại diện?"
            );


        if (!confirmed) {
            return;
        }


        try {

            setUploadingAvatar(true);

            setError("");
            setSuccess("");


            await api.delete(
                `/users/${currentUser.id}/avatar`
            );


            setProfile((prev) => ({
                ...prev,
                avatarUrl: null
            }));


            // =================================================
            // UPDATE STORAGE
            // =================================================

            const storedUser =
                getCurrentUser();


            if (storedUser) {

                const updatedUser = {
                    ...storedUser,
                    avatarUrl: null
                };


                localStorage.setItem(
                    "themis_user",
                    JSON.stringify(updatedUser)
                );


                sessionStorage.setItem(
                    "themis_user",
                    JSON.stringify(updatedUser)
                );
            }


            setSuccess(
                "Đã xóa ảnh đại diện."
            );


        } catch (err) {

            console.error(
                "DELETE AVATAR ERROR:",
                err
            );


            setError(
                err?.message ||
                "Không thể xóa ảnh."
            );


        } finally {

            setUploadingAvatar(false);

        }
    };


    // =========================================================
    // ROLE
    // =========================================================

    const role =
        String(
            profile?.role ||
            currentUser?.role ||
            ""
        ).toLowerCase();


    const roleName = {

        admin:
            "Quản trị viên",

        lawyer:
            "Luật sư",

        staff:
            "Nhân viên"

    }[role] || "Người dùng";


    // =========================================================
    // AVATAR
    // =========================================================

    const avatarUrl =
        buildAvatarUrl(
            profile?.avatarUrl
        ) || DEFAULT_AVATAR;


    // =========================================================
    // AVATAR ERROR
    // =========================================================

    const handleAvatarError = (e) => {

        if (
            e.currentTarget.dataset.fallback === "true"
        ) {
            return;
        }


        e.currentTarget.dataset.fallback = "true";

        e.currentTarget.src =
            DEFAULT_AVATAR;
    };


    // =========================================================
    // LOADING
    // =========================================================

    if (loading) {

        return (
            <div className="admin-profile">

                <div className="profile-container">

                    <div className="profile-loading">

                        Đang tải thông tin cá nhân...

                    </div>

                </div>

            </div>
        );
    }


    // =========================================================
    // ERROR
    // =========================================================

    if (error && !profile) {

        return (
            <div className="admin-profile">

                <div className="profile-container">

                    <div className="profile-error">

                        {error}

                    </div>

                </div>

            </div>
        );
    }


    // =========================================================
    // RENDER
    // =========================================================

    return (

        <div className="admin-profile">

            <div className="profile-container">


                {/* =================================================
                    HEADER
                ================================================= */}

                <div className="profile-header">

                    <div className="profile-header-left">

                        <div className="profile-title">

                            <FontAwesomeIcon
                                icon={faUser}
                            />

                            <h2>
                                Hồ sơ cá nhân
                            </h2>

                        </div>


                        <p>
                            Quản lý thông tin và ảnh đại diện của bạn
                        </p>

                    </div>


                    {/* =================================================
                        EDIT BUTTON
                    ================================================= */}

                    {!editing && (

                        <button
                            type="button"
                            className="profile-edit-button"
                            onClick={handleEdit}
                        >

                            <FontAwesomeIcon
                                icon={faPen}
                            />

                            <span>
                                Chỉnh sửa thông tin
                            </span>

                        </button>

                    )}

                </div>


                {/* =================================================
                    MESSAGE
                ================================================= */}

                {error && (

                    <div className="profile-message profile-message-error">

                        {error}

                    </div>

                )}


                {success && (

                    <div className="profile-message profile-message-success">

                        {success}

                    </div>

                )}


                {/* =================================================
                    PROFILE MAIN
                ================================================= */}

                <div className="profile-main-card">


                    {/* =================================================
                        AVATAR
                    ================================================= */}

                    <div className="profile-avatar-section">

                        <div className="profile-avatar-wrapper">

                            <img
                                src={avatarUrl}
                                alt="Ảnh đại diện"
                                className="profile-avatar"
                                onError={handleAvatarError}
                            />


                            <button
                                type="button"
                                className="avatar-camera-button"
                                onClick={handleChooseAvatar}
                                disabled={uploadingAvatar}
                                title="Đổi ảnh đại diện"
                            >

                                <FontAwesomeIcon
                                    icon={faCamera}
                                />

                            </button>

                        </div>


                        {/* Hidden input */}

                        <input
                            ref={fileInputRef}
                            type="file"
                            accept="image/jpeg,image/png,image/webp"
                            className="avatar-file-input"
                            onChange={handleAvatarChange}
                        />


                        {/* Avatar buttons */}

                        <div className="avatar-actions">

                            <button
                                type="button"
                                onClick={handleChooseAvatar}
                                disabled={uploadingAvatar}
                            >

                                <FontAwesomeIcon
                                    icon={faCamera}
                                />

                                {uploadingAvatar
                                    ? "Đang xử lý..."
                                    : "Đổi ảnh"
                                }

                            </button>


                            {profile?.avatarUrl && (

                                <button
                                    type="button"
                                    className="avatar-delete-button"
                                    onClick={handleDeleteAvatar}
                                    disabled={uploadingAvatar}
                                >

                                    <FontAwesomeIcon
                                        icon={faTrash}
                                    />

                                    Xóa ảnh

                                </button>

                            )}

                        </div>


                        <small>
                            JPG, PNG hoặc WEBP · tối đa 5MB
                        </small>

                    </div>


                    {/* =================================================
                        SUMMARY
                    ================================================= */}

                    <div className="profile-summary">

                        <h1>
                            {profile?.fullName || "Chưa cập nhật"}
                        </h1>


                        <span className="profile-role">
                            {roleName}
                        </span>


                        <p>
                            {profile?.email || "Chưa cập nhật"}
                        </p>

                    </div>

                </div>


                {/* =================================================
                    EDIT FORM
                ================================================= */}

                {editing ? (

                    <form
                        className="profile-edit-card"
                        onSubmit={handleSave}
                    >

                        <div className="profile-card-title">

                            <FontAwesomeIcon
                                icon={faPen}
                            />

                            <h3>
                                Chỉnh sửa thông tin
                            </h3>

                        </div>


                        <div className="profile-form-grid">


                            {/* HỌ TÊN */}

                            <div className="profile-form-group">

                                <label>
                                    Họ và tên
                                </label>

                                <input
                                    type="text"
                                    name="fullName"
                                    value={form.fullName}
                                    onChange={handleChange}
                                    placeholder="Nhập họ và tên"
                                />

                            </div>


                            {/* EMAIL */}

                            <div className="profile-form-group">

                                <label>
                                    Email
                                </label>

                                <input
                                    type="email"
                                    name="email"
                                    value={form.email}
                                    onChange={handleChange}
                                    placeholder="Nhập email"
                                />

                            </div>


                            {/* PHONE */}

                            <div className="profile-form-group">

                                <label>
                                    Số điện thoại
                                </label>

                                <input
                                    type="text"
                                    name="phone"
                                    value={form.phone}
                                    onChange={handleChange}
                                    placeholder="Nhập số điện thoại"
                                />

                            </div>

                        </div>


                        {/* FORM BUTTONS */}

                        <div className="profile-form-actions">

                            <button
                                type="button"
                                className="profile-cancel-button"
                                onClick={handleCancelEdit}
                                disabled={saving}
                            >

                                <FontAwesomeIcon
                                    icon={faXmark}
                                />

                                Hủy

                            </button>


                            <button
                                type="submit"
                                className="profile-save-button"
                                disabled={saving}
                            >

                                <FontAwesomeIcon
                                    icon={faSave}
                                />

                                {saving
                                    ? "Đang lưu..."
                                    : "Lưu thay đổi"
                                }

                            </button>

                        </div>

                    </form>

                ) : (

                    /* =================================================
                       INFORMATION
                    ================================================= */

                    <div className="profile-info-card">

                        <div className="profile-card-title">

                            <FontAwesomeIcon
                                icon={faUser}
                            />

                            <h3>
                                Thông tin tài khoản
                            </h3>

                        </div>


                        <div className="profile-info-grid">


                            {/* HỌ TÊN */}

                            <div className="profile-info-item">

                                <FontAwesomeIcon
                                    icon={faUser}
                                />

                                <div>

                                    <span>
                                        Họ và tên
                                    </span>

                                    <strong>
                                        {profile?.fullName ||
                                            "Chưa cập nhật"}
                                    </strong>

                                </div>

                            </div>


                            {/* EMAIL */}

                            <div className="profile-info-item">

                                <FontAwesomeIcon
                                    icon={faEnvelope}
                                />

                                <div>

                                    <span>
                                        Email
                                    </span>

                                    <strong>
                                        {profile?.email ||
                                            "Chưa cập nhật"}
                                    </strong>

                                </div>

                            </div>


                            {/* PHONE */}

                            <div className="profile-info-item">

                                <FontAwesomeIcon
                                    icon={faPhone}
                                />

                                <div>

                                    <span>
                                        Số điện thoại
                                    </span>

                                    <strong>
                                        {profile?.phone ||
                                            "Chưa cập nhật"}
                                    </strong>

                                </div>

                            </div>


                            {/* ROLE */}

                            <div className="profile-info-item">

                                <FontAwesomeIcon
                                    icon={faBriefcase}
                                />

                                <div>

                                    <span>
                                        Vai trò
                                    </span>

                                    <strong>
                                        {roleName}
                                    </strong>

                                </div>

                            </div>


                            {/* LAWYER */}

                            {role === "lawyer" && (

                                <>

                                    {/* BAR LICENSE */}

                                    <div className="profile-info-item">

                                        <FontAwesomeIcon
                                            icon={faIdCard}
                                        />

                                        <div>

                                            <span>
                                                Mã luật sư
                                            </span>

                                            <strong>

                                                {profile?.barLicenseNo ||
                                                    profile?.lawyer?.barLicenseNo ||
                                                    "Chưa cập nhật"}

                                            </strong>

                                        </div>

                                    </div>


                                    {/* EXPERIENCE */}

                                    <div className="profile-info-item">

                                        <FontAwesomeIcon
                                            icon={faAward}
                                        />

                                        <div>

                                            <span>
                                                Kinh nghiệm
                                            </span>

                                            <strong>

                                                {profile?.yearsExp ??
                                                    profile?.lawyer?.yearsExp ??
                                                    0}

                                                {" "}năm

                                            </strong>

                                        </div>

                                    </div>

                                </>

                            )}

                        </div>

                    </div>

                )}

            </div>

        </div>

    );
}