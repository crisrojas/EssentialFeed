//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Cristian Felipe Patiño Rojas on 28/11/24.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedValuesRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url)  { _, _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }
        .resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        URLSessionHTTPClient().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = anyURL()
        let error = NSError(domain: "any error", code: 1)
     
        URLProtocolStub.stub(
            url: url,
            data: nil,
            response: nil,
            error: error)
        
        let exp = expectation(description: "Wait for completion")
        makeSUT().get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError.code, error.code)
                XCTAssertEqual(receivedError.domain, error.domain)
                
            default:
                XCTFail("Expected failure with error \(error) got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_getFromURL_failsOnAllNilValues() {
        let url = anyURL()
        let error = NSError(domain: "any error", code: 1)
     
        URLProtocolStub.stub(
            url: url,
            data: nil,
            response: nil,
            error: nil)
        
        let exp = expectation(description: "Wait for completion")
        makeSUT().get(from: url) { result in
            switch result {
            case .failure:
                break
            default:
                XCTFail("Expected failure with error \(error) got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
    
        static func stub(url: URL, data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(
                data: data,
                response: response,
                error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(Self.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(Self.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            if let data = Self.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = Self.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = Self.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
