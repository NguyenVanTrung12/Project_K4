import { useState } from "react";
import { api } from "../api/api";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faCalendarDays, faClock, faXmark } from "@fortawesome/free-solid-svg-icons";

// Dùng khi user ĐÃ ĐĂNG NHẬP (client) muốn đặt lịch hẹn với 1 luật sư.
// Hỗ trợ 2 nguồn gọi:
//   1) Từ trang chi tiết YÊU CẦU TƯ VẤN đã được phân công luật sư
//      -> truyền prop `consultationRequest` (có .id, .lawyerId, .lawyerName, .title, .caseId)
//   2) Từ trang DANH SÁCH LUẬT SƯ, khách tự chọn 1 luật sư để đặt lịch trực tiếp
//      -> truyền prop `lawyer` (có .id, .fullName) — không cần tạo ConsultationRequest
//
// Props:
//  - consultationRequest?: object từ GET /api/consultation-requests/{id}
//  - lawyer?: object từ danh sách luật sư (dùng khi KHÔNG có consultationRequest)
//  - currentClientId: Guid của client hiện tại (lấy từ token/context auth)
//  - onClose: đóng modal
//  - onBooked: callback sau khi đặt lịch thành công

const timeSlots = ["08:30", "09:30", "10:30", "13:30", "14:30", "15:30", "16:30"];

const BookAppointmentModal = ({ consultationRequest, lawyer, currentClientId, onClose, onBooked }) => {
  const [scheduledDate, setScheduledDate] = useState("");
  const [scheduledTime, setScheduledTime] = useState("");
  const [durationMin, setDurationMin] = useState(30);
  const [description, setDescription] = useState("");
  const [state, setState] = useState({ loading: false, error: "" });

  // Chuẩn hoá thông tin luật sư + yêu cầu tư vấn (nếu có) từ 1 trong 2 nguồn trên
  const lawyerId = consultationRequest?.lawyerId ?? lawyer?.id;
  const lawyerName = consultationRequest?.lawyerName ?? lawyer?.fullName ?? lawyer?.name;

  if (!consultationRequest && !lawyer) return null;

  if (!lawyerId) {
    return (
      <div className="modal-overlay">
        <div className="modal-card">
          <p>Yêu cầu tư vấn này chưa được phân công luật sư, vui lòng chờ admin/staff xử lý trước khi đặt lịch hẹn.</p>
          <button onClick={onClose}>Đóng</button>
        </div>
      </div>
    );
  }

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!scheduledDate || !scheduledTime) {
      setState({ loading: false, error: "Vui lòng chọn ngày và khung giờ." });
      return;
    }

    setState({ loading: true, error: "" });

    try {
      const scheduledAt = `${scheduledDate}T${scheduledTime}:00`;

      await api.post("/appointments", {
        clientId: currentClientId,
        lawyerId,
        // Chỉ gửi khi đặt lịch từ 1 yêu cầu tư vấn cụ thể; đặt trực tiếp từ danh sách luật sư thì để null
        consultationRequestId: consultationRequest?.id ?? null,
        caseId: consultationRequest?.caseId ?? null,
        scheduledAt,
        durationMin,
        description,
      });

      onBooked?.();
      onClose?.();
    } catch (err) {
      const message = err?.response?.data?.message || "Không thể đặt lịch hẹn, vui lòng thử lại.";
      setState({ loading: false, error: message });
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-card">
        <div className="modal-header">
          <h3>Đặt lịch hẹn tư vấn</h3>
          <button type="button" onClick={onClose} aria-label="Đóng">
            <FontAwesomeIcon icon={faXmark} />
          </button>
        </div>

        <div className="modal-context">
          {consultationRequest && (
            <p><strong>Yêu cầu tư vấn:</strong> {consultationRequest.title}</p>
          )}
          <p><strong>Luật sư:</strong> {lawyerName}</p>
        </div>

        <form onSubmit={handleSubmit} className="modal-form">
          <div className="form-field">
            <label>Ngày hẹn <span>*</span></label>
            <input
              type="date"
              value={scheduledDate}
              onChange={(e) => setScheduledDate(e.target.value)}
              required
            />
          </div>

          <div className="form-field">
            <label>Khung giờ <span>*</span></label>
            <div className="time-grid">
              {timeSlots.map((t) => (
                <button
                  type="button"
                  key={t}
                  className={scheduledTime === t ? "active" : ""}
                  onClick={() => setScheduledTime(t)}
                >
                  <FontAwesomeIcon icon={faClock} /> {t}
                </button>
              ))}
            </div>
          </div>

          <div className="form-field">
            <label>Thời lượng (phút)</label>
            <select value={durationMin} onChange={(e) => setDurationMin(Number(e.target.value))}>
              <option value={30}>30 phút</option>
              <option value={45}>45 phút</option>
              <option value={60}>60 phút</option>
            </select>
          </div>

          <div className="form-field">
            <label>Ghi chú thêm</label>
            <textarea
              rows={3}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Mô tả thêm cho buổi hẹn (nếu có)..."
            />
          </div>

          {state.error && <div className="form-error">{state.error}</div>}

          <button type="submit" className="submit-btn" disabled={state.loading}>
            <FontAwesomeIcon icon={faCalendarDays} />
            {state.loading ? "Đang đặt lịch..." : "Xác nhận đặt lịch"}
          </button>
        </form>
      </div>
    </div>
  );
};

export default BookAppointmentModal;
