//
//  APIConfiguration.swift
//  AIEmotions
//
//  Backend configuration for writing publication.
//

import Foundation

enum APIConfiguration {
    static let baseURL = URL(string: "https://p3.fadilhim.com")!

    static var writingService: any WritingService {
        HTTPWritingService(baseURL: baseURL)
    }
}
