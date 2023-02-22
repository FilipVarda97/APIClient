import Foundation

/// Request object that is created with Enpoint, Path Components and Query Parametars
final class APIRequest {
    static let baseUrlNotConfiguredError = "API base url not configured. Use APIService.shared.configure(with: 'URL Here')"
    /// Endpoint returns string to create URL from baseUrl
    /// (Example: "https://api.github.com/search/repositories")
    private let endpoint: APIEndpoint

    /// Path components contains strings that will be added to "baseUrl  + enpoint"
    /// Example: "https://api.github.com/users/FilipVarda97"
    private var pathComponents: [String]

    /// QueryParams contains name and values of params that will be added to" baseUrl  + enpoint" or "baseUrl + enpoint + pathComponents"
    /// Example: "https://api.github.com/search/repositories?q=tetris&sort=stars&order=desc")
    private var queryParams: [URLQueryItem]

    /// Create urlString from all provided parametars (Example: "https://api.github.com/search/repositories?q=tetris")
    private var urlString: String {
        guard let baseUrl = APIService.shared.baseUrl else { fatalError(APIRequest.baseUrlNotConfiguredError) }
        var string = baseUrl + "/" + endpoint.rawValue

        if !pathComponents.isEmpty {
            pathComponents.forEach() {
                string += "/\($0)"
            }
        }

        if !queryParams.isEmpty {
            string += "?"
            let argument = queryParams.compactMap { item in
                guard let value = item.value else { return nil }
                return "\(item.name)=\(value)"
            }.joined(separator: "&")
            string += argument
        }

        return string
    }

    /// HttpMethod enum defining possible methods for request
    enum HttpMethod: String {
        case get = "GET"
        case put = "PUT"
        case head = "HEAD"
        case post = "POST"
        case delete = "DELETE"
        case connect = "CONNECT"
        case options = "OPTIONS"
        case trace = "TRACE"
    }

    
    public var httpMethod: HttpMethod = .get

    /// Computed URL that is needed to perform a URLRequest
    public var url: URL? {
        return URL(string: urlString)
    }

    // MARK: - Init
    /// Create APIRequest with provided enpoint. Path Components and Query Parametars are optional.
    public init(httpMethod: HttpMethod = .get,
                enpoint: APIEndpoint,
                pathComponents: [String] = [],
                queryParams: [URLQueryItem] = []) {
        guard let _ = APIService.shared.baseUrl else { fatalError(APIRequest.baseUrlNotConfiguredError) }
        self.endpoint = enpoint
        self.pathComponents = pathComponents
        self.queryParams = queryParams
    }

    /// Create APIRequest with provided URL. Provided URL must contain baseUrl
    /// - Parameter url: URL to parse and create path components and query items
    convenience init?(url: URL) {
        guard let baseUrl = APIService.shared.baseUrl else { fatalError(APIRequest.baseUrlNotConfiguredError) }
        let string = url.absoluteString
        if !string.contains(baseUrl) {
            return nil
        }
        /// Create pathComponents from urlString
        let trimmed = string.replacingOccurrences(of: baseUrl + "/", with: "")
        if trimmed.contains("/") {
            let components = trimmed.components(separatedBy: "/")
            if !components.isEmpty {
                let endpointString = components[0]
                var pathComponents: [String] = []
                if components.count > 1 {
                    pathComponents = components
                    pathComponents.removeFirst()
                }
                if let endpoint = APIEndpoint(rawValue: endpointString) {
                    self.init(enpoint: endpoint, pathComponents: pathComponents)
                    return
                }
            }
        /// Create queryParams from urlString
        } else if trimmed.contains("?") {
            let components = trimmed.components(separatedBy: "?")
            let endpointString = components[0]
            if let endpoint = APIEndpoint(rawValue: endpointString) {
                let queryParamsString = trimmed.replacingOccurrences(of: endpoint.rawValue + "?", with: "")
                let queryComponents = queryParamsString.components(separatedBy: "&")
                let queryParams: [URLQueryItem] = queryComponents.compactMap { queryComponent in
                    guard queryComponent.contains("=") else {
                        return nil
                    }
                    let parts = queryComponent.components(separatedBy: "=")
                    return URLQueryItem(name: parts[0], value: parts[1])
                }
                self.init(enpoint: endpoint, queryParams: queryParams)
                return
            }
        }
        return nil
    }
}
