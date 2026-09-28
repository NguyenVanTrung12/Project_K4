import { useEffect, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faXmark,
  faFileCirclePlus,
  faFloppyDisk,
  faCalendarDays,
} from "@fortawesome/free-solid-svg-icons";
import { api } from "../../api/api";
import "../../assets/css/admin/LawyerCreateCaseModal.css";

export default function LawyerCreateCaseModal({
  consultation,
  onClose,
  onCreated,
}) {
  const [form, setForm] = useState({
    docketNo: "",
    title: "",
    practiceAreaId: "",
    nextStep: "",
    courtName: "",
    openedAt: "",
  });

  const [practiceAreas, setPracticeAreas] = useState([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!consultation) return;

    const today = new Date();
    const date = today.toISOString().split("T")[0];

    setForm({
      docketNo: `HS-${today.getFullYear()}-${String(
        Math.floor(Math.random() * 9999)
      ).padStart(4, "0")}`,
      title: consultation.title || "",
      practiceAreaId: consultation.practiceAreaId || "",
      nextStep: "",
      courtName: "",
      openedAt: date,
    });
  }, [consultation]);

  useEffect(() => {
    loadPracticeAreas();
  }, []);

  const loadPracticeAreas = async () => {
    try {
      const data = await api.get("/practice-areas");

      setPracticeAreas(
        Array.isArray(data)
          ? data
          : data?.items || []
      );
    } catch (err) {
      console.error("Không thể lấy lĩnh vực:", err);
      setPracticeAreas([]);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;

    setForm((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!form.docketNo.trim()) {
      setError("Vui lòng nhập số hồ sơ.");
      return;
    }

    if (!form.title.trim()) {
      setError("Vui lòng nhập tiêu đề vụ án.");
      return;
    }

    try {
      setSaving(true);
      setError("");

      /*
       * KHÔNG cho Lawyer tự nhập:
       * clientId
       * lawyerId
       *
       * Backend phải lấy lawyerId từ JWT
       * và clientId từ consultation.
       */

      const payload = {
        consultationRequestId: consultation.id,

        docketNo: form.docketNo.trim(),

        title: form.title.trim(),

        practiceAreaId:
          form.practiceAreaId || null,

        nextStep:
          form.nextStep.trim() || null,

        courtName:
          form.courtName.trim() || null,

        openedAt:
          form.openedAt || null,
      };

      const created = await api.post(
        "/cases",
        payload
      );

      alert("Tạo hồ sơ vụ án thành công.");

      if (onCreated) {
        onCreated(created);
      }

      onClose();
    } catch (err) {
      console.error(
        "Lỗi tạo hồ sơ vụ án:",
        err
      );

      setError(
        err?.message ||
          "Không thể tạo hồ sơ vụ án."
      );
    } finally {
      setSaving(false);
    }
  };

  if (!consultation) {
    return null;
  }

  return (
    <div
      className="lawyer-create-case-overlay"
      onMouseDown={(e) => {
        if (
          e.target === e.currentTarget &&
          !saving
        ) {
          onClose();
        }
      }}
    >
      <div className="lawyer-create-case-modal">
        {/* HEADER */}
        <div className="lawyer-create-case-header">
          <div className="lawyer-create-case-header-left">
            <div className="lawyer-create-case-icon">
              <FontAwesomeIcon
                icon={faFileCirclePlus}
              />
            </div>

            <div>
              <h2>
                Tạo hồ sơ vụ án
              </h2>

              <p>
                Tạo hồ sơ từ yêu cầu tư vấn của
                khách hàng
              </p>
            </div>
          </div>

          <button
            type="button"
            className="lawyer-create-case-close"
            onClick={onClose}
            disabled={saving}
          >
            <FontAwesomeIcon
              icon={faXmark}
            />
          </button>
        </div>

        {/* CUSTOMER / CONSULTATION */}
        <div className="lawyer-create-case-source">
          <div>
            <span>
              Khách hàng
            </span>

            <strong>
              {consultation.clientName ||
                "--"}
            </strong>
          </div>

          <div>
            <span>
              Lĩnh vực
            </span>

            <strong>
              {consultation.practiceAreaName ||
                "--"}
            </strong>
          </div>

          <div>
            <span>
              Yêu cầu
            </span>

            <strong>
              {consultation.title ||
                "--"}
            </strong>
          </div>
        </div>

        {error && (
          <div className="lawyer-create-case-error">
            {error}
          </div>
        )}

        {/* FORM */}
        <form
          onSubmit={handleSubmit}
          className="lawyer-create-case-form"
        >
          <div className="lawyer-create-case-grid">
            {/* DOCKET */}
            <div className="lawyer-create-case-field">
              <label>
                Số hồ sơ <b>*</b>
              </label>

              <input
                type="text"
                name="docketNo"
                value={form.docketNo}
                onChange={handleChange}
                placeholder="VD: HS-2026-0001"
              />
            </div>

            {/* OPEN DATE */}
            <div className="lawyer-create-case-field">
              <label>
                Ngày mở hồ sơ
              </label>

              <div className="lawyer-create-case-date">
                <FontAwesomeIcon
                  icon={faCalendarDays}
                />

                <input
                  type="date"
                  name="openedAt"
                  value={form.openedAt}
                  onChange={handleChange}
                />
              </div>
            </div>
          </div>

          {/* TITLE */}
          <div className="lawyer-create-case-field">
            <label>
              Tiêu đề vụ án <b>*</b>
            </label>

            <input
              type="text"
              name="title"
              value={form.title}
              onChange={handleChange}
              placeholder="Nhập tiêu đề vụ án"
            />
          </div>

          {/* PRACTICE AREA */}
          <div className="lawyer-create-case-field">
            <label>
              Lĩnh vực pháp lý
            </label>

            <select
              name="practiceAreaId"
              value={form.practiceAreaId}
              onChange={handleChange}
            >
              <option value="">
                -- Chọn lĩnh vực --
              </option>

              {practiceAreas.map((area) => (
                <option
                  key={area.id}
                  value={area.id}
                >
                  {area.name ||
                    area.title}
                </option>
              ))}
            </select>
          </div>

          {/* COURT */}
          <div className="lawyer-create-case-field">
            <label>
              Tòa án
            </label>

            <input
              type="text"
              name="courtName"
              value={form.courtName}
              onChange={handleChange}
              placeholder="VD: Tòa án TP Hà Nội"
            />
          </div>

          {/* NEXT STEP */}
          <div className="lawyer-create-case-field">
            <label>
              Bước tiếp theo
            </label>

            <textarea
              name="nextStep"
              value={form.nextStep}
              onChange={handleChange}
              rows={3}
              placeholder="VD: Chuẩn bị hồ sơ, thu thập chứng cứ..."
            />
          </div>

          {/* INFO */}
          <div className="lawyer-create-case-info">
            <strong>
              Lưu ý
            </strong>

            <p>
              Hồ sơ này sẽ được tự động gắn với
              khách hàng và luật sư đang phụ trách
              yêu cầu tư vấn.
            </p>
          </div>

          {/* ACTIONS */}
          <div className="lawyer-create-case-actions">
            <button
              type="button"
              className="lawyer-create-case-cancel"
              onClick={onClose}
              disabled={saving}
            >
              Hủy
            </button>

            <button
              type="submit"
              className="lawyer-create-case-submit"
              disabled={saving}
            >
              <FontAwesomeIcon
                icon={faFloppyDisk}
              />

              {saving
                ? "Đang tạo..."
                : "Tạo hồ sơ vụ án"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}