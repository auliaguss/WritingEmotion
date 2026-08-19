//
//  WritingService.swift
//  AIEmotions
//
//  Backend contract for publishing a locally created writing.
//

import Foundation
import SwiftUI

struct PublishWritingRequest: Codable, Equatable, Sendable {
    let clientWritingID: UUID
    let title: String?
    let fullText: String
    let prompt: PublishedPrompt

    struct PublishedPrompt: Codable, Equatable, Sendable {
        let verb: String
        let fullText: String
        let emotions: [String]
    }
}

struct PublishedWritingResponse: Codable, Sendable {
    let id: String
    let clientWritingID: UUID
    let title: String
    let fullText: String
    let authorID: String
    let prompt: PublishWritingRequest.PublishedPrompt
    let status: String
    let createdAt: Date
    let publishedAt: Date
}

enum WritingServiceError: LocalizedError {
    case invalidResponse
    case conflictingSubmission
    case rejected(String)
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
        case .serverUnavailable:
            "The publishing service is unavailable. Please try again later."
        case .connectionFailed:
            "We couldn't connect to the publishing service. Check your connection and try again."
        case .decodingFailed:
            "The publishing service returned data the app couldn't read."
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
        var urlRequest = URLRequest(url: baseURL.appending(path: "api/writings"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(deviceID, forHTTPHeaderField: "X-Device-ID")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw WritingServiceError.connectionFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WritingServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200, 201:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
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
                return try decoder.decode(PublishedWritingResponse.self, from: data)
            } catch {
                throw WritingServiceError.decodingFailed
            }
        case 409:
            throw WritingServiceError.conflictingSubmission
        case 400..<500:
            let detail = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw WritingServiceError.rejected(
                detail?.detail ?? "The server rejected this writing. Please review it and try again."
            )
        default:
            throw WritingServiceError.serverUnavailable
        }
    }
}

struct MockWritingService: WritingService {
    func publish(
        _ request: PublishWritingRequest,
        deviceID: String
    ) async throws -> PublishedWritingResponse {
        try await Task.sleep(for: .milliseconds(500))
        let now = Date()
        return PublishedWritingResponse(
            id: "mock-\(request.clientWritingID.uuidString.lowercased())",
            clientWritingID: request.clientWritingID,
            title: request.title ?? generatedTitle(from: request.fullText),
            fullText: request.fullText,
            authorID: deviceID,
            prompt: request.prompt,
            status: "published",
            createdAt: now,
            publishedAt: now
        )
    }

    private func generatedTitle(from text: String) -> String {
        let firstLine = text
            .split(whereSeparator: { $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        return String((firstLine ?? "Untitled").prefix(256))
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
