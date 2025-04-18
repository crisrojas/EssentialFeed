//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Cristian Felipe Patiño Rojas on 9/4/25.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
   
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toLoad: [])
    }
    
    func test_load_deliversItemsSavedOnASeparatedInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let feed = uniqueImageFeed().models
        
        save(feed, with: sutToPerformSave)
        
        expect(sutToPerformLoad, toLoad: feed)
    }
    
    func test_save_overridesItemsSavedOnASeparatedInstance() {
        let sutToPerformFirstSave = makeSUT()
        let sutToPerformLastSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let firstFeed = uniqueImageFeed().models
        let latestFeed = uniqueImageFeed().models
        
        save(firstFeed, with: sutToPerformFirstSave)
        save(latestFeed, with: sutToPerformLastSave)
        
        expect(sutToPerformLoad, toLoad: latestFeed)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalFeedLoader {
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL)
        let sut = LocalFeedLoader(
            store: store,
            currentDate: Date.init
        )
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return sut
    }
    
    private func expect(
        _ sut: LocalFeedLoader,
        toLoad expectedImageFeed: [FeedImage],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            exp.fulfill()
            switch result {
            case let .success(imageFeed):
                XCTAssertEqual(
                    imageFeed,
                    expectedImageFeed,
                    "Expected empty feed",
                    file: file,
                    line: line
                )
            case let .failure(error):
                XCTFail(
                    "Expected successful feed result, got \(error) instead",
                    file: file,
                    line: line
                )
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    
    private func save(
        _ feed: [FeedImage],
        with sut: LocalFeedLoader,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for save completion")
        sut.save(feed) { result in
            switch result {
            case let .failure(error):
                XCTAssertNil(error, "Unexpected error: \(String(describing: error))", file: file, line: line)
            default: break
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
