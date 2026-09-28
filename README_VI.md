# Themis Trust

## Legal Technology Platform

**Themis Trust** là nền tảng dịch vụ pháp lý gồm **Mobile App, Website, Backend API và Database**, kết nối khách hàng với các luật sư trực thuộc công ty.

### Chức năng chính

**Khách hàng**
- Xem nội dung pháp lý.
- Tìm kiếm luật sư.
- Đăng ký / đăng nhập.
- Đặt lịch tư vấn.
- Gửi yêu cầu tư vấn.
- Trò chuyện với luật sư.
- Theo dõi yêu cầu và lịch hẹn.

**Luật sư**
- Đăng nhập bằng tài khoản được cấp.
- Tiếp nhận và xét duyệt yêu cầu tư vấn.
- Quản lý lịch tư vấn.
- Trò chuyện với khách hàng.
- Tạo và quản lý hồ sơ vụ án.
- Quản lý tài liệu liên quan.

---

## 1. Công nghệ

| Thành phần | Công nghệ | Phiên bản |
|---|---|---|
| Mobile | Flutter / Dart | Flutter 3.x / Dart 3.x |
| Backend | ASP.NET Core | .NET 8 |
| Frontend | ReactJS | React 18+ |
| Database | Microsoft SQL Server | SQL Server 2019 |
| ORM | Entity Framework Core | EF Core 8 |
| API | RESTful API | - |
| Authentication | JWT | - |

> Nếu source code đã có `pubspec.yaml`, `package.json` hoặc `.csproj`, hãy ưu tiên phiên bản được khai báo trong các file đó.

---

## 2. Kiến trúc

```text
Flutter Mobile App ─┐
                    ├── RESTful API ──> ASP.NET Core 8 ──> SQL Server 2019
ReactJS Website ────┘
```

---

## 3. Cấu trúc thư mục đề xuất

```text
ThemisTrust/
├── Backend/
├── Frontend/
├── Mobile/
└── README.md
```

---

# 4. Chuẩn bị môi trường

## Backend

Cài:

- .NET 8 SDK
- Visual Studio 2022 hoặc VS Code
- SQL Server 2019
- SQL Server Management Studio (SSMS)

Kiểm tra:

```bash
dotnet --version
dotnet --list-sdks
```

Kết quả cần có .NET 8.x.

---

## Frontend

Cài:

- Node.js LTS
- npm
- VS Code

Kiểm tra:

```bash
node --version
npm --version
```

---

## Mobile

Cài:

- Flutter SDK
- Dart SDK (đi kèm Flutter)
- Android Studio
- Android SDK
- Android Emulator hoặc Android phone

Kiểm tra:

```bash
flutter --version
flutter doctor
flutter devices
```

Nếu Android licenses chưa được chấp nhận:

```bash
flutter doctor --android-licenses
```

---

# 5. Cài và cấu hình SQL Server 2019

Cài **Microsoft SQL Server 2019 Database Engine** và SSMS.

Ví dụ cấu hình:

```text
Server: localhost
Database: ThemisTrustDB
Authentication: Windows Authentication
```

Hoặc:

```text
Server: localhost\SQLEXPRESS
Database: ThemisTrustDB
Authentication: SQL Server Authentication
```

Tên server thực tế phụ thuộc vào máy.

## Tạo database bằng EF Core

Nếu project đã có migrations:

```bash
cd Backend
dotnet ef database update
```

Nếu project có file SQL:

```text
database.sql
```

mở file bằng SSMS và Execute.

---

# 6. Backend – ASP.NET Core 8

## 6.1. Restore package

```bash
cd Backend
dotnet restore
```

## 6.2. Cài EF Core CLI

Nếu máy chưa có:

```bash
dotnet tool install --global dotnet-ef
```

Kiểm tra:

```bash
dotnet ef --version
```

## 6.3. Cấu hình database

Mở:

```text
Backend/appsettings.json
```

### Windows Authentication

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=ThemisTrustDB;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

### SQL Server Authentication

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=ThemisTrustDB;User Id=YOUR_USERNAME;Password=YOUR_PASSWORD;TrustServerCertificate=True;"
  }
}
```

Không commit password thật lên GitHub.

## 6.4. Migration

Nếu migration đã tồn tại:

```bash
dotnet ef database update
```

Nếu cần tạo migration mới sau khi thay đổi model:

```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

## 6.5. Chạy Backend

```bash
dotnet run
```

Hoặc:

```bash
dotnet watch run
```

Terminal sẽ hiển thị URL, ví dụ:

```text
http://localhost:5000
https://localhost:7000
```

Nếu có Swagger:

```text
https://localhost:<PORT>/swagger
```

---

# 7. Frontend – ReactJS

## 7.1. Cài dependencies

```bash
cd Frontend
npm install
```

## 7.2. Cấu hình Backend API

Nếu project dùng Vite, tạo hoặc chỉnh `.env`:

```env
VITE_API_URL=https://localhost:7000/api
```

Ví dụ Axios:

```javascript
import axios from "axios";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL
});

export default api;
```

Sau khi thay đổi `.env`, restart server.

## 7.3. Chạy ReactJS

```bash
npm run dev
```

Thông thường:

```text
http://localhost:5173
```

---

# 8. Mobile – Flutter / Dart

## 8.1. Cài dependencies

```bash
cd Mobile
flutter pub get
```

Kiểm tra code:

```bash
flutter analyze
```

## 8.2. Cấu hình Backend API

Android Emulator không nên dùng `localhost` để truy cập Backend trên máy tính.

Dùng:

```text
10.0.2.2
```

Ví dụ:

```dart
const String baseUrl = "http://10.0.2.2:5000/api";
```

`10.0.2.2` đại diện cho máy host khi chạy Android Emulator.

### Điện thoại thật

Nếu điện thoại và máy tính cùng mạng LAN, dùng IP LAN của máy tính:

```dart
const String baseUrl = "http://192.168.1.100:5000/api";
```

IP thực tế phụ thuộc mạng.

## 8.3. Chạy Flutter

Kiểm tra thiết bị:

```bash
flutter devices
```

Chạy:

```bash
flutter run
```

Hoặc:

```bash
flutter run -d <device-id>
```

---

# 9. Chạy toàn bộ hệ thống

Mở 3 terminal.

### Terminal 1 – Backend

```bash
cd Backend
dotnet restore
dotnet ef database update
dotnet run
```

### Terminal 2 – Frontend

```bash
cd Frontend
npm install
npm run dev
```

### Terminal 3 – Mobile

```bash
cd Mobile
flutter pub get
flutter run
```

## Thứ tự khởi động

```text
SQL Server
    ↓
ASP.NET Core 8 Backend
    ↓
ReactJS Website
    ↓
Flutter Mobile App
```

---

# 10. Kiểm tra hệ thống

### Database

Mở SSMS và kiểm tra:

```text
ThemisTrustDB
```

### Backend

Mở:

```text
https://localhost:<PORT>/swagger
```

### ReactJS

Mở:

```text
http://localhost:5173
```

### Flutter

Kiểm tra:

- Đăng nhập.
- Tìm luật sư.
- Đặt lịch.
- Gửi yêu cầu.
- Chat.
- Gọi API.

---

# 11. Các lỗi thường gặp

## Backend không kết nối SQL Server

Kiểm tra:

```text
Server name
Database name
Username
Password
SQL Server service
Connection string
```

## EF Core lỗi migration

```bash
dotnet ef database update
```

Nếu project thực sự chưa có migration:

```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

## ReactJS không gọi được API

Kiểm tra:

```text
VITE_API_URL
```

Backend phải đang chạy.

Kiểm tra CORS trong ASP.NET Core.

Ví dụ development:

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});
```

và:

```csharp
app.UseCors("AllowFrontend");
```

> Production nên giới hạn origin thay vì `AllowAnyOrigin()`.

## Flutter không kết nối được Backend

Android Emulator:

```text
10.0.2.2
```

Điện thoại thật:

```text
IP LAN của máy tính
```

Đảm bảo firewall cho phép port của Backend.

---

# 12. Build Production

## ReactJS

```bash
npm run build
```

Output thường:

```text
dist/
```

## Flutter Android

```bash
flutter build apk --release
```

hoặc:

```bash
flutter build appbundle --release
```

## Backend

```bash
dotnet publish -c Release
```

---

# 13. Bảo mật

Không commit:

```text
Database password
JWT secret
API secret
Private key
Production credentials
```

Có thể sử dụng:

```text
.env
User Secrets
Environment Variables
Secret Manager
```

Production nên:

- Sử dụng HTTPS.
- Sử dụng JWT secret mạnh.
- Giới hạn CORS.
- Dùng database account có quyền cần thiết.
- Không sử dụng `sa` nếu không cần.
- Validate dữ liệu đầu vào.
- Phân quyền Client / Lawyer.

---

# 14. Quy trình nghiệp vụ

```text
Tìm luật sư
    ↓
Đặt lịch
    ↓
Gửi yêu cầu tư vấn
    ↓
Luật sư xét duyệt
    ↓
Trò chuyện / tư vấn
    ↓
Tạo hồ sơ vụ án
    ↓
Quản lý vụ việc
```

---

## Themis Trust

**Legal Technology Platform**

> Connecting Clients and Lawyers through Technology.
