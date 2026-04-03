# Venues SwiftUI Migration

This directory contains a complete SwiftUI-based replacement for the existing UIKit `VenuesVC`, supporting all three operational modes (standard, admin, map) with feature-flagged gradual rollout.

## 📁 Files

### Core Implementation
- **`VenuesMigration.swift`** (520 lines)
  - `VenuesMode` enum (standard, admin, map)
  - `VenuesFlowMode` & `VenuesFeatureFlags` (feature flag control)
  - `VenuesInput` struct (input contract with legacy flag support)
  - `VenuesUnifiedItem` (unified data model)
  - `VenuesMigrationViewModel` (state management)
  - `VenuesMigrationView` (SwiftUI declarative UI)
  - `VenuesLegacyMapView` (SwiftUI wrapper around MKMapView)
  - `VenuesMigrationHostVC` (UIKit-to-SwiftUI bridge)
  - `VenuesMigrationFactory` (creation helpers)

- **`VenuesMigrationSegueEntryVC.swift`** (50 lines)
  - Storyboard-compatible entry point
  - Reads legacy global flags (`adminPage`, `mapViewPage`)
  - Launches migration based on feature flag
  - Falls back to legacy UIKit if flag disabled

### Documentation
- **`SPEC_COMPLIANCE.md`** — Maps all spec requirements to implementation
- **`INTEGRATION_GUIDE.md`** — How to wire entry points (programmatic & storyboard)
- **`FEATURE_FLAG_GUIDE.md`** — A/B test rollout strategy & UserDefaults control

---

## 🎯 Quick Start

### Enable Migration for All Users
```swift
UserDefaults.standard.set("migration", forKey: "venues.flow.mode")
```

### Enable 50/50 A/B Test
```swift
UserDefaults.standard.set("ab", forKey: "venues.flow.mode")
```

### Reset to Legacy (Safe Default)
```swift
UserDefaults.standard.set("legacy", forKey: "venues.flow.mode")
```

---

## 🧩 Three Modes

| Mode | Trigger | Behavior | Events |
|------|---------|----------|--------|
| **Standard** | `MoviesVC` row tap / `MovieDetailVC` Venues button | List of venues for selected movie + inline details panel | None |
| **Admin** | `AdminVC` segue (legacy flag `adminPage = true`) | All locations, highlights selected venue | `newScreenVenueSelected` |
| **Map** | `MapViewController` segue (legacy flag `mapViewPage = true`) | Map view with annotations, allows location selection | `screeningVenueSelected` |

---

## 🔌 Entry Points (Already Wired)

### Programmatic (Feature Flagged)
- ✅ `MoviesVC.tableView(_:didSelectRowAt:)` — Row selection
- ✅ `MovieDetailVC.Venues()` — Venues button tap

### Storyboard (Legacy Global Flags)
- ⏳ `AdminVC → VenuesMigrationSegueEntryVC` — Needs storyboard segue update
- ⏳ `MapViewController → VenuesMigrationSegueEntryVC` — Needs storyboard segue update

See `INTEGRATION_GUIDE.md` for setup steps.

---

## ✨ Key Features

- **Zero-Breaking-Change** — Legacy UIKit flow always available via feature flag
- **Sticky A/B Bucket** — 50/50 split per install (same cohort across sessions)
- **Global State Compatibility** — Reads/writes `PlacesData_`, `PlacesData2_`, `adminPage`, `mapViewPage`
- **NotificationCenter Preservation** — Emits `navigateBack`, `newScreenVenueSelected`, `screeningVenueSelected`
- **MapKit Integration** — SwiftUI Map wrapper with annotation updates + region binding
- **Safe Rollback** — One UserDefaults change reverts entire app to legacy

---

## 📊 Status

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 1–6 | ✅ Complete | Models, ViewModel, Views, UIKit bridge, feature flag |
| Phase 7 | ⏳ Pending | Storyboard segue rewiring (AdminVC, MapViewController) |
| Phase 8 | ⏳ Pending | Cleanup: remove UIKit VenuesVC after full migration |

---

## 🧪 Testing

See `INTEGRATION_GUIDE.md` for full testing checklist, including:
- Standard mode: list + details panel
- Admin mode: location highlighting + event emission
- Map mode: annotations + region updates
- Fallback behavior (legacy flag)
- A/B test cohort consistency

---

## 📚 Related Files

Outside this directory:
- `MoviesVC.swift` — Programmatic entry (row selection, feature flagged)
- `MovieDetailVC.swift` — Programmatic entry (Venues button, feature flagged)
- `AdminVC.swift` — Future: storyboard entry for admin mode (needs segue update)
- `MapViewController.swift` — Future: storyboard entry for map mode (needs segue update)
- `VenuesVC.swift` — Legacy UIKit implementation (preserved for rollback)

---

## 🚀 Rollout Timeline

1. **Verify** → All users on legacy (default)
2. **Canary** → Set to `"ab"` for 50/50 test in staging/QA
3. **Ramp** → Set to `"migration"` for full rollout
4. **Cleanup** → Remove legacy `VenuesVC` (after monitoring period)

---

## 💡 Notes

- Feature flag uses `UserDefaults` for simplicity; can later integrate with backend config service
- A/B test bucket is sticky per install; reset by clearing UserDefaults or resetting app
- All legacy NotificationCenter events are preserved for backward compatibility
- Global state (`PlacesData_`, `PlacesData2_`) is kept in sync; future phases can migrate to structured state

