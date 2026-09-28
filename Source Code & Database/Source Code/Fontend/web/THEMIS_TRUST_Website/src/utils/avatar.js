// Đặt file này tại: src/utils/avatar.js

const API_ORIGIN = (
  import.meta.env.VITE_API_URL || "https://localhost:5001/api"
).replace(/\/api\/?$/, "");

// Backend trả đường dẫn tương đối, ví dụ "/uploads/avatars/abc.jpg".
// Hàm này ghép thêm địa chỉ backend để trình duyệt tải đúng chỗ.
export const toAvatarUrl = (url) => {
  if (!url) return "";

  const value = String(url).trim();

  if (
    value.startsWith("http://") ||
    value.startsWith("https://") ||
    value.startsWith("data:") ||
    value.startsWith("blob:")
  ) {
    return value;
  }

  return value.startsWith("/")
    ? `${API_ORIGIN}${value}`
    : `${API_ORIGIN}/${value}`;
};