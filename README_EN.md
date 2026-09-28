# Themis Trust

## Legal Technology Platform

**Themis Trust** is a legal service platform consisting of a **Mobile App, Website, Backend API, and Database**, designed to connect clients with lawyers affiliated with the company.

### Main features

**Clients**
- View legal information and content.
- Search for lawyers.
- Register / log in.
- Book consultations.
- Submit consultation requests.
- Chat with lawyers.
- Track requests and appointments.

**Lawyers**
- Log in using an assigned account.
- Receive and review consultation requests.
- Manage consultation schedules.
- Chat with clients.
- Create and manage case records.
- Manage related documents.

---

## 1. Technology Stack

| Component | Technology | Version |
|---|---|---|
| Mobile | Flutter / Dart | Flutter 3.x / Dart 3.x |
| Backend | ASP.NET Core | .NET 8 |
| Frontend | ReactJS | React 18+ |
| Database | Microsoft SQL Server | SQL Server 2019 |
| ORM | Entity Framework Core | EF Core 8 |
| API | RESTful API | - |
| Authentication | JWT | - |

> If the source code contains `pubspec.yaml`, `package.json`, or `.csproj`, use the versions defined there as the source of truth.

---

## 2. Architecture

```text
Flutter Mobile App ─┐
                    ├── RESTful API ──> ASP.NET Core 8 ──> SQL Server 2019
ReactJS Website ────┘
```

---

## 3. Recommended Project Structure

```text
ThemisTrust/
├── Backend/
├── Frontend/
├── Mobile/
└── README.md
```

---

# 4. Development Environment

## Backend

Install:

- .NET 8 SDK
- Visual Studio 2022 or VS Code
- SQL Server 2019
- SQL Server Management Studio (SSMS)

Check:

```bash
dotnet --version
dotnet --list-sdks
```

The installed SDK should include .NET 8.x.

---

## Frontend

Install:

- Node.js LTS
- npm
- VS Code

Check:

```bash
node --version
npm --version
```

---

## Mobile

Install:

- Flutter SDK
- Dart SDK included with Flutter
- Android Studio
- Android SDK
- Android Emulator or physical Android device

Check:

```bash
flutter --version
flutter doctor
flutter devices
```

If Android licenses have not been accepted:

```bash
flutter doctor --android-licenses
```

---

# 5. Install and Configure SQL Server 2019

Install **Microsoft SQL Server 2019 Database Engine** and SSMS.

Example:

```text
Server: localhost
Database: ThemisTrustDB
Authentication: Windows Authentication
```

Or:

```text
Server: localhost\SQLEXPRESS
Database: ThemisTrustDB
Authentication: SQL Server Authentication
```

The actual server name depends on your installation.

## Create the database with EF Core

If migrations already exist:

```bash
cd Backend
dotnet ef database update
```

If the project contains:

```text
database.sql
```

open it in SSMS and execute it.

---

# 6. Backend – ASP.NET Core 8

## 6.1. Restore packages

```bash
cd Backend
dotnet restore
```

## 6.2. Install EF Core CLI

If not installed:

```bash
dotnet tool install --global dotnet-ef
```

Check:

```bash
dotnet ef --version
```

## 6.3. Configure the database

Open:

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

Never commit real passwords to GitHub.

## 6.4. Database migration

If migrations already exist:

```bash
dotnet ef database update
```

After changing models, create a new migration:

```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

## 6.5. Run the Backend

```bash
dotnet run
```

Or:

```bash
dotnet watch run
```

The terminal will show the actual URL, for example:

```text
http://localhost:5000
https://localhost:7000
```

If Swagger is enabled:

```text
https://localhost:<PORT>/swagger
```

---

# 7. Frontend – ReactJS

## 7.1. Install dependencies

```bash
cd Frontend
npm install
```

## 7.2. Configure the Backend API

If the project uses Vite, create/update `.env`:

```env
VITE_API_URL=https://localhost:7000/api
```

Example Axios configuration:

```javascript
import axios from "axios";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL
});

export default api;
```

Restart the development server after changing `.env`.

## 7.3. Run ReactJS

```bash
npm run dev
```

Usually available at:

```text
http://localhost:5173
```

---

# 8. Mobile – Flutter / Dart

## 8.1. Install dependencies

```bash
cd Mobile
flutter pub get
```

Check the code:

```bash
flutter analyze
```

## 8.2. Configure the Backend API

An Android Emulator should not normally use `localhost` to access the Backend running on the host computer.

Use:

```text
10.0.2.2
```

Example:

```dart
const String baseUrl = "http://10.0.2.2:5000/api";
```

`10.0.2.2` represents the host computer from an Android Emulator.

### Physical Android device

If the phone and computer are on the same LAN, use the computer's LAN IP:

```dart
const String baseUrl = "http://192.168.1.100:5000/api";
```

The actual IP depends on your network.

## 8.3. Run Flutter

Check devices:

```bash
flutter devices
```

Run:

```bash
flutter run
```

Or:

```bash
flutter run -d <device-id>
```

---

# 9. Run the Complete System

Use three terminals.

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

## Startup order

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

# 10. Verify the System

### Database

Open SSMS and verify:

```text
ThemisTrustDB
```

### Backend

Open:

```text
https://localhost:<PORT>/swagger
```

### ReactJS

Open:

```text
http://localhost:5173
```

### Flutter

Test:

- Login.
- Lawyer search.
- Appointment booking.
- Consultation request.
- Chat.
- API communication.

---

# 11. Common Issues

## Backend cannot connect to SQL Server

Check:

```text
Server name
Database name
Username
Password
SQL Server service
Connection string
```

## EF Core migration error

Run:

```bash
dotnet ef database update
```

If the project truly has no migration:

```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

## ReactJS cannot call the API

Check:

```text
VITE_API_URL
```

Make sure the Backend is running.

Check CORS in ASP.NET Core.

Development example:

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

and:

```csharp
app.UseCors("AllowFrontend");
```

> Production should restrict allowed origins instead of using `AllowAnyOrigin()`.

## Flutter cannot connect to the Backend

Android Emulator:

```text
10.0.2.2
```

Physical device:

```text
Computer LAN IP
```

Make sure the firewall allows the Backend port.

---

# 12. Production Build

## ReactJS

```bash
npm run build
```

Output:

```text
dist/
```

## Flutter Android

```bash
flutter build apk --release
```

or:

```bash
flutter build appbundle --release
```

## Backend

```bash
dotnet publish -c Release
```

---

# 13. Security

Never commit:

```text
Database password
JWT secret
API secret
Private key
Production credentials
```

Use:

```text
.env
User Secrets
Environment Variables
Secret Manager
```

For production:

- Use HTTPS.
- Use a strong JWT secret.
- Restrict CORS.
- Use a database account with appropriate permissions.
- Avoid using `sa` when unnecessary.
- Validate user input.
- Apply Client / Lawyer authorization.

---

# 14. Business Workflow

```text
Find a Lawyer
    ↓
Book an Appointment
    ↓
Submit Consultation Request
    ↓
Lawyer Reviews Request
    ↓
Chat / Consultation
    ↓
Create Case Record
    ↓
Manage Case
```

---

## Themis Trust

**Legal Technology Platform**

> Connecting Clients and Lawyers through Technology.
