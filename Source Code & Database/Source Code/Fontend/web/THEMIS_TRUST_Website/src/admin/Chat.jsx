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

import { api, getCurrentUser } from "../api/api";

import "../assets/css/admin/Chat.css";

/* =========================================================
   CẤU HÌNH
========================================================= */

const MESSAGE_POLL_MS = 3000;
const CONVERSATION_POLL_MS = 5000;

const AUTH_MESSAGE =
  "Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng xuất và đăng nhập lại.";

/* =========================================================
   HELPERS
========================================================= */

const toList = (data) =>
  Array.isArray(data)
    ? data
    : data?.items ||
      data?.data ||
      data?.users ||
      data?.clients ||
      data?.conversations ||
      [];

const getId = (item) =>
  item?.id ||
  item?.Id ||
  item?.userId ||
  item?.UserId ||
  null;

const getConversationClientId = (conversation) =>
  conversation?.clientId ||
  conversation?.ClientId ||
  conversation?.clientUserId ||
  conversation?.ClientUserId ||
  null;

const getLastMessageAt = (conversation) =>
  conversation?.lastMessageAt ||
  conversation?.LastMessageAt ||
  null;

const getClientName = (client) =>
  client?.fullName ||
  client?.FullName ||
  client?.name ||
  client?.Name ||
  "Khách hàng";

const getClientEmail = (client) =>
  client?.email ||
  client?.Email ||
  "—";

const getClientPhone = (client) =>
  client?.phone ||
  client?.Phone ||
  "—";

const hasStatus = (err, code) =>
  err?.status === code ||
  err?.response?.status === code ||
  new RegExp(`\\b${code}\\b`).test(
    String(err?.message || "")
  );

const conversationsSignature = (list) =>
  list
    .map(
      (item) =>
        `${getId(item)}:${
          getLastMessageAt(item) || ""
        }:${
          item?.lastMessagePreview ||
          item?.LastMessagePreview ||
          ""
        }`
    )
    .join("|");

const messagesSignature = (list) =>
  list
    .map(
      (item) =>
        `${item?.id || item?.Id}:${
          item?.isRead ??
          item?.IsRead ??
          ""
        }`
    )
    .join("|");

const formatTime = (date) => {
  if (!date) return "";

  const parsed = new Date(date);

  if (Number.isNaN(parsed.getTime())) {
    return "";
  }

  return parsed.toLocaleString("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
};

/* =========================================================
   COMPONENT
========================================================= */

const Chat = () => {
  const user = useMemo(
    () => getCurrentUser(),
    []
  );

  const currentUserId = getId(user);

  const currentRole = String(
    user?.role ||
      user?.Role ||
      user?.userRole ||
      user?.UserRole ||
      ""
  )
    .trim()
    .toLowerCase();

  /* =======================================================
     STATE
  ======================================================= */

  const [clients, setClients] = useState([]);
  const [conversations, setConversations] = useState([]);

  const [selectedClient, setSelectedClient] =
    useState(null);

  const [
    selectedConversation,
    setSelectedConversation,
  ] = useState(null);

  const [messages, setMessages] =
    useState([]);

  const [message, setMessage] =
    useState("");

  const [search, setSearch] =
    useState("");

  const [loading, setLoading] =
    useState(true);

  const [loadingMessages, setLoadingMessages] =
    useState(false);

  const [sending, setSending] =
    useState(false);

  const [
    creatingConversation,
    setCreatingConversation,
  ] = useState(false);

  const [error, setError] =
    useState("");

  /* =======================================================
     REFS
  ======================================================= */

  const authFailedRef =
    useRef(false);

  const activeConversationRef =
    useRef(null);

  const messagesSeqRef =
    useRef(0);

  const fetchingMessagesRef =
    useRef(false);

  const messagesBoxRef =
    useRef(null);

  const stickToBottomRef =
    useRef(true);

  /* =========================================================
     LOAD CLIENTS
     
     ADMIN / STAFF:
       GET /api/users
       -> lấy toàn bộ Client

     LAWYER:
       GET /api/lawyers/{lawyerId}/clients
       -> chỉ Client đã có Appointment với Lawyer đó
========================================================= */

  const loadClients = async () => {
    try {
      const role = currentRole;

      /* =====================================================
         LAWYER
      ===================================================== */

      if (role === "lawyer") {
        if (!currentUserId) {
          throw new Error(
            "Không xác định được UserId của Lawyer."
          );
        }

        const data = await api.get(
          `/lawyers/${currentUserId}/clients`
        );

        const clientList = toList(data);

        setClients(clientList);

        return;
      }

      /* =====================================================
         ADMIN
      ===================================================== */

      if (role === "admin") {
        const data =
          await api.get("/users");

        const clientList =
          toList(data).filter((item) => {
            const itemRole = String(
              item?.role ||
                item?.Role ||
                item?.userRole ||
                item?.UserRole ||
                ""
            )
              .trim()
              .toLowerCase();

            return itemRole === "client";
          });

        setClients(clientList);

        return;
      }

      /* =====================================================
         STAFF
         
         Nếu Staff được sử dụng Chat như Admin
      ===================================================== */

      if (role === "staff") {
        const data =
          await api.get("/users");

        const clientList =
          toList(data).filter((item) => {
            const itemRole = String(
              item?.role ||
                item?.Role ||
                item?.userRole ||
                item?.UserRole ||
                ""
            )
              .trim()
              .toLowerCase();

            return itemRole === "client";
          });

        setClients(clientList);

        return;
      }

      /* =====================================================
         ROLE KHÔNG HỢP LỆ
      ===================================================== */

      setClients([]);
    } catch (err) {
      console.error(
        "Không thể tải danh sách Client:",
        err
      );

      setClients([]);

      throw err;
    }
  };

  /* =========================================================
     LOAD CONVERSATIONS
========================================================= */

  const loadConversations =
    async () => {
      try {
        const data =
          await api.get(
            "/messages/conversations"
          );

        const list = toList(data);

        setConversations(list);

        return list;
      } catch (err) {
        console.error(
          "Không thể tải danh sách hội thoại:",
          err
        );

        setConversations([]);

        if (hasStatus(err, 401)) {
          authFailedRef.current =
            true;

          setError(AUTH_MESSAGE);
        }

        return [];
      }
    };

  /* =========================================================
     LOAD DATA
========================================================= */

  const loadData = async () => {
    try {
      setLoading(true);
      setError("");

      authFailedRef.current =
        false;

      await Promise.all([
        loadClients(),
        loadConversations(),
      ]);
    } catch (err) {
      console.error(
        "Lỗi tải dữ liệu Chat:",
        err
      );

      if (hasStatus(err, 401)) {
        authFailedRef.current =
          true;
      }

      setError(
        hasStatus(err, 401)
          ? AUTH_MESSAGE
          : err?.message ||
              "Không thể tải dữ liệu Chat."
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  /* =========================================================
     TÌM CONVERSATION THEO CLIENT
========================================================= */

  const findConversationByClient = (
    client,
    list = conversations
  ) => {
    if (!client) {
      return null;
    }

    const clientId =
      getId(client);

    /* -------------------------------------------------------
       ƯU TIÊN CLIENT ID
    ------------------------------------------------------- */

    let conversation =
      list.find((item) => {
        const conversationClientId =
          getConversationClientId(item);

        return (
          conversationClientId &&
          clientId &&
          String(
            conversationClientId
          ) === String(clientId)
        );
      });

    if (conversation) {
      return conversation;
    }

    /* -------------------------------------------------------
       DỰ PHÒNG EMAIL
    ------------------------------------------------------- */

    const clientEmail =
      String(
        client?.email ||
          client?.Email ||
          ""
      )
        .trim()
        .toLowerCase();

    if (clientEmail) {
      conversation =
        list.find((item) => {
          const conversationEmail =
            String(
              item?.clientEmail ||
                item?.ClientEmail ||
                ""
            )
              .trim()
              .toLowerCase();

          return (
            conversationEmail &&
            conversationEmail ===
              clientEmail
          );
        });
    }

    if (conversation) {
      return conversation;
    }

    /* -------------------------------------------------------
       DỰ PHÒNG TÊN
    ------------------------------------------------------- */

    const clientName =
      String(
        client?.fullName ||
          client?.FullName ||
          client?.name ||
          client?.Name ||
          ""
      )
        .trim()
        .toLowerCase();

    if (clientName) {
      conversation =
        list.find((item) => {
          const conversationName =
            String(
              item?.clientName ||
                item?.ClientName ||
                ""
            )
              .trim()
              .toLowerCase();

          return (
            conversationName &&
            conversationName ===
              clientName
          );
        });
    }

    return conversation || null;
  };

  /* =========================================================
     LOAD MESSAGES
========================================================= */

  const loadMessages = async (
    conversationId
  ) => {
    if (!conversationId) {
      setMessages([]);
      return;
    }

    try {
      setLoadingMessages(true);

      const data =
        await api.get(
          `/messages/conversations/${conversationId}`
        );

      setMessages(toList(data));
    } catch (err) {
      console.error(
        "Không thể tải tin nhắn:",
        err
      );

      setMessages([]);

      if (hasStatus(err, 401)) {
        authFailedRef.current =
          true;

        setError(AUTH_MESSAGE);
      } else if (
        err?.response?.status === 403 ||
        hasStatus(err, 403)
      ) {
        setError(
          "Bạn không có quyền xem cuộc trò chuyện này."
        );
      } else {
        alert(
          err?.message ||
            "Không thể tải tin nhắn."
        );
      }
    } finally {
      setLoadingMessages(false);
    }
  };

  /* =========================================================
     ACTIVE CONVERSATION
========================================================= */

  const activeConversationId =
    getId(selectedConversation);

  activeConversationRef.current =
    activeConversationId;

  /* =========================================================
     REFRESH MESSAGES
========================================================= */

  const refreshMessages = async (
    conversationId,
    { force = false } = {}
  ) => {
    if (!conversationId) {
      return;
    }

    if (
      !force &&
      fetchingMessagesRef.current
    ) {
      return;
    }

    const seq =
      ++messagesSeqRef.current;

    fetchingMessagesRef.current =
      true;

    try {
      const data =
        await api.get(
          `/messages/conversations/${conversationId}`
        );

      if (
        seq !==
        messagesSeqRef.current
      ) {
        return;
      }

      if (
        String(
          activeConversationRef.current
        ) !==
        String(conversationId)
      ) {
        return;
      }

      const list =
        toList(data);

      setMessages((prev) =>
        messagesSignature(prev) ===
        messagesSignature(list)
          ? prev
          : list
      );
    } catch (err) {
      if (hasStatus(err, 401)) {
        authFailedRef.current =
          true;

        setError(AUTH_MESSAGE);
      }
    } finally {
      if (
        seq ===
        messagesSeqRef.current
      ) {
        fetchingMessagesRef.current =
          false;
      }
    }
  };

  /* =========================================================
     REFRESH CONVERSATIONS
========================================================= */

  const refreshConversations =
    async () => {
      try {
        const data =
          await api.get(
            "/messages/conversations"
          );

        const list =
          toList(data);

        setConversations(
          (prev) =>
            conversationsSignature(
              prev
            ) ===
            conversationsSignature(
              list
            )
              ? prev
              : list
        );
      } catch (err) {
        if (hasStatus(err, 401)) {
          authFailedRef.current =
            true;

          setError(AUTH_MESSAGE);
        }
      }
    };

  /* =========================================================
     POLLING MESSAGES
========================================================= */

  useEffect(() => {
    if (!activeConversationId) {
      return undefined;
    }

    const tick = () => {
      if (
        document.hidden ||
        authFailedRef.current
      ) {
        return;
      }

      refreshMessages(
        activeConversationId
      );
    };

    const timer =
      setInterval(
        tick,
        MESSAGE_POLL_MS
      );

    document.addEventListener(
      "visibilitychange",
      tick
    );

    return () => {
      clearInterval(timer);

      document.removeEventListener(
        "visibilitychange",
        tick
      );
    };
  }, [activeConversationId]);

  /* =========================================================
     POLLING CONVERSATIONS
========================================================= */

  useEffect(() => {
    if (loading) {
      return undefined;
    }

    const tick = () => {
      if (
        document.hidden ||
        authFailedRef.current
      ) {
        return;
      }

      refreshConversations();
    };

    const timer =
      setInterval(
        tick,
        CONVERSATION_POLL_MS
      );

    document.addEventListener(
      "visibilitychange",
      tick
    );

    return () => {
      clearInterval(timer);

      document.removeEventListener(
        "visibilitychange",
        tick
      );
    };
  }, [loading]);

  /* =========================================================
     TỰ GẮN CONVERSATION
========================================================= */

  useEffect(() => {
    if (
      !selectedClient ||
      selectedConversation
    ) {
      return;
    }

    const found =
      findConversationByClient(
        selectedClient,
        conversations
      );

    if (found) {
      activeConversationRef.current =
        getId(found);

      setSelectedConversation(
        found
      );

      refreshMessages(
        getId(found),
        {
          force: true,
        }
      );
    }
  }, [
    conversations,
    selectedClient,
    selectedConversation,
  ]);

  /* =========================================================
     AUTO SCROLL
========================================================= */

  useEffect(() => {
    const box =
      messagesBoxRef.current;

    if (
      box &&
      stickToBottomRef.current
    ) {
      box.scrollTop =
        box.scrollHeight;
    }
  }, [
    messages,
    activeConversationId,
  ]);

  /* =========================================================
     CREATE CONVERSATION
========================================================= */

  const createConversation =
    async (client) => {
      if (!client) {
        return null;
      }

      const clientId =
        getId(client);

      if (!clientId) {
        alert(
          "Không xác định được mã khách hàng."
        );

        return null;
      }

      try {
        setCreatingConversation(
          true
        );

        /*
         * Lawyer:
         * Backend tự lấy LawyerId từ token.
         *
         * Client:
         * Frontend Chat này chủ yếu phục vụ
         * Admin/Lawyer. Nếu Client sử dụng API
         * này thì phải gửi lawyerId.
         */

        const body = {
          clientId:
            clientId,
        };

        /*
         * Admin/Staff cần gửi cả LawyerId.
         *
         * Tuy nhiên Chat dành cho Lawyer thì
         * backend tự lấy CurrentUserId.
         */

        if (
          currentRole ===
            "admin" ||
          currentRole ===
            "staff"
        ) {
          const lawyerId =
            client?.lawyerId ||
            client?.LawyerId;

          if (!lawyerId) {
            alert(
              "Không xác định được luật sư cho cuộc trò chuyện."
            );

            return null;
          }

          body.lawyerId =
            lawyerId;
        }

        const created =
          await api.post(
            "/messages/conversations",
            body
          );

        const conversation =
          created?.data ||
          created?.conversation ||
          created;

        if (!conversation) {
          throw new Error(
            "API không trả về thông tin cuộc hội thoại."
          );
        }

        setConversations(
          (prev) => {
            const exists =
              prev.some(
                (item) =>
                  String(
                    getId(item)
                  ) ===
                  String(
                    getId(
                      conversation
                    )
                  )
              );

            return exists
              ? prev
              : [
                  ...prev,
                  conversation,
                ];
          }
        );

        return conversation;
      } catch (err) {
        console.error(
          "Không thể tạo cuộc hội thoại:",
          err
        );

        if (hasStatus(err, 401)) {
          authFailedRef.current =
            true;

          setError(
            AUTH_MESSAGE
          );
        } else if (
          hasStatus(err, 403)
        ) {
          alert(
            "Bạn chỉ được chat với khách hàng đã đặt lịch với luật sư này."
          );
        } else {
          alert(
            err?.message ||
              "Không thể tạo cuộc hội thoại."
          );
        }

        return null;
      } finally {
        setCreatingConversation(
          false
        );
      }
    };

  /* =========================================================
     CHỌN CLIENT
========================================================= */

  const handleSelectClient =
    async (client) => {
      if (!client) {
        return;
      }

      setSelectedClient(client);

      setMessages([]);

      setMessage("");

      setError("");

      stickToBottomRef.current =
        true;

      let conversation =
        findConversationByClient(
          client
        );

      /*
       * Nếu chưa có conversation:
       * -> Backend sẽ kiểm tra Appointment.
       */

      if (!conversation) {
        conversation =
          await createConversation(
            client
          );
      }

      if (!conversation) {
        setSelectedConversation(
          null
        );

        return;
      }

      setSelectedConversation(
        conversation
      );

      await loadMessages(
        getId(conversation)
      );
    };

  /* =========================================================
     SEND MESSAGE
========================================================= */

  const handleSend = async (
    e
  ) => {
    e.preventDefault();

    const content =
      message.trim();

    if (!content) {
      return;
    }

    let conversation =
      selectedConversation;

    if (
      !conversation &&
      selectedClient
    ) {
      conversation =
        await createConversation(
          selectedClient
        );

      if (!conversation) {
        return;
      }

      setSelectedConversation(
        conversation
      );
    }

    if (!conversation) {
      alert(
        "Vui lòng chọn khách hàng."
      );

      return;
    }

    const conversationId =
      getId(conversation);

    if (!conversationId) {
      alert(
        "Không xác định được mã cuộc hội thoại."
      );

      return;
    }

    try {
      setSending(true);

      await api.post(
        "/messages",
        {
          conversationId:
            conversationId,

          content: content,

          attachmentUrl: null,
        }
      );

      setMessage("");

      stickToBottomRef.current =
        true;

      await refreshMessages(
        conversationId,
        {
          force: true,
        }
      );

      await refreshConversations();
    } catch (err) {
      console.error(
        "Không thể gửi tin nhắn:",
        err
      );

      if (hasStatus(err, 401)) {
        authFailedRef.current =
          true;

        setError(AUTH_MESSAGE);
      } else if (
        hasStatus(err, 403)
      ) {
        alert(
          "Bạn không có quyền gửi tin nhắn trong cuộc trò chuyện này."
        );
      } else {
        alert(
          err?.message ||
            "Không thể gửi tin nhắn."
        );
      }
    } finally {
      setSending(false);
    }
  };

  /* =========================================================
     BACK
========================================================= */

  const handleBack = () => {
    setSelectedClient(null);

    setSelectedConversation(
      null
    );

    setMessages([]);

    setMessage("");

    setError("");
  };

  /* =========================================================
     FILTER CLIENTS
========================================================= */

  const filteredClients =
    useMemo(() => {
      const keyword =
        search
          .trim()
          .toLowerCase();

      const matched = keyword
        ? clients.filter(
            (client) => {
              const name =
                String(
                  client?.fullName ||
                    client?.FullName ||
                    client?.name ||
                    client?.Name ||
                    ""
                ).toLowerCase();

              const email =
                String(
                  client?.email ||
                    client?.Email ||
                    ""
                ).toLowerCase();

              const phone =
                String(
                  client?.phone ||
                    client?.Phone ||
                    ""
                ).toLowerCase();

              return (
                name.includes(
                  keyword
                ) ||
                email.includes(
                  keyword
                ) ||
                phone.includes(
                  keyword
                )
              );
            }
          )
        : clients;

      return matched
        .map((client) => ({
          client,

          conversation:
            findConversationByClient(
              client,
              conversations
            ),
        }))
        .sort((a, b) => {
          if (
            a.conversation &&
            !b.conversation
          ) {
            return -1;
          }

          if (
            !a.conversation &&
            b.conversation
          ) {
            return 1;
          }

          if (
            a.conversation &&
            b.conversation
          ) {
            return (
              new Date(
                getLastMessageAt(
                  b.conversation
                ) || 0
              ) -
              new Date(
                getLastMessageAt(
                  a.conversation
                ) || 0
              )
            );
          }

          return getClientName(
            a.client
          ).localeCompare(
            getClientName(
              b.client
            ),
            "vi"
          );
        });
    }, [
      clients,
      conversations,
      search,
    ]);

  /* =========================================================
     RENDER
========================================================= */

  return (
    <div className="admin-page chat-page">

      {/* =====================================================
          HEADER
      ===================================================== */}

      <div className="admin-page-header">
        <div>
          <h1>
            <FontAwesomeIcon
              icon={faComments}
            />

            Tin nhắn
          </h1>

          <p>
            Trao đổi và hỗ trợ khách hàng
          </p>
        </div>
      </div>

      {/* =====================================================
          ERROR
      ===================================================== */}

      {error && (
        <div
          className="lawyer-message lawyer-message-error"
          style={{
            marginBottom: "15px",
          }}
        >
          {error}
        </div>
      )}

      {/* =====================================================
          CHAT CONTAINER
      ===================================================== */}

      <div className="chat-container">

        {/* ===================================================
            SIDEBAR
        =================================================== */}

        <div className="chat-conversations">

          <div className="chat-conversations-header">
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: "8px",
              }}
            >
              <h3>
                Khách hàng
              </h3>

              <span>
                {clients.length}
              </span>
            </div>
          </div>

          {/* SEARCH */}

          <div className="chat-search">

            <FontAwesomeIcon
              icon={
                faMagnifyingGlass
              }
            />

            <input
              type="text"
              placeholder="Tìm khách hàng..."
              value={search}
              onChange={(e) =>
                setSearch(
                  e.target.value
                )
              }
            />

          </div>

          {/* CLIENT LIST */}

          <div className="chat-conversation-list">

            {loading ? (
              <div className="chat-empty">
                Đang tải khách hàng...
              </div>
            ) : filteredClients.length ===
              0 ? (
              <div className="chat-empty">

                <FontAwesomeIcon
                  icon={faUser}
                />

                <p>
                  Không tìm thấy khách hàng
                </p>

                {currentRole ===
                  "lawyer" && (
                  <small>
                    Khách hàng sẽ xuất hiện
                    sau khi có người đặt lịch
                    với bạn.
                  </small>
                )}

              </div>
            ) : (
              filteredClients.map(
                ({
                  client,
                  conversation,
                }) => {
                  const clientId =
                    getId(client);

                  const isActive =
                    String(
                      getId(
                        selectedClient
                      )
                    ) ===
                    String(clientId);

                  const preview =
                    conversation
                      ? conversation.lastMessagePreview ||
                        conversation.LastMessagePreview ||
                        "Chưa có tin nhắn"
                      : "Chưa có tin nhắn";

                  return (
                    <button
                      key={clientId}
                      type="button"
                      className={`chat-conversation-item ${
                        isActive
                          ? "active"
                          : ""
                      }`}
                      onClick={() =>
                        handleSelectClient(
                          client
                        )
                      }
                    >

                      {/* AVATAR */}

                      <div className="chat-avatar">
                        <FontAwesomeIcon
                          icon={faUser}
                        />
                      </div>

                      {/* INFO */}

                      <div className="chat-conversation-info">

                        <div className="chat-conversation-name">

                          <span>
                            {getClientName(
                              client
                            )}
                          </span>

                          <FontAwesomeIcon
                            icon={faCircle}
                            className="online-dot"
                          />

                        </div>

                        <div
                          className="chat-preview"
                          style={{
                            color:
                              conversation
                                ? undefined
                                : "#999",
                          }}
                        >
                          {preview}
                        </div>

                        <div className="chat-time">
                          {conversation
                            ? formatTime(
                                getLastMessageAt(
                                  conversation
                                )
                              )
                            : ""}
                        </div>

                      </div>

                    </button>
                  );
                }
              )
            )}

          </div>
        </div>

        {/* ===================================================
            MAIN CHAT
        =================================================== */}

        <div className="chat-main">

          {!selectedClient ? (
            <div className="chat-no-selection">

              <FontAwesomeIcon
                icon={faComments}
              />

              <h3>
                Chọn khách hàng
              </h3>

              <p>
                Chọn một khách hàng bên trái
                để bắt đầu trò chuyện.
              </p>

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
                    background:
                      "transparent",
                    cursor: "pointer",
                    marginRight:
                      "10px",
                    fontSize: "16px",
                  }}
                  title="Quay lại"
                >
                  <FontAwesomeIcon
                    icon={faArrowLeft}
                  />
                </button>

                <div className="chat-avatar">
                  <FontAwesomeIcon
                    icon={faUser}
                  />
                </div>

                <div>
                  <h3>
                    {getClientName(
                      selectedClient
                    )}
                  </h3>

                  <span>
                    {getClientEmail(
                      selectedClient
                    )}
                  </span>
                </div>

              </div>

              {/* MESSAGES */}

              <div
                className="chat-messages"
                ref={messagesBoxRef}
                onScroll={(e) => {
                  const box =
                    e.currentTarget;

                  stickToBottomRef.current =
                    box.scrollHeight -
                      box.scrollTop -
                      box.clientHeight <
                    120;
                }}
              >

                {creatingConversation ? (
                  <div className="chat-empty">
                    <p>
                      Đang tạo cuộc trò chuyện...
                    </p>
                  </div>
                ) : loadingMessages ? (
                  <div className="chat-empty">
                    <p>
                      Đang tải tin nhắn...
                    </p>
                  </div>
                ) : messages.length ===
                  0 ? (
                  <div className="chat-empty">

                    <FontAwesomeIcon
                      icon={faComments}
                    />

                    <p>
                      Chưa có tin nhắn.
                    </p>

                    <small>
                      Hãy gửi tin nhắn đầu tiên
                      cho khách hàng.
                    </small>

                  </div>
                ) : (
                  messages.map((msg) => {
                    const senderId =
                      msg?.senderId ||
                      msg?.SenderId;

                    const isMine =
                      String(
                        senderId
                      ) ===
                      String(
                        currentUserId
                      );

                    return (
                      <div
                        key={
                          msg?.id ||
                          msg?.Id
                        }
                        className={`chat-message ${
                          isMine
                            ? "mine"
                            : "other"
                        }`}
                      >

                        <div className="chat-message-bubble">
                          {msg?.content ||
                            msg?.Content ||
                            ""}
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

              <form
                className="chat-input"
                onSubmit={
                  handleSend
                }
              >

                <input
                  type="text"
                  placeholder={
                    creatingConversation
                      ? "Đang tạo cuộc trò chuyện..."
                      : "Nhập tin nhắn..."
                  }
                  value={message}
                  disabled={
                    creatingConversation ||
                    sending
                  }
                  onChange={(e) =>
                    setMessage(
                      e.target.value
                    )
                  }
                />

                <button
                  type="submit"
                  disabled={
                    !message.trim() ||
                    creatingConversation ||
                    sending
                  }
                >
                  <FontAwesomeIcon
                    icon={
                      faPaperPlane
                    }
                  />

                  {sending
                    ? "Đang gửi..."
                    : "Gửi"}
                </button>

              </form>

            </>
          )}

        </div>
      </div>
    </div>
  );
};

export default Chat;