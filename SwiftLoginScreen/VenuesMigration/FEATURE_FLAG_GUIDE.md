# Venues Migration Feature Flag — A/B Test Setup

## Overview

The feature flag system supports three rollout modes:
- **`legacy`** — Always use existing UIKit `VenuesVC`
- **`migration`** — Always use new SwiftUI migration
- **`ab`** — 50/50 A/B test split per install (sticky)

---

## Usage

### Set Flow Mode

```swift
// Option 1: Always legacy (safe default)
UserDefaults.standard.set("legacy", forKey: "venues.flow.mode")

// Option 2: Always migration (full rollout)
UserDefaults.standard.set("migration", forKey: "venues.flow.mode")

// Option 3: 50/50 A/B test (sticky per install)
UserDefaults.standard.set("ab", forKey: "venues.flow.mode")
```

### Query Current Mode

```swift
if VenuesFeatureFlags.shouldUseMigration() {
    print("Using migration flow")
} else {
    print("Using legacy flow")
}
```

### Get Assigned Bucket (A/B test only)

```swift
// For metrics/analytics
let bucket = UserDefaults.standard.bool(forKey: "venues.flow.ab.bucket")
// bucket == true → Control (migration)
// bucket == false → Test (legacy)
```

---

## A/B Test Behavior

When flow mode is set to `"ab"`:
1. First app session **randomly assigns** bucket (true/false)
2. Bucket stored in `UserDefaults` with key `venues.flow.ab.bucket`
3. Same bucket used for **all subsequent sessions**
4. Cannot be changed without resetting UserDefaults

### Sticky Bucket Code
```swift
private static var abBucket: Bool {
    if UserDefaults.standard.object(forKey: abBucketKey) == nil {
        UserDefaults.standard.set(Bool.random(), forKey: abBucketKey)
    }
    return UserDefaults.standard.bool(forKey: abBucketKey)
}
```

---

## Rollout Strategy

### Phase 1: Verify (Legacy Only)
```
Flow Mode: "legacy"
Status: All users on UIKit VenuesVC
```

### Phase 2: Early Adopters (Opt-In)
```
Flow Mode: "legacy" (default)
Testers manually: UserDefaults.standard.set("migration", ...)
Status: Developers + QA test new flow
```

### Phase 3: Canary (Small A/B Test)
```
Flow Mode: "ab"
Split: 50% migration, 50% legacy (random per install)
Monitor: Crash rates, performance, event emissions
```

### Phase 4: Ramp (Gradual Increase)
```
Flow Mode: "migration"
Status: All new installs on SwiftUI migration
```

### Phase 5: Legacy Cleanup (Optional)
```
Remove: UIKit VenuesVC, storyboard segues
Keep: Feature flag infrastructure for future A/B tests
```

---

## Metrics to Track

When running A/B test, compare:
- **Crash rate** — SwiftUI vs UIKit
- **Performance** — Navigation latency, memory
- **Completeness** — VenuesDetailsVC drill-down success rate
- **Admin workflows** — `newScreenVenueSelected` event emission
- **Map workflows** — `screeningVenueSelected` event, region update accuracy

---

## Reset / Force Mode (Debug)

```swift
// Clear all feature flag state
UserDefaults.standard.removeObject(forKey: "venues.flow.mode")
UserDefaults.standard.removeObject(forKey: "venues.flow.ab.bucket")

// Force legacy for testing
UserDefaults.standard.set("legacy", forKey: "venues.flow.mode")

// Force migration for testing
UserDefaults.standard.set("migration", forKey: "venues.flow.mode")

// Force A/B and re-assign bucket
UserDefaults.standard.removeObject(forKey: "venues.flow.ab.bucket")
UserDefaults.standard.set("ab", forKey: "venues.flow.mode")
```

---

## Runtime Toggle (Debug Menu)

For internal testing, you could add a debug screen:

```swift
class DebugVenuesSettingsVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let legacyButton = UIButton(type: .system)
        legacyButton.setTitle("Force Legacy", for: .normal)
        legacyButton.addTarget(self, action: #selector(forceLegacy), for: .touchUpInside)
        view.addSubview(legacyButton)
        
        let migrationButton = UIButton(type: .system)
        migrationButton.setTitle("Force Migration", for: .normal)
        migrationButton.addTarget(self, action: #selector(forceMigration), for: .touchUpInside)
        view.addSubview(migrationButton)
        
        let abButton = UIButton(type: .system)
        abButton.setTitle("A/B Test (50/50)", for: .normal)
        abButton.addTarget(self, action: #selector(forceAB), for: .touchUpInside)
        view.addSubview(abButton)
    }
    
    @objc func forceLegacy() {
        VenuesFeatureFlags.setFlowMode(.legacy)
        showAlert("Switched to Legacy (restart app for effect)")
    }
    
    @objc func forceMigration() {
        VenuesFeatureFlags.setFlowMode(.migration)
        showAlert("Switched to Migration (restart app for effect)")
    }
    
    @objc func forceAB() {
        VenuesFeatureFlags.setFlowMode(.ab)
        UserDefaults.standard.removeObject(forKey: "venues.flow.ab.bucket")
        showAlert("Switched to A/B Test (restart app to assign bucket)")
    }
    
    private func showAlert(_ msg: String) {
        let alert = UIAlertController(title: "Feature Flag", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

---

## Monitoring

Once live, log feature flag decision at app startup:

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let mode = VenuesFeatureFlags.flowMode
        let shouldUseMigration = VenuesFeatureFlags.shouldUseMigration()
        
        NSLog("[Venues] Feature flag mode: %@, shouldUseMigration: %@", 
              mode.rawValue, 
              shouldUseMigration ? "true" : "false")
        
        // ... rest of app setup
        return true
    }
}
```

---

## Related Files

- `VenuesMigration.swift` — `VenuesFeatureFlags` + `VenuesFlowMode` enums
- `MoviesVC.swift` — Uses `shouldUseMigration()` for row selection
- `MovieDetailVC.swift` — Uses `shouldUseMigration()` for Venues button

