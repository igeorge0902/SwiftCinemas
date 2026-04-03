# Venues SwiftUI Migration — Entry Point Integration Guide

## Overview

The migration supports **three modes** (standard, admin, map) and two activation paths:
1. **Programmatic** — from code with feature flag (MoviesVC, MovieDetailVC)
2. **Storyboard** — via segue with legacy global flags (AdminVC, MapViewController)

---

## Feature Flag Control

Use `VenuesFeatureFlags` to control rollout:

```swift
// Always use legacy
UserDefaults.standard.set("legacy", forKey: "venues.flow.mode")

// Always use migration
UserDefaults.standard.set("migration", forKey: "venues.flow.mode")

// 50/50 A/B test (sticky per install)
UserDefaults.standard.set("ab", forKey: "venues.flow.mode")
```

---

## Path 1: Programmatic Entry (Feature Flagged)

### MoviesVC — Row Selection

When user taps a movie row:
- Feature flag checks `shouldUseMigration()`
- If true: open SwiftUI migration (standard mode)
- If false: perform legacy `goto_venues` segue

**Already wired in:** `MoviesVC.tableView(_:didSelectRowAt:)`

```swift
if VenuesFeatureFlags.shouldUseMigration(), let movie = selectedMovie(at: indexPath) {
    presentVenuesMigration(for: movie)
} else {
    performSegue(withIdentifier: "goto_venues", sender: self)
}
```

---

### MovieDetailVC — Venues Button

When user taps "Venues" button on detail screen:
- Feature flag checks `shouldUseMigration()`
- If true: open SwiftUI migration (standard mode)
- If false: perform legacy `goto_venues2` segue

**Already wired in:** `MovieDetailVC.Venues()`

```swift
if VenuesFeatureFlags.shouldUseMigration() {
    presentVenuesMigration()
} else {
    performSegue(withIdentifier: "goto_venues2", sender: self)
}
```

---

## Path 2: Storyboard Entry (Legacy Global Flags)

### AdminVC → VenuesVC (Admin Mode)

**Spec requirement:** AdminVC → VenuesVC must continue to work (admin mode)

**Setup:**
1. In Storyboard, change `goto_venues` segue destination to `VenuesMigrationSegueEntryVC`
2. In `AdminVC.prepare(for:sender:)`, before calling `super.prepare()`:
   ```swift
   override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
       if segue.identifier == "goto_venues" {
           adminPage = true  // ← Flag tells migration: "Use admin mode"
           let nextVC = segue.destination as? VenuesMigrationSegueEntryVC
           // ... set movie/details properties
       }
       super.prepare(for: segue, sender: nil)
   }
   ```

**How it works:**
- `VenuesMigrationSegueEntryVC.viewWillAppear()` reads `adminPage == true`
- `VenuesInput.fromLegacyFlags()` converts to `.admin` mode
- SwiftUI migration launches in admin mode

---

### MapViewController → VenuesVC (Map Mode)

**Spec requirement:** MapViewController → VenuesVC must continue to work (map mode)

**Setup:**
1. In Storyboard, change `goto_venues_map` segue destination to `VenuesMigrationSegueEntryVC`
2. In `MapViewController.prepare(for:sender:)`:
   ```swift
   override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
       if segue.identifier == "goto_venues_map" {
           mapViewPage = true  // ← Flag tells migration: "Use map mode"
           let nextVC = segue.destination as? VenuesMigrationSegueEntryVC
           // ... set movie/details properties
       }
       super.prepare(for: segue, sender: nil)
   }
   ```

**How it works:**
- `VenuesMigrationSegueEntryVC.viewWillAppear()` reads `mapViewPage == true`
- `VenuesInput.fromLegacyFlags()` converts to `.map` mode
- SwiftUI migration launches in map mode

---

## Mode Behavior Reference

### Standard Mode
- Loads venues for the selected movie
- Shows list + inline details panel
- Allows drill-down to `VenuesDetailsVC`
- No special global state handling

### Admin Mode
- Loads all locations
- Highlights selected venue (from `originalVenueName`)
- Emits `newScreenVenueSelected` on selection
- Used by AdminUpdateVC to manage movies-on-venues

### Map Mode
- Loads locations into `PlacesData2_`
- Displays SwiftUI Map with annotations
- Updates region on selection
- Emits `screeningVenueSelected` on selection
- Dismisses after selection to return to MapViewController

---

## Fallback Behavior

If feature flag is disabled (legacy):
- All entry points revert to existing UIKit `VenuesVC`
- No changes needed to storyboards or calling code
- Safe rollback path always available

---

## Testing Checklist

- [ ] Standard mode: row tap from MoviesVC opens migration, shows venues list + details panel
- [ ] Standard mode: fallback to legacy segue when flag is "legacy"
- [ ] Admin mode: flag set, admin locations list loads correctly
- [ ] Admin mode: venue selection emits `newScreenVenueSelected`
- [ ] Map mode: flag set, map displays with annotations
- [ ] Map mode: location selection updates map region + emits `screeningVenueSelected`
- [ ] A/B test: rollout to 50% of installs with sticky bucket
- [ ] No regression: legacy UIKit Venues still works when flag disabled

---

## Files

- `VenuesMigration.swift` — Core models, ViewModel, Views, Factory
- `VenuesMigrationSegueEntryVC.swift` — Storyboard bridge controller
- `MoviesVC.swift` — Programmatic entry (row selection)
- `MovieDetailVC.swift` — Programmatic entry (Venues button)

