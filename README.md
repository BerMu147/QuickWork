# QuickWork

A job-posting mobile application that connects people who need work done with people looking for work. Built with an ASP.NET Core Web API backend and a Flutter frontend.

## 📱 Applications

QuickWork consists of the following applications:

1. **Mobile App** (`QuickWork_Mobile`) - The primary app for browsing, posting, and applying to jobs on the go.
2. **WebAPI Backend** (`QuickWork.WebAPI`) - RESTful API that powers the mobile app.
3. **Email Subscriber** (`QuickWork.Subscriber`) - Background service that sends transactional emails.

## 🔐 Test Login Credentials

### Mobile App
- **Username:** `berinm`
- **Password:** `test`

> **Note:** Users can **browse jobs as a guest** (no login required). Logging in unlocks publishing, applying, "My Jobs", and the profile.

## 📧 Email Notifications

### Welcome Email
The system sends a welcome email when a new user registers.

- **Target:** `quickworkberinm@gmail.com`

> This is currently a notification hook and will be expanded automatically as the application grows (e.g. application status updates).

### Transport
The email service uses **Gmail SMTP** to send outbound messages. Configuration lives in the `EmailSenderService` and can be switched for production.

## 🏗️ Project Structure

```
QuickWork/
├── QuickWork.WebAPI/          # .NET Core Web API (Backend)
│   ├── Controllers/           # API Controllers (Users, JobPostings, ...)
│   ├── Helpers/               # JWT token helper, error handling
│   └── Program.cs             # Application entry point
│
├── QuickWork.Services/        # Business Logic Layer
│   ├── Database/              # Entity Framework Core, DbContext, DataSeeder
│   ├── Services/              # Service implementations
│   ├── Interfaces/            # Service interfaces
│   └── Helpers/               # Utility classes (email, password hashing)
│
├── QuickWork.Model/           # Data Transfer Objects (DTOs)
│   ├── Requests/              # Upsert/request models
│   ├── Responses/             # Response models
│   └── SearchObjects/         # Search/filter models
│
├── QuickWork.Subscriber/      # Background email notification service
│   ├── Services/              # Email sender and template services
│   └── Models/                # Notification models
│
├── Assets/                    # Brand assets (logo) used by the app
│
└── UI/                        # Flutter Applications
    └── QuickWork_Mobile/      # Mobile app (browse, publish, apply)
```

## 🛠️ Technology Stack

### Backend
- **ASP.NET Core** - Web API framework
- **Entity Framework Core** - ORM for database operations
- **SQL Server** - Database
- **JWT** - Token-based authentication
- **Swagger** - API documentation

### Frontend
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Provider** - State management
- **Dio** - HTTP networking
- **shared_preferences** - Local session persistence

## 🗄️ Database

The system uses SQL Server with Entity Framework Core. The database is seeded with:
- Test users (e.g. `berinm`)
- Job categories
- Cities and gender lookups
- Sample job postings
- Countries / cities for the Balkan region

## 🚀 Getting Started

### Prerequisites
- .NET SDK
- Flutter SDK
- SQL Server (or Docker)

### Running Locally

1. Start SQL Server and configure the connection string in `appsettings.json`.
2. Run the **QuickWork.WebAPI** project (the API will seed the database on startup).
3. Start **QuickWork.Subscriber** if email notifications are needed.
4. Run the Flutter mobile app from `QuickWork/UI/QuickWork_Mobile/`:
   ```bash
   flutter pub get
   flutter run
   ```

> **Note:** The mobile app is configured for a development backend at `https://192.168.0.15:7074` with a self-signed certificate. Update `AppConstants.apiBaseUrl` for your environment, and remove the self-signed handling for production.

## 📝 Features

- **Browse jobs as a guest** — no account required to view listings
- **User registration & login** (optional login, auto-login on register)
- **Job publishing** — post a job (category, city, payment, schedule)
- **Apply to jobs** — one-tap application with login-gating
- **My Jobs tab** — see published jobs and submitted applications
- **Profile tab** — view and edit profile details
- **Search & filtering** — find jobs by title, category, and city
- **Session persistence** across app restarts

## 🔒 Security

- JWT bearer-token authentication
- Password hashing with salt
- Role-based access control
- Actions are **account-gated**: browsing is public, but publishing/applying requires an account
- Input validation and exception handling

## 📄 License

See LICENSE file for details.
