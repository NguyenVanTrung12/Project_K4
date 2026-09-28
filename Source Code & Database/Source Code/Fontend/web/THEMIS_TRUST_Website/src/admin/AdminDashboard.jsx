import { useEffect, useMemo, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
    faUsers,
    faUserTie,
    faCalendarDays,
    faFileLines,
    faChartPie,
    faCalendarCheck,
    faArrowUp,
    faArrowTrendUp,
    faBriefcase,
    faClock
} from "@fortawesome/free-solid-svg-icons";

import { api, getCurrentUser } from "../api/api";
import "../../src/assets/css/admin/AdminDashboard.css";

const statusLabel = (status) => {
    const labels = {
        pending: "Chờ xác nhận",
        confirmed: "Đã xác nhận",
        completed: "Hoàn thành",
        cancelled: "Đã hủy",
        rejected: "Từ chối",
        processing: "Đang xử lý",
        new: "Mới"
    };

    return labels[String(status || "").toLowerCase()] || status || "—";
};

const roleLabel = (role) => {
    const roles = {
        admin: "Quản trị viên",
        lawyer: "Luật sư",
        staff: "Nhân viên",
        client: "Khách hàng"
    };

    return roles[String(role || "").toLowerCase()] || role || "Người dùng";
};

const normalizeRole = (role) => String(role || "").trim().toLowerCase();

const safeNumber = (value) => {
    const number = Number(value);
    return Number.isFinite(number) ? number : 0;
};

const formatNumber = (value) =>
    safeNumber(value).toLocaleString("vi-VN");

const formatDate = (value) => {
    if (!value) return "—";

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
        return "—";
    }

    return date.toLocaleDateString("vi-VN");
};

const formatTime = (value) => {
    if (!value) return "—";

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
        return "—";
    }

    return date.toLocaleTimeString("vi-VN", {
        hour: "2-digit",
        minute: "2-digit"
    });
};

const isToday = (value) => {
    if (!value) return false;

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
        return false;
    }

    const today = new Date();

    return (
        date.getDate() === today.getDate() &&
        date.getMonth() === today.getMonth() &&
        date.getFullYear() === today.getFullYear()
    );
};

export default function AdminDashboard() {
    const user = getCurrentUser();
    const role = normalizeRole(user?.role);

    const isAdmin = role === "admin";
    const isLawyer = role === "lawyer";
    const isStaff = role === "staff";

    const [stats, setStats] = useState(null);
    const [users, setUsers] = useState([]);
    const [requests, setRequests] = useState([]);
    const [appointments, setAppointments] = useState([]);

    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");

    useEffect(() => {
        let mounted = true;

        const loadDashboard = async () => {
            try {
                setLoading(true);
                setError("");

                /*
                 * Admin / Staff:
                 *   - dashboard
                 *   - users
                 *   - consultation requests
                 *   - appointments
                 *
                 * Lawyer:
                 *   - dashboard
                 *   - consultation requests
                 *   - appointments
                 *
                 * Lawyer KHÔNG gọi /users vì endpoint này chỉ dành
                 * cho Admin/Staff.
                 */

                const dashboardPromise = api.get("/dashboard/stats");

                const requestsPromise = api
                    .get("/consultation-requests")
                    .catch(() => []);

                const appointmentsPromise = api
                    .get("/appointments")
                    .catch(() => []);

                let usersPromise = Promise.resolve([]);

                if (isAdmin || isStaff) {
                    usersPromise = api
                        .get("/users")
                        .catch(() => []);
                }

                const [dashboardData, usersData, requestsData, appointmentsData] =
                    await Promise.all([
                        dashboardPromise,
                        usersPromise,
                        requestsPromise,
                        appointmentsPromise
                    ]);

                if (!mounted) return;

                setStats(dashboardData || {});
                setUsers(Array.isArray(usersData) ? usersData : []);
                setRequests(
                    Array.isArray(requestsData) ? requestsData : []
                );
                setAppointments(
                    Array.isArray(appointmentsData)
                        ? appointmentsData
                        : []
                );
            } catch (err) {
                if (!mounted) return;

                console.error("Dashboard error:", err);

                setError(
                    err?.message ||
                    "Không thể tải dữ liệu dashboard."
                );
            } finally {
                if (mounted) {
                    setLoading(false);
                }
            }
        };

        loadDashboard();

        return () => {
            mounted = false;
        };
    }, [isAdmin, isStaff]);

    const displayStats = useMemo(() => {
        return {
            totalUsers: safeNumber(stats?.totalUsers),
            totalClients: safeNumber(stats?.totalClients),
            totalLawyers: safeNumber(stats?.totalLawyers),
            totalAppointments: safeNumber(stats?.totalAppointments),
            pendingAppointments: safeNumber(
                stats?.pendingAppointments
            ),
            totalCases: safeNumber(stats?.totalCases),
            totalRequests: safeNumber(stats?.totalRequests),

            appointmentsByDay: Array.isArray(
                stats?.appointmentsByDay
            )
                ? stats.appointmentsByDay
                : [],

            casesByArea: Array.isArray(stats?.casesByArea)
                ? stats.casesByArea
                : []
        };
    }, [stats]);

    const todayAppointments = useMemo(() => {
        return appointments
            .filter((appointment) =>
                isToday(appointment?.scheduledAt)
            )
            .sort(
                (a, b) =>
                    new Date(a.scheduledAt) -
                    new Date(b.scheduledAt)
            )
            .slice(0, 5);
    }, [appointments]);

    const latestUsers = useMemo(() => {
        return [...users]
            .sort((a, b) => {
                const dateA = new Date(a?.createdAt || 0);
                const dateB = new Date(b?.createdAt || 0);

                return dateB - dateA;
            })
            .slice(0, 5);
    }, [users]);

    const latestRequests = useMemo(() => {
        return [...requests]
            .sort((a, b) => {
                const dateA = new Date(a?.createdAt || 0);
                const dateB = new Date(b?.createdAt || 0);

                return dateB - dateA;
            })
            .slice(0, 5);
    }, [requests]);

    const kpis = useMemo(() => {
        /*
         * Lawyer không nên hiển thị:
         * - Tổng người dùng
         * - Tổng luật sư
         *
         * Thay vào đó hiển thị các dữ liệu liên quan
         * đến công việc của luật sư.
         */

        if (isLawyer) {
            return [
                {
                    title: "Lịch tư vấn",
                    value: displayStats.totalAppointments,
                    icon: faCalendarDays,
                    type: "blue",
                    desc: `${displayStats.pendingAppointments} lịch chờ xác nhận`
                },
                {
                    title: "Hồ sơ vụ án",
                    value: displayStats.totalCases,
                    icon: faBriefcase,
                    type: "gold",
                    desc: "Hồ sơ đang quản lý"
                },
                {
                    title: "Yêu cầu tư vấn",
                    value: displayStats.totalRequests,
                    icon: faFileLines,
                    type: "blue",
                    desc: "Yêu cầu được phân công"
                },
                {
                    title: "Lịch hôm nay",
                    value: todayAppointments.length,
                    icon: faCalendarCheck,
                    type: "blue",
                    desc: "Lịch làm việc hôm nay"
                }
            ];
        }

        return [
            {
                title: "Tổng người dùng",
                value: displayStats.totalUsers,
                icon: faUsers,
                type: "blue",
                desc: `${displayStats.totalClients} khách hàng`
            },
            {
                title: "Tổng luật sư",
                value: displayStats.totalLawyers,
                icon: faUserTie,
                type: "blue",
                desc: "Đang quản lý trên hệ thống"
            },
            {
                title: "Tổng lịch tư vấn",
                value: displayStats.totalAppointments,
                icon: faCalendarDays,
                type: "blue",
                desc: `${displayStats.pendingAppointments} lịch chờ xác nhận`
            },
            {
                title: "Hồ sơ vụ án",
                value: displayStats.totalCases,
                icon: faFileLines,
                type: "gold",
                desc: `${displayStats.totalRequests} yêu cầu tư vấn`
            }
        ];
    }, [
        isLawyer,
        displayStats,
        todayAppointments.length
    ]);

    if (loading) {
        return (
            <div className="admin-dashboard">
                <div className="dashboard-panel">
                    <p>Đang tải dữ liệu dashboard...</p>
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="admin-dashboard">
                <div className="dashboard-panel">
                    <p style={{ color: "red" }}>{error}</p>
                </div>
            </div>
        );
    }

    const greetingName =
        user?.fullName ||
        (isLawyer
            ? "Luật sư"
            : isStaff
                ? "Nhân viên"
                : "Quản trị viên");

    return (
        <div className="admin-dashboard">

            {/* =========================
                HERO
            ========================= */}
            <section className="dashboard-hero">
                <div className="dashboard-hero__background" />
                <div className="dashboard-hero__overlay" />

                <div className="dashboard-hero__content">
                    <h1>
                        Chào mừng bạn trở lại, {greetingName}!
                    </h1>

                    <p>
                        {isLawyer
                            ? "Theo dõi công việc, lịch tư vấn và hồ sơ được phân công."
                            : isStaff
                                ? "Theo dõi hoạt động và dữ liệu vận hành của Themis Trust."
                                : "Dữ liệu được lấy trực tiếp từ hệ thống Themis Trust."}
                    </p>
                </div>

                <div className="dashboard-hero__date">
                    <div className="dashboard-hero__date-icon">
                        <FontAwesomeIcon icon={faCalendarDays} />
                    </div>

                    <div>
                        <strong>
                            {new Date().toLocaleDateString(
                                "vi-VN",
                                {
                                    weekday: "long",
                                    day: "2-digit",
                                    month: "2-digit",
                                    year: "numeric"
                                }
                            )}
                        </strong>

                        <span>
                            Chúc bạn một ngày làm việc hiệu quả!
                        </span>
                    </div>
                </div>
            </section>


            {/* =========================
                KPI
            ========================= */}
            <section className="dashboard-statistics">
                {kpis.map((item) => (
                    <div
                        className="dashboard-stat-card"
                        key={item.title}
                    >
                        <div
                            className={`dashboard-stat-card__icon ${item.type}`}
                        >
                            <FontAwesomeIcon icon={item.icon} />
                        </div>

                        <div className="dashboard-stat-card__content">
                            <span className="dashboard-stat-card__title">
                                {item.title}
                            </span>

                            <div className="dashboard-stat-card__value-row">
                                <strong>
                                    {formatNumber(item.value)}
                                </strong>

                                <span className="dashboard-stat-card__growth">
                                    <FontAwesomeIcon icon={faArrowUp} />
                                    live
                                </span>
                            </div>

                            <p>{item.desc}</p>
                        </div>
                    </div>
                ))}
            </section>


            {/* =========================
                MAIN GRID
            ========================= */}
            <section className="dashboard-main-grid">

                {/* =========================
                    APPOINTMENT CHART
                ========================= */}
                <div className="dashboard-panel dashboard-chart-panel">

                    <div className="dashboard-panel__header">
                        <div className="dashboard-panel__title">
                            <FontAwesomeIcon icon={faCalendarDays} />

                            <h2>
                                {isLawyer
                                    ? "Lịch tư vấn của bạn"
                                    : "Lịch tư vấn 7 ngày gần nhất"}
                            </h2>
                        </div>
                    </div>

                    <div className="bar-chart">

                        <div className="bar-chart__y-axis">
                            <span>10</span>
                            <span>8</span>
                            <span>6</span>
                            <span>4</span>
                            <span>2</span>
                            <span>0</span>
                        </div>

                        <div className="bar-chart__area">

                            <div className="bar-chart__bars">

                                {displayStats.appointmentsByDay.length > 0 ? (
                                    displayStats.appointmentsByDay.map(
                                        (item) => {

                                            const value =
                                                safeNumber(item?.value);

                                            const height =
                                                Math.min(
                                                    100,
                                                    value * 10
                                                );

                                            return (
                                                <div
                                                    className="bar-chart__group"
                                                    key={
                                                        item?.label ||
                                                        Math.random()
                                                    }
                                                >
                                                    <div className="bar-chart__columns">
                                                        <div
                                                            className="bar online"
                                                            style={{
                                                                height: `${height}%`
                                                            }}
                                                        />
                                                    </div>

                                                    <span>
                                                        {item?.label || "—"}
                                                    </span>
                                                </div>
                                            );
                                        }
                                    )
                                ) : (
                                    <p>
                                        Chưa có dữ liệu lịch tư vấn.
                                    </p>
                                )}

                            </div>
                        </div>
                    </div>
                </div>


                {/* =========================
                    CASES BY AREA
                ========================= */}
                <div className="dashboard-panel dashboard-specialty-panel">

                    <div className="dashboard-panel__header">
                        <div className="dashboard-panel__title">
                            <FontAwesomeIcon icon={faChartPie} />

                            <h2>
                                {isLawyer
                                    ? "Hồ sơ theo lĩnh vực"
                                    : "Hồ sơ theo lĩnh vực"}
                            </h2>
                        </div>
                    </div>

                    <div className="specialty-list">

                        {displayStats.casesByArea.length > 0 ? (
                            displayStats.casesByArea.map((item) => (
                                <div
                                    className="specialty-item"
                                    key={item?.label || Math.random()}
                                >
                                    <div>
                                        <span className="specialty-dot" />

                                        <span>
                                            {item?.label || "Chưa xác định"}
                                        </span>
                                    </div>

                                    <strong>
                                        {formatNumber(item?.value)}
                                    </strong>
                                </div>
                            ))
                        ) : (
                            <p>Chưa có dữ liệu hồ sơ.</p>
                        )}

                    </div>
                </div>


                {/* =========================
                    TODAY APPOINTMENTS
                ========================= */}
                <div className="dashboard-panel dashboard-today-panel">

                    <div className="dashboard-panel__header">
                        <div className="dashboard-panel__title">
                            <FontAwesomeIcon icon={faCalendarCheck} />

                            <h2>
                                {isLawyer
                                    ? "Lịch làm việc hôm nay"
                                    : "Lịch hẹn hôm nay"}
                            </h2>
                        </div>
                    </div>

                    <div className="today-list">

                        {todayAppointments.length > 0 ? (
                            todayAppointments.map((appointment) => (
                                <div
                                    className="today-item"
                                    key={appointment.id}
                                >

                                    <div className="today-time">
                                        <strong>
                                            {formatTime(
                                                appointment.scheduledAt
                                            )}
                                        </strong>
                                    </div>

                                    <div className="today-content">
                                        <strong>
                                            {appointment.clientName ||
                                                appointment.client?.fullName ||
                                                "Khách hàng"}
                                        </strong>

                                        <p>
                                            Luật sư:{" "}
                                            {appointment.lawyerName ||
                                                appointment.lawyer?.fullName ||
                                                "—"}
                                        </p>
                                    </div>

                                    <span
                                        className={`today-status ${
                                            appointment.status || ""
                                        }`}
                                    >
                                        {statusLabel(
                                            appointment.status
                                        )}
                                    </span>

                                </div>
                            ))
                        ) : (
                            <p>
                                Hôm nay chưa có lịch hẹn.
                            </p>
                        )}

                    </div>
                </div>
            </section>


            {/* =========================
                BOTTOM GRID
            ========================= */}
            <section className="dashboard-bottom-grid">

                {/* =========================
                    USERS
                ========================= */}
                {(isAdmin || isStaff) && (
                    <div className="dashboard-panel dashboard-table-panel">

                        <div className="dashboard-panel__header">
                            <div className="dashboard-panel__title">
                                <FontAwesomeIcon icon={faUsers} />

                                <h2>
                                    Người dùng mới nhất
                                </h2>
                            </div>
                        </div>

                        <div className="dashboard-table-wrapper">

                            <table className="dashboard-table">

                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Họ và tên</th>
                                        <th>Email</th>
                                        <th>Vai trò</th>
                                        <th>Trạng thái</th>
                                    </tr>
                                </thead>

                                <tbody>

                                    {latestUsers.length > 0 ? (
                                        latestUsers.map((item, index) => (
                                            <tr key={item.id}>

                                                <td>
                                                    {index + 1}
                                                </td>

                                                <td>
                                                    <div className="user-table-name">
                                                        <span>
                                                            {item.fullName ||
                                                                "—"}
                                                        </span>
                                                    </div>
                                                </td>

                                                <td>
                                                    {item.email || "—"}
                                                </td>

                                                <td>
                                                    {roleLabel(item.role)}
                                                </td>

                                                <td>
                                                    <span className="table-status active">
                                                        {item.isActive
                                                            ? "Hoạt động"
                                                            : "Đã khóa"}
                                                    </span>
                                                </td>

                                            </tr>
                                        ))
                                    ) : (
                                        <tr>
                                            <td
                                                colSpan="5"
                                                style={{
                                                    textAlign: "center"
                                                }}
                                            >
                                                Chưa có người dùng.
                                            </td>
                                        </tr>
                                    )}

                                </tbody>

                            </table>

                        </div>
                    </div>
                )}


                {/* =========================
                    CONSULTATION REQUESTS
                ========================= */}
                <div className="dashboard-panel dashboard-table-panel">

                    <div className="dashboard-panel__header">
                        <div className="dashboard-panel__title">
                            <FontAwesomeIcon icon={faFileLines} />

                            <h2>
                                {isLawyer
                                    ? "Yêu cầu tư vấn được phân công"
                                    : "Yêu cầu tư vấn mới"}
                            </h2>
                        </div>
                    </div>

                    <div className="dashboard-table-wrapper">

                        <table className="dashboard-table request-table">

                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Tiêu đề</th>
                                    <th>Lĩnh vực</th>
                                    <th>Ngày gửi</th>
                                    <th>Trạng thái</th>
                                </tr>
                            </thead>

                            <tbody>

                                {latestRequests.length > 0 ? (
                                    latestRequests.map(
                                        (item, index) => (
                                            <tr key={item.id}>

                                                <td>
                                                    {index + 1}
                                                </td>

                                                <td>
                                                    {item.title || "—"}
                                                </td>

                                                <td>
                                                    {item.practiceAreaName ||
                                                        "—"}
                                                </td>

                                                <td>
                                                    {formatDate(
                                                        item.createdAt
                                                    )}
                                                </td>

                                                <td>
                                                    <span
                                                        className={`request-status ${
                                                            item.status || ""
                                                        }`}
                                                    >
                                                        {statusLabel(
                                                            item.status
                                                        )}
                                                    </span>
                                                </td>

                                            </tr>
                                        )
                                    )
                                ) : (
                                    <tr>
                                        <td
                                            colSpan="5"
                                            style={{
                                                textAlign: "center"
                                            }}
                                        >
                                            Chưa có yêu cầu tư vấn.
                                        </td>
                                    </tr>
                                )}

                            </tbody>

                        </table>

                    </div>
                </div>


                {/* =========================
                    SYSTEM INFORMATION
                ========================= */}
                <div className="dashboard-panel dashboard-activity-panel">

                    <div className="dashboard-panel__header">
                        <div className="dashboard-panel__title">
                            <FontAwesomeIcon icon={faArrowTrendUp} />

                            <h2>
                                {isLawyer
                                    ? "Thông tin công việc"
                                    : "Thông tin hệ thống"}
                            </h2>
                        </div>
                    </div>

                    <div className="activity-list">

                        {isLawyer ? (
                            <>
                                <div className="activity-item">

                                    <div className="activity-icon user">
                                        <FontAwesomeIcon icon={faCalendarCheck} />
                                    </div>

                                    <div className="activity-content">
                                        <p>
                                            {formatNumber(
                                                displayStats.totalAppointments
                                            )}{" "}
                                            lịch tư vấn
                                        </p>

                                        <span>
                                            Tổng số lịch được phân công
                                        </span>
                                    </div>

                                </div>

                                <div className="activity-item">

                                    <div className="activity-icon chat">
                                        <FontAwesomeIcon icon={faClock} />
                                    </div>

                                    <div className="activity-content">
                                        <p>
                                            {formatNumber(
                                                displayStats.pendingAppointments
                                            )}{" "}
                                            lịch đang chờ
                                        </p>

                                        <span>
                                            Cần xử lý
                                        </span>
                                    </div>

                                </div>

                                <div className="activity-item">

                                    <div className="activity-icon register">
                                        <FontAwesomeIcon icon={faBriefcase} />
                                    </div>

                                    <div className="activity-content">
                                        <p>
                                            {formatNumber(
                                                displayStats.totalCases
                                            )}{" "}
                                            hồ sơ vụ án
                                        </p>

                                        <span>
                                            Hồ sơ đang quản lý
                                        </span>
                                    </div>

                                </div>
                            </>
                        ) : (
                            <>
                                <div className="activity-item">

                                    <div className="activity-icon user">
                                        <FontAwesomeIcon icon={faUsers} />
                                    </div>

                                    <div className="activity-content">
                                        <p>
                                            {formatNumber(
                                                displayStats.totalClients
                                            )}{" "}
                                            khách hàng đang có hồ sơ
                                        </p>

                                        <span>
                                            Dữ liệu hiện tại
                                        </span>
                                    </div>

                                </div>

                                <div className="activity-item">

                                    <div className="activity-icon chat">
                                        <FontAwesomeIcon icon={faCalendarCheck} />
                                    </div>

                                    <div className="activity-content">
                                        <p>
                                            {formatNumber(
                                                displayStats.totalRequests
                                            )}{" "}
                                            yêu cầu tư vấn
                                        </p>

                                        <span>
                                            Dữ liệu hiện tại
                                        </span>
                                    </div>

                                </div>

                                <div className="activity-item">

                                    <div className="activity-icon register">
                                        <FontAwesomeIcon icon={faFileLines} />
                                    </div>

                                    <div className="activity-content">
                                        <p>
                                            {formatNumber(
                                                displayStats.totalCases
                                            )}{" "}
                                            hồ sơ vụ án
                                        </p>

                                        <span>
                                            Dữ liệu hiện tại
                                        </span>
                                    </div>

                                </div>
                            </>
                        )}

                    </div>
                </div>

            </section>

        </div>
    );
}