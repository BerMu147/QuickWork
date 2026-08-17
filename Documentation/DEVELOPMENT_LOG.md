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
| Polish | Completed jobs counter | ✅ Done | Profile stat card; see detailed entry |
| Polish | Job status lifecycle ("Mark as Complete") | ✅ Done | Publisher: Open → InProgress → Completed |
| Polish | User custom skills | ✅ Done | Add/list/delete skills on Profile; see detailed entry |
| Polish | Work experience (Bio + work history) | ✅ Done | Profile Bio field + verified "Work history" card; see detailed entry |
| Polish | Reviews & rating | ✅ Done | Publisher⇄worker reviews + Profile rating card; see detailed entry |
| Bugfix | Applicant profile preview | ✅ Done | Tappable applicant → read-only profile (no shared-provider clobber) |
| Bugfix | Clear per-user state on logout | ✅ Done | Fixes skills/reviews/jobs bleed across accounts |
| Bugfix | Reviews: aggregate average + separate page | ✅ Done | Profile summary + "See reviews" → dedicated reviews list |

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
- Live-backend integration tests pass (login, registration, job posting/lookup, job application, job publish, my-jobs, profile update, publisher accept/reject, messaging).
- Backend integration tests require the backend to be running.

---

## To Be Aware Of (Future / Polish)
- **Welcome email** on registration — config target `quickworkberinm@gmail.com` in `EmailSenderService.cs`.
- **Push notifications** — **parked as a later / production feature.** See `Documentation/PUSH_NOTIFICATIONS_DESIGN.md` for the full design (FCM + RabbitMQ + DeviceTokens). Plan is: in-app notifications bell first (reuses existing `NotificationsController`, no backend change), then true push after Desktop ships.
- **Opening animation video** (`QuickWork/Assets/QuickWork Load Video.mp4`) — considered but **not** wired in; the app uses a lightweight first-launch logo splash instead to keep startup fast and smooth.
- Remove self-signed cert handling before production.
- Job descriptions may have diacritics/encoding quirks in existing seed data.

---

## Polish Progress (Current Phase)

- **✅ First-launch logo splash** — added `SplashScreen` (fade-in branded logo), shown on first launch only (tracked via `shared_preferences`), then hands off to home. Deliberately **no video** to avoid startup lag/fragility. Refined to show only the brand logo (the logo already contains the "QuickWork" text, so no separate heading).
- **✅ README corrected** — rewritten to describe the actual QuickWork job-posting app (previously an unrelated "eRent" template). Same section structure preserved.
- **✅ Search & filters** — dedicated `SearchJobScreen` (title keyword, category, city). A tappable search bar on the Jobs feed opens it; results reload the feed, with an active-filters chip + "clear filters". Reuses the backend's existing `JobPostingSearchObject` (no backend changes).
- **✅ Publisher review / Accept–Reject** — added `ReviewApplicationsScreen` reachable by tapping a published job in "My Jobs → Published". Lists each candidate (avatar initials, name, email, message, applied date) with **Accept / Reject** buttons. Uses the existing `PUT /JobApplications/{id}` endpoint; statuses update live and any accepted/rejected applications remove their action buttons. Updated `JobPostingRepository` + `JobPostingProvider` accordingly.
- **✅ Per-job messaging (publisher ↔ worker)** — in-app chat to coordinate job details without exposing contact info publicly. Added `MessageModel` / `MessageRepository` / `MessageProvider` + a `ConversationScreen` (chat bubbles, send box, auto-mark-incoming-as-read). Entry points: publisher → "Message" on an applicant in Review Applications; worker (logged in) → "Message the publisher" on the job detail page. Reuses the existing `MessagesController` (`POST/GET/PATCH mark-as-read`) — no backend changes.
- **✅ Completed jobs counter** — the Profile tab now shows a **"Completed Jobs"** stat card under the user's name. `JobPostingProvider.completedJobsCount` = published jobs with status `Completed` + the user's applications with status `Accepted`. Frontend-only (no backend/schema changes); the profile auto-loads My Jobs data when opened.
- **✅ Job status lifecycle ("Mark as Complete")** — published jobs could previously never leave `Open`, so the completed-jobs counter could never move. Added a **publisher-controlled workflow**: `Open → InProgress → Completed` (with a `Cancelled` path). Backend: new `ChangeStatusAsync` in `JobPostingService` (ownership check + transition validation, stamps `CompletedAt`) and endpoint **`PUT /JobPostings/{id}/status?postedByUserId=&status=`**. Frontend: `JobPostingRepository.updateJobStatus` + `JobPostingProvider.changeJobStatus`, and a **Job status card** on `ReviewApplicationsScreen` showing a color-coded badge with "Mark In Progress" / "Mark Complete" buttons. No schema/migration needed. **Requires a backend rebuild in VS.**

- **✅ User custom skills** — users can add custom skills to their profile so publishers can gauge relevance; skills render as chips (with delete) and a text field to add new ones. Backend: new `UserSkill` entity + `DbSet`, `UserSkillService` (duplicate-name guard, ownership check on delete, `UserException` validation) and `UserSkillsController` (`GET`, `GET/{id}`, `POST`, `PUT/{id}`, `DELETE/{id}`). Frontend: `UserSkillModel` / `UserSkillRepository` / `SkillProvider` + a **Skills card** on `ProfileScreen`. **DB migration applied via VS** (`Add-Migration` + `Update-Database`, e.g. `AddUserSkill`) — the `UserSkill` table is now live in SQL Server with a `SkillName` column. Verified by `flutter analyze` (0 issues) + widget tests (adds/removes skills against a fake repo).
- **✅ Work experience (Bio + verified work history)** — implemented as a searchable-free-text **"Bio"** plus a **platform-verified "Work history"** card (kept intentionally simple instead of a fabricated CV table).
  - **Bio (self-described):** new nullable `Bio` column (`MaxLength(500)`) on `Users`, wired through `UserUpsertRequest` / `UserResponse` / `UserService` (create/update/map). **DB migration applied via VS** (`AddMigration AddBioUser` → `Update-Database`) — the `Bio` column is live in `dbo.Users`. Frontend: a multiline **"Bio (optional)"** field on `EditProfileScreen` and italic display under the username on `ProfileScreen`.
  - **Work history (platform-verified, no schema):** a **"Work history"** card on the Profile listing — with a check icon each — published jobs marked `Completed` plus the user's accepted applications as a worker (de-duplicated, ordered); shows an empty state when none. Reuses `JobPostingProvider`'s My Jobs data (same definition as the completed-jobs counter).
    - **Tests:** `test/profile_screen_test.dart` updated to scroll to the user-details rows (the new card pushes them below the default test viewport). `flutter analyze` (0 issues) + widget tests pass.

- **✅ Reviews & rating (publisher ⇄ worker)** — after a job is **Completed**, either party can review the other, and every user's Profile shows their **average rating** and the reviews they've received.
  - **Review form:** a reusable `ReviewFormScreen` (modal bottom sheet) with a 1–5 **star picker**, optional comment, live submitting/error state. New `ReviewProvider` (`reviews`, `averageRating`, `isLoading`, `isSubmitting`, `submitError`, `hasReviewed`) wired through the existing backend `Review` service (no backend changes needed).
  - **Publisher → worker:** on `ReviewApplicationsScreen`, an **accepted worker of a Completed job** gets a **"Review"** button (switches to a disabled "Reviewed" badge once submitted).
  - **Worker → publisher:** on the job detail page, a hired worker (accepted application) of a **Completed** job gets a **"Review the publisher"** button (→ "You reviewed the publisher").
  - **Profile card:** a **"Reviews & rating"** card under the work history shows the average rating as stars + the received reviews (reviewer name, per-review stars, job title, comment), loaded via `ReviewProvider.loadForUser`. Reuses `ReviewProvider` added at the app root.
    - **Tests:** fixed tests that build tab/Profile screens (added `ReviewProvider` to `HomeScreen`, `ProfileScreen`, and `ReviewApplicationsScreen` providers); added `test/reviews_feature_test.dart` (profile rating, publisher review action/submission, no-review-on-open, review form). `flutter analyze` (0 issues) + widget tests pass.

---

## Pre-Desktop Bugfixes (done — Mobile app)

Three user-reported bugs were fixed in the Mobile app (`QuickWork/UI/QuickWork_Mobile/`) before starting the Desktop phase. **None required a backend rebuild or migration** (the backend filtering was already correct).

### ✅ Bugfix 1 — Publisher cannot view an applicant's profile overview
- Added a **tappable applicant tile** on `ReviewApplicationsScreen` (the avatar/name row, with a chevron affordance) that navigates to a new **`ApplicantProfileScreen`**.
- That screen is a **self-contained, read-only** view — it loads the **applicant's own data locally** via the repositories (`fetchUser`, `fetchSkillsForUser`, `fetchReviewsForUser`, `fetchAverageRating`, `fetchJobsForUser`, `fetchApplicationsForUser`) and **never mutates** the logged-in user's shared `SkillProvider`/`ReviewProvider`.
- Shows: name, username, bio, city, custom skills, average rating + received reviews, and a platform-verified completed-jobs count.
- Accepts optional repository injection for testability (defaults to real repos).
- **Tests:** `test/applicant_profile_screen_test.dart` (tap name opens profile; profile shows the applicant's data, not the viewer's).

### ✅ Bugfix 2 — Skills bleed across accounts (stale shared provider)
- **Root cause:** `SkillProvider` was created once at the app root and never cleared on logout, so one account's skills persisted into the next account's session.
- **Fix (clear-on-logout, approach 1):** added a `clear()` method to `SkillProvider`, `JobPostingProvider`, and `MessageProvider` (`ReviewProvider.clear()` already existed), and wired all four into the **logout handler in `home_screen.dart`** (the single logout call site) *before* `AuthProvider.logout()`.
- `JobPostingProvider.clear()` also resets the error/status message fields so no stale UI state persists.
- **Tests:** `test/auth_clear_on_logout_test.dart` (log in as user A, add skills, log out via the UI popup, assert shared `SkillProvider` is emptied so a subsequent account can't see A's skills).

### ✅ Bugfix 3 — Reviews: aggregate average + separate reviews page (UI change only)
- **Root cause:** the Profile `_buildReviews` rendered every received review inline on the card, and `ReviewProvider.clear()` was not wired on logout (same cross-user risk as Bugfix 2 — now covered by Bugfix 2's clear-on-logout).
- **Fix**
  1. Profile "Reviews & rating" card now shows a **single aggregate average rating** (stars + "N reviews" count) — no inline history.
  2. Beneath the average, a **"See reviews" button** (disabled when no reviews) opens a new **`ReviewsScreen`** page listing each received review individually (reviewer name, per-review stars, job title, comment).
  3. Clear-on-logout applied (see Bugfix 2).
- **Tests:** new `test/reviews_screen_test.dart` (empty state + individual review listing + aggregate average); updated `test/reviews_feature_test.dart` (profile shows aggregate only, then navigates to the dedicated page for the individual reviewers).

**All three bugfixes:** `flutter analyze` → 0 issues; offline widget tests pass, no backend rebuild/migration required.

---

## Open Notes (Validated During Testing — For Polish Phase)

### Application status lifecycle (publisher side)
- Backend status values: **Pending, Accepted, Rejected, Withdrawn** (it's *Rejected*, not "Denied"). UI color-codes each.
- ✅ **Implemented** in polish: publisher reviews applications for their job (My Jobs → Published → tap the job) and can **Accept/Reject** via `PUT /JobApplications/{id}`. Statuses appear in the "Applications" tab of My Jobs too.

### Contact / communication flow
- After an application is **accepted**, the Publisher and Worker need to get in touch.
- ✅ **Implemented in polish:** per-job in-app messaging (publisher ↔ worker) to coordinate details — no public contact exposure. Initiated from the Review Applications screen or the job detail page.
- *(Optionally, a future "Messages" inbox tab could aggregate all conversations; currently threads are reached per job.)*

### Trust / anti-scam measures
- **How to verify a user/publisher is real?** (e.g. could prevent unreasonable/fake job postings.)
- Possible future measures: verified profiles, phone verification on registration, enforce a valid contact method, moderation.
- *(Note taken — open design question; not part of the core sub-steps.)*

### User Profile Additional Features
- ✅ **Done** — user custom skills (add/list/delete on Profile). Backend `UserSkill` table/service/controller + frontend `SkillProvider`/`SkillRepository`/Skills card. **`UserSkill` EF migration created & applied via VS** — the table is live in the DB with a `SkillName` column.
- User can add previous work experiences. Nothing too descriptive, just the indication of experience — **✅ Done** — implemented as a **"Bio"** free-text field (self-described experience) + a **platform-verified "Work history"** card (completed jobs). See the Polish Progress entry above.
- User can leave the impression after finished job with publisher (worker<=>publisher) can be positive/negative/neutral — **✅ Done** — the backend `Review` service is now wired to the frontend: a `ReviewFormScreen` (star rating + comment) launched from an accepted worker's tile (publisher→worker) and from the job detail page (worker→publisher) once a job is **Completed**; users see their average rating + reviews on Profile. See the Polish Progress entry above. *(Currently a fixed 1–5 star rating is used rather than separate positive/negative/neutral sentiment.)*
- ✅ **Done** — completed jobs count on the profile, plus the **"Mark as Complete"** workflow it depends on.

---

## Desktop App (QuickWork_Desktop) — IN PROGRESS / READY (mirror of Mobile)

> Separate Flutter app under `QuickWork/UI/QuickWork_Desktop/`, per project requirements. It **mirrors the completed Mobile app** (same features, same backend), with a **responsive navigation shell** added for desktop. The Admin console is a **separate** app (`QuickWork_Admin/`), which is the next phase.

### ✅ Desktop — Scaffolding (two separate apps)
- Per project requirements, the Desktop part is **two separate Flutter applications**:
  - `QuickWork/UI/QuickWork_Desktop/` — the normal user app (mirrors Mobile).
  - `QuickWork/UI/QuickWork_Admin/` — a standalone **Administrator** console (reports, analytics, user/job/review moderation, support). **Next phase.**
- Both scaffolded with `flutter create --org ba.quickwork` for **all cross-platform targets**: `windows, linux, macos, android, ios, web`.
- Project names: `quickwork_desktop` and `quickwork_admin`. Org matches the Mobile app (`ba.quickwork`).
- Both have the full platform scaffold (`android/ ios/ lib/ linux/ macos/ test/ web/ windows/`) + `pubspec.yaml` + `analysis_options.yaml`.
- Committed: `906f6a9` (Admin scaffold), `068b84d` (Desktop scaffold).

### ✅ Desktop — Port of Mobile (mirror)
- Copied the proven Mobile architecture into `QuickWork_Desktop`: `core/` (`api`, `theme`, `constants`), `features/` (`auth`, `jobs`, `lookup`, `reviews`, `splash`, `home`), `app/`, `main.dart`.
- Fixed the package namespace `package:quickwork_mobile/` → `package:quickwork_desktop/`.
- Added the Mobile dependencies to `pubspec.yaml` (`dio`, `provider`, `go_router`, `shared_preferences`, `intl`) + the `assets/splash_logo.png` asset.
- Ported the offline widget tests (15 suites) with corrected imports.
- **Feature parity with Mobile:** auth (login/registration/session/JWT guest browse), job listings/detail/Apply/Publish, My Jobs (Published + Applications), Search & filters, publisher Accept/Reject (Review Applications), per-job messaging (Conversation), job status lifecycle ("Mark as Complete"), Profile (edit, Bio, custom skills, work history, completed-jobs counter), Reviews & rating + dedicated Reviews screen, developer-profile preview (ApplicantProfile), clear-on-logout.
- **Verification:** `flutter analyze` → 0 issues; **31 offline widget tests pass.**
- Committed: `b523389` (Desktop Port Mirroring of Mobile).

### ✅ Desktop — Responsive navigation polish
- Replaced the fixed bottom-nav shell with a **width-aware responsive layout** in `HomeScreen`:
  - **Wide screens (≥ 600px logical width — desktop, tablet landscape):** a left-hand **`NavigationRail`** with **Jobs / My Jobs / Profile** destinations, plus a **"publish a job" "+" icon** docked to the top of the rail (shown only to logged-in users; guests see the login icon). No bottom bar.
  - **Narrow screens (< 600px — phones):** the original **`BottomNavigationBar`** with the floating "Publish" **FAB** on the Jobs tab.
  - The rail uses `labelType: NavigationRailLabelType.all` (icons + labels). NOTE: `extended: true` was intentionally **not** combined with `labelType: all` because that combination triggers a Flutter `NavigationRail` assertion — the conflict was resolved by dropping `extended`.
- Same logic preserved: account popup menu, logout-with-clear-on-logout, guest login-gating, all three tab screens.
- **Tests:** added 2 tests to `test/home_screen_test.dart` — wide screen shows `NavigationRail` and **no** bottom bar; narrow screen shows `BottomNavigationBar` and no rail (uses `tester.view.physicalSize`/`devicePixelRatio` to set the logical viewport).
- **Verification:** `flutter analyze` → 0 issues; **31 offline widget tests pass.**
- ⚠️ **Uncommitted** (user commits): `lib/features/home/screens/home_screen.dart`, `test/home_screen_test.dart`.

> **Note on tooling:** the Desktop `pubspec.yaml` and the first `home_screen.dart` rewrite suffered **whitespace/encoding corruption** via PowerShell `Set-Content` (non-UTF-8 output broke the Dart analyzer's file discovery). Both were rewritten cleanly (`pubspec.yaml` via direct file write; `home_screen.dart` via the file tool in proper UTF-8).

---

## Admin App (QuickWork_Admin) — NEXT PHASE (planned)

Scaffolded but not yet built (`QuickWork/UI/QuickWork_Admin/`). See `AI_Instructions_Desktop2.md` for the full handoff. Scope (from project requirements), to confirm/refine with the user:
1. **Overview by job offer / job demand categories** (analytics).
2. Adding new jobs/services.
3. Sending relevant notifications to users.
4. Communication between users via messages.
5. Sending a request for a requested job / offered service.
6. Job request confirmation.
7. Connecting users and work duties.
8. Adding services offered on the personal profile.
9. Business execution analytics (user profile).
10. Editing the user profile.
11. **Administration panel for managing the application** (the admin console / dashboard — reports, support, requests, analytics).
12. Business reports (exportable).

**Note:** **Payments** are explicitly deferred — the user is unsure whether a PayPal service is required or whether it will be removed entirely; confirm before building anything payment-related.