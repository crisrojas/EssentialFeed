//
//  SharedTestHelpers.swift
//  EssentialFeed
//
//  Created by Cristian Felipe Patiño Rojas on 31/12/24.
//

import Foundation

func anyURL() -> URL {
    URL(string: "http://any-url.com")!
}

func anyNSError() -> NSError {
    NSError(
        domain: "any error",
        code: 0
    )
}
