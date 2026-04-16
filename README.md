# AL ASEL — Moroccan artisan marketplace (MVP)

Production-oriented hackathon stack: **Flutter** (clean architecture) + **Node.js / Express** + **Firestore** (or in-memory demo mode).

## Quick start — API (demo, no Firebase key)

```powershell
cd backend
npm install
$env:MEMORY_STORE='1'; $env:SEED_DEMO='1'; node src/index.js
```

- Health: `GET http://127.0.0.1:4000/api/v1/health`
- Price estimator (public): `GET /api/v1/estimate?category=painting&sqm=40`
- Authenticated routes use header `X-Demo-Uid: demo_client` or `demo_artisan` when `MEMORY_STORE=1`.

## Quick start — Flutter

1. Install Flutter SDK and add to PATH.
2. `cd mobile` then `flutter pub get`
3. Point the app to your API (default `http://127.0.0.1:4000/api/v1`). For Android emulator use `http://10.0.2.2:4000/api/v1`:

   `flutter run --dart-define=API_BASE=http://10.0.2.2:4000/api/v1`

## Product architecture

| Layer | Responsibility |
|--------|----------------|
| **Flutter app** | UI/UX, Riverpod state, REST client, optional Socket.IO client for chat rooms |
| **API** | Auth (Firebase ID token or demo UID), trust scoring, matching, price rules, persistence |
| **Firestore** | Collections: `users`, `artisanProfiles`, `serviceRequests`, `reviews`, `conversations`, `messages` |
| **Real-time** | Socket.IO rooms `conv:{conversationId}` + REST persistence |

### Trust Score (0–100)

Deterministic composite from: average rating, review count, response time, recent jobs, reported issues. See `backend/src/services/trustScore.service.js`.

### Smart matching

Weighted score: category fit, city/area, trust score, availability. See `backend/src/services/matching.service.js` and `GET /api/v1/artisans/match`.

### Price estimator

MAD bands per trade + optional per m² + urgency uplift. See `backend/src/services/priceEstimator.service.js`.

### Before / after proof

Portfolio items `type: before_after | image | video` on `artisanProfiles.portfolio`.

## Folder layout

```
backend/src/
  config/firebase.js      # Firebase Admin init
  db/index.js             # Firestore or MEMORY_STORE maps
  middleware/auth.js
  routes/v1.routes.js
  controllers/
  services/               # trust, matching, pricing
  seed/demoSeed.js
  realtime.js             # Socket.IO broadcast helper

mobile/lib/
  app/router.dart
  core/theme/             # Moroccan palette + Cairo (Google Fonts)
  core/config/api_config.dart
  core/network/api_client.dart
  data/models/
  data/repositories/
  presentation/screens/
  presentation/widgets/   # zellij-inspired background
```

## API (v1)

| Method | Path | Notes |
|--------|------|--------|
| GET | `/health` | Liveness |
| GET | `/estimate` | Query: `category`, `sqm`, `urgency` |
| POST | `/users/bootstrap` | Body: `role`, `displayName`, `city` |
| GET | `/users/me` | Current user |
| GET | `/artisans` | Filters: `category`, `city`, `minRating`, `available` |
| GET | `/artisans/match` | Query: `category`, `city`, `urgency` |
| GET | `/artisans/:id` | Public profile + trust |
| PUT | `/artisans/profile` | Artisan profile |
| POST | `/artisans/portfolio` | Before/after item |
| POST | `/requests` | Client service request |
| GET | `/requests/mine` | Client |
| GET | `/requests/inbox` | Artisan open jobs in their categories |
| POST | `/reviews` | Create review; recomputes artisan stats |
| GET | `/artisans/:artisanId/reviews` | List reviews |
| GET/POST | `/conversations` | Thread list / open conversation |
| GET/POST | `/conversations/:id/messages` | Chat + Socket.IO fan-out |

## Data models (examples)

**User**

```json
{
  "id": "uid_123",
  "role": "client",
  "displayName": "Salma",
  "phone": "+212600000000",
  "city": "Rabat"
}
```

**ArtisanProfile**

```json
{
  "id": "uid_artisan",
  "userId": "uid_artisan",
  "displayName": "Hassan Peinture",
  "bio": "Finitions propres, délais respectés.",
  "categories": ["painting", "tiling"],
  "serviceAreas": ["Casablanca", "Mohammedia"],
  "portfolio": [
    {
      "id": "pf_1",
      "type": "before_after",
      "beforeUrl": "https://...",
      "afterUrl": "https://...",
      "caption": "Salle de bain — zellige moderne"
    }
  ],
  "available": true,
  "public": true,
  "avgRating": 4.8,
  "reviewCount": 24,
  "avgResponseHours": 3,
  "completedJobs90d": 9,
  "reportedIssues": 0
}
```

**Request**

```json
{
  "id": "req_abc",
  "clientId": "uid_client",
  "title": "Fuite sous évier",
  "description": "Urgent, étage 3",
  "category": "plumbing",
  "city": "Casablanca",
  "status": "open",
  "urgency": "urgent"
}
```

**Review**

```json
{
  "clientId": "uid_client",
  "artisanId": "uid_artisan",
  "requestId": "req_abc",
  "rating": 5,
  "text": "Très pro, à l’heure."
}
```

**Message**

```json
{
  "conversationId": "conv_id",
  "senderId": "uid_client",
  "text": "Bonjour, êtes-vous dispo samedi ?",
  "createdAt": "2026-04-16T12:00:00.000Z"
}
```

## UI screens (Flutter)

| Screen | Purpose |
|--------|---------|
| Splash | Brand mark + tagline |
| Home | Entry: Explore, Request, Artisan space |
| Explore | Category chips, city, artisan list with Trust |
| Artisan detail | Bio, rating, portfolio before/after |
| Request | Form + live price estimate |
| Artisan home | Bootstrap artisan + publish categories/zones |

## Branding — AL ASEL

- **Concept**: Hexagon = workshop / tile; inner star = zellij geometry; terracotta center = artisan handiwork; deep blue frame = trust and sea.
- **Colors**: Deep Blue `#1C3D5A`, Terracotta `#C56A3D`, Sand `#F4EDE4`, Gold `#C9A227`.
- **Typography**: **Cairo** (Google Fonts) — Latin + Arabic; clean, modern.
- **Asset**: `mobile/assets/branding/logo.svg`.

## Production Firebase

1. Create a Firebase project, enable **Firestore** and **Authentication**.
2. Download a service account JSON → set `GOOGLE_APPLICATION_CREDENTIALS` in `.env`.
3. Flutter: add `firebase_core` + `firebase_auth`, send `Authorization: Bearer <idToken>` and remove `MEMORY_STORE` on the server.

## Scale & roadmap

- **Payments**: Stripe/CMI escrow + milestone release.
- **Geo**: PostGIS or Firestore geoqueries for radius search.
- **Trust**: fraud signals, SLA on first response, verified ID (KYC).
- **Notifications**: FCM for mobile + email/SMS for OTP.
- **Moderation**: report queue, portfolio image scanning.
- **Artisan ops**: calendar sync, routing, spare parts marketplace.

---

Built for hackathon demos: use `MEMORY_STORE=1` + `SEED_DEMO=1` for instant judges’ walkthrough.
