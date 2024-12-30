//
//  FeedStoreSpy.swift
//  EssentialFeed
//
//  Created by Cristian Felipe Patiño Rojas on 31/12/24.
//
import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {

    private var deletionCompletions  = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
   
    private(set) var receivedMessages = [ReceivedMessage]()
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    func deleteCachedFeed(completion: @escaping (Error?) -> Void) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(feed, timestamp))
    }
    
    func retrieve() {
        receivedMessages.append(.retrieve)
    }
}
