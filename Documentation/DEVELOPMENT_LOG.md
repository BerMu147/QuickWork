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
| S6 | Job detail + Apply flow (login-gating) | ✅ Done | Application submission |
| S7 | Publish Job form | ✅ Done | For logged-in users, "+" FAB |
| S8 | "My Jobs" tab | ✅ Done | Published jobs + applications |
| S9 | Profile tab | ✅ Done | User info + edit |
| Polish | Splash screen, README, search & filters | ✅ Done | Logo splash, README, + search screen |

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

### ✅ S6 — Job Detail + Apply Flow (Login-gating)
- Full job detail view (description, schedule, duration, payment).
- **Apply button** with **login-gating**: guests tapping Apply are prompted to log in first; logged-in users apply directly.
- `POST /JobApplications` submission via repository/provider.
- Success feedback + "Applied" state; application error display.
- "Log in to apply" vs "Apply for this job" contextual button label.
- Integration test: logged-in user can apply, verified against live backend.

### ✅ S7 — Publish Job Form
- Full publish form: title, description, category, city, address, payment, duration, scheduled date, start/end time.
- **Category lookup** added (15 categories; endpoint requires auth — fits account-gated publishing).
- **"+" Publish FAB** on the Jobs tab, shown only to **logged-in users**.
- `POST /JobPostings` via repository/provider; new job appears at the top of the feed.
- Added `intl` dependency for date/time formatting.
- Integration test: logged-in user can publish, verified against live backend.

### ✅ S8 — "My Jobs" Tab
- Replaced the "My Jobs" placeholder with a real tab showing the **published jobs** and **my applications**.
- Two sub-tabs: **Published** (jobs I posted, with status) and **Applications** (jobs I applied to, application status).
- **Login-gated**: a guest opening the tab is prompted to log in.
- Repository: added `postedByUserId` filter, `fetchJobsForUser()` and `fetchApplicationsForJob()`.
- Provider: added `myJobPostings`, `isLoadingMyJobs`, `loadMyJobs()` (loads posts + applications in parallel).
- Integration test: logged-in user can fetch their posted jobs & applications, verified against live backend.

### ✅ S9 — Profile Tab
- Replaced the "Profile" placeholder with a real tab showing the logged-in user's **avatar (initials), full name, username, email, phone, city, gender**.
- **Login-gated**: guests are prompted to log in (matches My Jobs).
- **Edit profile** form: first/last name, email, phone, gender, city.
- Added `UserRepository` (`PUT /Users/{id}`, `GET /Users/{id}`) and `UserUpdateRequest`.
- `AuthProvider.updateUser()` refreshes the in-memory + persisted user after editing.
- All three bottom tabs are now fully implemented.
- Integration test: logged-in user can update their profile, verified against live backend (with safe round-trip restore).

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
- Live-backend integration tests pass (login, registration, job posting/lookup, job application, job publish, my-jobs, profile update).
- Backend integration tests require the backend to be running.

---

## To Be Aware Of (Future / Polish)
- **Welcome email** on registration — config target `quickworkberinm@gmail.com` in `EmailSenderService.cs`.
- **Opening animation video** (`QuickWork/Assets/QuickWork Load Video.mp4`) — considered but **not** wired in; the app uses a lightweight first-launch logo splash instead to keep startup fast and smooth.
- Remove self-signed cert handling before production.
- Job descriptions may have diacritics/encoding quirks in existing seed data.

---

## Polish Progress (Current Phase)

- **✅ First-launch logo splash** — added `SplashScreen` (fade-in branded logo), shown on first launch only (tracked via `shared_preferences`), then hands off to home. Deliberately **no video** to avoid startup lag/fragility.
- **✅ README corrected** — rewritten to describe the actual QuickWork job-posting app (previously an unrelated "eRent" template). Same section structure preserved.
- **✅ Search & filters** — dedicated `SearchJobScreen` (title keyword, category, city). A tappable search bar on the Jobs feed opens it; results reload the feed, with an active-filters chip + "clear filters". Reuses the backend's existing `JobPostingSearchObject` (no backend changes).

---

## Open Notes (Validated During Testing — For Polish Phase)

### Application status lifecycle (publisher side)
- Backend status values: **Pending, Accepted, Rejected, Withdrawn** (it's *Rejected*, not "Denied"). UI color-codes each.
- **Not yet clear how the publisher updates a candidate's status** (accept/reject) from within the app. Needs a publisher-side "review applications" UI + `PUT /JobApplications/{id}` update flow. *(Note taken — to implement in polish.)*

### Contact / communication flow
- After an application is **accepted**, the Publisher and Worker need to get in touch.
- **Open options to decide:** private contact via **phone number** and/or an **in-app messaging** system (`MessagesController` exists on the backend).
- *(Note taken — to decide & implement in polish.)*

### Trust / anti-scam measures
- **How to verify a user/publisher is real?** (e.g. could prevent unreasonable/fake job postings.)
- Possible future measures: verified profiles, phone verification on registration, enforce a valid contact method, moderation.
- *(Note taken — open design question; not part of the core sub-steps.)*

### User Profile Additional Features
- User can add custom skills so the publisher knows if it's related to something specific
- User can add previous work experiences. Nothing too descriptive, just the indication of experience
- User can leave the impression after finished job with publisher (worker<=>publisher) can be positive/negative/neutral
- On User profile overview there should be a count of total completed jobs (will be relevant for additional features)