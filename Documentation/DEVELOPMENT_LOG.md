# QuickWork — Development Log

A live tracker of what's been built and what's next.

**Stack:** Flutter (mobile app) + ASP.NET Core WebAPI (backend) + MS SQL Server
**Mobile app path:** `QuickWork/UI/QuickWork_Mobile/`
**Backend path:** `QuickWork/QuickWork.WebAPI/`

---

## Progress Summary

| Sub-step | Feature | Status | Notes |
|----------|---------|--------|-------|
| S1 | App foundation (theme, entry point) | ✅ Done | Brand palette, provider wiring |
| S2 | API client + auth backbone | ✅ Done | Dio, JWT, AuthProvider, session persist |
| S3 | Login screen | ✅ Done | Optional login, guest entry, register link |
| S4 | Registration screen | ✅ Done | Gender/City lookups, auto-login |
| S5 | Job listings + navigation shell | ✅ Done | Bottom nav, guest browsing |
| S6 | Job detail + Apply flow (login-gating) | ⏳ Next | Application submission |
| S7 | Publish Job form | 🔲 | For logged-in users |
| S8 | "My Jobs" tab | 🔲 | Jobs I posted + applications |
| S9 | Profile tab | 🔲 | User info / edit |
| Polish | Search & filters, welcome email, splash/logo, push notifications | 🔲 | Notifications/config pending |

---

## Detailed Status

### ✅ S1 — App Foundation
- Flutter project for Android / iOS / Web / Windows.
- Brand theme: teal-blue (`#129ACA`), cyan secondary, cream background.
- `main.dart`, `app.dart` (root + provider wiring).

### ✅ S2 — API Client + Auth Backbone
- Dio HTTP client with JWT bearer-token interceptor.
- Base URL: `https://192.168.0.15:7074` (self-signed cert accepted for dev).
- `ApiException` error normalization.
- Auth models + `AuthRepository` (`POST /Users/authenticate`).
- `AuthProvider` with login/logout/session restore, persisted via `shared_preferences`.

### ✅ S3 — Login Screen
- Username/password form with validation, loading, error display.
- "Register now!" and "Continue as guest" options.
- Login is **optional** (guests can browse).

### ✅ S4 — Registration Screen
- Full form: first/last name, username, email, phone, gender, city, password.
- Genders & cities loaded from backend (`GET /Gender`, `GET /City`).
- `POST /Users` creates account, then **auto-login**.

### ✅ S5 — Job Listings + Navigation Shell
- Job model, repository, provider (list/loading/error states).
- Job card widget + Jobs feed (pull-to-refresh) + Job detail screen.
- Bottom navigation shell: **Jobs / My Jobs / Profile**.
- **Guest browsing enabled**: added `[AllowAnonymous]` to backend `Get`, `GetRecommended`, `GetById` in `JobPostingsController.cs`.

---

## Design Decisions
- **Login is optional** — guests can browse jobs freely.
- **Browsing is public; actions (apply/publish) require an account** (like an online shop — browse freely, check out with account).
- Session persists across app restarts.
- Self-signed dev certificate accepted in the app (remove for production).

---

## Testing Notes
- `flutter analyze` — no issues.
- Offline widget tests pass.
- Live-backend integration tests pass (login, registration, job posting fetch).
- Backend integration tests require the backend to be running.

---

## To Be Aware Of (Future / Polish)
- **Welcome email** on registration — config target `quickworkberinm@gmail.com` in `EmailSenderService.cs`.
- **Splash / logo screen** to be built by the user (app opens straight to home currently).
- Remove self-signed cert handling before production.
- Job descriptions may have diacritics/encoding quirks in existing seed data.
