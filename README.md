# SwiftCinemas — iOS Client

> Native iOS client for the Cinemas movie ticket booking platform.

Copyright © 2015–2026 George Gaspar. All rights reserved.

## Overview

SwiftCinemas is the iOS front-end for the Cinemas platform — a full-stack cinema booking system with Quarkus microservices, MySQL databases, Kafka-based realtime notifications, and an AngularJS web client. The app provides:

- **User authentication** (login, registration, voucher activation)
- **Movie browsing** with paginated search and category filtering
- **Venue discovery** with MapKit integration and geofencing notifications
- **Seat selection** with real-time availability
- **Ticket purchasing** via Braintree (Cards & PayPal)
- **Purchase history** with ticket details, QR codes, and PDF export
- **Calendar integration** (iOS Calendar & Google Calendar)
- **Admin functions** for managing screenings and venues
- **WebSocket-based realtime** movie notifications
- **Firebase Cloud Messaging** for push notifications
- **WebView-based web login** as an alternative authentication path

## Architecture

### Backend Services

| Service | Port | Root Path | Purpose |
|---------|------|-----------|---------|
| `dalogin-quarkus` | 443 (TLS) | `/login` | Auth gateway, session management |
| `mbook-quarkus` | 8888 | `/mbook-1` | User/device/support API |
| `mbooks-quarkus` | 8080 | `/mbooks-1` | Movie/booking/payment API |
| `simple-service-webapp-quarkus` | 8085 | `/simple-service-webapp` | Image serving |

The app connects to `https://milo.crabdance.com` by default (configured in `URLManager.swift`).

### Request Flow

```
iOS App → NGINX Ingress (TLS) → Apache reverse-proxy → Backend services
```

### Networking Layer

The app employs three distinct request managers:

| Manager | Usage | Protocol |
|---------|-------|----------|
| `GeneralRequestManager` | All API calls (movies, venues, seats, booking, payments) | `URLSession` |
| `RequestManager` | WebView-originated login/session calls | `URLSession` |
| `RestApiManager` | Admin and activation requests | `URLSession` |

All managers share a singleton `URLSession` (`URLSession.sharedCustomSession`) configured via:
- **`CustomSessionConfiguration`** — enables HTTP pipelining, always-accept cookies
- **`CustomURLSessionDelegate`** — handles TLS certificate challenges (allows self-signed certs for dev hosts)
- **`CustomURLRequest`** — builds requests with JSON/URL-encoded/image content types and custom headers

### Security

- **HMAC-SHA512** authentication: login/registration requests include `X-HMAC-HASH` and `X-MICRO-TIME` headers
- **SHA3-512** password hashing (client-side, before sending)
- **AES-128 encryption** for ciphertext tokens (`Ciphertext` header) using PBKDF2 key derivation
- **XSRF-TOKEN** and **JSESSIONID** cookies for session management
- **X-Token** header for Ciphertext filter authentication
- Crypto operations use CryptoJS via JavaScriptCore (`CryptoJS.swift` + bundled `.js` files)

### Caching

| Layer | Technology | What it caches |
|-------|-----------|----------------|
| **CoreData** | `CachedURLResponse` entity | Web resources (HTML, JS, images) from WebView requests |
| **Realm** | `CachedResponse` objects | API responses (movies, venues) with 1-hour TTL |
| **URLCache** | Standard iOS URL cache | Protocol-level HTTP caching |

### Realtime

- **WebSocket** connection to `wss://milo.crabdance.com/mbook-1/ws` (via `URLManager.webSocketURL`) using native `URLSessionWebSocketTask`
- Sends ping every 30 seconds to keep the connection alive through NGINX/Apache proxies
- Auto-reconnects after 3 seconds on disconnection
- Receives movie notification broadcasts from Kafka consumers on the backend
- **Firebase Cloud Messaging** for push notifications (remote + local)
- **Geofencing** via `CLCircularRegion` — triggers local notifications when the user enters a 500m radius of a venue

## Screen Flow

```
LoginVC ──────────────┐
   │                  │
   ├→ SignupVC        │
   │                  │
   └→ HomeVC ─────────┘
        │
        ├→ MoviesVC (paginated, searchable, categorised)
        │    └→ VenuesVC (venues for selected movie)
        │         └→ VenuesDetailsVC (screening dates, seat map, media player)
        │              ├→ PopOverDates (date picker popover)
        │              ├→ SeatCells (seat grid with reservation state)
        │              ├→ iOSCalendarVC → AttendeesVC
        │              └→ BasketVC (selected seats → Braintree checkout)
        │
        ├→ WebViewController (AngularJS web UI in WKWebView)
        │
        ├→ MapViewController (all venue locations on MapKit)
        │    └→ VenuesVC (venues at selected location)
        │
        └→ MenuVC
             ├→ PurchasesVC (purchase history, sortable by date)
             │    └→ TicketsVC (tickets per purchase, QR codes, PDF export)
             └→ AdminVC (add new screenings)
                  ├→ MoviesVC (movie picker popover)
                  ├→ VenuesVC (venue picker popover)
                  └→ AdminUpdateVC (update existing screenings)
```

## Data Models

| Model | Fields | Source Endpoint |
|-------|--------|-----------------|
| `MoviesData` | movieId, name, detail, large_picture, imdb | `/mbooks-1/rest/book/movies/paging` |
| `SeatsData` | seatId, seatNumber, seatRow, isReserved, price, tax | `/mbooks-1/rest/book/seats/{id}` |
| `DatesData` | screeningDatesId, screeningDate, movieId | `/mbooks-1/rest/book/dates/{screenId}` |
| `BasketData` | movie_name, seatId, seat details, price, tax, screening info | Client-side (selected seats) |
| `PurchaseData` | orderId, purchaseId, movie_name, venue_name, dates | `/login/GetAllPurchases` |
| `AllTicketsData` | movie_name, venue_name, seat details, screening_date, ticketId | `/login/ManagePurchases` |
| `TicketsData` | movie_name, seat details, price, tax, ticketId | Booking response |
| `ScreenData` | ScreeningId, movie, venue, date, rows, seats | Admin add-screen response |
| `PlacesData` | locationId, title, address, coordinate, thumbnail | `/mbooks-1/rest/book/locations` |

## Dependencies (CocoaPods)

| Pod | Purpose |
|-----|---------|
| `SwiftyJSON` | JSON parsing |
| `Realm` | Local object caching (API responses) |
| `Braintree` | Payment processing (Cards) |
| `BraintreeDropIn` | Payment UI (Drop-In) |
| `FirebaseAuth` | Firebase Authentication |
| `FirebaseFirestore` | Firebase Firestore |
| `FirebaseMessaging` | Push notifications (FCM) |
| `Starscream` | WebSocket client (legacy, now replaced by native `URLSessionWebSocketTask`) |

## Building

### Prerequisites
- Xcode 15+ (Swift 5.x)
- CocoaPods (`gem install cocoapods`)

### Setup
```bash
cd SwiftCinemas
pod install
open SwiftCinemas.xcworkspace
```

> ⚠️ Always open the `.xcworkspace` file (not `.xcodeproj`) after installing pods.

### Configuration
- **Server URL**: Edit `baseHost` in `URLManager.swift` (single place for base host, all service paths, WebSocket URL, and image URL)
- **Self-signed hosts**: Automatically derived from `URLManager.baseHost` in `CustomURLSessionDelegate.swift`
- **Firebase**: Replace `FireBaseGoogleService-Info.plist` with your Firebase project config
- **Braintree**: Update the sandbox token in `BasketVC.swift`

### TLS / Self-Signed Certificates
If using self-signed certificates:
1. Create your own Certificate Authority (CA)
2. Install the CA on your server (Apache) and the iOS device/simulator
3. Add your host to `Constants.selfSignedHosts` in `CustomURLSessionDelegate.swift`
4. Configure App Transport Security exceptions in `Info.plist`

See: [Using Self-Signed SSL Certificates with iOS](https://blog.httpwatch.com/2013/12/12/five-tips-for-using-self-signed-ssl-certificates-with-ios/)

## API Endpoints Used

### Authentication (`/login`)
| Method | Path | Description |
|--------|------|-------------|
| POST | `/login/HelloWorld` | Login (HMAC-authenticated) |
| POST | `/login/register` | User registration |
| POST | `/login/voucher` | Voucher validation |
| POST | `/login/activation` | Account activation email |
| GET | `/login/logout` | Logout |
| GET | `/login/admin` | Admin session check |
| GET | `/login/index.html` | Web UI (WebView) |

### Movies & Booking (`/mbooks-1/rest/book`)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/movies/paging?setFirstResult=N` | Paginated movie list (30 per page) |
| GET | `/movies/paging?category=X` | Movies by category |
| GET | `/venue/{movieId}` | Venues showing a movie |
| GET | `/dates/{screenId}` | Screening dates for a venue/movie |
| GET | `/seats/{screeningDateId}` | Seat map for a screening |
| GET | `/locations` | All venue locations (for map + geofencing) |
| POST | `/admin/addscreen` | Add new screening (admin) |

### Purchases (proxied through `/login`)
| Method | Path | Description |
|--------|------|-------------|
| POST | `/login/CheckOut` | Book tickets + payment |
| GET | `/login/GetAllPurchases` | User's purchase history |
| GET | `/login/ManagePurchases?purchaseId=X` | Tickets for a purchase |

### Images (`/simple-service-webapp/webapi`)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/{image-path}` | Movie posters, venue photos, profile pictures |

## Debugging

### Network Debugging
- Enable `CFNETWORK_DIAGNOSTICS=3` (set in `AppDelegate.willFinishLaunchingWithOptions`)
- Use [Charles Web Proxy](https://www.charlesproxy.com/) for traffic inspection
- Safari Web Inspector for WKWebView debugging

### Database Locations
CoreData and Realm databases are stored in the app's Documents directory. Location is printed at launch:
```
dB location: file:///Users/.../Documents/
```
- **CoreData**: inspect with SQLite browser
- **Realm**: inspect with [Realm Studio](https://www.mongodb.com/docs/realm/studio/)

## Git Repository

```
git@github.com:igeorge0902/SwiftCinemas.git
```

## Related Repositories

| Repository | Description |
|-----------|-------------|
| [dalogin-quarkus](https://github.com/igeorge0902/dalogin-quarkus) | Auth gateway (Quarkus) |
| [mbook-quarkus](https://github.com/igeorge0902/mbook-quarkus) | User/device API (Quarkus) |
| [mbooks-quarkus](https://github.com/igeorge0902/mbooks-quarkus) | Movie/booking API (Quarkus) |
| [simple-service-webapp-quarkus](https://github.com/igeorge0902/simple-service-webapp-quarkus) | Image service (Quarkus) |
| [k8infra](https://github.com/igeorge0902/k8infra) | Kubernetes manifests & DB schemas |

## Project History

- **2015**: Initial development as `SwiftLoginScreen` (Swift 1.x)
- **2016**: Movie browsing, venue discovery, seat selection, calendar integration
- **2017**: Ticket purchasing (Braintree), purchase history, basket/checkout flow
- **2019**: Updated to Swift 4.2, Xcode 11.1
- **2020**: Admin panel for screen management
- **2025**: Renamed to `SwiftCinemas`, added WebSocket support (native `URLSessionWebSocketTask`), Firebase Cloud Messaging, geofencing, WKWebView migration
- **2026**: Backend migrated from WildFly to Quarkus microservices on Kubernetes

---

Copyright © 2015–2026 George Gaspar. All rights reserved.
