import AppKit
import AuthenticationServices
import CryptoKit
import Foundation
import Security

final class SpotifyWebAPIClient: NSObject {
    typealias ResultHandler<T> = (Result<T, Error>) -> Void

    static let redirectURI = "notchshelf://spotify-auth"
    static let requiredScopes = [
        "user-library-read",
        "user-library-modify",
        "playlist-read-private",
        "playlist-read-collaborative"
    ]

    private let tokenStore = SpotifyTokenStore()
    private var authSession: ASWebAuthenticationSession?
    private var pendingVerifier: String?
    private var pendingState: String?

    func hasToken() -> Bool {
        tokenStore.load() != nil
    }

    func hasRequiredScopes() -> Bool {
        guard let token = tokenStore.load() else { return false }
        let grantedScopes = Set(token.scope.split(separator: " ").map(String.init))
        return Self.requiredScopes.allSatisfy { grantedScopes.contains($0) }
    }

    func authorize(clientID: String, completion: @escaping ResultHandler<Void>) {
        let verifier = Self.randomCodeVerifier()
        let state = UUID().uuidString

        pendingVerifier = verifier
        pendingState = state

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "scope", value: Self.requiredScopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: Self.codeChallenge(for: verifier)),
            URLQueryItem(name: "state", value: state)
        ]

        guard let url = components?.url else {
            completion(.failure(SpotifyWebAPIError.invalidAuthURL))
            return
        }

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "notchshelf"
        ) { [weak self] callbackURL, error in
            guard let self else { return }
            self.authSession = nil

            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let callbackURL,
                  let result = Self.authorizationResult(from: callbackURL),
                  result.state == self.pendingState,
                  let verifier = self.pendingVerifier else {
                DispatchQueue.main.async {
                    completion(.failure(SpotifyWebAPIError.invalidAuthCallback))
                }
                return
            }

            self.exchangeCode(result.code, verifier: verifier, clientID: clientID, completion: completion)
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        authSession = session

        if !session.start() {
            authSession = nil
            completion(.failure(SpotifyWebAPIError.couldNotStartAuthorization))
        }
    }

    func checkSaved(uri: String, clientID: String, completion: @escaping ResultHandler<Bool>) {
        authorizedRequest(
            endpoint: "https://api.spotify.com/v1/me/library/contains",
            method: "GET",
            queryItems: [URLQueryItem(name: "uris", value: uri)],
            clientID: clientID
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let values = try JSONDecoder().decode([Bool].self, from: data)
                    completion(.success(values.first ?? false))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func save(uri: String, clientID: String, completion: @escaping ResultHandler<Void>) {
        updateLibrary(uri: uri, method: "PUT", clientID: clientID, completion: completion)
    }

    func remove(uri: String, clientID: String, completion: @escaping ResultHandler<Void>) {
        updateLibrary(uri: uri, method: "DELETE", clientID: clientID, completion: completion)
    }

    func playlists(clientID: String, completion: @escaping ResultHandler<[SpotifyPlaylist]>) {
        authorizedRequest(
            endpoint: "https://api.spotify.com/v1/me/playlists",
            method: "GET",
            queryItems: [
                URLQueryItem(name: "limit", value: "50"),
                URLQueryItem(name: "offset", value: "0")
            ],
            clientID: clientID
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(SpotifyPlaylistsResponse.self, from: data)
                    completion(.success(response.items.map(\.playlist)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func updateLibrary(
        uri: String,
        method: String,
        clientID: String,
        completion: @escaping ResultHandler<Void>
    ) {
        authorizedRequest(
            endpoint: "https://api.spotify.com/v1/me/library",
            method: method,
            queryItems: [URLQueryItem(name: "uris", value: uri)],
            clientID: clientID
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func authorizedRequest(
        endpoint: String,
        method: String,
        queryItems: [URLQueryItem],
        clientID: String,
        didRetry: Bool = false,
        completion: @escaping ResultHandler<Data>
    ) {
        accessToken(clientID: clientID) { [weak self] tokenResult in
            guard let self else { return }

            switch tokenResult {
            case .success(let accessToken):
                guard var components = URLComponents(string: endpoint) else {
                    completion(.failure(SpotifyWebAPIError.invalidAPIURL))
                    return
                }

                components.queryItems = queryItems
                guard let url = components.url else {
                    completion(.failure(SpotifyWebAPIError.invalidAPIURL))
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }

                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    if statusCode == 401, !didRetry {
                        self.tokenStore.clear()
                        self.authorizedRequest(
                            endpoint: endpoint,
                            method: method,
                            queryItems: queryItems,
                            clientID: clientID,
                            didRetry: true,
                            completion: completion
                        )
                        return
                    }

                    guard (200..<300).contains(statusCode) else {
                        DispatchQueue.main.async {
                            completion(.failure(SpotifyWebAPIError.apiStatus(statusCode)))
                        }
                        return
                    }

                    DispatchQueue.main.async {
                        completion(.success(data ?? Data()))
                    }
                }.resume()

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func accessToken(clientID: String, completion: @escaping ResultHandler<String>) {
        guard let token = tokenStore.load() else {
            completion(.failure(SpotifyWebAPIError.authorizationRequired))
            return
        }

        if !token.isExpiringSoon {
            completion(.success(token.accessToken))
            return
        }

        refresh(token: token, clientID: clientID) { [weak self] result in
            switch result {
            case .success(let refreshed):
                self?.tokenStore.save(refreshed)
                completion(.success(refreshed.accessToken))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func exchangeCode(
        _ code: String,
        verifier: String,
        clientID: String,
        completion: @escaping ResultHandler<Void>
    ) {
        tokenRequest(
            clientID: clientID,
            parameters: [
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": Self.redirectURI,
                "code_verifier": verifier
            ]
        ) { [weak self] result in
            switch result {
            case .success(let token):
                self?.tokenStore.save(token)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func refresh(
        token: SpotifyAuthToken,
        clientID: String,
        completion: @escaping ResultHandler<SpotifyAuthToken>
    ) {
        tokenRequest(
            clientID: clientID,
            parameters: [
                "grant_type": "refresh_token",
                "refresh_token": token.refreshToken
            ],
            fallbackRefreshToken: token.refreshToken,
            completion: completion
        )
    }

    private func tokenRequest(
        clientID: String,
        parameters: [String: String],
        fallbackRefreshToken: String? = nil,
        completion: @escaping ResultHandler<SpotifyAuthToken>
    ) {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {
            completion(.failure(SpotifyWebAPIError.invalidAPIURL))
            return
        }

        var fields = parameters
        fields["client_id"] = clientID

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncoded(fields).data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(statusCode), let data else {
                DispatchQueue.main.async {
                    completion(.failure(SpotifyWebAPIError.apiStatus(statusCode)))
                }
                return
            }

            do {
                let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
                let token = SpotifyAuthToken(
                    accessToken: tokenResponse.accessToken,
                    refreshToken: tokenResponse.refreshToken ?? fallbackRefreshToken ?? "",
                    expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn)),
                    scope: tokenResponse.scope ?? ""
                )
                DispatchQueue.main.async {
                    completion(.success(token))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

extension SpotifyWebAPIClient: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.keyWindow ?? NSApp.windows.first ?? ASPresentationAnchor()
    }
}

private extension SpotifyWebAPIClient {
    struct AuthorizationResult {
        let code: String
        let state: String
    }

    static func authorizationResult(from callbackURL: URL) -> AuthorizationResult? {
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        let code = components?.queryItems?.first { $0.name == "code" }?.value
        let state = components?.queryItems?.first { $0.name == "state" }?.value

        guard let code, let state else { return nil }
        return AuthorizationResult(code: code, state: state)
    }

    static func randomCodeVerifier() -> String {
        let allowed = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        return String(bytes.map { allowed[Int($0) % allowed.count] })
    }

    static func codeChallenge(for verifier: String) -> String {
        let data = Data(verifier.utf8)
        let digest = SHA256.hash(data: data)
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func formEncoded(_ fields: [String: String]) -> String {
        fields
            .sorted { $0.key < $1.key }
            .map { key, value in
                "\(percentEncode(key))=\(percentEncode(value))"
            }
            .joined(separator: "&")
    }

    static func percentEncode(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}

private struct SpotifyTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
    }
}

private struct SpotifyPlaylistsResponse: Decodable {
    let items: [SpotifyPlaylistItem]
}

private struct SpotifyPlaylistItem: Decodable {
    let id: String
    let name: String
    let uri: String
    let owner: SpotifyPlaylistOwner?
    let tracks: SpotifyPlaylistTracks?
    let images: [SpotifyPlaylistImage]

    var playlist: SpotifyPlaylist {
        SpotifyPlaylist(
            id: id,
            name: name,
            uri: uri,
            ownerName: owner?.displayName ?? "",
            trackCount: tracks?.total ?? 0,
            artworkURL: images.first?.url
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case uri
        case owner
        case tracks
        case images
    }
}

private struct SpotifyPlaylistOwner: Decodable {
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

private struct SpotifyPlaylistTracks: Decodable {
    let total: Int
}

private struct SpotifyPlaylistImage: Decodable {
    let url: String
}

private struct SpotifyAuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let scope: String

    var isExpiringSoon: Bool {
        Date().addingTimeInterval(90) >= expiresAt
    }
}

private final class SpotifyTokenStore {
    private let service = "com.ioannismesionis.notchshelf.spotify"
    private let account = "oauth"

    func load() -> SpotifyAuthToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(SpotifyAuthToken.self, from: data)
    }

    func save(_ token: SpotifyAuthToken) {
        guard let data = try? JSONEncoder().encode(token) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}

enum SpotifyWebAPIError: LocalizedError {
    case invalidAuthURL
    case invalidAuthCallback
    case couldNotStartAuthorization
    case invalidAPIURL
    case authorizationRequired
    case apiStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidAuthURL:
            return "Could not build Spotify authorization URL."
        case .invalidAuthCallback:
            return "Spotify authorization did not complete."
        case .couldNotStartAuthorization:
            return "Could not open Spotify authorization."
        case .invalidAPIURL:
            return "Could not build Spotify API request."
        case .authorizationRequired:
            return "Connect Spotify library."
        case .apiStatus(let code):
            return "Spotify API returned \(code)."
        }
    }
}
