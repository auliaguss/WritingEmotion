//
//  WritingService.swift
//  AIEmotions
//
//  Live backend contract for publishing and reading writings.
//

import Foundation
import SwiftUI

struct PublishWritingRequest: Codable, Equatable, Sendable {
    let clientWritingID: UUID
    let title: String?
    let fullText: String
    let prompt: PublishedPrompt

    private enum CodingKeys: String, CodingKey {
        case clientWritingID = "client_writing_id"
        case title
        case fullText = "full_text"
        case prompt
    }

    struct PublishedPrompt: Codable, Equatable, Sendable {
        let verb: String
        let fullText: String
        let emotions: [String]

        private enum CodingKeys: String, CodingKey {
            case verb
            case fullText = "full_text"
            case emotions
        }
    }
}

struct PublishedWritingPreview: Codable, Identifiable, Sendable {
    let id: String
    let clientWritingID: UUID
    let title: String
    let previewText: String
    let authorID: String
    let prompt: PublishWritingRequest.PublishedPrompt
    let status: String
    let createdAt: Date
    let publishedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case clientWritingID = "client_writing_id"
        case title
        case previewText = "preview_text"
        case authorID = "author_id"
        case prompt
        case status
        case createdAt = "created_at"
        case publishedAt = "published_at"
    }
}

struct PublishedWritingResponse: Codable, Identifiable, Sendable {
    let id: String
    let clientWritingID: UUID
    let title: String
    let fullText: String
    let authorID: String
    let prompt: PublishWritingRequest.PublishedPrompt
    let status: String
    let createdAt: Date
    let publishedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case clientWritingID = "client_writing_id"
        case title
        case fullText = "full_text"
        case authorID = "author_id"
        case prompt
        case status
        case createdAt = "created_at"
        case publishedAt = "published_at"
    }
}

enum WritingServiceError: LocalizedError {
    case invalidResponse
    case conflictingSubmission
    case rejected(String)
    case notFound
    case serverUnavailable
    case connectionFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The server returned an unexpected response. Please try again."
        case .conflictingSubmission:
            "This writing conflicts with an earlier publish attempt. Keep it as a draft for now."
        case let .rejected(message):
            message
        case .notFound:
            "This writing is no longer available."
        case .serverUnavailable:
            "The writing service is unavailable. Please try again later."
        case .connectionFailed:
            "We couldn't connect to the writing service. Check your connection and try again."
        case .decodingFailed:
            "The writing service returned data the app couldn't read."
        }
    }

    var canRetry: Bool {
        if case .conflictingSubmission = self {
            return false
        }
        return true
    }
}

protocol WritingService: Sendable {
    func publish(
        _ request: PublishWritingRequest,
        deviceID: String
    ) async throws -> PublishedWritingResponse

    func fetchWritings(deviceID: String) async throws -> [PublishedWritingPreview]

    func fetchWriting(
        id: String,
        deviceID: String
    ) async throws -> PublishedWritingResponse
}

struct HTTPWritingService: WritingService {
    let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func publish(
        _ request: PublishWritingRequest,
        deviceID: String
    ) async throws -> PublishedWritingResponse {
        var urlRequest = makeRequest(path: "api/writings", deviceID: deviceID)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await send(urlRequest)
        switch response.statusCode {
        case 200, 201:
            return try decode(PublishedWritingResponse.self, from: data)
        case 409:
            throw WritingServiceError.conflictingSubmission
        default:
            throw error(for: response.statusCode, data: data)
        }
    }

    func fetchWritings(deviceID: String) async throws -> [PublishedWritingPreview] {
        let request = makeRequest(path: "api/writings", deviceID: deviceID)
        let (data, response) = try await send(request)
        guard response.statusCode == 200 else {
            throw error(for: response.statusCode, data: data)
        }
        return try decode([PublishedWritingPreview].self, from: data)
            .sorted { $0.publishedAt > $1.publishedAt }
    }

    func fetchWriting(
        id: String,
        deviceID: String
    ) async throws -> PublishedWritingResponse {
        let request = makeRequest(path: "api/writings/\(id)", deviceID: deviceID)
        let (data, response) = try await send(request)
        guard response.statusCode == 200 else {
            throw error(for: response.statusCode, data: data)
        }
        return try decode(PublishedWritingResponse.self, from: data)
    }

    private func makeRequest(path: String, deviceID: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.setValue(deviceID, forHTTPHeaderField: "X-Device-ID")
        return request
    }

    private func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WritingServiceError.invalidResponse
            }
            return (data, httpResponse)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as WritingServiceError {
            throw error
        } catch {
            throw WritingServiceError.connectionFailed
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractionalFormatter.date(from: value) {
                return date
            }

            let formatter = ISO8601DateFormatter()
            guard let date = formatter.date(from: value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid ISO 8601 date"
                )
            }
            return date
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw WritingServiceError.decodingFailed
        }
    }

    private func error(for statusCode: Int, data: Data) -> WritingServiceError {
        if statusCode == 404 {
            return .notFound
        }
        if (400..<500).contains(statusCode) {
            let detail = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            return .rejected(detail?.detail ?? "The server rejected this request.")
        }
        return .serverUnavailable
    }
}

private struct APIErrorResponse: Decodable {
    let detail: String?
}

private struct WritingServiceKey: EnvironmentKey {
    static let defaultValue: any WritingService = APIConfiguration.writingService
}

extension EnvironmentValues {
    var writingService: any WritingService {
        get { self[WritingServiceKey.self] }
        set { self[WritingServiceKey.self] = newValue }
    }
}
