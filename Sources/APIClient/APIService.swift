import Foundation

/// Service that can make a API call if provided with APIRequest object
final class APIService {
    static let shared = APIService()

    public var baseUrl: String?

    // MARK: - Init
    private init() {
        self.baseUrl = nil
    }

    public func configure(with baseUrl: String) {
        guard baseUrl.isEmpty else { fatalError("Can't configure with empty string") }
        self.baseUrl = baseUrl
    }

    /// An enum with coresponding errors for simpler error handling and naming
    enum APIServiceError: Error {
        case failedToCreateRequest
        case failedToFetchData
        case failedToDecodeData
    }

    // MARK: - Implementation
    /// Creating request with provided params
    private func requestFrom(_ apiRequest: APIRequest) -> URLRequest? {
        guard let url = apiRequest.url else { return nil }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = apiRequest.httpMethod.rawValue
        return urlRequest
    }

    /// Executing the request.
    /// Parameter T is generic type that has to comfort to Codable protocol.
    public func execute<T: Codable>(_ request: APIRequest,
                                    expected type: T.Type,
                                    completion: @escaping (Result<T, Error>) -> Void) {
        guard let urlRequest = requestFrom(request) else {
            completion(.failure(APIServiceError.failedToCreateRequest))
            return
        }
        let task =  URLSession.shared.dataTask(with: urlRequest) { data, _, error in
            guard error == nil, let data = data else {
                completion(.failure(error ?? APIServiceError.failedToFetchData))
                return
            }
            do {
                let result = try JSONDecoder().decode(type.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
