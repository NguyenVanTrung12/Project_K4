import { useEffect, useMemo, useRef, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faComments,
  faPaperPlane,
  faMagnifyingGlass,
  faUser,
  faCircle,
  faArrowLeft,
} from "@fortawesome/free-solid-svg-icons";

import { api, getCurrentUser } from "../../api/api";

import "../../assets/css/admin/Chat.css";

/* =========================================================
   CẤU HÌNH
========================================================= */

// GET /api/appointments: backend tự lọc theo role,
// khách (client) chỉ nhận các lịch hẹn của chính mình.
const APPOINTMENTS_ENDPOINT = "/appointments";

// Lịch hẹn ở các trạng thái này KHÔNG được tính là "đã đặt lịch".
// (đã bỏ dấu + chữ thường, xem normalizeText bên dưới)
const INACTIVE_STATUSES = [
  "cancelled",
  "canceled",
  "rejected",
  "declined",
  "expired",
  "huy",
  "da huy",
  "tu choi",
  "da tu choi",
];

const AUTH_MESSAGE =
  "Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng xuất và đăng nhập lại.";

const NOT_BOOKED_MESSAGE =
  "Bạn cần đặt lịch với luật sư này trước khi nhắn tin.";

// Chu kỳ tự kiểm tra tin nhắn mới (ms)
const MESSAGE_POLL_MS = 3000; // cuộc trò chuyện đang mở
const CONVERSATION_POLL_MS = 5000; // danh sách bên trái

/* =========================================================
   HELPERS
========================================================= */

const API_ORIGIN = (
  import.meta.env.VITE_API_URL || "https://localhost:5001/api"
).replace(/\/api\/?$/, "");

// Backend trả "/uploads/avatars/abc.jpg" nên cần ghép địa chỉ backend
const toAvatarUrl = (url) => {
  if (!url) return "";

  const value = String(url).trim();

  if (/^(https?:|data:|blob:)/i.test(value)) {
    return value;
  }

  return value.startsWith("/")
    ? `${API_ORIGIN}${value}`
    : `${API_ORIGIN}/${value}`;
};

const toList = (data) =>
  Array.isArray(data) ? data : data?.items || data?.data || [];

// Bỏ dấu để gõ "bao" ra được "Bảo"
const normalizeText = (value) =>
  String(value || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d");

const getId = (item) =>
  item?.id || item?.Id || item?.userId || item?.UserId || null;

const getConversationLawyerId = (conversation) =>
  conversation?.lawyerId ||
  conversation?.LawyerId ||
  conversation?.lawyerUserId ||
  conversation?.LawyerUserId ||
  null;

const getLawyerName = (lawyer) =>
  lawyer?.fullName ||
  lawyer?.FullName ||
  lawyer?.name ||
  lawyer?.Name ||
  "Luật sư";

const getLawyerEmail = (lawyer) => lawyer?.email || lawyer?.Email || "";

const getLawyerTitle = (lawyer) => lawyer?.title || lawyer?.Title || "";

const getLawyerAvatar = (lawyer) =>
  toAvatarUrl(lawyer?.avatarUrl || lawyer?.AvatarUrl || "");

const getLastMessageAt = (conversation) =>
  conversation?.lastMessageAt || conversation?.LastMessageAt || null;

// Lấy id luật sư từ một lịch hẹn
const getAppointmentLawyerId = (appointment) =>
  appointment?.lawyerId ||
  appointment?.LawyerId ||
  appointment?.lawyerUserId ||
  appointment?.LawyerUserId ||
  appointment?.lawyer?.id ||
  appointment?.lawyer?.Id ||
  null;

// Lịch hẹn còn hiệu lực = chưa bị hủy / từ chối
const isActiveAppointment = (appointment) => {
  const status = normalizeText(appointment?.status ?? appointment?.Status ?? "");

  return !INACTIVE_STATUSES.includes(status);
};

// api.js ném Error("API 401") nên kiểm tra cả status lẫn message
const hasStatus = (err, code) =>
  err?.status === code ||
  err?.response?.status === code ||
  new RegExp(`\\b${code}\\b`).test(String(err?.message || ""));

// So sánh nhanh để không render lại khi dữ liệu không đổi
const conversationsSignature = (list) =>
  list
    .map(
      (item) =>
        `${getId(item)}:${getLastMessageAt(item) || ""}:${
          item?.lastMessagePreview || item?.LastMessagePreview || ""
        }`
    )
    .join("|");

const messagesSignature = (list) =>
  list
    .map((item) => `${item?.id || item?.Id}:${item?.isRead ?? item?.IsRead ?? ""}`)
    .join("|");

const formatTime = (date) => {
  if (!date) return "";

  const parsed = new Date(date);

  if (Number.isNaN(parsed.getTime())) return "";

  return parsed.toLocaleString("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
};

/* =========================================================
   ẢNH ĐẠI DIỆN
   Hiện icon nếu chưa có ảnh hoặc ảnh lỗi
========================================================= */

const ChatAvatar = ({ src, name }) => {
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setFailed(false);
  }, [src]);

  return (
    <div className="chat-avatar" style={{ overflow: "hidden" }}>
      {src && !failed ? (
        <img
          src={src}
          alt={name}
          onError={() => setFailed(true)}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
            borderRadius: "50%",
            display: "block",
          }}
        />
      ) : (
        <FontAwesomeIcon icon={faUser} />
      )}
    </div>
  );
};

/* =========================================================
   COMPONENT
========================================================= */

const ChatPage = () => {
  const user = useMemo(() => getCurrentUser(), []);

  const currentUserId = getId(user);

  /* =======================================================
     STATE
  ======================================================= */

  const [lawyers, setLawyers] = useState([]);
  const [appointments, setAppointments] = useState([]);
  const [conversations, setConversations] = useState([]);

  const [selectedLawyer, setSelectedLawyer] = useState(null);
  const [selectedConversation, setSelectedConversation] = useState(null);

  const [messages, setMessages] = useState([]);
  const [message, setMessage] = useState("");

  const [search, setSearch] = useState("");

  const [loading, setLoading] = useState(true);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [sending, setSending] = useState(false);
  const [creatingConversation, setCreatingConversation] = useState(false);

  const [error, setError] = useState("");

  // Ref cho polling / cuộn tin nhắn
  const authFailedRef = useRef(false); // 401 -> dừng polling
  const activeConversationRef = useRef(null);
  const messagesSeqRef = useRef(0);
  const fetchingMessagesRef = useRef(false);
  const messagesBoxRef = useRef(null);
  const stickToBottomRef = useRef(true);

  /* =======================================================
     BÁO LỖI THỐNG NHẤT
     401 -> hiện banner (không alert liên tục)
     403 -> chưa đặt lịch / không có quyền
  ======================================================= */

  const notifyError = (err, fallback) => {
    if (hasStatus(err, 401)) {
      authFailedRef.current = true;
      setError(AUTH_MESSAGE);
      return;
    }

    if (hasStatus(err, 403)) {
      alert(NOT_BOOKED_MESSAGE);
      return;
    }

    alert(err?.message || fallback);
  };

  /* =======================================================
     LOAD LAWYERS
     GET /api/lawyers  (chỉ lấy luật sư đang hoạt động)
  ======================================================= */

  const loadLawyers = async () => {
    const data = await api.get("/lawyers");

    const list = toList(data).filter(
      (lawyer) => (lawyer?.isAvailable ?? lawyer?.IsAvailable ?? true) !== false
    );

    setLawyers(list);
  };

  /* =======================================================
     LOAD APPOINTMENTS
     Lịch hẹn của khách đang đăng nhập -> quyết định được
     nhắn tin với luật sư nào.
  ======================================================= */

  const loadAppointments = async () => {
    try {
      const data = await api.get(APPOINTMENTS_ENDPOINT);

      setAppointments(toList(data));
    } catch (err) {
      console.error("Không thể tải danh sách lịch hẹn:", err);

      setAppointments([]);

      setError(
        hasStatus(err, 401)
          ? AUTH_MESSAGE
          : "Không thể tải danh sách lịch hẹn của bạn."
      );
    }
  };

  /* =======================================================
     LOAD CONVERSATIONS
     GET /api/messages/conversations
     Các cuộc trò chuyện của khách đang đăng nhập
  ======================================================= */

  const loadConversations = async () => {
    try {
      const data = await api.get("/messages/conversations");

      const list = toList(data);

      setConversations(list);

      return list;
    } catch (err) {
      console.error("Không thể tải danh sách hội thoại:", err);

      setConversations([]);

      if (hasStatus(err, 401)) {
        authFailedRef.current = true;
        setError(AUTH_MESSAGE);
      }

      return [];
    }
  };

  const loadData = async () => {
    try {
      setLoading(true);
      setError("");
      authFailedRef.current = false;

      await Promise.all([
        loadLawyers(),
        loadAppointments(),
        loadConversations(),
      ]);
    } catch (err) {
      console.error("Lỗi tải dữ liệu chat:", err);

      setError(
        hasStatus(err, 401)
          ? AUTH_MESSAGE
          : err?.message || "Không thể tải danh sách luật sư."
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  /* =======================================================
     LUẬT SƯ ĐÃ ĐẶT LỊCH
     Chỉ những luật sư này mới được nhắn tin.
  ======================================================= */

  const bookedLawyerIds = useMemo(() => {
    const ids = new Set();

    appointments.filter(isActiveAppointment).forEach((appointment) => {
      const lawyerId = getAppointmentLawyerId(appointment);

      if (lawyerId) ids.add(String(lawyerId));
    });

    return ids;
  }, [appointments]);

  const canChatWith = (lawyer) =>
    bookedLawyerIds.has(String(getId(lawyer)));

  const bookedLawyers = useMemo(
    () => lawyers.filter((lawyer) => bookedLawyerIds.has(String(getId(lawyer)))),
    [lawyers, bookedLawyerIds]
  );

  /* =======================================================
     TÌM CUỘC TRÒ CHUYỆN VỚI MỘT LUẬT SƯ
  ======================================================= */

  const findConversationByLawyer = (lawyer, list = conversations) => {
    if (!lawyer) return null;

    const lawyerId = getId(lawyer);

    // Ưu tiên khớp theo ID
    let conversation = list.find((item) => {
      const conversationLawyerId = getConversationLawyerId(item);

      return (
        conversationLawyerId &&
        lawyerId &&
        String(conversationLawyerId) === String(lawyerId)
      );
    });

    if (conversation) return conversation;

    // Dự phòng: khớp email
    const email = getLawyerEmail(lawyer).trim().toLowerCase();

    if (email) {
      conversation = list.find(
        (item) =>
          String(item?.lawyerEmail || item?.LawyerEmail || "")
            .trim()
            .toLowerCase() === email
      );
    }

    if (conversation) return conversation;

    // Dự phòng: khớp tên
    const name = getLawyerName(lawyer).trim().toLowerCase();

    return (
      list.find(
        (item) =>
          String(item?.lawyerName || item?.LawyerName || "")
            .trim()
            .toLowerCase() === name
      ) || null
    );
  };

  /* =======================================================
     LOAD MESSAGES
     GET /api/messages/conversations/{id}
  ======================================================= */

  const loadMessages = async (conversationId) => {
    if (!conversationId) {
      setMessages([]);
      return;
    }

    try {
      setLoadingMessages(true);

      const data = await api.get(`/messages/conversations/${conversationId}`);

      setMessages(toList(data));
    } catch (err) {
      console.error("Không thể tải tin nhắn:", err);

      setMessages([]);

      notifyError(err, "Không thể tải tin nhắn.");
    } finally {
      setLoadingMessages(false);
    }
  };

  /* =======================================================
     TỰ ĐỘNG CẬP NHẬT (POLLING)
     Nhận tin nhắn mới mà không cần tải lại trang.
     - Cuộc trò chuyện đang mở: kiểm tra mỗi 3 giây
     - Danh sách bên trái: kiểm tra mỗi 5 giây
     - Tab đang ẩn thì tạm dừng, quay lại tab thì cập nhật ngay
     - Gặp 401 thì dừng hẳn để không spam lỗi
  ======================================================= */

  const activeConversationId = getId(selectedConversation);

  activeConversationRef.current = activeConversationId;

  // Tải tin nhắn "âm thầm": không hiện "Đang tải...", không nhấp nháy
  const refreshMessages = async (conversationId, { force = false } = {}) => {
    if (!conversationId) return;

    // Poll thường bị bỏ qua nếu request trước chưa xong
    if (!force && fetchingMessagesRef.current) return;

    const seq = ++messagesSeqRef.current;

    fetchingMessagesRef.current = true;

    try {
      const data = await api.get(`/messages/conversations/${conversationId}`);

      // Đã có request mới hơn, hoặc đã chuyển sang cuộc trò chuyện khác
      if (seq !== messagesSeqRef.current) return;

      if (String(activeConversationRef.current) !== String(conversationId)) {
        return;
      }

      const list = toList(data);

      setMessages((prev) =>
        messagesSignature(prev) === messagesSignature(list) ? prev : list
      );
    } catch (err) {
      if (hasStatus(err, 401)) {
        authFailedRef.current = true;
        setError(AUTH_MESSAGE);
      }
    } finally {
      if (seq === messagesSeqRef.current) {
        fetchingMessagesRef.current = false;
      }
    }
  };

  // Tải danh sách hội thoại "âm thầm" (cập nhật preview + giờ nhắn cuối)
  const refreshConversations = async () => {
    try {
      const data = await api.get("/messages/conversations");

      const list = toList(data);

      setConversations((prev) =>
        conversationsSignature(prev) === conversationsSignature(list)
          ? prev
          : list
      );
    } catch (err) {
      if (hasStatus(err, 401)) {
        authFailedRef.current = true;
        setError(AUTH_MESSAGE);
      }
    }
  };

  // Poll tin nhắn của cuộc trò chuyện đang mở
  useEffect(() => {
    if (!activeConversationId) return undefined;

    const tick = () => {
      if (document.hidden || authFailedRef.current) return;

      refreshMessages(activeConversationId);
    };

    const timer = setInterval(tick, MESSAGE_POLL_MS);

    document.addEventListener("visibilitychange", tick);

    return () => {
      clearInterval(timer);
      document.removeEventListener("visibilitychange", tick);
    };
  }, [activeConversationId]);

  // Poll danh sách hội thoại
  useEffect(() => {
    if (loading) return undefined;

    const tick = () => {
      if (document.hidden || authFailedRef.current) return;

      refreshConversations();
    };

    const timer = setInterval(tick, CONVERSATION_POLL_MS);

    document.addEventListener("visibilitychange", tick);

    return () => {
      clearInterval(timer);
      document.removeEventListener("visibilitychange", tick);
    };
  }, [loading]);

  // Đang mở khung chat trống mà luật sư vừa tạo hội thoại -> tự gắn vào
  useEffect(() => {
    if (!selectedLawyer || selectedConversation) return;

    const found = findConversationByLawyer(selectedLawyer, conversations);

    if (found) {
      activeConversationRef.current = getId(found);

      setSelectedConversation(found);

      refreshMessages(getId(found), { force: true });
    }
  }, [conversations, selectedLawyer, selectedConversation]);

  // Tự cuộn xuống tin mới nhất (nếu đang ở gần cuối)
  useEffect(() => {
    const box = messagesBoxRef.current;

    if (box && stickToBottomRef.current) {
      box.scrollTop = box.scrollHeight;
    }
  }, [messages, activeConversationId]);

  /* =======================================================
     CREATE CONVERSATION
     POST /api/messages/conversations

     Khách là người bắt đầu nên gửi lawyerId.
     Backend PHẢI kiểm tra khách đã đặt lịch với luật sư này
     (frontend chỉ chặn để trải nghiệm tốt, không thay được
     kiểm tra ở backend).
  ======================================================= */

  const createConversation = async (lawyer) => {
    if (!lawyer) return null;

    const lawyerId = getId(lawyer);

    if (!lawyerId) {
      alert("Không xác định được mã luật sư.");

      return null;
    }

    if (!canChatWith(lawyer)) {
      alert(NOT_BOOKED_MESSAGE);

      return null;
    }

    try {
      setCreatingConversation(true);

      const created = await api.post("/messages/conversations", {
        lawyerId: lawyerId,
        clientId: currentUserId,
      });

      const conversation =
        created?.data || created?.conversation || created;

      if (!conversation) {
        throw new Error("API không trả về thông tin cuộc hội thoại.");
      }

      setConversations((prev) => {
        const exists = prev.some(
          (item) => String(getId(item)) === String(getId(conversation))
        );

        return exists ? prev : [...prev, conversation];
      });

      return conversation;
    } catch (err) {
      console.error("Không thể tạo cuộc hội thoại:", err);

      notifyError(err, "Không thể tạo cuộc hội thoại.");

      return null;
    } finally {
      setCreatingConversation(false);
    }
  };

  /* =======================================================
     CHỌN LUẬT SƯ

     Đã từng nhắn: mở cuộc trò chuyện cũ.
     Chưa nhắn: chỉ mở khung chat trống, cuộc trò chuyện
     chỉ được tạo khi khách gửi tin đầu tiên.
  ======================================================= */

  const handleSelectLawyer = async (lawyer, conversation) => {
    if (!lawyer) return;

    if (!canChatWith(lawyer)) {
      alert(NOT_BOOKED_MESSAGE);
      return;
    }

    setSelectedLawyer(lawyer);
    setSelectedConversation(conversation || null);
    stickToBottomRef.current = true;
    setMessages([]);
    setMessage("");

    if (conversation) {
      await loadMessages(getId(conversation));
    }
  };

  /* =======================================================
     GỬI TIN NHẮN
  ======================================================= */

  const handleSend = async (e) => {
    e.preventDefault();

    const content = message.trim();

    if (!content) return;

    if (!selectedLawyer) {
      alert("Vui lòng chọn luật sư.");
      return;
    }

    if (!canChatWith(selectedLawyer)) {
      alert(NOT_BOOKED_MESSAGE);
      return;
    }

    // Chưa có cuộc trò chuyện -> tạo ở tin nhắn đầu tiên
    let conversation = selectedConversation;

    if (!conversation) {
      conversation = await createConversation(selectedLawyer);

      if (!conversation) return;

      setSelectedConversation(conversation);
    }

    const conversationId = getId(conversation);

    if (!conversationId) {
      alert("Không xác định được mã cuộc hội thoại.");
      return;
    }

    try {
      setSending(true);

      await api.post("/messages", {
        conversationId: conversationId,
        content: content,
        attachmentUrl: null,
      });

      setMessage("");

      stickToBottomRef.current = true;

      await refreshMessages(conversationId, { force: true });

      await refreshConversations();
    } catch (err) {
      console.error("Không thể gửi tin nhắn:", err);

      notifyError(err, "Không thể gửi tin nhắn.");
    } finally {
      setSending(false);
    }
  };

  /* =======================================================
     QUAY LẠI
  ======================================================= */

  const handleBack = () => {
    setSelectedLawyer(null);
    setSelectedConversation(null);
    setMessages([]);
    setMessage("");
  };

  /* =======================================================
     DANH SÁCH HIỂN THỊ
     Chỉ gồm luật sư đã đặt lịch. Lọc theo từ khóa;
     luật sư đã nhắn xếp lên đầu, mới nhắn gần nhất trên cùng.
  ======================================================= */

  const listItems = useMemo(() => {
    const keyword = normalizeText(search.trim());

    return bookedLawyers
      .map((lawyer) => ({
        lawyer,
        conversation: findConversationByLawyer(lawyer, conversations),
      }))
      .filter(({ lawyer }) => {
        if (!keyword) return true;

        return normalizeText(
          [getLawyerName(lawyer), getLawyerEmail(lawyer), getLawyerTitle(lawyer)].join(
            " "
          )
        ).includes(keyword);
      })
      .sort((a, b) => {
        if (a.conversation && !b.conversation) return -1;
        if (!a.conversation && b.conversation) return 1;

        if (a.conversation && b.conversation) {
          return (
            new Date(getLastMessageAt(b.conversation) || 0) -
            new Date(getLastMessageAt(a.conversation) || 0)
          );
        }

        return getLawyerName(a.lawyer).localeCompare(getLawyerName(b.lawyer), "vi");
      });
  }, [bookedLawyers, conversations, search]);

  /* =======================================================
     RENDER
  ======================================================= */

  return (
    <div className="admin-page chat-page">
      {/* HEADER */}

      <div className="admin-page-header">
        <div>
          <h1>
            <FontAwesomeIcon icon={faComments} />
            Tin nhắn
          </h1>

          <p>Trao đổi trực tiếp với luật sư bạn đã đặt lịch</p>
        </div>
      </div>

      {/* ERROR */}

      {error && (
        <div
          style={{
            marginBottom: "15px",
            padding: "12px 16px",
            borderRadius: "8px",
            background: "#fff1f0",
            color: "#cf1322",
          }}
        >
          {error}
        </div>
      )}

      {/* CHAT CONTAINER */}

      <div className="chat-container">
        {/* =================================================
            SIDEBAR: DANH SÁCH LUẬT SƯ ĐÃ ĐẶT LỊCH
        ================================================= */}

        <div className="chat-conversations">
          <div className="chat-conversations-header">
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: "8px",
              }}
            >
              <h3>Luật sư</h3>

              <span>{bookedLawyers.length}</span>
            </div>
          </div>

          {/* SEARCH */}

          <div className="chat-search">
            <FontAwesomeIcon icon={faMagnifyingGlass} />

            <input
              type="text"
              placeholder="Tìm luật sư..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          {/* LIST */}

          <div className="chat-conversation-list">
            {loading ? (
              <div className="chat-empty">Đang tải danh sách luật sư...</div>
            ) : listItems.length === 0 ? (
              <div className="chat-empty">
                <FontAwesomeIcon icon={faUser} />

                {bookedLawyers.length === 0 ? (
                  <>
                    <p>Bạn chưa đặt lịch với luật sư nào</p>

                    <small>
                      Đặt lịch với một luật sư để bắt đầu nhắn tin.
                    </small>
                  </>
                ) : (
                  <p>Không tìm thấy luật sư</p>
                )}
              </div>
            ) : (
              listItems.map(({ lawyer, conversation }) => {
                const lawyerId = getId(lawyer);

                const isActive =
                  String(getId(selectedLawyer)) === String(lawyerId);

                const preview = conversation
                  ? conversation.lastMessagePreview ||
                    conversation.LastMessagePreview ||
                    "Chưa có tin nhắn"
                  : getLawyerTitle(lawyer) || "Bắt đầu trò chuyện";

                return (
                  <button
                    key={lawyerId}
                    type="button"
                    className={`chat-conversation-item ${
                      isActive ? "active" : ""
                    }`}
                    onClick={() => handleSelectLawyer(lawyer, conversation)}
                  >
                    <ChatAvatar
                      src={getLawyerAvatar(lawyer)}
                      name={getLawyerName(lawyer)}
                    />

                    <div className="chat-conversation-info">
                      <div className="chat-conversation-name">
                        <span>{getLawyerName(lawyer)}</span>

                        <FontAwesomeIcon
                          icon={faCircle}
                          className="online-dot"
                        />
                      </div>

                      <div
                        className="chat-preview"
                        style={{ color: conversation ? undefined : "#999" }}
                      >
                        {preview}
                      </div>

                      <div className="chat-time">
                        {conversation
                          ? formatTime(getLastMessageAt(conversation))
                          : ""}
                      </div>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </div>

        {/* =================================================
            MAIN CHAT
        ================================================= */}

        <div className="chat-main">
          {!selectedLawyer ? (
            <div className="chat-no-selection">
              <FontAwesomeIcon icon={faComments} />

              <h3>Chọn luật sư</h3>

              <p>Chọn một luật sư bên trái để bắt đầu trò chuyện.</p>
            </div>
          ) : (
            <>
              {/* CHAT HEADER */}

              <div className="chat-main-header">
                <button
                  type="button"
                  onClick={handleBack}
                  style={{
                    border: "none",
                    background: "transparent",
                    cursor: "pointer",
                    marginRight: "10px",
                    fontSize: "16px",
                  }}
                  title="Quay lại"
                >
                  <FontAwesomeIcon icon={faArrowLeft} />
                </button>

                <ChatAvatar
                  src={getLawyerAvatar(selectedLawyer)}
                  name={getLawyerName(selectedLawyer)}
                />

                <div>
                  <h3>{getLawyerName(selectedLawyer)}</h3>

                  <span>
                    {getLawyerTitle(selectedLawyer) ||
                      getLawyerEmail(selectedLawyer) ||
                      "Luật sư"}
                  </span>
                </div>
              </div>

              {/* MESSAGES */}

              <div
                className="chat-messages"
                ref={messagesBoxRef}
                onScroll={(e) => {
                  const box = e.currentTarget;

                  stickToBottomRef.current =
                    box.scrollHeight - box.scrollTop - box.clientHeight < 120;
                }}
              >
                {creatingConversation ? (
                  <div className="chat-empty">
                    <p>Đang tạo cuộc trò chuyện...</p>
                  </div>
                ) : loadingMessages ? (
                  <div className="chat-empty">
                    <p>Đang tải tin nhắn...</p>
                  </div>
                ) : messages.length === 0 ? (
                  <div className="chat-empty">
                    <FontAwesomeIcon icon={faComments} />

                    <p>Chưa có tin nhắn.</p>

                    <small>Hãy gửi tin nhắn đầu tiên cho luật sư.</small>
                  </div>
                ) : (
                  messages.map((msg) => {
                    const senderId = msg?.senderId || msg?.SenderId;

                    const isMine = String(senderId) === String(currentUserId);

                    return (
                      <div
                        key={msg?.id || msg?.Id}
                        className={`chat-message ${isMine ? "mine" : "other"}`}
                      >
                        <div className="chat-message-bubble">
                          {msg?.content || msg?.Content || ""}
                        </div>

                        <div className="chat-message-time">
                          {formatTime(
                            msg?.sentAt ||
                              msg?.SentAt ||
                              msg?.createdAt ||
                              msg?.CreatedAt
                          )}
                        </div>
                      </div>
                    );
                  })
                )}
              </div>

              {/* INPUT */}

              <form className="chat-input" onSubmit={handleSend}>
                <input
                  type="text"
                  placeholder={
                    creatingConversation
                      ? "Đang tạo cuộc trò chuyện..."
                      : "Nhập tin nhắn..."
                  }
                  value={message}
                  disabled={creatingConversation || sending}
                  onChange={(e) => setMessage(e.target.value)}
                />

                <button
                  type="submit"
                  disabled={!message.trim() || creatingConversation || sending}
                >
                  <FontAwesomeIcon icon={faPaperPlane} />

                  {sending ? "Đang gửi..." : "Gửi"}
                </button>
              </form>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export { ChatPage };

export default ChatPage;
