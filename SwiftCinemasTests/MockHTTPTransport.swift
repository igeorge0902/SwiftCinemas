import Foundation

struct MockHTTPResponse {
    let statusCode: Int
    let headers: [String: String]
    let body: Data
}

extension MockHTTPResponse {
    static func json(_ object: [String: Any], statusCode: Int = 200) -> MockHTTPResponse {
        let body = (try? JSONSerialization.data(withJSONObject: object, options: [])) ?? Data()
        return MockHTTPResponse(
            statusCode: statusCode,
            headers: ["Content-Type": "application/json"],
            body: body
        )
    }
}

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) -> MockHTTPResponse)?
    static var capturedRequests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        Self.capturedRequests.append(request)
        let mocked = handler(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: mocked.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mocked.headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: mocked.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        requestHandler = nil
        capturedRequests.removeAll()
    }

    static func lastRequest() -> URLRequest? {
        capturedRequests.last
    }
}

