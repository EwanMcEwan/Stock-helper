import Foundation
import os.log

private let logger = Logger(subsystem: "com.stockhelper", category: "APIClient")

enum APIError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, body: Data?)
    case decodingError(Error)
    case networkError(Error)
    case rateLimited
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .httpError(let code, _): "HTTP \(code)"
        case .decodingError(let e): "Decode error: \(e.localizedDescription)"
        case .networkError(let e): "Network error: \(e.localizedDescription)"
        case .rateLimited: "Rate limited — try again later"
        case .noData: "No data returned"
        }
    }
}

final class APIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func fetch<T: Decodable>(_ type: T.Type, from url: URL, headers: [String: String] = [:]) async throws -> T {
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        logger.debug("GET \(url.absoluteString)")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299: break
            case 429: throw APIError.rateLimited
            default: throw APIError.httpError(statusCode: http.statusCode, body: data)
            }
        }

        do {
            return try JSONDecoder.iso8601().decode(T.self, from: data)
        } catch {
            logger.error("Decode failed: \(error)")
            throw APIError.decodingError(error)
        }
    }

    func fetchData(from url: URL, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299: break
            case 429: throw APIError.rateLimited
            default: throw APIError.httpError(statusCode: http.statusCode, body: data)
            }
        }
        return data
    }
}

extension JSONDecoder {
    static func iso8601() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
