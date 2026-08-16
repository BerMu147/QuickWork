# QuickWork — Push Notifications Design (DRAFT — for production, after Desktop phase)

> **Status: PARKED / FOR LATER (production feature).** Do **not** implement during the Desktop/Admin phase.
> This is a forward-looking design memo so we don't forget the plan. Reference only.
> **Decision recorded:** Push notifications are a *later / production* feature. First ship the lighter-weight **in-app notifications** (reuse existing backend), then add true push (Firebase Cloud Messaging + RabbitMQ) once Desktop ships and the product is proven.

---

## Why this is separate from what already exists

Your backend **already** has two relevant building blocks, but **neither** is "true mobile push":

1. **In-app `Notifications`** — `Notification` entity + `INotificationService` + `NotificationsController`
   (`GET /Notifications`, `GET /Notifications/{id}`, `POST`, `PATCH /{id}/mark-as-read`, `PATCH /mark-all-as-read`, `DELETE`).
   These are **DB rows** a user sees when the app is open. Reuse them for the in-app bell/list.

2. **RabbitMQ + `QuickWork.Subscriber`** — a background consumer (EasyNetQ / RabbitHutch) that currently
   subscribes to `JobPostingNotification` and **sends admin emails**. It already uses `docker-compose.yml`
   and `Dockerfile.notifications`. This is the **async/decoupling layer** — perfect to extend for push dispatch.

What is **missing** for true push: any **FCM/APNs integration**, a **`DeviceTokens`** registration table,
and a **push dispatcher** (consumer that forwards notifications to FCM). No `firebase_messaging` in the Flutter app yet.

---

## Definitions (so we don't conflate them)

- **In-app notification** — DB row shown in a bell/list while the app is open. Already built server-side.
- **True push notification** — OS-level popup/delivery even when the app is closed/backgrounded.
  Requires a vendor push service: **FCM** (Android + iOS via APNs) or APNs direct (iOS).

---

## When to do it (the "suitable time")

- **Now / Desktop phase:** implement the **in-app notifications bell** (low effort, no backend change,
  reuses `NotificationsController`). High value, low risk.
- **After Desktop ships:** implement **true push** as a full vertical feature.
  Good signals it's the right time: product is proven, you want OS prompts,
  you need fan-out to many users, or you want email + push + in-app in one asynchronous workflow.

---

## Proposed architecture (for later)

### 1. Device token registration (backend + DB)
- New table **`DeviceTokens`**: `Id`, `UserId`, `DeviceToken` (FCM token), `Platform` (android/ios/web),
  `CreatedAt`, `LastSeenAt`, maybe a `DeviceId`.
- New endpoint(s), e.g. **`POST /DeviceTokens`** (register/refresh), **`DELETE /DeviceTokens/{token}`** (logout/remove).
- **DB migration required** → backend rebuild in VS + `Add-Migration`/`Update-Database`.
  Managed by the user in VS.

### 2. Notification dispatch (backend, using RabbitMQ)
- Events that trigger a notification (e.g. application accepted/rejected, new message,
  job completed, someone reviewed you) **publish a message** on a queue (e.g. `PushNotifications` / `Notifications`).
- A consumer — extend **`QuickWork.Subscriber`** (or add a `PushDispatcher` worker) —
  receives the message, looks up the target user's **FCM tokens**, and calls **FCM HTTP v1 API**
  to deliver the OS notification. Also handles email via the existing email path.
- Keeps the API fast and resilient (fire-and-forget via the queue), consistent with the
  existing job-posting → email pattern.

### 3. Mobile (Flutter)
- Add the **`firebase_messaging`** package (plus `firebase_core`).
- **Foreground handler**: show/increment the in-app notification state or an OS notification.
- **Background handler** (`FirebaseMessaging.onBackgroundMessage`): required so notifications
  are handled/silent-pushed when the app is terminated/backgrounded.
- **Token lifecycle**: on login, register the current FCM token via `POST /DeviceTokens`;
  on logout, remove it. Refresh the token on `FirebaseMessaging.onTokenRefresh`.
- **Info.plist / manifest / Google-services**: needed config per platform (Google Services JSON for Android,
  APNs key + entitlements for iOS).

### 4. Permissions / UX
- Request notification permission at an appropriate moment (not at first launch).
- Provide a settings toggle (all / messages / applications / reviews / jobs).
- On tapping a push, deep-link to the relevant screen (job detail, conversation, application).

---

## Non-goals / caveats to remember

- **iOS push requires** a paid Apple Developer account + a real device + APNs provisioning.
- FCM config (`google-services.json` Android / `GoogleService-Info.plist` iOS) must **not** be committed.
- Self-signed dev cert handling and FCM/APNs do **not** mix — production only, clean TLS.
- Production push often means production-grade infrastructure; the current dev `https://192.168.0.15:7074`
  base URL and self-signed cert are dev-only and must be removed/changed together for real FCM delivery.

---

## Suggested order when we pick this up later

1. **Phase 1 (can be before/independent of push):** In-app notifications bell in Mobile (`GET /Notifications`,
   unread badge, mark-as-read). No backend change.
2. **Phase 2 (backend):** `DeviceTokens` migration + register/remove endpoints (VS rebuild + migration).
3. **Phase 3 (backend worker):** `PushDispatcher` consumer in/extending `QuickWork.Subscriber`
   (RabbitMQ) → FCM HTTP v1.
4. **Phase 4 (mobile):** `firebase_messaging`, background handler, token registration on login/logout,
   permission + settings, deep-linking.
5. **Verify** against a real device and the production backend config.

---

*See `Documentation/DEVELOPMENT_LOG.md` and `AI_Instructions_Desktop.md` for the current state and phase plan.*
