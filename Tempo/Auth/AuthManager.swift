// Required SPM packages (Xcode → File → Add Package Dependencies):
//   • GTMAppAuth  — https://github.com/google/GTMAppAuth
//   • AppAuth     — pulled in automatically by GTMAppAuth

import Foundation
import AppKit
import AuthenticationServices

@Observable
final class AuthManager: NSObject {
    var isAuthenticated = false
    var userEmail       = ""
    var isLoading       = false
    var error: String?

    // Uncomment once GTMAppAuth is installed:
    // private var authorization: GTMAppAuthFetcherAuthorization?

    override init() {
        super.init()
        loadStoredAuth()
    }

    // MARK: - Persistence

    func loadStoredAuth() {
        // TODO: restore saved authorization from Keychain
        //   authorization = GTMAppAuthFetcherAuthorization(
        //       fromKeychainForName: Credentials.keychainItemName)
        //   isAuthenticated = authorization?.canAuthorize() ?? false
        //   userEmail = authorization?.userEmail ?? ""
    }

    private func saveAuth() {
        // TODO: persist to Keychain
        //   GTMAppAuthFetcherAuthorization.save(
        //       authorization!, toKeychainForName: Credentials.keychainItemName)
    }

    // MARK: - OAuth Flow

    func startOAuthFlow() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // Build the Google authorization URL manually until GTMAppAuth is added.
        // After adding the package, replace this block with OIDAuthorizationRequest
        // and GTMAppAuth.authState(byPresenting:presenting:callback:).

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id",     value: Credentials.clientID),
            URLQueryItem(name: "redirect_uri",  value: Credentials.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope",         value: Credentials.scopes.joined(separator: " ")),
            URLQueryItem(name: "access_type",   value: "offline"),
            URLQueryItem(name: "prompt",        value: "consent"),
        ]

        guard let authURL = components.url else {
            error = "Failed to build authorization URL."
            return
        }

        let callbackScheme = "com.googleusercontent.apps.400499345876-u9u0no7nqh4r586jue75cafqvh37sg2c"

        do {
            let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                let session = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: callbackScheme
                ) { url, err in
                    if let url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: err ?? AuthError.cancelled)
                    }
                }
                session.prefersEphemeralWebBrowserSession = false
                session.presentationContextProvider = self
                session.start()
            }

            try await exchangeCode(from: callbackURL)
        } catch AuthError.cancelled {
            // User dismissed the sheet — not a real error.
        } catch {
            self.error = error.localizedDescription
        }
    }

    func signOut() {
        // TODO: remove from Keychain
        //   GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Credentials.keychainItemName)
        isAuthenticated = false
        userEmail = ""
        // authorization = nil
    }

    // MARK: - Token Exchange

    private func exchangeCode(from callbackURL: URL) async throws {
        guard
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
            let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            throw AuthError.missingCode
        }

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = [
            "code":          code,
            "client_id":     Credentials.clientID,
            "client_secret": Credentials.clientSecret,
            "redirect_uri":  Credentials.redirectURI,
            "grant_type":    "authorization_code",
        ]
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: "&")
        .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // TODO: Replace with GTMAppAuth storage once package is installed.
        //       For now, store in UserDefaults as a temporary bridge.
        UserDefaults.standard.set(tokenResponse.accessToken,  forKey: "tempo.accessToken")
        UserDefaults.standard.set(tokenResponse.refreshToken, forKey: "tempo.refreshToken")
        UserDefaults.standard.set(
            Date.now.addingTimeInterval(Double(tokenResponse.expiresIn)),
            forKey: "tempo.tokenExpiry"
        )

        isAuthenticated = true
    }

    // MARK: - Token Refresh

    func validAccessToken() async throws -> String {
        // TODO: delegate to GTMAppAuth which handles refresh automatically.
        //   return try await withCheckedThrowingContinuation { continuation in
        //       authorization?.fetcherAuthorizer.authorizeRequest(nil) { error in ... }
        //   }

        let expiry = UserDefaults.standard.object(forKey: "tempo.tokenExpiry") as? Date ?? .distantPast
        if expiry > Date.now.addingTimeInterval(60) {
            return UserDefaults.standard.string(forKey: "tempo.accessToken") ?? ""
        }
        return try await refreshAccessToken()
    }

    private func refreshAccessToken() async throws -> String {
        guard let refreshToken = UserDefaults.standard.string(forKey: "tempo.refreshToken") else {
            throw AuthError.noRefreshToken
        }

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = [
            "refresh_token": refreshToken,
            "client_id":     Credentials.clientID,
            "client_secret": Credentials.clientSecret,
            "grant_type":    "refresh_token",
        ]
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: "&")
        .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        UserDefaults.standard.set(tokenResponse.accessToken, forKey: "tempo.accessToken")
        UserDefaults.standard.set(
            Date.now.addingTimeInterval(Double(tokenResponse.expiresIn)),
            forKey: "tempo.tokenExpiry"
        )

        return tokenResponse.accessToken
    }
}

// MARK: - Supporting Types

private struct TokenResponse: Decodable {
    let accessToken:  String
    let refreshToken: String?
    let expiresIn:    Int

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn    = "expires_in"
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.windows.first(where: { $0.isVisible }) ?? NSWindow()
    }
}

enum AuthError: LocalizedError {
    case cancelled
    case missingCode
    case noRefreshToken

    var errorDescription: String? {
        switch self {
        case .cancelled:      return "Authorization was cancelled."
        case .missingCode:    return "No authorization code returned from Google."
        case .noRefreshToken: return "No refresh token — please sign in again."
        }
    }
}
