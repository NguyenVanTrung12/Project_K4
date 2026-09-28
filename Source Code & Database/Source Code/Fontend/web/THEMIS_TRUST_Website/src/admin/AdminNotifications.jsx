import { useEffect, useMemo, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faMagnifyingGlass,
  faChevronDown,
  faCalendarDays,
  faFilter,
  faChevronRight,
  faChevronLeft,
  faUser,
  faGear,
  faFileLines,
  faCalendarCheck,
  faCreditCard,
  faBell,
  faCheck,
  faTriangleExclamation,
  faRotate,
} from "@fortawesome/free-solid-svg-icons";

import "../assets/css/admin/AdminNotifications.css";

import {
  api,
  getCurrentUser,
} from "../api/api";

/* =========================================================
   HELPER
========================================================= */

const normalizeString = (value) => {
  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  return String(value);
};


/* =========================================================
   ROLE
========================================================= */

const getRole = (user) => {
  if (!user) {
    return "";
  }

  return normalizeString(
    user?.role ??
      user?.Role ??
      user?.roleName ??
      user?.RoleName ??
      user?.userRole ??
      user?.UserRole
  )
    .trim()
    .toLowerCase();
};


/* =========================================================
   ID THÔNG BÁO
========================================================= */

const getNotificationId = (
  notification
) => {
  return (
    notification?.id ??
    notification?.Id ??
    notification?.notificationId ??
    notification?.NotificationId
  );
};


/* =========================================================
   USER ID
========================================================= */

const getUserId = (user) => {
  return (
    user?.id ??
    user?.Id ??
    user?.userId ??
    user?.UserId
  );
};


/* =========================================================
   LẤY USER ID CỦA THÔNG BÁO
========================================================= */

const getNotificationUserId = (
  notification
) => {
  return (
    notification?.userId ??
    notification?.UserId ??
    notification?.receiverId ??
    notification?.ReceiverId ??
    notification?.recipientId ??
    notification?.RecipientId ??
    notification?.targetUserId ??
    notification?.TargetUserId
  );
};


/* =========================================================
   LẤY TÊN LAWYER TỪ THÔNG BÁO
========================================================= */

const getNotificationLawyerName = (
  notification
) => {
  return normalizeString(
    notification?.lawyerName ??
      notification?.LawyerName ??
      notification?.receiverName ??
      notification?.ReceiverName ??
      notification?.recipientName ??
      notification?.RecipientName ??
      notification?.userName ??
      notification?.UserName ??
      notification?.fullName ??
      notification?.FullName ??
      notification?.user?.fullName ??
      notification?.user?.FullName ??
      notification?.lawyer?.fullName ??
      notification?.lawyer?.FullName ??
      ""
  ).trim();
};


/* =========================================================
   XÁC ĐỊNH LOẠI THÔNG BÁO
========================================================= */

const getNotificationType = (
  notification
) => {

  const rawType =
    notification?.type ??
    notification?.Type ??
    notification?.notificationType ??
    notification?.NotificationType ??
    notification?.category ??
    notification?.Category ??
    "";

  const type =
    normalizeString(
      rawType
    )
      .trim()
      .toLowerCase();


  const title =
    normalizeString(
      notification?.title ??
        notification?.Title ??
        notification?.message ??
        notification?.Message ??
        notification?.content ??
        notification?.Content ??
        ""
    ).toLowerCase();


  if (
    type.includes("consultation") ||
    type.includes("tư vấn") ||
    title.includes("yêu cầu tư vấn")
  ) {
    return {
      type: "Yêu cầu tư vấn",
      typeClass: "consultation",
      icon: faFileLines,
    };
  }


  if (
    type.includes("reply") ||
    type.includes("response") ||
    type.includes("phản hồi")
  ) {
    return {
      type: "Phản hồi tư vấn",
      typeClass: "reply",
      icon: faFileLines,
    };
  }


  if (
    type.includes("appointment") ||
    type.includes("booking") ||
    type.includes("lịch")
  ) {
    return {
      type: "Lịch tư vấn",
      typeClass: "booking",
      icon: faCalendarCheck,
    };
  }


  if (
    type.includes("profile") ||
    type.includes("hồ sơ")
  ) {
    return {
      type: "Cập nhật hồ sơ",
      typeClass: "profile",
      icon: faUser,
    };
  }


  if (
    type.includes("payment") ||
    type.includes("thanh toán")
  ) {
    return {
      type: "Thanh toán",
      typeClass: "payment",
      icon: faCreditCard,
    };
  }


  if (
    type.includes("system") ||
    type.includes("hệ thống")
  ) {
    return {
      type: "Hệ thống",
      typeClass: "system",
      icon: faGear,
    };
  }


  return {
    type:
      rawType
        ? normalizeString(rawType)
        : "Hệ thống",

    typeClass: "system",

    icon: faBell,
  };
};


/* =========================================================
   NGƯỜI GỬI
========================================================= */

const getSenderName = (
  notification
) => {

  return normalizeString(
    notification?.senderName ??
      notification?.SenderName ??
      notification?.sender?.fullName ??
      notification?.sender?.FullName ??
      notification?.createdByName ??
      notification?.CreatedByName ??
      notification?.fullName ??
      notification?.FullName ??
      "Hệ thống"
  );
};


/* =========================================================
   LOẠI NGƯỜI GỬI
========================================================= */

const getSenderType = (
  notification
) => {

  const role =
    normalizeString(
      notification?.senderRole ??
        notification?.SenderRole ??
        notification?.role ??
        notification?.Role ??
        ""
    ).toLowerCase();


  if (
    role.includes("lawyer")
  ) {
    return "Luật sư";
  }


  if (
    role.includes("client")
  ) {
    return "Khách hàng";
  }


  if (
    role.includes("admin")
  ) {
    return "Quản trị viên";
  }


  if (
    role.includes("staff")
  ) {
    return "Nhân viên";
  }


  if (
    getSenderName(
      notification
    ) === "Hệ thống"
  ) {
    return "System";
  }


  return "Người dùng";
};


/* =========================================================
   AVATAR
========================================================= */

const getAvatarText = (
  name
) => {

  if (!name) {
    return "";
  }


  if (
    name === "Hệ thống"
  ) {
    return "";
  }


  const words =
    name
      .trim()
      .split(/\s+/)
      .filter(Boolean);


  if (
    words.length === 1
  ) {
    return words[0]
      .substring(0, 2)
      .toUpperCase();
  }


  return (
    words[0][0] +
    words[words.length - 1][0]
  ).toUpperCase();
};


/* =========================================================
   NGÀY
========================================================= */

const getNotificationDateValue = (
  notification
) => {

  return (
    notification?.createdAt ??
    notification?.CreatedAt ??
    notification?.date ??
    notification?.Date ??
    notification?.timestamp ??
    notification?.Timestamp ??
    null
  );
};


/* =========================================================
   FORMAT DATE
========================================================= */

const formatDate = (
  value
) => {

  if (!value) {
    return "--";
  }


  const date =
    new Date(value);


  if (
    Number.isNaN(
      date.getTime()
    )
  ) {
    return normalizeString(
      value
    );
  }


  return date.toLocaleDateString(
    "vi-VN"
  );
};


/* =========================================================
   FORMAT TIME
========================================================= */

const formatTime = (
  value
) => {

  if (!value) {
    return "--:--";
  }


  const date =
    new Date(value);


  if (
    Number.isNaN(
      date.getTime()
    )
  ) {
    return "";
  }


  return date.toLocaleTimeString(
    "vi-VN",
    {
      hour: "2-digit",
      minute: "2-digit",
    }
  );
};


/* =========================================================
   DESCRIPTION
========================================================= */

const getDescription = (
  notification
) => {

  return normalizeString(
    notification?.description ??
      notification?.Description ??
      notification?.body ??
      notification?.Body ??
      notification?.content ??
      notification?.Content ??
      notification?.message ??
      notification?.Message ??
      notification?.title ??
      notification?.Title ??
      ""
  );
};


/* =========================================================
   TITLE
========================================================= */

const getTitle = (
  notification
) => {

  return normalizeString(
    notification?.title ??
      notification?.Title ??
      notification?.subject ??
      notification?.Subject ??
      notification?.message ??
      notification?.Message ??
      "Thông báo"
  );
};


/* =========================================================
   READ
========================================================= */

const isNotificationRead = (
  notification
) => {

  const value =
    notification?.isRead ??
    notification?.IsRead ??
    notification?.read ??
    notification?.Read;


  if (
    value === true ||
    value === 1 ||
    value === "1" ||
    value === "true"
  ) {
    return true;
  }


  const status =
    normalizeString(
      notification?.status ??
        notification?.Status ??
        ""
    ).toLowerCase();


  return (
    status === "read" ||
    status === "đã đọc" ||
    status === "da doc"
  );
};


/* =========================================================
   MAP NOTIFICATION
========================================================= */

const mapNotification = (
  notification,
  index
) => {

  const notificationType =
    getNotificationType(
      notification
    );


  const sender =
    getSenderName(
      notification
    );


  const read =
    isNotificationRead(
      notification
    );


  const dateValue =
    getNotificationDateValue(
      notification
    );


  const notificationUserId =
    getNotificationUserId(
      notification
    );


  return {

    ...notification,

    id:
      getNotificationId(
        notification
      ) ??
      index + 1,

    userId:
      notificationUserId,

    lawyerName:
      getNotificationLawyerName(
        notification
      ),

    title:
      getTitle(
        notification
      ),

    description:
      getDescription(
        notification
      ),

    sender,

    senderType:
      getSenderType(
        notification
      ),

    avatarText:
      getAvatarText(
        sender
      ),

    type:
      notificationType.type,

    typeClass:
      notificationType.typeClass,

    date:
      formatDate(
        dateValue
      ),

    time:
      formatTime(
        dateValue
      ),

    dateValue,

    status:
      read
        ? "Đã đọc"
        : "Chưa đọc",

    statusClass:
      read
        ? "read"
        : "unread",

    icon:
      notificationType.icon,

    isSystem:
      sender === "Hệ thống",
  };
};


/* =========================================================
   EXTRACT ARRAY
========================================================= */

const extractArray = (
  response
) => {

  if (
    Array.isArray(response)
  ) {
    return response;
  }


  if (
    Array.isArray(
      response?.data
    )
  ) {
    return response.data;
  }


  if (
    Array.isArray(
      response?.items
    )
  ) {
    return response.items;
  }


  if (
    Array.isArray(
      response?.Items
    )
  ) {
    return response.Items;
  }


  if (
    Array.isArray(
      response?.notifications
    )
  ) {
    return response.notifications;
  }


  if (
    Array.isArray(
      response?.Notifications
    )
  ) {
    return response.Notifications;
  }


  return [];
};


/* =========================================================
   EXTRACT LAWYERS
========================================================= */

const extractLawyers = (
  response
) => {

  const data =
    extractArray(
      response
    );


  return data
    .map((item) => {

      const id =
        getUserId(
          item
        );


      const name =
        normalizeString(
          item?.fullName ??
            item?.FullName ??
            item?.name ??
            item?.Name ??
            item?.userName ??
            item?.UserName ??
            item?.email ??
            item?.Email ??
            ""
        ).trim();


      const role =
        getRole(
          item
        );


      return {
        id,
        name,
        role,
      };

    })
    .filter(
      (item) =>
        item.id &&
        item.name &&
        (
          item.role ===
            "lawyer" ||
          !item.role
        )
    );
};


/* =========================================================
   COMPONENT
========================================================= */

const AdminNotifications = () => {

  /* =======================================================
     CURRENT USER
  ======================================================= */

  const currentUser =
    getCurrentUser();


  const currentRole =
    getRole(
      currentUser
    );


  const isAdmin =
    currentRole === "admin";


  const isLawyer =
    currentRole === "lawyer";


  /* =======================================================
     NOTIFICATIONS
  ======================================================= */

  const [
    notifications,
    setNotifications,
  ] = useState([]);


  /* =======================================================
     LAWYERS
  ======================================================= */

  const [
    lawyers,
    setLawyers,
  ] = useState([]);


  /* =======================================================
     LOADING
  ======================================================= */

  const [
    loading,
    setLoading,
  ] = useState(true);


  const [
    loadingLawyers,
    setLoadingLawyers,
  ] = useState(false);


  /* =======================================================
     ERROR
  ======================================================= */

  const [
    error,
    setError,
  ] = useState("");


  /* =======================================================
     FILTER
  ======================================================= */

  const [
    searchValue,
    setSearchValue,
  ] = useState("");


  const [
    lawyerFilter,
    setLawyerFilter,
  ] = useState("all");


  const [
    typeFilter,
    setTypeFilter,
  ] = useState(
    "Tất cả loại thông báo"
  );


  const [
    statusFilter,
    setStatusFilter,
  ] = useState(
    "Tất cả trạng thái"
  );


  const [
    selectedTime,
    setSelectedTime,
  ] = useState("");


  const [
    selectedRows,
    setSelectedRows,
  ] = useState([]);


  /* =======================================================
     LOAD NOTIFICATIONS
     
     Admin:
       GET /notifications
       -> backend trả tất cả

     Lawyer:
       GET /notifications
       -> backend trả notification của lawyer hiện tại
  ======================================================= */

  const loadNotifications =
    async () => {

      try {

        setLoading(true);

        setError("");


        const response =
          await api.get(
            "/notifications"
          );


        console.log(
          "NOTIFICATIONS API:",
          response
        );


        const data =
          extractArray(
            response
          );


        const mappedData =
          data.map(
            (
              notification,
              index
            ) =>
              mapNotification(
                notification,
                index
              )
          );


        setNotifications(
          mappedData
        );


        setSelectedRows([]);


      } catch (err) {

        console.error(
          "LOAD NOTIFICATIONS ERROR:",
          err
        );


        setNotifications([]);


        setError(
          err?.response?.data?.message ||
          err?.response?.data ||
          err?.message ||
          "Không thể tải danh sách thông báo."
        );


      } finally {

        setLoading(false);

      }
    };


  /* =======================================================
     LOAD LAWYERS
     
     CHỈ ADMIN
  ======================================================= */

  const loadLawyers =
    async () => {

      if (!isAdmin) {
        return;
      }


      try {

        setLoadingLawyers(
          true
        );


        const response =
          await api.get(
            "/users"
          );


        console.log(
          "USERS API:",
          response
        );


        const lawyerList =
          extractLawyers(
            response
          );


        setLawyers(
          lawyerList
        );


      } catch (err) {

        console.error(
          "LOAD LAWYERS ERROR:",
          err
        );


        /*
          Không chặn trang thông báo
          nếu API users lỗi.
        */

        setLawyers([]);

      } finally {

        setLoadingLawyers(
          false
        );

      }
    };


  /* =======================================================
     LOAD
  ======================================================= */

  useEffect(() => {

    loadNotifications();

    if (isAdmin) {
      loadLawyers();
    }

  }, [isAdmin]);


  /* =======================================================
     FILTER DATA
  ======================================================= */

  const filteredNotifications =
    useMemo(() => {

      const keyword =
        searchValue
          .toLowerCase()
          .trim();


      return notifications.filter(
        (notification) => {

          /* -----------------------------------------------
             SEARCH
          ----------------------------------------------- */

          const matchesSearch =
            !keyword ||
            normalizeString(
              notification.title
            )
              .toLowerCase()
              .includes(keyword) ||

            normalizeString(
              notification.sender
            )
              .toLowerCase()
              .includes(keyword) ||

            normalizeString(
              notification.description
            )
              .toLowerCase()
              .includes(keyword) ||

            normalizeString(
              notification.lawyerName
            )
              .toLowerCase()
              .includes(keyword);


          /* -----------------------------------------------
             LAWYER
          ----------------------------------------------- */

          let matchesLawyer =
            true;


          if (
            isAdmin &&
            lawyerFilter !== "all"
          ) {

            const notificationUserId =
              normalizeString(
                notification.userId
              );


            matchesLawyer =
              notificationUserId ===
                normalizeString(
                  lawyerFilter
                ) ||

              normalizeString(
                notification.lawyerName
              )
                .toLowerCase() ===
                normalizeString(
                  lawyers.find(
                    (lawyer) =>
                      normalizeString(
                        lawyer.id
                      ) ===
                      normalizeString(
                        lawyerFilter
                      )
                  )?.name
                )
                  .toLowerCase();

          }


          /* -----------------------------------------------
             TYPE
          ----------------------------------------------- */

          const matchesType =
            typeFilter ===
              "Tất cả loại thông báo" ||
            notification.type ===
              typeFilter;


          /* -----------------------------------------------
             STATUS
          ----------------------------------------------- */

          const matchesStatus =
            statusFilter ===
              "Tất cả trạng thái" ||
            notification.status ===
              statusFilter;


          /* -----------------------------------------------
             DATE
          ----------------------------------------------- */

          let matchesDate = true;


          if (selectedTime) {

            if (
              !notification.dateValue
            ) {

              matchesDate = false;

            } else {

              const date =
                new Date(
                  notification.dateValue
                );


              if (
                Number.isNaN(
                  date.getTime()
                )
              ) {

                matchesDate = false;

              } else {

                const year =
                  date
                    .getFullYear()
                    .toString()
                    .padStart(
                      4,
                      "0"
                    );


                const month =
                  String(
                    date.getMonth() + 1
                  ).padStart(
                    2,
                    "0"
                  );


                const day =
                  String(
                    date.getDate()
                  ).padStart(
                    2,
                    "0"
                  );


                const localDate =
                  `${year}-${month}-${day}`;


                matchesDate =
                  localDate ===
                  selectedTime;

              }
            }
          }


          return (
            matchesSearch &&
            matchesLawyer &&
            matchesType &&
            matchesStatus &&
            matchesDate
          );
        }
      );

    }, [
      notifications,
      searchValue,
      lawyerFilter,
      typeFilter,
      statusFilter,
      selectedTime,
      lawyers,
      isAdmin,
    ]);


  /* =======================================================
     SELECT ALL
  ======================================================= */

  const handleSelectAll = (
    event
  ) => {

    if (
      event.target.checked
    ) {

      setSelectedRows(
        filteredNotifications.map(
          (notification) =>
            notification.id
        )
      );

    } else {

      setSelectedRows([]);
    }
  };


  /* =======================================================
     SELECT ROW
  ======================================================= */

  const handleSelectRow = (
    id
  ) => {

    setSelectedRows(
      (prev) => {

        if (
          prev.includes(id)
        ) {

          return prev.filter(
            (item) =>
              item !== id
          );
        }


        return [
          ...prev,
          id,
        ];
      }
    );
  };


  /* =======================================================
     VIEW
  ======================================================= */

  const handleViewNotification = (
    notification
  ) => {

    console.log(
      "XEM THÔNG BÁO:",
      notification
    );

  };


  /* =======================================================
     FILTER
  ======================================================= */

  const handleFilter = () => {

    console.log(
      "BỘ LỌC THÔNG BÁO:",
      {
        searchValue,
        lawyerFilter,
        typeFilter,
        statusFilter,
        selectedTime,
      }
    );

  };


  /* =======================================================
     CLEAR FILTER
  ======================================================= */

  const handleClearFilter = () => {

    setSearchValue("");

    setLawyerFilter(
      "all"
    );

    setTypeFilter(
      "Tất cả loại thông báo"
    );

    setStatusFilter(
      "Tất cả trạng thái"
    );

    setSelectedTime("");

  };


  /* =======================================================
     LOADING
  ======================================================= */

  if (loading) {

    return (

      <section
        className="admin-notification-page"
      >

        <div
          className="admin-notification-empty"
        >

          <FontAwesomeIcon
            icon={faBell}
          />

          <p>
            Đang tải danh sách thông báo...
          </p>

        </div>

      </section>
    );
  }


  /* =======================================================
     RENDER
  ======================================================= */

  return (

    <section
      className="admin-notification-page"
    >

      {/* ===================================================
          FILTER BAR
      =================================================== */}

      <div
        className="admin-notification-filter-bar"
      >

        {/* SEARCH */}

        <div
          className="admin-notification-search"
        >

          <FontAwesomeIcon
            icon={
              faMagnifyingGlass
            }
          />

          <input
            type="text"
            placeholder="Tìm kiếm theo nội dung, người gửi..."
            value={
              searchValue
            }
            onChange={(
              event
            ) =>
              setSearchValue(
                event.target.value
              )
            }
          />

        </div>


        {/* =================================================
            LAWYER FILTER
            CHỈ ADMIN
        ================================================= */}

        {isAdmin && (

          <div
            className="admin-notification-select"
          >

            <select
              value={
                lawyerFilter
              }
              onChange={(
                event
              ) =>
                setLawyerFilter(
                  event.target.value
                )
              }
            >

              <option value="all">
                Tất cả luật sư
              </option>


              {lawyers.map(
                (lawyer) => (

                  <option
                    key={
                      lawyer.id
                    }
                    value={
                      lawyer.id
                    }
                  >

                    {lawyer.name}

                  </option>

                )
              )}

            </select>


            <FontAwesomeIcon
              icon={
                faChevronDown
              }
            />

          </div>

        )}


        {/* =================================================
            TYPE
        ================================================= */}

        <div
          className="admin-notification-select"
        >

          <select
            value={
              typeFilter
            }
            onChange={(
              event
            ) =>
              setTypeFilter(
                event.target.value
              )
            }
          >

            <option>
              Tất cả loại thông báo
            </option>

            <option>
              Yêu cầu tư vấn
            </option>

            <option>
              Phản hồi tư vấn
            </option>

            <option>
              Lịch tư vấn
            </option>

            <option>
              Cập nhật hồ sơ
            </option>

            <option>
              Thanh toán
            </option>

            <option>
              Hệ thống
            </option>

          </select>


          <FontAwesomeIcon
            icon={
              faChevronDown
            }
          />

        </div>


        {/* =================================================
            STATUS
        ================================================= */}

        <div
          className="admin-notification-select"
        >

          <select
            value={
              statusFilter
            }
            onChange={(
              event
            ) =>
              setStatusFilter(
                event.target.value
              )
            }
          >

            <option>
              Tất cả trạng thái
            </option>

            <option>
              Chưa đọc
            </option>

            <option>
              Đã đọc
            </option>

          </select>


          <FontAwesomeIcon
            icon={
              faChevronDown
            }
          />

        </div>


        {/* =================================================
            DATE
        ================================================= */}

        <div
          className="admin-notification-date"
        >

          <FontAwesomeIcon
            icon={
              faCalendarDays
            }
          />

          <input
            type="date"
            value={
              selectedTime
            }
            onChange={(
              event
            ) =>
              setSelectedTime(
                event.target.value
              )
            }
          />

        </div>


        {/* =================================================
            FILTER BUTTON
        ================================================= */}

        <button
          type="button"
          className="admin-notification-filter-button"
          onClick={
            handleFilter
          }
        >

          <FontAwesomeIcon
            icon={
              faFilter
            }
          />

          <span>
            Lọc
          </span>

        </button>


        {/* =================================================
            CLEAR
        ================================================= */}

        <button
          type="button"
          onClick={
            handleClearFilter
          }
          title="Xóa bộ lọc"
          style={{
            border: "none",
            background:
              "transparent",
            cursor:
              "pointer",
            padding:
              "8px",
          }}
        >

          <FontAwesomeIcon
            icon={
              faRotate
            }
          />

        </button>

      </div>


      {/* ===================================================
          ERROR
      =================================================== */}

      {error && (

        <div
          style={{
            marginBottom:
              "16px",
            padding:
              "14px 16px",
            borderRadius:
              "8px",
            background:
              "#fff1f2",
            color:
              "#b91c1c",
            display:
              "flex",
            alignItems:
              "center",
            gap:
              "10px",
          }}
        >

          <FontAwesomeIcon
            icon={
              faTriangleExclamation
            }
          />

          <span>
            {error}
          </span>


          <button
            type="button"
            onClick={
              loadNotifications
            }
            style={{
              marginLeft:
                "auto",
              border:
                "none",
              background:
                "transparent",
              cursor:
                "pointer",
              fontWeight:
                600,
            }}
          >
            Thử lại
          </button>

        </div>

      )}


      {/* ===================================================
          TABLE
      =================================================== */}

      <div
        className="admin-notification-table-card"
      >

        <div
          className="admin-notification-table-wrapper"
        >

          <table
            className="admin-notification-table"
          >

            <thead>

              <tr>

                <th
                  className="admin-notification-checkbox-column"
                >

                  <input
                    type="checkbox"
                    checked={
                      filteredNotifications.length >
                        0 &&
                      selectedRows.length ===
                        filteredNotifications.length
                    }
                    onChange={
                      handleSelectAll
                    }
                  />

                </th>


                <th
                  className="admin-notification-number"
                >
                  #
                </th>


                <th>
                  Tiêu đề
                </th>


                <th>
                  Người gửi
                </th>


                {/* =================================================
                    LAWYER COLUMN
                ================================================= */}

                {isAdmin && (

                  <th>
                    Luật sư
                  </th>

                )}


                <th>
                  Loại thông báo
                </th>


                <th>
                  Thời gian
                </th>


                <th>
                  Trạng thái
                </th>


                <th
                  className="admin-notification-action-column"
                >

                  <span
                    className="admin-notification-header-arrow"
                  >

                    <FontAwesomeIcon
                      icon={
                        faChevronDown
                      }
                    />

                  </span>

                </th>

              </tr>

            </thead>


            <tbody>

              {filteredNotifications.map(
                (
                  notification,
                  index
                ) => (

                  <tr
                    key={
                      notification.id
                    }
                    className={
                      notification.status ===
                      "Chưa đọc"
                        ? "admin-notification-unread-row"
                        : ""
                    }
                  >

                    {/* CHECKBOX */}

                    <td>

                      <input
                        type="checkbox"
                        checked={
                          selectedRows.includes(
                            notification.id
                          )
                        }
                        onChange={() =>
                          handleSelectRow(
                            notification.id
                          )
                        }
                      />

                    </td>


                    {/* NUMBER */}

                    <td
                      className="admin-notification-number"
                    >

                      {index + 1}

                    </td>


                    {/* TITLE */}

                    <td>

                      <div
                        className="admin-notification-title-cell"
                      >

                        {notification.status ===
                          "Chưa đọc" && (

                          <span
                            className="admin-notification-unread-dot"
                          />

                        )}


                        <div>

                          <strong>
                            {
                              notification.title
                            }
                          </strong>

                          <p>
                            {
                              notification.description
                            }
                          </p>

                        </div>

                      </div>

                    </td>


                    {/* SENDER */}

                    <td>

                      <div
                        className="admin-notification-sender"
                      >

                        <div
                          className={
                            notification.isSystem
                              ? "admin-notification-avatar admin-notification-avatar-system"
                              : "admin-notification-avatar"
                          }
                        >

                          {notification.isSystem ? (

                            <FontAwesomeIcon
                              icon={
                                faGear
                              }
                            />

                          ) : (

                            notification.avatarText

                          )}

                        </div>


                        <div>

                          <strong>
                            {
                              notification.sender
                            }
                          </strong>

                          <span>
                            {
                              notification.senderType
                            }
                          </span>

                        </div>

                      </div>

                    </td>


                    {/* =================================================
                        LAWYER
                    ================================================= */}

                    {isAdmin && (

                      <td>

                        <div
                          style={{
                            display:
                              "flex",
                            alignItems:
                              "center",
                            gap:
                              "8px",
                          }}
                        >

                          <FontAwesomeIcon
                            icon={
                              faUser
                            }
                          />

                          <span>

                            {
                              notification.lawyerName ||
                              lawyers.find(
                                (
                                  lawyer
                                ) =>
                                  normalizeString(
                                    lawyer.id
                                  ) ===
                                  normalizeString(
                                    notification.userId
                                  )
                              )?.name ||
                              "Không xác định"
                            }

                          </span>

                        </div>

                      </td>

                    )}


                    {/* TYPE */}

                    <td>

                      <span
                        className={
                          `admin-notification-type ` +
                          `admin-notification-type-${notification.typeClass}`
                        }
                      >

                        {
                          notification.type
                        }

                      </span>

                    </td>


                    {/* DATE */}

                    <td>

                      <div
                        className="admin-notification-time"
                      >

                        <strong>
                          {
                            notification.date
                          }
                        </strong>

                        <span>
                          {
                            notification.time
                          }
                        </span>

                      </div>

                    </td>


                    {/* STATUS */}

                    <td>

                      <span
                        className={
                          `admin-notification-status ` +
                          `admin-notification-status-${notification.statusClass}`
                        }
                      >

                        {notification.status ===
                          "Đã đọc" && (

                          <FontAwesomeIcon
                            icon={
                              faCheck
                            }
                          />

                        )}

                        {
                          notification.status
                        }

                      </span>

                    </td>


                    {/* ACTION */}

                    <td>

                      <button
                        type="button"
                        className="admin-notification-view-button"
                        onClick={() =>
                          handleViewNotification(
                            notification
                          )
                        }
                        aria-label="Xem thông báo"
                      >

                        <FontAwesomeIcon
                          icon={
                            faChevronRight
                          }
                        />

                      </button>

                    </td>

                  </tr>

                )
              )}

            </tbody>

          </table>

        </div>


        {/* ===================================================
            EMPTY
        =================================================== */}

        {filteredNotifications.length ===
          0 && (

          <div
            className="admin-notification-empty"
          >

            <FontAwesomeIcon
              icon={
                faBell
              }
            />

            <p>

              {notifications.length ===
              0
                ? "Chưa có thông báo."
                : "Không tìm thấy thông báo phù hợp."
              }

            </p>

          </div>

        )}


        {/* ===================================================
            FOOTER
        =================================================== */}

        <div
          className="admin-notification-table-footer"
        >

          <div
            className="admin-notification-result"
          >

            Hiển thị{" "}

            <strong>
              {
                filteredNotifications.length
              }
            </strong>

            {" "}trên tổng số{" "}

            <strong>
              {
                notifications.length
              }
            </strong>

            {" "}thông báo

          </div>


          <div
            className="admin-notification-pagination"
          >

            <button
              type="button"
              className="admin-notification-page-button"
              disabled
            >

              <FontAwesomeIcon
                icon={
                  faChevronLeft
                }
              />

            </button>


            <button
              type="button"
              className="admin-notification-page-button active"
            >
              1
            </button>


            <button
              type="button"
              className="admin-notification-page-button"
              disabled
            >

              <FontAwesomeIcon
                icon={
                  faChevronRight
                }
              />

            </button>

          </div>

        </div>

      </div>

    </section>
  );
};


export default AdminNotifications;