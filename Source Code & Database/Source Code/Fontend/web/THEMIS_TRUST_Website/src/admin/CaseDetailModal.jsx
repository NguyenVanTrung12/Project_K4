import { useEffect, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faXmark,
  faFolderOpen,
  faUser,
  faScaleBalanced,
  faGavel,
  faCalendarDays,
  faClock,
  faFileLines,
  faTrash,
  faUpload,
  faPlus,
  faCircleCheck,
  faCircle,
  faPen,
} from "@fortawesome/free-solid-svg-icons";

import { api } from "../api/api";

export default function CaseDetailModal({
  caseId,
  isAdmin,
  isLawyer,
  onClose,
  onChanged,
}) {
  const [caseData, setCaseData] =
    useState(null);

  const [loading, setLoading] =
    useState(true);

  const [error, setError] =
    useState("");

  const [saving, setSaving] =
    useState(false);

  const [showEdit, setShowEdit] =
    useState(false);

  const [showEventForm, setShowEventForm] =
    useState(false);

  const [eventTitle, setEventTitle] =
    useState("");

  const [eventDate, setEventDate] =
    useState("");

  const [eventNote, setEventNote] =
    useState("");

  const [editTitle, setEditTitle] =
    useState("");

  const [editStatus, setEditStatus] =
    useState("");

  const [editNextStep, setEditNextStep] =
    useState("");

  const [editCourtName, setEditCourtName] =
    useState("");

  const loadCase = async () => {
    try {
      setLoading(true);
      setError("");

      const data =
        await api.get(
          `/cases/${caseId}`
        );

      setCaseData(data);

      setEditTitle(
        data?.title || ""
      );

      setEditStatus(
        data?.status || "filed"
      );

      setEditNextStep(
        data?.nextStep || ""
      );

      setEditCourtName(
        data?.courtName || ""
      );
    } catch (err) {
      console.error(
        "Load case detail error:",
        err
      );

      setError(
        err?.message ||
          "Không thể tải chi tiết hồ sơ."
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCase();
  }, [caseId]);

  const formatDate = (value) => {
    if (!value) return "—";

    const date =
      new Date(value);

    if (
      Number.isNaN(
        date.getTime()
      )
    ) {
      return "—";
    }

    return date.toLocaleDateString(
      "vi-VN"
    );
  };

  const formatDateTime = (value) => {
    if (!value) return "—";

    const date =
      new Date(value);

    if (
      Number.isNaN(
        date.getTime()
      )
    ) {
      return "—";
    }

    return date.toLocaleString(
      "vi-VN"
    );
  };

  const getStatusText = (value) => {
    switch (
      String(value || "")
        .toLowerCase()
    ) {
      case "filed":
        return "Đã nộp";

      case "in_review":
        return "Đang thụ lý";

      case "hearing":
        return "Đang xét xử";

      case "resolved":
        return "Đã giải quyết";

      default:
        return "Chưa xác định";
    }
  };

  const saveCase = async () => {
    try {
      setSaving(true);

      await api.put(
        `/cases/${caseId}`,
        {
          title: editTitle,
          status: editStatus,
          nextStep: editNextStep,
          courtName: editCourtName,
          closedAt:
            editStatus === "resolved"
              ? new Date().toISOString()
              : null,
        }
      );

      setShowEdit(false);

      await loadCase();

      onChanged?.();
    } catch (err) {
      alert(
        err?.message ||
          "Không thể cập nhật hồ sơ."
      );
    } finally {
      setSaving(false);
    }
  };

  const addEvent = async () => {
    if (!eventTitle.trim()) {
      alert(
        "Vui lòng nhập tên sự kiện."
      );
      return;
    }

    if (!eventDate) {
      alert(
        "Vui lòng chọn ngày."
      );
      return;
    }

    try {
      setSaving(true);

      await api.post(
        `/cases/${caseId}/events`,
        {
          title: eventTitle,
          eventDate:
            new Date(
              eventDate
            ).toISOString(),
          note: eventNote,
          isDone: false,
          sortOrder:
            (caseData?.events?.length ||
              0) + 1,
        }
      );

      setEventTitle("");
      setEventDate("");
      setEventNote("");
      setShowEventForm(false);

      await loadCase();
    } catch (err) {
      alert(
        err?.message ||
          "Không thể thêm sự kiện."
      );
    } finally {
      setSaving(false);
    }
  };

  const toggleEvent = async (
    eventId
  ) => {
    try {
      await api.patch(
        `/cases/events/${eventId}/toggle-done`
      );

      await loadCase();
    } catch (err) {
      alert(
        err?.message ||
          "Không thể cập nhật sự kiện."
      );
    }
  };

  const deleteEvent = async (
    eventId
  ) => {
    if (
      !window.confirm(
        "Bạn có chắc muốn xóa sự kiện này?"
      )
    ) {
      return;
    }

    try {
      await api.delete(
        `/cases/events/${eventId}`
      );

      await loadCase();
    } catch (err) {
      alert(
        err?.message ||
          "Không thể xóa sự kiện."
      );
    }
  };

  const uploadDocument = async (
    event
  ) => {
    const file =
      event.target.files?.[0];

    if (!file) return;

    if (
      file.size >
      10 * 1024 * 1024
    ) {
      alert(
        "File tối đa 10MB."
      );

      return;
    }

    try {
      setSaving(true);

      const formData =
        new FormData();

      formData.append(
        "file",
        file
      );

      await api.post(
        `/cases/${caseId}/documents`,
        formData
      );

      await loadCase();
    } catch (err) {
      alert(
        err?.message ||
          "Không thể upload tài liệu."
      );
    } finally {
      setSaving(false);

      event.target.value = "";
    }
  };

  const deleteDocument = async (
    documentId
  ) => {
    if (
      !window.confirm(
        "Bạn có chắc muốn xóa tài liệu này?"
      )
    ) {
      return;
    }

    try {
      await api.delete(
        `/cases/documents/${documentId}`
      );

      await loadCase();
    } catch (err) {
      alert(
        err?.message ||
          "Không thể xóa tài liệu."
      );
    }
  };

  const deleteCase = async () => {
    if (!isAdmin) {
      return;
    }

    if (
      !window.confirm(
        "Bạn có chắc muốn XÓA hồ sơ vụ án này?"
      )
    ) {
      return;
    }

    try {
      setSaving(true);

      await api.delete(
        `/cases/${caseId}`
      );

      onChanged?.();

      onClose();
    } catch (err) {
      alert(
        err?.message ||
          "Không thể xóa hồ sơ."
      );
    } finally {
      setSaving(false);
    }
  };

  if (!caseId) {
    return null;
  }

  return (
    <div
      className="case-modal-overlay"
      onMouseDown={(e) => {
        if (
          e.target ===
          e.currentTarget
        ) {
          onClose();
        }
      }}
    >
      <div className="case-modal">

        {/* HEADER */}
        <div className="case-modal-header">

          <div>
            <div className="case-modal-title">

              <FontAwesomeIcon
                icon={faFolderOpen}
              />

              <div>
                <h2>
                  {caseData?.title ||
                    "Chi tiết hồ sơ"}
                </h2>

                <span>
                  {caseData?.docketNo ||
                    ""}
                </span>
              </div>
            </div>
          </div>

          <button
            className="case-modal-close"
            onClick={onClose}
          >
            <FontAwesomeIcon
              icon={faXmark}
            />
          </button>
        </div>

        {/* BODY */}
        <div className="case-modal-body">

          {loading ? (
            <div className="lawyer-loading">
              Đang tải hồ sơ...
            </div>

          ) : error ? (

            <div className="lawyer-message lawyer-message-error">
              {error}
            </div>

          ) : caseData ? (

            <>
              {/* INFO */}
              <div className="case-detail-grid">

                <div className="case-detail-item">
                  <span>
                    <FontAwesomeIcon
                      icon={faUser}
                    />
                    Khách hàng
                  </span>

                  <strong>
                    {caseData.clientName ||
                      "—"}
                  </strong>
                </div>

                <div className="case-detail-item">
                  <span>
                    <FontAwesomeIcon
                      icon={
                        faScaleBalanced
                      }
                    />
                    Luật sư
                  </span>

                  <strong>
                    {caseData.lawyerName ||
                      "—"}
                  </strong>
                </div>

                <div className="case-detail-item">
                  <span>
                    <FontAwesomeIcon
                      icon={faGavel}
                    />
                    Lĩnh vực
                  </span>

                  <strong>
                    {caseData.practiceAreaName ||
                      "—"}
                  </strong>
                </div>

                <div className="case-detail-item">
                  <span>
                    <FontAwesomeIcon
                      icon={faGavel}
                    />
                    Tòa án
                  </span>

                  <strong>
                    {caseData.courtName ||
                      "Chưa cập nhật"}
                  </strong>
                </div>

                <div className="case-detail-item">
                  <span>
                    <FontAwesomeIcon
                      icon={
                        faCalendarDays
                      }
                    />
                    Ngày mở
                  </span>

                  <strong>
                    {formatDate(
                      caseData.openedAt
                    )}
                  </strong>
                </div>

                <div className="case-detail-item">
                  <span>
                    <FontAwesomeIcon
                      icon={faClock}
                    />
                    Trạng thái
                  </span>

                  <strong>
                    {getStatusText(
                      caseData.status
                    )}
                  </strong>
                </div>
              </div>

              {/* NEXT STEP */}
              <div className="case-detail-section">

                <div className="case-section-header">
                  <h3>
                    Bước xử lý tiếp theo
                  </h3>
                </div>

                <div className="case-next-step">
                  {caseData.nextStep ||
                    "Chưa cập nhật"}
                </div>
              </div>

              {/* ACTION */}
              <div className="case-detail-actions">

                {(isAdmin ||
                  isLawyer) && (
                  <button
                    className="case-primary-button"
                    onClick={() =>
                      setShowEdit(
                        !showEdit
                      )
                    }
                  >
                    <FontAwesomeIcon
                      icon={faPen}
                    />
                    Chỉnh sửa
                  </button>
                )}

                {(isAdmin ||
                  isLawyer) && (
                  <button
                    className="case-secondary-button"
                    onClick={() =>
                      setShowEventForm(
                        !showEventForm
                      )
                    }
                  >
                    <FontAwesomeIcon
                      icon={faPlus}
                    />
                    Thêm sự kiện
                  </button>
                )}

                {isAdmin && (
                  <button
                    className="case-danger-button"
                    onClick={
                      deleteCase
                    }
                    disabled={saving}
                  >
                    <FontAwesomeIcon
                      icon={faTrash}
                    />
                    Xóa hồ sơ
                  </button>
                )}
              </div>

              {/* EDIT */}
              {showEdit && (
                <div className="case-form">

                  <h3>
                    Chỉnh sửa hồ sơ
                  </h3>

                  <label>
                    Tên vụ án
                  </label>

                  <input
                    value={editTitle}
                    onChange={(e) =>
                      setEditTitle(
                        e.target.value
                      )
                    }
                  />

                  <label>
                    Trạng thái
                  </label>

                  <select
                    value={editStatus}
                    onChange={(e) =>
                      setEditStatus(
                        e.target.value
                      )
                    }
                  >
                    <option value="filed">
                      Đã nộp
                    </option>

                    <option value="in_review">
                      Đang thụ lý
                    </option>

                    <option value="hearing">
                      Đang xét xử
                    </option>

                    <option value="resolved">
                      Đã giải quyết
                    </option>
                  </select>

                  <label>
                    Bước xử lý tiếp theo
                  </label>

                  <input
                    value={
                      editNextStep
                    }
                    onChange={(e) =>
                      setEditNextStep(
                        e.target.value
                      )
                    }
                  />

                  <label>
                    Tòa án
                  </label>

                  <input
                    value={
                      editCourtName
                    }
                    onChange={(e) =>
                      setEditCourtName(
                        e.target.value
                      )
                    }
                  />

                  <div className="case-form-actions">
                    <button
                      className="case-secondary-button"
                      onClick={() =>
                        setShowEdit(
                          false
                        )
                      }
                    >
                      Hủy
                    </button>

                    <button
                      className="case-primary-button"
                      onClick={
                        saveCase
                      }
                      disabled={saving}
                    >
                      {saving
                        ? "Đang lưu..."
                        : "Lưu thay đổi"}
                    </button>
                  </div>
                </div>
              )}

              {/* EVENT FORM */}
              {showEventForm && (
                <div className="case-form">

                  <h3>
                    Thêm sự kiện
                  </h3>

                  <label>
                    Tên sự kiện
                  </label>

                  <input
                    value={
                      eventTitle
                    }
                    onChange={(e) =>
                      setEventTitle(
                        e.target.value
                      )
                    }
                    placeholder="Ví dụ: Nộp hồ sơ lên tòa"
                  />

                  <label>
                    Ngày
                  </label>

                  <input
                    type="datetime-local"
                    value={
                      eventDate
                    }
                    onChange={(e) =>
                      setEventDate(
                        e.target.value
                      )
                    }
                  />

                  <label>
                    Ghi chú
                  </label>

                  <textarea
                    value={
                      eventNote
                    }
                    onChange={(e) =>
                      setEventNote(
                        e.target.value
                      )
                    }
                    placeholder="Ghi chú..."
                  />

                  <div className="case-form-actions">

                    <button
                      className="case-secondary-button"
                      onClick={() =>
                        setShowEventForm(
                          false
                        )
                      }
                    >
                      Hủy
                    </button>

                    <button
                      className="case-primary-button"
                      onClick={
                        addEvent
                      }
                      disabled={saving}
                    >
                      {saving
                        ? "Đang lưu..."
                        : "Thêm sự kiện"}
                    </button>

                  </div>
                </div>
              )}

              {/* TIMELINE */}
              <div className="case-detail-section">

                <div className="case-section-header">

                  <h3>
                    Tiến trình vụ án
                  </h3>

                  <span>
                    {caseData.events
                      ?.length || 0}{" "}
                    sự kiện
                  </span>
                </div>

                {caseData.events?.length >
                0 ? (

                  <div className="case-timeline">

                    {caseData.events.map(
                      (event) => (

                        <div
                          className={`case-timeline-item ${
                            event.isDone
                              ? "done"
                              : ""
                          }`}
                          key={
                            event.id
                          }
                        >

                          <div className="case-timeline-icon">

                            <FontAwesomeIcon
                              icon={
                                event.isDone
                                  ? faCircleCheck
                                  : faCircle
                              }
                            />

                          </div>

                          <div className="case-timeline-content">

                            <div className="case-timeline-top">

                              <strong>
                                {event.title}
                              </strong>

                              <span>
                                {formatDateTime(
                                  event.eventDate
                                )}
                              </span>

                            </div>

                            {event.note && (
                              <p>
                                {
                                  event.note
                                }
                              </p>
                            )}

                            <div className="case-event-actions">

                              <button
                                onClick={() =>
                                  toggleEvent(
                                    event.id
                                  )
                                }
                              >
                                <FontAwesomeIcon
                                  icon={
                                    faCircleCheck
                                  }
                                />

                                {event.isDone
                                  ? "Đã hoàn thành"
                                  : "Đánh dấu hoàn thành"}
                              </button>

                              <button
                                className="case-event-delete"
                                onClick={() =>
                                  deleteEvent(
                                    event.id
                                  )
                                }
                              >
                                <FontAwesomeIcon
                                  icon={
                                    faTrash
                                  }
                                />

                                Xóa
                              </button>

                            </div>
                          </div>
                        </div>
                      )
                    )}

                  </div>

                ) : (

                  <div className="case-empty">
                    Chưa có sự kiện nào.
                  </div>
                )}
              </div>

              {/* DOCUMENTS */}
              <div className="case-detail-section">

                <div className="case-section-header">

                  <div>
                    <h3>
                      Tài liệu hồ sơ
                    </h3>

                    <span>
                      {caseData.documents
                        ?.length || 0}{" "}
                      tài liệu
                    </span>
                  </div>

                  <label className="case-upload-button">

                    <FontAwesomeIcon
                      icon={faUpload}
                    />

                    Upload tài liệu

                    <input
                      type="file"
                      accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
                      onChange={
                        uploadDocument
                      }
                      hidden
                    />

                  </label>
                </div>

                {caseData.documents
                  ?.length > 0 ? (

                  <div className="case-documents">

                    {caseData.documents.map(
                      (doc) => (

                        <div
                          className="case-document"
                          key={
                            doc.id
                          }
                        >

                          <div className="case-document-icon">

                            <FontAwesomeIcon
                              icon={
                                faFileLines
                              }
                            />

                          </div>

                          <div className="case-document-info">

                            <strong>
                              {doc.fileName}
                            </strong>

                            <small>
                              {doc.fileType?.toUpperCase()}{" "}
                              •{" "}
                              {formatDateTime(
                                doc.uploadedAt
                              )}
                            </small>

                          </div>

                          <div className="case-document-actions">

                            <a
                              href={
                                doc.fileUrl
                              }
                              target="_blank"
                              rel="noreferrer"
                            >
                              Xem
                            </a>

                            <button
                              onClick={() =>
                                deleteDocument(
                                  doc.id
                                )
                              }
                            >
                              <FontAwesomeIcon
                                icon={
                                  faTrash
                                }
                              />
                            </button>

                          </div>

                        </div>
                      )
                    )}

                  </div>

                ) : (

                  <div className="case-empty">
                    Chưa có tài liệu.
                  </div>
                )}

              </div>
            </>
          ) : null}
        </div>
      </div>
    </div>
  );
}