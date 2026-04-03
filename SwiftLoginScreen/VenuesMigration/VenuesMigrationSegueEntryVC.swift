import UIKit

/// Storyboard-compatible entry point for SwiftUI venues migration.
/// Reads legacy UIKit input properties (set via prepare(for:sender:))
/// and launches migration flow based on feature flag.
final class VenuesMigrationSegueEntryVC: UIViewController, HasAppServices {
    var appServices: AppServices!

    // Properties set by prepare(for:sender:) from source ViewController
    var movieId: Int = 0
    var movieName: String = ""
    var selectLargePicture: String = ""
    var selectDetails: String = ""
    var imdb: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        injectAppServicesIfNeeded()
    }

    override func viewWillAppear(_: Bool) {
        guard VenuesFeatureFlags.shouldUseMigration() else {
            // Legacy UIKit flow would have been triggered instead.
            // This should only be reached if segue was wired to wrong controller.
            dismiss(animated: true)
            return
        }

        let input = VenuesInput.fromLegacyFlags(
            movieId: movieId,
            movieName: movieName,
            selectLargePicture: selectLargePicture,
            selectDetails: selectDetails,
            imdb: imdb
        )

        let migrationVC = VenuesMigrationFactory.makeFromLegacyFlags(
            movieId: movieId,
            movieName: movieName,
            selectLargePicture: selectLargePicture,
            selectDetails: selectDetails,
            imdb: imdb,
            appServices: appServices
        )

        migrationVC.modalPresentationStyle = .fullScreen
        present(migrationVC, animated: false)
    }
}

