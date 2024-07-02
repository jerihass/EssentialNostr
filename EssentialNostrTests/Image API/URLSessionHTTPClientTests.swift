//
//  Created by Jericho Hasselbush on 7/2/24.
//

import XCTest
import EssentialNostr

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionDataTask
}

protocol HTTPSessionDataTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session: HTTPSession
    init(session: HTTPSession) {
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
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let session = HTTPSessionSpy()
        let task = URLSessionDataTaskSpy()

        session.stub(url: url, task: task)

        let sut = URLSessionHTTPClient(session: session)

        sut.get(from: url) { _ in }

        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "http://any-url.com")!
        let session = HTTPSessionSpy()
        let error = NSError(domain: "domain", code: 1)

        session.stub(url: url, error: error)

        let sut = URLSessionHTTPClient(session: session)

        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .failure(gotError as NSError):
                XCTAssertEqual(gotError, error)
            default:
                XCTFail("Expected failure, got \(result) instead.")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }


    // MARK: - Helpers
    private class HTTPSessionSpy: HTTPSession {
        private var stubs = [URL:Stub]()
        private struct Stub {
            let error: Error?
            let task: HTTPSessionDataTask
        }
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionDataTask {
            guard let stub = stubs[url] else { fatalError("No stub for \(url)") }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }

        func stub(url: URL, task: HTTPSessionDataTask = URLSessionDataTaskSpy(), error: Error? = nil) {
            stubs[url] = Stub(error: error, task: task)
        }
    }

    private class URLSessionDataTaskSpy: HTTPSessionDataTask {
        var resumeCallCount = 0

        func resume() {
            resumeCallCount += 1
        }
    }
}
