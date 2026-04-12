import Foundation

enum MockResponseFixtures {
    static func response(for request: URLRequest) -> MockHTTPResponse {
        let method = request.httpMethod?.uppercased() ?? "GET"
        let path = request.url?.path ?? ""

        switch (method, path) {
        case ("GET", "/mbooks-1/rest/book/locations"):
            return .json([
                "locations": [
                    [
                        "locationId": 1,
                        "name": "Mock Cinema",
                        "formatted_address": "Mock Street 1",
                        "latitude": 47.5,
                        "longitude": 19.0,
                        "thumbnail": "mock.jpg"
                    ]
                ]
            ])
        case ("GET", "/mbooks-1/rest/book/movies/search"):
            return .json([
                "movies": [
                    [
                        "movieId": "1",
                        "name": "Mock Movie",
                        "large_picture": "/movies/mock.jpg",
                        "detail": "Mock Detail",
                        "iMDB_url": "tt123"
                    ]
                ]
            ])
        default:
            return .json(["error": "No fixture for \(method) \(path)"], statusCode: 404)
        }
    }
}

