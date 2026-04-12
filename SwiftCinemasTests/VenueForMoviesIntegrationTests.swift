import Foundation
import XCTest
@testable import SwiftCinemas

@MainActor
final class VenueForMoviesIntegrationTests: XCTestCase {
    private var sut: MbooksService!

    override func setUp() {
        super.setUp()

        if TestBackendMode.current == .mocked {
            MockURLProtocol.requestHandler = MockResponseFixtures.response(for:)
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)
            let apiClient = APIClient(
                baseURL: URL(string: URLManager.baseURL)!,
                session: session,
                cache: InMemoryCache(),
                headers: SessionHeaderProvider()
            )
            sut = MbooksService(apiClient: apiClient)
        } else {
            let apiClient = APIClient(
                baseURL: URL(string: URLManager.baseURL)!,
                session: .sharedCustomSession,
                cache: InMemoryCache(),
                headers: SessionHeaderProvider()
            )
            sut = MbooksService(apiClient: apiClient)
        }
    }

    override func tearDown() {
        MockURLProtocol.reset()
        sut = nil
        super.tearDown()
    }

    func testBackendModeDefaultsToMocked() {
        XCTAssertTrue(
            TestBackendMode.current == .mocked || TestBackendMode.current == .real,
            "Backend mode must resolve to mocked or real"
        )
    }

    func testLocations_UsesGetPathAndReturnsFixtureInMockMode() async throws {
        guard TestBackendMode.current == .mocked else {
            throw XCTSkip("Set SWIFT_REST_BACKEND=mocked to run deterministic fixture contract tests")
        }

        let data = try await sut.locations()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(json["locations"], "Expected locations key in mocked payload")

        let request = try XCTUnwrap(MockURLProtocol.lastRequest())
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/mbooks-1/rest/book/locations")
    }

    func testMoviesSearch_EncodesQueryAndReturnsMoviesFixtureInMockMode() async throws {
        guard TestBackendMode.current == .mocked else {
            throw XCTSkip("Set SWIFT_REST_BACKEND=mocked to run deterministic fixture contract tests")
        }

        _ = try await sut.moviesSearch(query: ["movie_name": "Mock"])

        let request = try XCTUnwrap(MockURLProtocol.lastRequest())
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/mbooks-1/rest/book/movies/search")

        let queryItems = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems
        let movieName = queryItems?.first(where: { $0.name == "movie_name" })?.value
        XCTAssertEqual(movieName, "Mock")
    }

    func testLocations_LiveSmokeWhenRealBackendEnabled() async throws {
        guard TestBackendMode.current == .real else {
            throw XCTSkip("Set SWIFT_REST_BACKEND=real to run live backend smoke tests")
        }

        let data = try await sut.locations()
        XCTAssertFalse(data.isEmpty, "Real backend returned an empty response for locations")
    }
}
