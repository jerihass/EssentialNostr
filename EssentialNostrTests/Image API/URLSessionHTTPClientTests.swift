//
//  Created by Jericho Hasselbush on 7/2/24.
//

import XCTest
import EssentialNostr

class URLSessionHTTPClient {
    private let session: URLSession
    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInteceptingRequests()
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: "domain", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)

        let sut = URLSessionHTTPClient()

        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .failure(gotError as NSError):
                XCTAssertEqual(gotError.domain, error.domain)
                XCTAssertEqual(gotError.code, error.code)
            default:
                XCTFail("Expected failure, got \(result) instead.")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
        URLProtocolStub.stopInteceptingRequests()
    }


    // MARK: - Helpers
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func startInteceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
            stub = nil
        }

        static func stopInteceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
        }

        override class func canInit(with request: URLRequest) -> Bool {
            true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {

            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
