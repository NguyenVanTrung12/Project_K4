const API_BASE_URL =
  import.meta.env.VITE_API_URL ||
  "http://localhost:5000/api";


// =========================================================
// TOKEN
// =========================================================

export function getToken() {
  return (
    localStorage.getItem("themis_token") ||
    sessionStorage.getItem("themis_token")
  );
}


// =========================================================
// CURRENT USER
// =========================================================

export function getCurrentUser() {
  try {
    const raw =
      localStorage.getItem("themis_user") ||
      sessionStorage.getItem("themis_user");

    return raw ? JSON.parse(raw) : null;
  } catch (error) {
    console.error("Không thể đọc thông tin người dùng:", error);
    return null;
  }
}


// =========================================================
// SAVE AUTH
// =========================================================

export function saveAuth(data, remember = true) {
  const storage = remember
    ? localStorage
    : sessionStorage;

  // Xóa auth cũ
  localStorage.removeItem("themis_token");
  localStorage.removeItem("themis_user");

  sessionStorage.removeItem("themis_token");
  sessionStorage.removeItem("themis_user");

  // Lưu auth mới
  storage.setItem(
    "themis_token",
    data.token
  );

  storage.setItem(
    "themis_user",
    JSON.stringify(data.user)
  );
}


// =========================================================
// LOGOUT
// =========================================================

export function logout() {
  localStorage.removeItem("themis_token");
  localStorage.removeItem("themis_user");

  sessionStorage.removeItem("themis_token");
  sessionStorage.removeItem("themis_user");
}


// =========================================================
// REQUEST
// =========================================================

async function request(path, options = {}) {

  const headers = new Headers(
    options.headers || {}
  );


  // =======================================================
  // CONTENT-TYPE
  //
  // Nếu gửi FormData:
  // Không được tự set application/json.
  //
  // Browser sẽ tự tạo:
  // multipart/form-data; boundary=...
  // =======================================================

  if (
    !(options.body instanceof FormData) &&
    options.body !== undefined &&
    options.body !== null
  ) {
    headers.set(
      "Content-Type",
      "application/json"
    );
  }


  // =======================================================
  // TOKEN
  // =======================================================

  const token = getToken();

  if (token) {
    headers.set(
      "Authorization",
      `Bearer ${token}`
    );
  }


  // =======================================================
  // URL
  // =======================================================

  const url =
    `${API_BASE_URL}${path}`;


  console.log(
    `${options.method || "GET"} ${url}`
  );


  // =======================================================
  // DEBUG REQUEST BODY
  // =======================================================

  if (options.body) {

    if (options.body instanceof FormData) {

      console.log(
        "REQUEST BODY: [FormData]"
      );

      // In danh sách field của FormData để dễ debug
      for (const [key, value] of options.body.entries()) {

        if (value instanceof File) {
          console.log(
            `FormData ${key}:`,
            value.name,
            value.type,
            value.size
          );
        } else {
          console.log(
            `FormData ${key}:`,
            value
          );
        }
      }

    } else {

      try {

        console.log(
          "REQUEST BODY:",
          JSON.parse(options.body)
        );

      } catch {

        console.log(
          "REQUEST BODY:",
          options.body
        );

      }
    }
  }


  // =======================================================
  // FETCH
  // =======================================================

  let response;

  try {

    response = await fetch(
      url,
      {
        ...options,
        headers,
      }
    );

  } catch (error) {

    console.error(
      "FETCH ERROR:",
      error
    );

    throw new Error(
      "Không thể kết nối đến máy chủ API. " +
      "Hãy kiểm tra Backend đã chạy chưa."
    );
  }


  // =======================================================
  // ĐỌC RESPONSE
  // =======================================================

  let body = null;

  const contentType =
    response.headers.get(
      "content-type"
    ) || "";


  try {

    if (
      contentType.includes(
        "application/json"
      ) ||
      contentType.includes(
        "problem+json"
      )
    ) {

      body = await response.json();

    } else {

      const text =
        await response.text();

      if (text) {

        try {

          body = JSON.parse(text);

        } catch {

          body = {
            message: text,
          };

        }
      }
    }

  } catch (error) {

    console.error(
      "RESPONSE PARSE ERROR:",
      error
    );

    body = null;
  }


  // =======================================================
  // ERROR
  // =======================================================

  if (!response.ok) {

    console.error(
      "API ERROR STATUS:",
      response.status
    );

    console.error(
      "API ERROR BODY:",
      body
    );


    let message =
      `API ${response.status}`;


    if (body) {

      // ---------------------------------------------------
      // Controller trả:
      //
      // { message: "..." }
      // ---------------------------------------------------

      if (body.message) {

        message =
          body.message;

      }


      // ---------------------------------------------------
      // Backend trả detail
      // ---------------------------------------------------

      if (body.detail) {

        message +=
          `\n\nChi tiết Backend:\n${body.detail}`;

      }


      // ---------------------------------------------------
      // ValidationProblemDetails
      // ---------------------------------------------------

      if (
        body.errors &&
        typeof body.errors === "object"
      ) {

        const validationMessages =
          [];


        Object.entries(
          body.errors
        ).forEach(
          ([field, messages]) => {

            if (
              Array.isArray(messages)
            ) {

              messages.forEach(
                (msg) => {

                  validationMessages.push(
                    `${field}: ${msg}`
                  );

                }
              );

            } else if (
              messages
            ) {

              validationMessages.push(
                `${field}: ${messages}`
              );

            }

          }
        );


        if (
          validationMessages.length > 0
        ) {

          message +=
            "\n\nLỗi validation:\n" +
            validationMessages.join(
              "\n"
            );

        }
      }
    }


    // ---------------------------------------------------
    // Một số API có thể trả lỗi dạng:
    //
    // { error: "..." }
    // ---------------------------------------------------

    if (
      body &&
      body.error &&
      !body.message
    ) {

      message =
        body.error;

    }


    throw new Error(message);
  }


  // =======================================================
  // 204 NO CONTENT
  // =======================================================

  if (response.status === 204) {
    return null;
  }


  // =======================================================
  // RETURN
  // =======================================================

  return body;
}


// =========================================================
// API
// =========================================================

export const api = {

  // =======================================================
  // GET
  // =======================================================

  get: (path) =>
    request(path),


  // =======================================================
  // POST
  //
  // Hỗ trợ:
  // - JSON
  // - FormData
  // =======================================================

  post: (path, body) =>
    request(
      path,
      {
        method: "POST",

        body:
          body instanceof FormData
            ? body
            : JSON.stringify(body),
      }
    ),


  // =======================================================
  // PUT
  // =======================================================

  put: (path, body) =>
    request(
      path,
      {
        method: "PUT",

        body:
          body instanceof FormData
            ? body
            : JSON.stringify(body),
      }
    ),


  // =======================================================
  // PATCH
  // =======================================================

  patch: (path, body) =>
    request(
      path,
      {
        method: "PATCH",

        body:
          body instanceof FormData
            ? body
            : JSON.stringify(body),
      }
    ),


  // =======================================================
  // DELETE
  // =======================================================

  delete: (path) =>
    request(
      path,
      {
        method: "DELETE",
      }
    ),


  // =======================================================
  // UPLOAD
  //
  // Dùng cho:
  // - Avatar
  // - Hình ảnh luật sư
  // - Hình ảnh khách hàng
  // - File
  //
  // Ví dụ:
  //
  // const formData = new FormData();
  // formData.append("file", selectedFile);
  //
  // await api.upload(
  //   `/users/${userId}/avatar`,
  //   formData
  // );
  // =======================================================

  upload: (path, formData) => {

    if (!(formData instanceof FormData)) {

      throw new Error(
        "api.upload() yêu cầu FormData."
      );

    }

    return request(
      path,
      {
        method: "POST",
        body: formData,
      }
    );
  },

};


// =========================================================
// DEFAULT
// =========================================================

export default API_BASE_URL;