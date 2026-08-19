//
//  APIConfiguration.swift
//  AIEmotions
//
//  Set `baseURL` when the deployed backend URL is available. Until then,
//  the app uses the mock service so the complete publish flow can be tested.
//

import Foundation

enum APIConfiguration {
    static let baseURL: URL? = nil

    static var writingService: any WritingService {
        guard let baseURL else {
            return MockWritingService()
        }
        return HTTPWritingService(baseURL: baseURL)
    }
}
