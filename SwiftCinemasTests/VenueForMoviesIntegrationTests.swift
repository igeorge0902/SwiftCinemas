import XCTest
import SwiftyJSON // assuming you use it
@testable import YourAppModule

final class VenueForMoviesIntegrationTests: XCTestCase {

    var vc: VenueForMoviesVC!

    override func setUp() {
        super.setUp()
        vc = VenueForMoviesVC()
        // Optionally set test locationId
        vc.locationId = 123
        vc.appServices = AppServices.shared // or a test double
    }

    override func tearDown() {
        vc = nil
        super.tearDown()
    }

    func testAddDataLoadsMoviesAndVenues() async throws {
        // Clear data before test
        vc.TableData.removeAll()
        vc.VenueData.removeAll()

        // Call addData() async
        await vc.addData()

        // Assertions
        XCTAssertFalse(vc.TableData.isEmpty, "TableData should be populated after addData()")
        XCTAssertFalse(vc.VenueData.isEmpty, "VenueData should be populated after addData()")

        // Optional: check first item structure
        if let firstMovie = vc.TableData.first {
            XCTAssertNotNil(firstMovie.movieId, "Movie ID should not be nil")
            XCTAssertNotNil(firstMovie.title, "Movie title should not be nil")
        }

        if let firstVenue = vc.VenueData.first {
            XCTAssertNotNil(firstVenue.venueId, "Venue ID should not be nil")
            XCTAssertNotNil(firstVenue.name, "Venue name should not be nil")
        }
    }

    func testLocationsApiCall() async throws {
        do {
            let data = try await vc.appServices.locations()
            let json = try JSON(data: data)

            XCTAssertNotNil(json["locations"].array, "Locations array should exist")
            XCTAssertFalse(json["locations"].array!.isEmpty, "Locations array should not be empty")
        } catch {
            XCTFail("locations() API call failed: \(error)")
        }
    }
}
